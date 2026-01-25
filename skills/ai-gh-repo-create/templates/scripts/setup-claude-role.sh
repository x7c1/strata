#!/bin/bash

if [ -z "$ROLE" ]; then
    echo "Error: ROLE environment variable is required"
    echo "Usage: ROLE=frontend make workspace"
    exit 1
fi

echo "Setting up Claude role: $ROLE"

# Create directories
mkdir -p claude.local/shared
mkdir -p claude.local/${ROLE}

# Create bash history file if it doesn't exist
touch claude.local/${ROLE}/.bash_history

# Create shared config if it doesn't exist
if [ ! -f claude.local/shared/.claude.json ]; then
    echo "{}" > claude.local/shared/.claude.json
fi

echo "Role $ROLE setup complete"
echo "  - Shared config: claude.local/shared/"
echo "  - Role history: claude.local/${ROLE}/.bash_history"
