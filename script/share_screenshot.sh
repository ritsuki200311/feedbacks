#!/usr/bin/env bash
set -euo pipefail

# Copies a screenshot/image into the workspace at design/<dest_name>
# Usage:
#   bash script/share_screenshot.sh "/full/path/to/file.png" [dest-name.png]
#   bash script/share_screenshot.sh   # auto-detect latest screenshot (Desktop/TemporaryItems)

dest_dir="design"
mkdir -p "$dest_dir"

_next_name() {
  local base="$1" ext="$2" i=1
  local candidate="$base.$ext"
  while [[ -e "$dest_dir/$candidate" ]]; do
    candidate="${base}-${i}.${ext}"
    i=$((i+1))
  done
  printf '%s' "$candidate"
}

# Resolve source
if [[ "${1:-}" != "" ]]; then
  src="$1"
else
  desktop="$HOME/Desktop"
  cand=""
  if [[ -d "$desktop" ]]; then
    cand=$(ls -t \
      "$desktop"/スクリーンショット*.png \
      "$desktop"/スクリーンショット*.jpg \
      "$desktop"/スクリーンショット*.jpeg \
      "$desktop"/Screen\ Shot*.png \
      "$desktop"/Screen\ Shot*.jpg \
      "$desktop"/Screen\ Shot*.jpeg \
      2>/dev/null | head -n1 || true)
  fi
  # Try TemporaryItems (when screenshot is not yet saved to Desktop)
  if [[ -z "${cand}" ]]; then
    cand=$(ls -t /var/folders/*/*/*/TemporaryItems/NSIRD_screencaptureui_*/**/* 2>/dev/null | head -n1 || true)
  fi
  if [[ -z "$cand" ]]; then
    echo "No screenshot path provided and no recent screenshot found." >&2
    echo "Usage: $0 \"/full/path/to/file.png\" [dest-name.png]" >&2
    exit 1
  fi
  src="$cand"
fi

# Determine destination name
if [[ "${2:-}" != "" ]]; then
  dest_name="$2"
else
  # Use source extension if available, default to png
  filename=$(basename -- "$src")
  ext="${filename##*.}"
  [[ "$ext" == "$filename" ]] && ext="png"
  dest_name=$(_next_name "screenshot" "$ext")
fi

cp "$src" "$dest_dir/$dest_name"
ls -lh "$dest_dir/$dest_name"
echo "✓ Copied to $dest_dir/$dest_name"
