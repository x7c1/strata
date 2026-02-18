# Statusline: Rate-Limit Usage Display

Display rate-limit utilization in the Claude Code status line.

## Components

| File | Type | Description |
|---|---|---|
| `hooks/record-usage.sh` | Stop hook | Fetches utilization from the OAuth API and appends to `~/.claude/token-logs/usage.jsonl`. Auto-enabled on install via `hooks/hooks.json`. |
| `hooks/statusline.sh` | statusLine script | Displays branch, context usage, and rate limits. Requires manual setup in `settings.json`. |
| `hooks/platform.sh` | Shared library | Provides OS detection, credential retrieval, and date parsing. |

## Setup

### record-usage.sh (automatic)

Installing strata as a plugin automatically enables this Stop hook.

### statusline.sh (manual)

Add the following to `settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "<path>/hooks/statusline.sh"
  }
}
```

## Prerequisites

- jq
- curl

## Platform support

- macOS
- Linux (Ubuntu)
