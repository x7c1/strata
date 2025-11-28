#!/bin/bash

# Analyze staged changes for commit message generation
# Excludes lock files and minified files to avoid consuming too many tokens

set -e

# Patterns to exclude from diff analysis
# Note: .gitignore files are already excluded by git diff
EXCLUDE_PATTERNS=(
    "package-lock.json"
    "yarn.lock"
    "pnpm-lock.yaml"
    "Cargo.lock"
    "Gemfile.lock"
    "poetry.lock"
    "composer.lock"
    "*.min.js"
    "*.min.css"
)

# Colors for output
BLUE='\033[0;34m'
NC='\033[0m' # No Color

main() {
    echo -e "${BLUE}=== Staged Changes Overview ===${NC}"
    echo ""

    show_filtered_stat

    echo ""
    echo -e "${BLUE}=== Changes Context (first 100 lines) ===${NC}"
    echo ""

    show_filtered_diff
}

show_filtered_stat() {
    local stat_output
    stat_output=$(git diff --cached --stat)

    if [ -z "$stat_output" ]; then
        echo "No staged changes found."
        return
    fi

    # Filter out excluded patterns
    echo "$stat_output" | while IFS= read -r line; do
        local skip=false
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            if [[ "$line" == *"$pattern"* ]]; then
                skip=true
                break
            fi
        done

        if [ "$skip" = false ]; then
            echo "$line"
        fi
    done
}

show_filtered_diff() {
    local files
    files=$(git diff --cached --name-only)

    if [ -z "$files" ]; then
        echo "No staged changes found."
        return
    fi

    # Build list of files to include (excluding patterns)
    local included_files=()
    local md_files=()

    while IFS= read -r file; do
        local skip=false
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            if [[ "$file" == *"$pattern"* ]]; then
                skip=true
                break
            fi
        done

        if [ "$skip" = false ]; then
            # Separate .md files for special handling
            if [[ "$file" == *.md ]]; then
                md_files+=("$file")
            else
                included_files+=("$file")
            fi
        fi
    done <<< "$files"

    # Show diff for non-md files
    if [ ${#included_files[@]} -gt 0 ]; then
        git diff --cached --unified=1 -- "${included_files[@]}" | head -100
    fi

    # Show only first 20 lines of diff for .md files
    if [ ${#md_files[@]} -gt 0 ]; then
        echo ""
        echo "--- Markdown files (first 20 lines only) ---"
        git diff --cached --unified=1 -- "${md_files[@]}" | head -20
    fi

    # Check if all files were excluded
    if [ ${#included_files[@]} -eq 0 ] && [ ${#md_files[@]} -eq 0 ]; then
        echo "All staged files are excluded from analysis (lock files, minified files, etc.)"
        return
    fi
}

main
