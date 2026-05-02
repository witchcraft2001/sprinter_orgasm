#!/usr/bin/env bash
set -euo pipefail

if ! command -v mformat >/dev/null 2>&1 || ! command -v mcopy >/dev/null 2>&1 || ! command -v mmd >/dev/null 2>&1; then
  echo "Error: mtools is required (mformat, mcopy and mmd were not found)." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

exe_path="${1:-$repo_root/out/orgasm.exe}"
image_path="${2:-$repo_root/distr/orgasm.img}"
examples_dir="$repo_root/examples"

validate_83() {
  local name="$1"

  if [[ ! "$name" =~ ^[A-Za-z0-9_-]{1,8}(\.[A-Za-z0-9_-]{1,3})?$ ]]; then
    echo "Error: '$name' is not an 8.3-compatible file name." >&2
    exit 1
  fi
}

copy_file() {
  local src="$1"
  local dst="$2"

  validate_83 "$(basename "$dst")"
  mcopy -i "$image_path" -o "$src" "::$dst"
}

if [ ! -f "$exe_path" ]; then
  make -C "$repo_root"
fi

if [ ! -f "$exe_path" ]; then
  echo "Error: executable not found: $exe_path" >&2
  exit 1
fi

mkdir -p "$(dirname "$image_path")"
rm -f "$image_path"

mformat -C -i "$image_path" -f 1440 ::
copy_file "$exe_path" "ORGASM.EXE"
copy_file "$repo_root/README" "README"
copy_file "$repo_root/README.eng" "README.ENG"
copy_file "$repo_root/HISTORY" "HISTORY"

if [ -d "$examples_dir" ]; then
  mmd -i "$image_path" ::/EXAMPLES
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
    mcopy -i "$image_path" -o "$example_path" "::/EXAMPLES/$upper_name"
  done < <(find "$examples_dir" -maxdepth 1 -type f ! -name '.*' | sort)
fi

echo "Created FAT12 image: $image_path"
