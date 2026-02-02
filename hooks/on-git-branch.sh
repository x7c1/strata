#!/bin/bash
# Hook: Validate branch naming before creating a new branch

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/command-detect.sh"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only process branch creation commands
if ! is_branch_creation "$COMMAND"; then
  exit 0
fi

BRANCH_NAME=$(get_branch_name "$COMMAND")

# Validate branch name
if [[ -n "$BRANCH_NAME" ]]; then

  # Pattern 1: Exploratory work (YYYY-MM-DD_HHMM)
  PATTERN_EXPLORATORY='^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4}$'

  # Pattern 2: Task-based work ({prefix}/{year}-{number}-{description})
  # - plan/    : Planning or direct implementation
  # - feature/ : Implementation (new features)
  # - fix/     : Implementation (bug fixes)
  PATTERN_TASK='^(plan|feature|fix)/[0-9]{4}-[0-9]+-[a-z0-9-]+$'

  if [[ "$BRANCH_NAME" =~ $PATTERN_EXPLORATORY ]] || [[ "$BRANCH_NAME" =~ $PATTERN_TASK ]]; then
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
   - Prefixes: \`plan/\` (planning), \`feature/\` (new features), \`fix/\` (bug fixes)
   - Examples:
     - \`plan/2026-1-add-dark-mode\`
     - \`feature/2026-12-refactor-auth\`
     - \`fix/2026-3-login-error\`
EOF
  exit 2
fi

exit 0
