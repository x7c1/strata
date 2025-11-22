#!/bin/bash

# Script to remove trailing whitespace and convert whitespace-only lines to empty lines
# Usage: ./remove-trailing-whitespace.sh [file_or_directory]

set -e

TARGET="${1:-.}"

should_skip() {
    local file="$1"

    # Skip if not a text file
    if ! file "$file" | grep -q "text"; then
        echo "Skipping binary file: $file"
        return 0  # true - should skip
    fi

    # Skip markdown files
    if [[ "$file" == *.md ]]; then
        echo "Skipping markdown file: $file"
        return 0  # true - should skip
    fi

    return 1  # false - should not skip
}

process_file() {
    local file="$1"

    if should_skip "$file"; then
        return
    fi

    echo "Processing: $file"
    sed -i 's/[[:space:]]*$//' "$file"
}

if [ -f "$TARGET" ]; then
    # Single file
    process_file "$TARGET"
elif [ -d "$TARGET" ]; then
    # Directory - process all text files except markdown
    echo "Processing directory: $TARGET"

    find "$TARGET" -type f | while read -r file; do
        process_file "$file"
    done

    echo "Processed files in $TARGET"
else
    echo "Error: $TARGET is not a valid file or directory"
    exit 1
fi

echo "Trailing whitespace removal completed"
