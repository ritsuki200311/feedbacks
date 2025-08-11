#!/usr/bin/env bash
set -euo pipefail

# Open a file in VS Code, reusing the current window if possible.
# Usage: bash script/open_in_vscode.sh [path] [line] [column]

path=${1:-}
line=${2:-1}
col=${3:-1}

if [[ -z "$path" ]]; then
  echo "Usage: $0 <path> [line] [column]" >&2
  exit 1
fi

if command -v code >/dev/null 2>&1; then
  # --goto ensures VS Code jumps and (re)loads the file buffer
  code --reuse-window --goto "$path:$line:$col"
else
  # Fallback for macOS without 'code' CLI
  if [[ "$(uname)" == "Darwin" ]]; then
    open -a "Visual Studio Code" "$path"
  else
    echo "VS Code CLI not found. Install it from VS Code: 'Shell Command: Install \"code\" command in PATH'" >&2
    exit 2
  fi
fi

