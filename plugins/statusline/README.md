# statusline plugin

Displays branch, context window, and rate-limit usage in the Claude Code status line.

## How it works

- `statusline.sh` reads the JSON input from stdin (provided by Claude Code) and renders a three-line status bar
- Rate-limit usage (`rate_limits` field) is included natively in the status line JSON — no external polling needed

## Setup

Run `/statusline:setup` to configure `settings.local.json` automatically, or add manually:

```json
{
  "statusLine": {
    "type": "command",
    "command": "<path to statusline.sh>"
  }
}
```
