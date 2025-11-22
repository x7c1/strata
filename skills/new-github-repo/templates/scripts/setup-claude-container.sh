#!/bin/bash

# Script to setup Claude container environment

set -e

main() {
    setup_claude_config
    setup_bash_history
    echo "Setup completed successfully!"
    echo "Original ~/.claude.json preserved"
}

setup_claude_config() {
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is required but not installed. Please install jq first."
        exit 1
    fi

    # Check if ~/.claude.json exists
    if [ ! -f ~/.claude.json ]; then
        echo "Error: ~/.claude.json not found"
        exit 1
    fi

    # Check if claude.local/shared/.claude.json already exists
    if [ -f claude.local/shared/.claude.json ]; then
        echo "claude.local/shared/.claude.json already exists. Skipping Claude config setup."
        return
    fi

    # Create claude.local/shared directory if it doesn't exist
    mkdir -p claude.local/shared

    # Copy ~/.claude.json to claude.local/shared/
    echo "Copying ~/.claude.json to claude.local/shared/.claude.json..."
    cp ~/.claude.json claude.local/shared/.claude.json

    # Empty the projects history using jq
    echo "Emptying project history..."
    jq '.projects = {}' claude.local/shared/.claude.json > claude.local/shared/.claude.json.tmp && \
        mv claude.local/shared/.claude.json.tmp claude.local/shared/.claude.json

    echo "Successfully created claude.local/shared/.claude.json with empty project history"
}

setup_bash_history() {
    # Create claude.local/shared directory if it doesn't exist
    mkdir -p claude.local/shared

    # Check if .bash_history already exists
    if [ -f claude.local/shared/.bash_history ]; then
        echo "claude.local/shared/.bash_history already exists. Skipping bash history setup."
        return
    fi

    # Create empty .bash_history file for Docker volume mount
    echo "Creating empty .bash_history file..."
    touch claude.local/shared/.bash_history

    echo "Created claude.local/shared/.bash_history for Docker history persistence"
}

main
