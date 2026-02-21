#!/bin/bash

# PreToolUse hook to block git -C flag
# git -C bypasses other hooks and complicates allowed-list management.
# Use `cd <path> && git <cmd>` instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/command-detect.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if ! has_git_c_flag "$COMMAND"; then
    exit 0
fi

cat << 'EOF' >&2
ERROR: `git -C` is not allowed.

The `-C` flag can bypass other git hooks and complicates command validation.
Use `cd <path> && git <cmd>` instead.
EOF
exit 2
