# Setup Statusline

Configures the Claude Code status line for the current project by writing the statusline command path to `.claude/settings.local.json`.

## Instructions

- Resolve the absolute path to `statusline.sh` from this skill's base directory
  - The script is located at `../../scripts/statusline.sh` relative to this skill's base directory
  - Convert the resolved path to an absolute path
- Read the project's `.claude/settings.local.json` if it exists (or start with an empty object `{}`)
- Set the `statusLine` field with the resolved absolute path:
  ```json
  {
    "statusLine": {
      "type": "command",
      "command": "<resolved-absolute-path>"
    }
  }
  ```
- Preserve any existing fields in `settings.local.json` — only add or update the `statusLine` key
- Inform the user that the status line is now configured and will appear on the next Claude Code session
- If the plugin is updated and the status line stops working, re-run `/statusline:setup` to resolve the new path
