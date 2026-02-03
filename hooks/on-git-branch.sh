#!/bin/bash
# Hook: Validate branch naming before creating a new branch

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/command-detect.sh"
source "$SCRIPT_DIR/branch-rules.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only process branch creation commands
if ! is_branch_creation "$COMMAND"; then
  exit 0
fi

BRANCH_NAME=$(get_branch_name "$COMMAND")

# Validate branch name
if [[ -n "$BRANCH_NAME" ]]; then
  if is_valid_branch_name "$BRANCH_NAME"; then
    exit 0
  fi

  cat << EOF >&2
ERROR: Branch name '$BRANCH_NAME' does not match required patterns.

## Branch Naming Rules

Choose the appropriate format based on your situation:

1. **Exploratory work** (no specific task yet):
   - Format: \`YYYY-MM-DD_HHMM\`
   - Example: \`$(date '+%Y-%m-%d_%H%M')\`

2. **Task-based work** (from plan.md):
   - Format: \`{prefix}/{year}-{number}-{description}\`
   - Prefixes: \`plan/\`, \`feature/\`, \`fix/\`, \`refactor/\`
   - Examples:
     - \`plan/2026-1-add-dark-mode\`
     - \`feature/2026-12-user-auth\`
     - \`fix/2026-3-login-error\`
     - \`refactor/2026-18-layer-architecture\`
EOF
  exit 2
fi

exit 0
