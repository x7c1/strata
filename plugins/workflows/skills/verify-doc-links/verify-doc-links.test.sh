#!/usr/bin/env bash
# Tests for verify-doc-links.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VERIFY="$SCRIPT_DIR/verify-doc-links.sh"
FIXTURES="$SCRIPT_DIR/tests/fixtures"

# Create no-newline fixture at runtime (git/linters auto-add trailing newlines)
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT
printf '# No newline' > "$TMPDIR/no-newline.md"

pass=0
fail=0

assert_success() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "PASS: $desc"
    pass=$((pass + 1))
  else
    echo "FAIL: $desc (expected success, got failure)"
    fail=$((fail + 1))
  fi
}

assert_failure() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: $desc (expected failure, got success)"
    fail=$((fail + 1))
  else
    echo "PASS: $desc"
    pass=$((pass + 1))
  fi
}

assert_output_contains() {
  local desc="$1"; shift
  local pattern="$1"; shift
  local output
  output=$("$@" 2>&1) || true
  if echo "$output" | grep -q "$pattern"; then
    echo "PASS: $desc"
    pass=$((pass + 1))
  else
    echo "FAIL: $desc (pattern '$pattern' not found in output)"
    echo "  output: $output"
    fail=$((fail + 1))
  fi
}

# --- Valid links ---

echo "=== Testing valid links ==="

assert_success "file with valid links passes" \
  bash "$VERIFY" "$FIXTURES/good.md"

assert_success "file with no links passes" \
  bash "$VERIFY" "$FIXTURES/no-links.md"

assert_success "file with anchor links passes" \
  bash "$VERIFY" "$FIXTURES/anchors.md"

assert_success "multiple valid files pass" \
  bash "$VERIFY" "$FIXTURES/good.md" "$FIXTURES/subdir/nested.md"

# --- Broken links ---

echo ""
echo "=== Testing broken links ==="

assert_failure "file with broken link fails" \
  bash "$VERIFY" "$FIXTURES/broken.md"

assert_output_contains "broken link is reported" "BROKEN" \
  bash "$VERIFY" "$FIXTURES/broken.md"

assert_failure "mix of valid and broken fails" \
  bash "$VERIFY" "$FIXTURES/good.md" "$FIXTURES/broken.md"

# --- Multiple links per line ---

echo ""
echo "=== Testing multiple links per line ==="

assert_failure "two links per line, second broken, fails" \
  bash "$VERIFY" "$FIXTURES/multi-link-broken.md"

assert_success "two valid links per line passes" \
  bash "$VERIFY" "$FIXTURES/multi-link-ok.md"

# --- Trailing newline ---

echo ""
echo "=== Testing trailing newline ==="

assert_failure "file without trailing newline fails" \
  bash "$VERIFY" "$TMPDIR/no-newline.md"

assert_output_contains "missing newline is reported" "NO NEWLINE" \
  bash "$VERIFY" "$TMPDIR/no-newline.md"

# --- Missing file ---

echo ""
echo "=== Testing missing file ==="

assert_failure "nonexistent file fails" \
  bash "$VERIFY" "$FIXTURES/does-not-exist.md"

assert_output_contains "missing file is reported" "MISSING" \
  bash "$VERIFY" "$FIXTURES/does-not-exist.md"

# --- No arguments ---

echo ""
echo "=== Testing no arguments ==="

assert_failure "no arguments fails" \
  bash "$VERIFY"

# --- Directory arguments ---

echo ""
echo "=== Testing directory arguments ==="

assert_success "directory with only valid files" \
  bash "$VERIFY" "$FIXTURES/subdir"

assert_failure "directory containing a broken file" \
  bash "$VERIFY" "$FIXTURES"

assert_output_contains "directory recurses into subdirs" "All links OK" \
  bash "$VERIFY" "$FIXTURES/subdir"

assert_output_contains "directory reports broken links" "BROKEN" \
  bash "$VERIFY" "$FIXTURES"

# --- Mixed arguments ---

echo ""
echo "=== Testing mixed arguments ==="

assert_failure "file + directory with broken links" \
  bash "$VERIFY" "$FIXTURES/good.md" "$FIXTURES"

assert_success "valid file + valid directory" \
  bash "$VERIFY" "$FIXTURES/good.md" "$FIXTURES/subdir"

# --- Summary ---

echo ""
echo "================================"
echo "Results: $pass passed, $fail failed"
if [[ $fail -gt 0 ]]; then
  exit 1
fi
