#!/usr/bin/env bash

set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
workflow_file=${WORKFLOW_FILE:-build.yml}
source_run_id=${SOURCE_BUILD_RUN_ID:-${GITHUB_RUN_ID:-}}
source_run_number=${SOURCE_BUILD_RUN_NUMBER:-${GITHUB_RUN_NUMBER:-}}
source_sha=${SOURCE_BUILD_SHA:-${GITHUB_SHA:-}}
branch=${SOURCE_BUILD_BRANCH:-${GITHUB_REF_NAME:-main}}
max_wait_seconds=${RELEASE_COORDINATOR_MAX_WAIT_SECONDS:-3600}
poll_interval_seconds=${RELEASE_COORDINATOR_POLL_INTERVAL_SECONDS:-30}
settle_seconds=${RELEASE_COORDINATOR_SETTLE_SECONDS:-30}
release_min_interval_seconds=${RELEASE_MIN_INTERVAL_SECONDS:-43200}
start_time=$(date +%s)

require_env() {
    local name=$1

    if [[ -z "${!name:-}" ]]; then
        echo "Missing required environment variable: ${name}" >&2
        exit 2
    fi
}

set_should_publish() {
    local value=$1

    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "should_publish=${value}" >> "$GITHUB_OUTPUT"
    fi

    echo "should_publish=${value}"
}

workflow_runs_json() {
    local attempt

    for attempt in 1 2 3; do
        if gh api -X GET \
            "repos/${GITHUB_REPOSITORY}/actions/workflows/${workflow_file}/runs" \
            -f branch="${branch}" \
            -f per_page=100; then
            return 0
        fi

        echo "Failed to fetch workflow runs (attempt ${attempt}/3)." >&2
        sleep 5
    done

    return 1
}

fetch_branch_head() {
    git fetch --no-tags origin "${branch}" >/dev/null 2>&1 || true
}

newer_run_is_build_relevant() {
    local event=$1
    local head_sha=$2

    if [[ "$event" == "workflow_dispatch" ]]; then
        return 0
    fi

    fetch_branch_head

    if ! git cat-file -e "${head_sha}^{commit}" 2>/dev/null; then
        echo "Unable to inspect newer run ${head_sha}; treating it as build-relevant." >&2
        return 0
    fi

    "${script_dir}/build-relevance.sh" range "$source_sha" "$head_sha"
}

has_newer_build_relevant_run() {
    local runs_json=$1
    local run_id
    local run_number
    local status
    local event
    local head_sha

    while IFS=$'\t' read -r run_id run_number status event head_sha; do
        [[ -n "${run_id:-}" ]] || continue

        if newer_run_is_build_relevant "$event" "$head_sha"; then
            echo "Newer build-relevant ${workflow_file} run #${run_number} (${status}, ${head_sha}) exists; this run will not publish a Release."
            return 0
        fi
    done < <(
        jq -r \
            --argjson current_run_number "$source_run_number" \
            --arg current_run_id "$source_run_id" \
            '.workflow_runs[]
             | select((.id | tostring) != $current_run_id)
             | select(.run_number > $current_run_number)
             | select(.event == "push" or .event == "workflow_dispatch")
             | [.id, .run_number, .status, .event, .head_sha]
             | @tsv' <<< "$runs_json"
    )

    return 1
}

active_older_run_count() {
    local runs_json=$1

    jq -r \
        --argjson current_run_number "$source_run_number" \
        --arg current_run_id "$source_run_id" \
        '.workflow_runs
         | map(select((.id | tostring) != $current_run_id)
               | select(.run_number < $current_run_number)
               | select(.event == "push" or .event == "workflow_dispatch")
               | select(.status != "completed"))
         | length' <<< "$runs_json"
}

iso8601_to_epoch() {
    local timestamp=$1

    if command -v python3 >/dev/null 2>&1; then
        python3 -c 'from datetime import datetime, timezone; import sys; print(int(datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00")).timestamp()))' "$timestamp"
        return
    fi

    if date -u -d "$timestamp" +%s >/dev/null 2>&1; then
        date -u -d "$timestamp" +%s
        return
    fi

    date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$timestamp" +%s
}

latest_release_json() {
    gh api -X GET "repos/${GITHUB_REPOSITORY}/releases/latest" 2>/dev/null || true
}

latest_release_is_within_cooldown() {
    local release_json
    local published_at
    local tag_name
    local published_epoch
    local now
    local age

    if (( release_min_interval_seconds <= 0 )); then
        return 1
    fi

    release_json=$(latest_release_json)
    if [[ -z "$release_json" ]]; then
        echo "No previous GitHub Release found; publishing Release."
        return 1
    fi

    published_at=$(jq -r '.published_at // empty' <<< "$release_json")
    tag_name=$(jq -r '.tag_name // "unknown"' <<< "$release_json")
    if [[ -z "$published_at" ]]; then
        echo "Latest GitHub Release has no published_at timestamp; publishing Release."
        return 1
    fi

    if ! published_epoch=$(iso8601_to_epoch "$published_at"); then
        echo "Unable to parse latest Release time (${published_at}); publishing Release." >&2
        return 1
    fi

    now=$(date -u +%s)
    age=$((now - published_epoch))
    if (( age < release_min_interval_seconds )); then
        echo "Latest Release ${tag_name} was published ${age}s ago; minimum interval is ${release_min_interval_seconds}s. Skipping Release publication and keeping artifacts only."
        return 0
    fi

    echo "Latest Release ${tag_name} was published ${age}s ago; publishing Release."
    return 1
}

main() {
    local quiet_period_seen=false
    local runs_json
    local older_count
    local now
    local elapsed

    require_env GITHUB_REPOSITORY
    require_env source_run_id
    require_env source_run_number
    require_env source_sha

    while true; do
        runs_json=$(workflow_runs_json)

        if has_newer_build_relevant_run "$runs_json"; then
            set_should_publish false
            return 0
        fi

        older_count=$(active_older_run_count "$runs_json")
        if [[ "$older_count" == "0" ]]; then
            if [[ "$quiet_period_seen" == false && "$settle_seconds" -gt 0 ]]; then
                quiet_period_seen=true
                echo "No older active build deb runs remain; waiting ${settle_seconds}s for the run list to settle."
                sleep "$settle_seconds"
                continue
            fi

            if latest_release_is_within_cooldown; then
                set_should_publish false
                return 0
            fi

            echo "This is the latest build-relevant completed packaging run; publishing Release."
            set_should_publish true
            return 0
        fi

        now=$(date +%s)
        elapsed=$((now - start_time))
        if (( elapsed >= max_wait_seconds )); then
            echo "Timed out waiting for older build deb runs to finish after ${elapsed}s." >&2
            exit 1
        fi

        echo "Waiting for ${older_count} older build deb run(s) to finish before publishing Release."
        sleep "$poll_interval_seconds"
    done
}

main "$@"
