#!/bin/bash

# Shared branch naming rules for hooks

# Branch name patterns
PATTERN_EXPLORATORY='^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4}$'
PATTERN_TASK='^(plan|feature|fix|refactor)/[0-9]{4}-[0-9]+-[a-z0-9-]+$'

# Check if branch name matches exploratory pattern (YYYY-MM-DD_HHMM)
is_exploratory_branch_name() {
    local branch="$1"
    [[ "$branch" =~ $PATTERN_EXPLORATORY ]]
}

# Check if branch name matches task pattern ({prefix}/{year}-{number}-{description})
is_task_branch_name() {
    local branch="$1"
    [[ "$branch" =~ $PATTERN_TASK ]]
}

# Extract the plan number from a task branch name
# e.g., "feature/2026-18-layer-architecture" -> "18"
get_plan_number() {
    local branch="$1"
    if [[ "$branch" =~ ^[a-z]+/[0-9]{4}-([0-9]+)- ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}

# Extract the year from a task branch name
# e.g., "feature/2026-18-layer-architecture" -> "2026"
get_plan_year() {
    local branch="$1"
    if [[ "$branch" =~ ^[a-z]+/([0-9]{4})- ]]; then
        echo "${BASH_REMATCH[1]}"
    fi
}

# Check if the plan referenced by a task branch exists in docs/plans/
# Searches for docs/plans/{year}/{number}-*/
plan_exists() {
    local branch="$1"
    local project_root="${2:-$CLAUDE_PROJECT_DIR}"
    local year number
    year=$(get_plan_year "$branch")
    number=$(get_plan_number "$branch")
    if [[ -z "$year" || -z "$number" ]]; then
        return 1
    fi
    local matches
    matches=$(find "$project_root/docs/plans/$year" -maxdepth 1 -type d -name "${number}-*" 2>/dev/null)
    [[ -n "$matches" ]]
}

# Check if branch name is valid (matches any allowed pattern)
is_valid_branch_name() {
    local branch="$1"
    is_exploratory_branch_name "$branch" || is_task_branch_name "$branch"
}
