#!/usr/bin/env bash
set -euo pipefail

# Set or show auto-open mode: A (DEV_NOTES only), B (DEV_NOTES + up to 3), C (OFF)
# Usage:
#   bash script/auto_open_mode.sh          # show current
#   bash script/auto_open_mode.sh B        # set to B

mode_file=".codexcli/auto_open_mode"

show() {
  if [[ -f "$mode_file" ]]; then
    echo "Current auto-open mode: $(cat "$mode_file")"
  else
    echo "Current auto-open mode: (unset)"
  fi
}

case "${1:-}" in
  A|B|C)
    mkdir -p .codexcli
    echo "$1" > "$mode_file"
    show
    ;;
  "")
    show
    ;;
  *)
    echo "Usage: $0 [A|B|C]" >&2
    exit 1
    ;;
esac

