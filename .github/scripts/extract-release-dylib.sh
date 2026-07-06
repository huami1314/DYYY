#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

package_version=${PACKAGE_VERSION:-$(awk -F': ' '$1 == "Version" { print $2; exit }' control)}
source_deb_glob=${SOURCE_DEB_GLOB:-packages/*arm64e*.deb}
fallback_deb_glob=${FALLBACK_DEB_GLOB:-packages/*roothide*.deb}
output_dir=${OUTPUT_DIR:-packages}
tweak_dylib_name=${TWEAK_DYLIB_NAME:-DYYY.dylib}
required_arch=${REQUIRED_ARCH:-arm64e}

if [[ -z "$package_version" ]]; then
    echo "Unable to read package version from control" >&2
    exit 1
fi

matching_debs=()
while IFS= read -r deb; do
    matching_debs+=("$deb")
done < <(compgen -G "$source_deb_glob" | sort)

if [[ "${#matching_debs[@]}" -eq 0 && -n "$fallback_deb_glob" ]]; then
    while IFS= read -r deb; do
        matching_debs+=("$deb")
    done < <(compgen -G "$fallback_deb_glob" | sort)
fi

if [[ "${#matching_debs[@]}" -ne 1 ]]; then
    echo "Expected exactly one arm64e Deb package, found ${#matching_debs[@]}:" >&2
    printf '  %s\n' "${matching_debs[@]}" >&2
    exit 1
fi

source_deb=${matching_debs[0]}
case "$source_deb" in
    /*) source_deb_path=$source_deb ;;
    *) source_deb_path=$PWD/$source_deb ;;
esac

work_dir=$(mktemp -d)
extract_dir="$work_dir/data"
trap 'rm -rf "$work_dir"' EXIT

mkdir -p "$extract_dir"
(
    cd "$work_dir"
    ar -x "$source_deb_path"
)

data_archives=("$work_dir"/data.tar.*)
if [[ "${#data_archives[@]}" -ne 1 ]]; then
    echo "Expected exactly one data.tar archive in ${source_deb}, found ${#data_archives[@]}" >&2
    exit 1
fi

tar -xf "${data_archives[0]}" -C "$extract_dir"

dylib_paths=()
while IFS= read -r dylib_path; do
    dylib_paths+=("$dylib_path")
done < <(find "$extract_dir" -type f -name "$tweak_dylib_name" | sort)

if [[ "${#dylib_paths[@]}" -eq 0 ]]; then
    while IFS= read -r dylib_path; do
        dylib_paths+=("$dylib_path")
    done < <(find "$extract_dir" -type f -name '*.dylib' | sort)
fi

if [[ "${#dylib_paths[@]}" -ne 1 ]]; then
    echo "Expected exactly one dylib in ${source_deb}, found ${#dylib_paths[@]}:" >&2
    printf '  %s\n' "${dylib_paths[@]}" >&2
    exit 1
fi

mkdir -p "$output_dir"
output_file="${output_dir}/DYYY_${package_version}.dylib"
cp "${dylib_paths[0]}" "$output_file"

if command -v lipo >/dev/null 2>&1; then
    lipo_info=$(lipo -info "$output_file")
    echo "$lipo_info"

    if [[ -n "$required_arch" ]] &&
       ! grep -Eq "(^|[^[:alnum:]_])${required_arch}([^[:alnum:]_]|$)" <<< "$lipo_info"; then
        echo "Extracted dylib does not contain required architecture: ${required_arch}" >&2
        exit 1
    fi
fi

printf 'Package artifact: %s\n' "$output_file"
