#!/bin/bash

# Shared branch naming rules for hooks

# Branch name patterns
PATTERN_EXPLORATORY='^[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{4}$'
# Top-level: feature/2026-1-description
# Sub-plan:  feature/2026-17/1-description
# Deeper:    feature/2026-17/1/2-description
PATTERN_TASK='^(plan|feature|fix|refactor)/[0-9]{4}-[0-9]+(/[0-9]+)*-[a-z0-9-]+$'

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

# Check if branch is for implementing an existing plan (feature/, fix/, refactor/)
# plan/ branches are for creating new plans, so they don't require an existing plan
is_implementation_branch_name() {
    local branch="$1"
    [[ "$branch" =~ ^(feature|fix|refactor)/ ]] && is_task_branch_name "$branch"
}

# Resolve the plan directory path from a branch name
# e.g., "feature/2026-18-layer-arch"            -> "docs/plans/2026/018-*"
# e.g., "feature/2026-17/1-payment-flow"        -> "docs/plans/2026/017-*/plans/001-*"
# e.g., "feature/2026-17/1/2-validation"        -> "docs/plans/2026/017-*/plans/001-*/plans/002-*"
resolve_plan_path() {
    local branch="$1"
    local project_root="${2:-.}"

    # Strip prefix (feature/, fix/, etc.)
    local path_part="${branch#*/}"

    # Extract year
    local year="${path_part%%-*}"
    local rest="${path_part#*-}"

    # Build glob pattern by walking the segments
    local glob_path="$project_root/docs/plans/$year"

    # Split remaining part: could be "17-desc" or "17/1-desc" or "17/1/2-desc"
    # Segments separated by / are intermediate parents; the last segment has a description
    IFS='/' read -ra segments <<< "$rest"

    for segment in "${segments[@]}"; do
        # Extract number from segment (e.g., "17-description" -> "17", "1" -> "1")
        local number="${segment%%-*}"
        local padded
        padded=$(printf "%03d" "$number")
        glob_path="$glob_path/${padded}-*/plans"
    done

    # Remove trailing /plans — the last segment is the target plan itself
    glob_path="${glob_path%/plans}"

    echo "$glob_path"
}

# Check if the plan referenced by a task branch exists in docs/plans/
plan_exists() {
    local branch="$1"
    local project_root="${2:-$(git rev-parse --show-toplevel 2>/dev/null || echo "$CLAUDE_PROJECT_DIR")}"
    local glob_path
    glob_path=$(resolve_plan_path "$branch" "$project_root")
    # Use compgen to check if glob matches any directory
    compgen -G "$glob_path" > /dev/null 2>&1
}

# Check if branch name is valid (matches any allowed pattern)
is_valid_branch_name() {
    local branch="$1"
    is_exploratory_branch_name "$branch" || is_task_branch_name "$branch"
}
