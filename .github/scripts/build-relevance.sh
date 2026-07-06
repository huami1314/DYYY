#!/usr/bin/env bash

set -euo pipefail

zero_sha="0000000000000000000000000000000000000000"

is_direct_build_path() {
    local path=$1

    case "$path" in
        DYYY.plist|control|Resources/*|layout/*)
            return 0
            ;;
    esac

    if [[ "$path" != */* ]]; then
        case "$path" in
            *.h|*.m|*.mm|*.x|*.xm|*.c|*.cc|*.cpp|*.s|*.S)
                return 0
                ;;
        esac
    fi

    return 1
}

normalize_makefile_revision() {
    local revision=$1
    local makefile_content

    if ! makefile_content=$(git show "${revision}:Makefile" 2>/dev/null); then
        return 0
    fi

    printf '%s\n' "$makefile_content" |
        awk '
            BEGIN {
                skip_device_block = 0
                skip_after_package = 0
            }

            skip_device_block {
                if ($0 ~ /^[[:space:]]*THEOS_DEVICE_PORT[[:space:]]*[:+?]?=/) {
                    skip_device_block = 0
                }
                next
            }

            /^[[:space:]]*ifeq[[:space:]]*\(\$\(shell whoami\),huami\)/ {
                skip_device_block = 1
                next
            }

            skip_after_package {
                line = $0
                gsub(/^[[:space:]]+|[[:space:]\\]+$/, "", line)
                if (line == "fi") {
                    skip_after_package = 0
                }
                next
            }

            /^after-package::[[:space:]]*$/ {
                skip_after_package = 1
                next
            }

            /^[[:space:]]*THEOS_DEVICE_(IP|PORT)[[:space:]]*[:+?]?=/ {
                next
            }

            {
                line = $0
                sub(/[[:space:]]*#.*/, "", line)
                gsub(/[[:space:]]+/, " ", line)
                sub(/^ /, "", line)
                sub(/ $/, "", line)

                if (line == "" || line == "-include Makefile.local") {
                    next
                }

                print line
            }
        '
}

makefile_affects_build() {
    local before=$1
    local after=$2
    local before_file
    local after_file
    local result

    before_file=$(mktemp)
    after_file=$(mktemp)

    normalize_makefile_revision "$before" > "$before_file"
    normalize_makefile_revision "$after" > "$after_file"

    if cmp -s "$before_file" "$after_file"; then
        result=1
    else
        result=0
    fi

    rm -f "$before_file" "$after_file"
    return "$result"
}

commit_touches_path() {
    local hash=$1
    local expected_path=$2

    git diff-tree --root --no-commit-id --name-only -r "$hash" |
        grep -Fxq "$expected_path"
}

commit_touches_direct_build_path() {
    local hash=$1
    local path

    while IFS= read -r path; do
        if is_direct_build_path "$path"; then
            return 0
        fi
    done < <(git diff-tree --root --no-commit-id --name-only -r "$hash")

    return 1
}

commit_affects_build() {
    local hash=$1
    local parent

    if commit_touches_direct_build_path "$hash"; then
        return 0
    fi

    if ! commit_touches_path "$hash" "Makefile"; then
        return 1
    fi

    parent=$(git rev-parse "${hash}^" 2>/dev/null || git hash-object -t tree /dev/null)
    makefile_affects_build "$parent" "$hash"
}

range_affects_build() {
    local before=$1
    local after=$2
    local path
    local makefile_changed=false

    if [[ -z "$before" || "$before" == "$zero_sha" ]] ||
       ! git cat-file -e "${before}^{commit}" 2>/dev/null; then
        before=$(git hash-object -t tree /dev/null)
    fi

    while IFS= read -r path; do
        if is_direct_build_path "$path"; then
            return 0
        fi

        if [[ "$path" == "Makefile" ]]; then
            makefile_changed=true
        fi
    done < <(git diff --name-only "$before" "$after")

    if [[ "$makefile_changed" == true ]]; then
        makefile_affects_build "$before" "$after"
        return
    fi

    return 1
}

main() {
    local command=${1:-}

    case "$command" in
        commit)
            commit_affects_build "$2"
            ;;
        range)
            range_affects_build "$2" "$3"
            ;;
        makefile)
            makefile_affects_build "$2" "$3"
            ;;
        *)
            echo "Usage: $0 {commit <sha>|range <before> <after>|makefile <before> <after>}" >&2
            exit 2
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]:-$0}" == "$0" ]]; then
    main "$@"
fi
