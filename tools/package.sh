#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

if ! command -v zip >/dev/null 2>&1; then
  echo "Error: zip is not installed or not in PATH" >&2
  exit 1
fi

exe_path="${1:-$repo_root/out/orgasm.exe}"
zip_path="${2:-$repo_root/distr/orgasm.zip}"
package_root="$repo_root/out/package"
package_dir="$package_root/ORGASM"
examples_dir="$repo_root/examples"

validate_83() {
  local name="$1"

  if [[ ! "$name" =~ ^[A-Za-z0-9_-]{1,8}(\.[A-Za-z0-9_-]{1,3})?$ ]]; then
    echo "Error: '$name' is not an 8.3-compatible file name." >&2
    exit 1
  fi
}

copy_package_file() {
  local src="$1"
  local dst="$2"

  validate_83 "$(basename "$dst")"
  cp "$src" "$package_dir/$dst"
}

if [ ! -f "$exe_path" ]; then
  make -C "$repo_root"
fi

if [ ! -f "$exe_path" ]; then
  echo "Error: executable not found: $exe_path" >&2
  exit 1
fi

mkdir -p "$(dirname "$zip_path")"
zip_dir="$(cd "$(dirname "$zip_path")" && pwd)"
zip_path="$zip_dir/$(basename "$zip_path")"

rm -rf "$package_dir"
mkdir -p "$package_dir/EXAMPLES"

copy_package_file "$exe_path" "ORGASM.EXE"
copy_package_file "$repo_root/README" "README"
copy_package_file "$repo_root/README.eng" "README.ENG"
copy_package_file "$repo_root/HISTORY" "HISTORY"

if [ -d "$examples_dir" ]; then
  seen_example_names="|"
  while IFS= read -r example_path; do
    example_name="$(basename "$example_path")"
    validate_83 "$example_name"
    upper_name="$(printf '%s' "$example_name" | tr '[:lower:]' '[:upper:]')"
    if [[ "$seen_example_names" == *"|$upper_name|"* ]]; then
      echo "Error: duplicate 8.3 example name after uppercasing: $upper_name" >&2
      exit 1
    fi
    seen_example_names="$seen_example_names$upper_name|"
    cp "$example_path" "$package_dir/EXAMPLES/$upper_name"
  done < <(find "$examples_dir" -maxdepth 1 -type f ! -name '.*' | sort)
fi

rm -f "$zip_path"
cd "$package_root"
zip -qr "$zip_path" ORGASM

echo "Created $zip_path"
