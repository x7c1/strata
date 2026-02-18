#!/usr/bin/env bash
# Cross-platform helper functions for hooks.
# Source this file; do not execute it directly.

# Detect the current OS.
# Returns "darwin" or "linux".
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "darwin" ;;
    *)      echo "linux" ;;
  esac
}

# Retrieve the OAuth access token from platform-specific credential storage.
# macOS: Keychain via `security find-generic-password`
# Linux: ~/.claude/.credentials.json
get_oauth_token() {
  local os
  os="$(detect_os)"

  local creds=""
  if [ "$os" = "darwin" ]; then
    creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null)
  else
    local cred_file="${HOME}/.claude/.credentials.json"
    if [ -f "$cred_file" ]; then
      creds=$(cat "$cred_file" 2>/dev/null)
    fi
  fi

  if [ -z "$creds" ]; then
    return
  fi

  echo "$creds" | jq -r '.claudeAiOauth.accessToken // empty'
}

# Parse an ISO 8601 datetime string to epoch seconds.
# Usage: parse_iso_date "2025-01-01T12:00:00.000Z"
# Strips fractional seconds and trailing Z before parsing.
parse_iso_date() {
  local input="$1"
  if [ -z "$input" ]; then
    return
  fi

  # Strip fractional seconds and trailing Z:
  #   "2025-01-01T12:00:00.123Z" -> "2025-01-01T12:00:00"
  local cleaned="${input%%.*}"
  cleaned="${cleaned%Z}"

  local os
  os="$(detect_os)"

  local epoch=""
  if [ "$os" = "darwin" ]; then
    epoch=$(date -j -u -f "%Y-%m-%dT%H:%M:%S" "$cleaned" +%s 2>/dev/null)
  else
    epoch=$(date -u -d "$cleaned" +%s 2>/dev/null)
  fi

  if [ -n "$epoch" ]; then
    echo "$epoch"
  fi
}
