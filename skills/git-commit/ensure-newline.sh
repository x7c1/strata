#!/bin/bash

# Script to check if files end with newline and add one if they don't
# Usage: ./ensure-newline.sh [file1] [file2] ... or stdin

# Function to check if a file is likely a text file
is_text_file() {
    local file="$1"
    
    # Check if file exists
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    # Use file command to check if it's text
    file_type=$(file -b "$file" 2>/dev/null)
    if [[ "$file_type" =~ text|ASCII|UTF-8|empty ]]; then
        return 0
    fi
    
    return 1
}

add_newline_if_needed() {
    local file="$1"
    
    # Skip empty strings
    if [[ -z "$file" ]]; then
        return 0
    fi
    
    if [[ ! -f "$file" ]]; then
        echo "Warning: '$file' is not a regular file" >&2
        return 1
    fi
    
    # Skip non-text files
    if ! is_text_file "$file"; then
        echo "Skipping non-text file: $file"
        return 0
    fi
    
    # Check if file is empty
    if [[ ! -s "$file" ]]; then
        return 0
    fi
    
    # Check if file ends with newline
    if [[ -n "$(tail -c1 "$file")" ]]; then
        echo "Adding newline to: $file"
        echo >> "$file"
    else
        echo "Already ends with newline: $file"
    fi
}

# If no arguments provided, read from stdin
if [[ $# -eq 0 ]]; then
    while IFS= read -r file; do
        add_newline_if_needed "$file"
    done
else
    # Process each file argument
    for file in "$@"; do
        add_newline_if_needed "$file"
    done
fi
