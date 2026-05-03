#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

if ! command -v zip >/dev/null 2>&1; then
  echo "Error: zip is not installed or not in PATH" >&2
  exit 1
fi

if ! command -v iconv >/dev/null 2>&1; then
  echo "Error: iconv is required to convert documentation to CP866." >&2
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

path_to_83_upper() {
  local path="$1"
  local part
  local upper_part
  local result=""

  while [ -n "$path" ]; do
    if [[ "$path" == */* ]]; then
      part="${path%%/*}"
      path="${path#*/}"
    else
      part="$path"
      path=""
    fi

    validate_83 "$part"
    upper_part="$(printf '%s' "$part" | tr '[:lower:]' '[:upper:]')"
    if [ -n "$result" ]; then
      result="$result/$upper_part"
    else
      result="$upper_part"
    fi
  done

  printf '%s' "$result"
}

copy_package_file() {
  local src="$1"
  local dst="$2"

  validate_83 "$(basename "$dst")"
  cp "$src" "$package_dir/$dst"
}

copy_package_cp866_file() {
  local src="$1"
  local dst="$2"

  validate_83 "$(basename "$dst")"
  iconv -f UTF-8 -t CP866 "$src" > "$package_dir/$dst"
}

is_example_text_file() {
  local name
  name="$(basename "$1" | tr '[:lower:]' '[:upper:]')"

  case "$name" in
    *.ASM|*.BAT|MAKEFILE) return 0 ;;
    *) return 1 ;;
  esac
}

copy_example_file() {
  local src="$1"
  local dst="$2"

  if is_example_text_file "$dst"; then
    awk '{ sub(/\r$/, ""); printf "%s\r", $0 }' "$src" > "$package_dir/EXAMPLES/$dst"
  else
    cp "$src" "$package_dir/EXAMPLES/$dst"
  fi
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
copy_package_cp866_file "$repo_root/README" "README"
copy_package_cp866_file "$repo_root/README.eng" "README.ENG"
copy_package_cp866_file "$repo_root/HISTORY" "HISTORY"

if [ -d "$examples_dir" ]; then
  seen_example_paths="|EXAMPLES|"
  while IFS= read -r example_path; do
    rel_path="${example_path#$examples_dir/}"
    upper_path="$(path_to_83_upper "$rel_path")"
    if [[ "$seen_example_paths" == *"|$upper_path|"* ]]; then
      echo "Error: duplicate 8.3 example path after uppercasing: $upper_path" >&2
      exit 1
    fi
    seen_example_paths="$seen_example_paths$upper_path|"
    mkdir -p "$package_dir/EXAMPLES/$upper_path"
  done < <(find "$examples_dir" -mindepth 1 -type d ! -path '*/.*' | sort)

  while IFS= read -r example_path; do
    rel_path="${example_path#$examples_dir/}"
    upper_path="$(path_to_83_upper "$rel_path")"
    if [[ "$seen_example_paths" == *"|$upper_path|"* ]]; then
      echo "Error: duplicate 8.3 example path after uppercasing: $upper_path" >&2
      exit 1
    fi
    seen_example_paths="$seen_example_paths$upper_path|"
    mkdir -p "$(dirname "$package_dir/EXAMPLES/$upper_path")"
    copy_example_file "$example_path" "$upper_path"
  done < <(find "$examples_dir" -type f ! -path '*/.*' | sort)
fi

rm -f "$zip_path"
cd "$package_root"
zip -qr "$zip_path" ORGASM

echo "Created $zip_path"
