#!/usr/bin/env bash
set -euo pipefail

if ! command -v mformat >/dev/null 2>&1 || ! command -v mcopy >/dev/null 2>&1 || ! command -v mmd >/dev/null 2>&1; then
  echo "Error: mtools is required (mformat, mcopy and mmd were not found)." >&2
  exit 1
fi

if ! command -v iconv >/dev/null 2>&1; then
  echo "Error: iconv is required to convert documentation to CP866." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"

exe_path="${1:-$repo_root/out/orgasm.exe}"
image_path="${2:-$repo_root/distr/orgasm.img}"
examples_dir="$repo_root/examples"
tmp_dir="$(mktemp -d)"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

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

copy_file() {
  local src="$1"
  local dst="$2"

  validate_83 "$(basename "$dst")"
  mcopy -i "$image_path" -o "$src" "::$dst"
}

copy_cp866_file() {
  local src="$1"
  local dst="$2"
  local converted="$tmp_dir/$(basename "$dst")"

  validate_83 "$(basename "$dst")"
  iconv -f UTF-8 -t CP866 "$src" > "$converted"
  mcopy -i "$image_path" -o "$converted" "::$dst"
}

copy_source_file() {
  local src="$1"
  local dst="$2"
  local converted="$tmp_dir/$(basename "$dst").src"

  validate_83 "$(basename "$dst")"
  # CRLF first (awk on UTF-8 input), then convert to CP866
  awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "$src" \
    | iconv -f UTF-8 -t CP866 \
    > "$converted"
  mcopy -i "$image_path" -o "$converted" "::/SOURCES/$dst"
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
  local converted="$tmp_dir/$(basename "$dst").cr"

  if is_example_text_file "$dst"; then
    awk '{ sub(/\r$/, ""); printf "%s\r\n", $0 }' "$src" > "$converted"
    mcopy -i "$image_path" -o "$converted" "::/EXAMPLES/$dst"
  else
    mcopy -i "$image_path" -o "$src" "::/EXAMPLES/$dst"
  fi
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
copy_cp866_file "$repo_root/README" "README"
copy_cp866_file "$repo_root/README.eng" "README.ENG"
copy_cp866_file "$repo_root/HISTORY" "HISTORY"

mmd -i "$image_path" ::/SOURCES
seen_source_paths="|"
while IFS= read -r src_file; do
  base="$(basename "$src_file")"
  upper_name="$(printf '%s' "$base" | tr '[:lower:]' '[:upper:]')"
  if [[ "$seen_source_paths" == *"|$upper_name|"* ]]; then
    echo "Error: duplicate 8.3 source name after uppercasing: $upper_name" >&2
    exit 1
  fi
  seen_source_paths="$seen_source_paths$upper_name|"
  copy_source_file "$src_file" "$upper_name"
done < <(find "$repo_root" -maxdepth 1 -type f \
           \( -iname '*.asm' -o -iname 'Makefile' -o -iname '*.bat' \) \
           ! -iname 'orgasm.lst' \
           | sort)

if [ -d "$examples_dir" ]; then
  mmd -i "$image_path" ::/EXAMPLES
  seen_example_paths="|EXAMPLES|"
  while IFS= read -r example_path; do
    rel_path="${example_path#$examples_dir/}"
    upper_path="$(path_to_83_upper "$rel_path")"
    if [[ "$seen_example_paths" == *"|$upper_path|"* ]]; then
      echo "Error: duplicate 8.3 example path after uppercasing: $upper_path" >&2
      exit 1
    fi
    seen_example_paths="$seen_example_paths$upper_path|"
    mmd -i "$image_path" "::/EXAMPLES/$upper_path"
  done < <(find "$examples_dir" -mindepth 1 -type d ! -path '*/.*' | sort)

  while IFS= read -r example_path; do
    rel_path="${example_path#$examples_dir/}"
    upper_path="$(path_to_83_upper "$rel_path")"
    if [[ "$seen_example_paths" == *"|$upper_path|"* ]]; then
      echo "Error: duplicate 8.3 example path after uppercasing: $upper_path" >&2
      exit 1
    fi
    seen_example_paths="$seen_example_paths$upper_path|"
    copy_example_file "$example_path" "$upper_path"
  done < <(find "$examples_dir" -type f ! -path '*/.*' | sort)
fi

echo "Created FAT12 image: $image_path"
