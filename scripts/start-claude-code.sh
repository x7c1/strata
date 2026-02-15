#!/bin/bash

# Check if Claude Code is installed
if ! command -v claude &> /dev/null; then
    echo "First startup detected. Installing Claude Code using native installer..."

    # Install Claude Code using native installer
    curl -fsSL https://claude.ai/install.sh | bash
    echo "Installation completed."
else
    echo "Claude Code is already installed. Checking for updates..."

    # Update Claude Code to latest version
    claude update
    echo "Update check completed."
fi

# Start Claude Code with strata plugin loaded directly (no marketplace cache updates needed)
STRATA_DIR="$(cd "$(dirname "$0")/.." && pwd)"
exec claude --plugin-dir "$STRATA_DIR"
