#!/bin/bash

# Script to format staged text files (remove trailing whitespace and ensure newlines)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ENSURE_NEWLINE_SCRIPT="$SCRIPT_DIR/ensure-newline.sh"
readonly REMOVE_TRAILING_WHITESPACE_SCRIPT="$SCRIPT_DIR/remove-trailing-whitespace.sh"

# Main execution
main() {
    check_required_scripts

    echo "Checking staged files..."

    local staged_files
    staged_files=$(get_staged_files)

    if [[ -z "$staged_files" ]]; then
        echo "No files are staged for commit."
        exit 0
    fi

    echo "Found staged files:"
    echo "$staged_files"
    echo ""

    local existing_files
    existing_files=$(echo "$staged_files" | filter_existing_files)

    if [[ -z "$existing_files" ]]; then
        echo "No existing staged files to process."
        exit 0
    fi

    echo "Running remove-trailing-whitespace.sh on staged files..."
    echo ""

    local modified_whitespace
    modified_whitespace=$(echo "$existing_files" | process_whitespace_removal)

    echo ""
    echo "Running ensure-newline.sh on staged files..."
    echo ""

    local modified_newline
    modified_newline=$(process_newline_ensuring "$existing_files")

    # Combine all modified files
    local all_modified
    all_modified=$(printf '%s\n%s\n' "$modified_whitespace" "$modified_newline" | grep -v '^$' || true)

    restage_files "$all_modified"
}

# Check if required scripts exist and are executable
check_required_scripts() {
    local -a missing_scripts=()

    [[ ! -x "$ENSURE_NEWLINE_SCRIPT" ]] && missing_scripts+=("ensure-newline.sh")
    [[ ! -x "$REMOVE_TRAILING_WHITESPACE_SCRIPT" ]] && missing_scripts+=("remove-trailing-whitespace.sh")

    if [[ ${#missing_scripts[@]} -gt 0 ]]; then
        echo "Error: Missing or non-executable scripts: ${missing_scripts[*]}" >&2
        exit 1
    fi
}

# Get staged files excluding common directories
get_staged_files() {
    git diff --cached --name-only --diff-filter=AMR | \
        grep -v "/node_modules/" | \
        grep -v "/.git/" || true
}

# Filter for existing files only
filter_existing_files() {
    local -a existing_files=()

    while IFS= read -r file; do
        [[ -f "$file" ]] && existing_files+=("$file")
    done

    printf '%s\n' "${existing_files[@]}"
}

# Check if file is processable text file (not binary, not markdown)
is_processable_text_file() {
    local file="$1"
    file "$file" | grep -q "text" && [[ "$file" != *.md ]]
}

# Process files with whitespace removal
process_whitespace_removal() {
    local -a modified_files=()

    while IFS= read -r file; do
        if [[ -n "$file" ]] && is_processable_text_file "$file"; then
            # Run the script and check if file was actually modified
            local output
            output=$("$REMOVE_TRAILING_WHITESPACE_SCRIPT" "$file" 2>&1)

            # Only add to modified list if the script actually processed the file
            if [[ "$output" == *"Processing:"* ]]; then
                modified_files+=("$file")
            fi
        fi
    done

    printf '%s\n' "${modified_files[@]}"
}

# Process files with newline ensuring
process_newline_ensuring() {
    local files="$1"
    echo "$files" | "$ENSURE_NEWLINE_SCRIPT" | \
        grep "Adding newline to:" | \
        sed 's/Adding newline to: //' || true
}

# Re-stage modified files
restage_files() {
    local files="$1"

    if [[ -n "$files" ]]; then
        echo ""
        echo "Re-staging modified files:"
        while IFS= read -r file; do
            if [[ -n "$file" ]]; then
                echo "  git add $file"
                git add "$file"
            fi
        done <<< "$files"
    else
        echo "No files were modified."
    fi
}

main "$@"
