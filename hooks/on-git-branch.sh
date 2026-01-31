#!/bin/bash
# Hook: Validate branch naming before creating a new branch

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Check if this is a branch creation command
if echo "$COMMAND" | grep -qE 'git (checkout -b|branch|switch -c)'; then
  # Extract branch name from command
  BRANCH_NAME=$(echo "$COMMAND" | sed -E 's/.*git (checkout -b|branch|switch -c) +([^ ]+).*/\2/')

  # Pattern 1: Exploratory work (YYYY-MM-DD_HHMM)
  PATTERN_EXPLORATORY='^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4}$'

  # Pattern 2: Plan-based work (plan/{year}-{number}-{description})
  PATTERN_PLAN='^plan/[0-9]{4}-[0-9]+-[a-z0-9-]+$'

  if [[ "$BRANCH_NAME" =~ $PATTERN_EXPLORATORY ]] || [[ "$BRANCH_NAME" =~ $PATTERN_PLAN ]]; then
    exit 0
  fi

  cat << EOF
ERROR: Branch name '$BRANCH_NAME' does not match required patterns.

## Branch Naming Rules

Choose the appropriate format based on your situation:

1. **Exploratory work** (no specific task yet):
   - Format: \`YYYY-MM-DD_HHMM\`
   - Example: \`$(date '+%Y-%m-%d_%H%M')\`

2. **Plan-based work** (from plan.md):
   - Format: \`plan/{year}-{number}-{description}\`
   - Examples:
     - \`plan/2026-1-add-dark-mode\`
     - \`plan/2026-12-refactor-auth\`
EOF
  exit 1
fi

exit 0
