#!/usr/bin/env bash
# Verify that relative links in Markdown files resolve to existing targets.
#
# Usage:
#   verify-doc-links.sh FILE...
#
# Extracts Markdown links of the form [text](relative/path) and checks
# that each target exists on the filesystem. Also verifies that every
# file ends with a newline.
set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 FILE..." >&2
  exit 1
fi

errors=0

for file in "$@"; do
  if [[ ! -f "$file" ]]; then
    echo "MISSING: $file does not exist" >&2
    errors=$((errors + 1))
    continue
  fi

  dir=$(dirname "$file")

  # Check relative links (skip URLs starting with http/https/mailto/#)
  grep -oP '\[.*?\]\(\K[^)]+' "$file" | while read -r link; do
    case "$link" in
      http://*|https://*|mailto:*|\#*) continue ;;
    esac
    target="$dir/$link"
    if [[ ! -e "$target" ]]; then
      echo "BROKEN: $file -> $link" >&2
      # Increment via a temp file since this runs in a subshell
      echo x >> /tmp/verify-doc-links-errors.$$
    fi
  done

  # Check trailing newline
  if [[ -n "$(tail -c 1 "$file")" ]]; then
    echo "NO NEWLINE: $file" >&2
    errors=$((errors + 1))
  fi
done

# Collect subshell errors
if [[ -f /tmp/verify-doc-links-errors.$$ ]]; then
  sub_errors=$(wc -l < /tmp/verify-doc-links-errors.$$)
  errors=$((errors + sub_errors))
  rm -f /tmp/verify-doc-links-errors.$$
fi

if [[ $errors -gt 0 ]]; then
  echo "Found $errors error(s)." >&2
  exit 1
else
  echo "All links OK."
fi
