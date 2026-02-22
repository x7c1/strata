# Setup Statusline

Configures the Claude Code status line for the current project by writing the statusline command path to `.claude/settings.local.json`.

## Instructions

- Locate the installed statusline plugin's `statusline.sh` script under `~/.claude/plugins/cache/`
  - Search for a file matching the pattern `~/.claude/plugins/cache/strata-dev/statusline/*/scripts/statusline.sh`
  - If multiple versions exist, use the most recent one
  - If not found, inform the user that the statusline plugin is not installed and they should install it first
- Read the project's `.claude/settings.local.json` if it exists (or start with an empty object `{}`)
- Set the `statusLine` field with the resolved absolute path:
  ```json
  {
    "statusLine": {
      "type": "command",
      "command": "<resolved-absolute-path>/scripts/statusline.sh"
    }
  }
  ```
- Preserve any existing fields in `settings.local.json` — only add or update the `statusLine` key
- Inform the user that the status line is now configured and will appear on the next Claude Code session
- If the plugin is updated and the status line stops working, re-run `/statusline:setup` to resolve the new path
