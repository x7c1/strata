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

# Check if branch name is valid (matches any allowed pattern)
is_valid_branch_name() {
    local branch="$1"
    is_exploratory_branch_name "$branch" || is_task_branch_name "$branch"
}
