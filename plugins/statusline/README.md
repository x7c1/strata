# statusline plugin

Displays branch, context window, and rate-limit usage in the Claude Code status line.

## How it works

- `poll-usage.sh` runs on the host, polls Claude Code's `/status` dialog via tmux, and writes usage data to `~/.claude/token-logs/usage.jsonl`
- `statusline.sh` runs inside each container and reads that file to display rate-limit usage
- `platform.sh` provides OS-specific helpers (e.g., date parsing)

## Docker setup

When running Claude Code inside Docker containers, you must mount `token-logs` so that usage data written by the host's `poll-usage.sh` is visible to each container's `statusline.sh`:

```yaml
volumes:
  - ~/.claude/token-logs:/home/developer/.claude/token-logs
```

Use short-form (without `create_host_path: false`) because the directory may not exist until `poll-usage.sh` runs for the first time.

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
