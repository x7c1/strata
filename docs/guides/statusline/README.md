# Statusline: Rate-Limit Usage Display

Display rate-limit utilization in the Claude Code status line.

## Components

| File | Type | Description |
|---|---|---|
| `hooks/poll-usage.sh` | Long-running script | Polls `/status` Usage tab via tmux and appends to `~/.claude/token-logs/usage.jsonl`. |
| `hooks/statusline.sh` | statusLine script | Displays branch, context usage, and rate limits. Requires manual setup in `settings.json`. |
| `hooks/platform.sh` | Shared library | Provides OS detection, date parsing, and reset time conversion. |

## Setup

### poll-usage.sh (manual)

Start the polling process in a terminal:

```bash
./hooks/poll-usage.sh           # continuous polling (60-120s interval)
./hooks/poll-usage.sh --once    # single capture then exit
```

The script launches a dedicated Claude Code instance in a tmux session (`claude-status-poll`), periodically opens `/status`, navigates to the Usage tab, and parses the displayed rate-limit data.

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
- tmux

## Platform support

- macOS
- Linux (Ubuntu)
