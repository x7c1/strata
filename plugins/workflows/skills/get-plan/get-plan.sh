#!/bin/bash

# Get README.md path from current branch name
# Supports plan/, feature/, fix/ prefixes and nested sub-plans

set -euo pipefail

main() {
    local branch
    branch=$(git branch --show-current 2>/dev/null || echo "")

    if [[ -z "$branch" ]]; then
        echo "Error: Not in a git repository or no branch checked out" >&2
        exit 1
    fi

    local prefix
    prefix=$(get_branch_prefix "$branch")

    if [[ -z "$prefix" ]]; then
        echo "No plan associated with branch: $branch"
        echo "This appears to be an exploratory branch."
        exit 0
    fi

    get_plan_path "$branch" "$prefix"
}

get_branch_prefix() {
    local branch="$1"
    if [[ "$branch" =~ ^plan/ ]]; then
        echo "plan/"
    elif [[ "$branch" =~ ^feature/ ]]; then
        echo "feature/"
    elif [[ "$branch" =~ ^fix/ ]]; then
        echo "fix/"
    fi
}

# Zero-pad a number to 3 digits
pad_number() {
    printf "%03d" "$1"
}

# Find a directory matching "{padded-number}-*" in the given base directory
resolve_dir_by_number() {
    local base_dir="$1"
    local number="$2"
    local padded
    padded=$(pad_number "$number")

    local matches=()
    for dir in "${base_dir}/${padded}-"*/; do
        [[ -d "$dir" ]] && matches+=("$dir")
    done

    if [[ ${#matches[@]} -eq 0 ]]; then
        echo "Error: No directory matching '${padded}-*' in ${base_dir}/" >&2
        exit 1
    fi
    if [[ ${#matches[@]} -gt 1 ]]; then
        echo "Error: Multiple directories matching '${padded}-*' in ${base_dir}/" >&2
        exit 1
    fi

    basename "${matches[0]}"
}

get_plan_path() {
    local branch="$1"
    local prefix="$2"

    # Remove prefix
    local plan_part="${branch#"$prefix"}"

    # Split by /
    IFS='/' read -ra segments <<< "$plan_part"

    if [[ ${#segments[@]} -eq 0 ]]; then
        echo "Error: Empty plan path" >&2
        exit 1
    fi

    # First segment: "year-number-description" or "year-number"
    local first="${segments[0]}"
    local year="${first%%-*}"
    local identifier="${first#*-}"

    local plan_path

    if [[ ${#segments[@]} -eq 1 ]]; then
        # Single segment: full name (e.g., "2026-17-subscription-licensing")
        # Extract number and resolve to zero-padded directory
        local number="${identifier%%-*}"
        local top_dir
        top_dir=$(resolve_dir_by_number "docs/plans/${year}" "$number")
        plan_path="docs/plans/${year}/${top_dir}"
    else
        # Multiple segments: first is "year-number", resolve to full directory name
        local top_dir
        top_dir=$(resolve_dir_by_number "docs/plans/${year}" "$identifier")
        plan_path="docs/plans/${year}/${top_dir}"

        # Intermediate segments (all except last): number-only, need resolution
        for ((i = 1; i < ${#segments[@]} - 1; i++)); do
            local sub_dir
            sub_dir=$(resolve_dir_by_number "${plan_path}/plans" "${segments[$i]}")
            plan_path="${plan_path}/plans/${sub_dir}"
        done

        # Last segment: "number-description", resolve by number
        local last="${segments[${#segments[@]} - 1]}"
        local last_number="${last%%-*}"
        local last_dir
        last_dir=$(resolve_dir_by_number "${plan_path}/plans" "$last_number")
        plan_path="${plan_path}/plans/${last_dir}"
    fi

    plan_path="${plan_path}/README.md"

    if [[ -f "$plan_path" ]]; then
        echo "$plan_path"
    else
        echo "Plan path: $plan_path"
        echo "Warning: File does not exist" >&2
        exit 1
    fi
}

main
