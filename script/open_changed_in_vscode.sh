#!/usr/bin/env bash
set -euo pipefail

# Open DEV_NOTES.md and up to 3 additional changed files in VS Code.
# Usage: bash script/open_changed_in_vscode.sh <path1> [path2 ...]

root_dir=$(pwd)
mode_file=".codexcli/auto_open_mode"
mode="B"
[[ -f "$mode_file" ]] && mode=$(cat "$mode_file" | tr -d '\n' | tr '[:lower:]' '[:upper:]')

if ! command -v code >/dev/null 2>&1; then
  if [[ "$(uname)" == "Darwin" ]]; then
    # Fallback: open without line targeting
    open -a "Visual Studio Code" >/dev/null 2>&1 || true
  fi
fi

open_file() {
  local p="$1"; local line="${2:-1}"; local col="${3:-1}"
  if command -v code >/dev/null 2>&1; then
    code --reuse-window --goto "$p:$line:$col" || true
  else
    if [[ "$(uname)" == "Darwin" ]]; then
      open -a "Visual Studio Code" "$p" || true
    fi
  fi
}

# Always open DEV_NOTES.md if exists
if [[ -f "DEV_NOTES.md" ]]; then
  open_file "DEV_NOTES.md" 1 1
fi

# Respect mode: A opens only DEV_NOTES.md; B opens up to 3 more; C does nothing extra
if [[ "$mode" == "C" ]]; then
  exit 0
fi

if [[ "$mode" == "A" ]]; then
  exit 0
fi

# Mode B: open up to 3 prioritized files
files=()
for arg in "$@"; do
  if [[ -f "$arg" ]]; then
    # simple dedup without associative arrays
    already=0
    for e in "${files[@]}"; do
      [[ "$e" == "$arg" ]] && already=1 && break
    done
    [[ $already -eq 0 ]] && files+=("$arg")
  fi
done

# Prioritize controllers > views > others
prio_list=()
for f in "${files[@]}"; do
  case "$f" in
    app/controllers/*) prio=1;;
    app/views/*) prio=2;;
    *) prio=3;;
  esac
  prio_list+=("$prio|$f")
done

IFS=$'\n' sorted=($(printf '%s\n' "${prio_list[@]}" | sort))
count=0
for item in "${sorted[@]}"; do
  path="${item#*|}"
  open_file "$path" 1 1
  count=$((count+1))
  [[ $count -ge 3 ]] && break
done
