#!/usr/bin/env bash
# Show git status summary for specified repositories
#
# Usage: check-repo-status.sh <path> [<path> ...]

set -euo pipefail

: "${CLAUDE_PROJECT_DIR:=$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <path> [<path> ...]" >&2
  exit 1
fi

for repo in "$@"; do
  dir="$CLAUDE_PROJECT_DIR/$repo"
  echo "========================================"
  echo "## $repo"
  echo "========================================"

  if [[ ! -d "$dir/.git" ]]; then
    echo "(not cloned)"
    echo
    continue
  fi

  cd "$dir"

  echo
  echo "### Branch"
  git branch --show-current

  echo
  echo "### Status"
  git status --short || echo "(clean)"

  echo
  echo "### Recent commits"
  git log --oneline -5

  echo
  echo "### Remote sync"
  branch=$(git branch --show-current)
  if git rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
    ahead=$(git rev-list --count "origin/$branch..$branch")
    behind=$(git rev-list --count "$branch..origin/$branch")
    echo "ahead: $ahead, behind: $behind"
  else
    echo "no remote tracking branch"
  fi

  echo
done
