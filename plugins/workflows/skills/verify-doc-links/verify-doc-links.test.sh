#!/bin/bash

# Test script for verify-doc-links.sh

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/verify-doc-links.sh"

# Test counters
PASS=0
FAIL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Create temp directory for test fixtures
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

assert_exit_code() {
    local description="$1"
    local expected_code="$2"
    shift 2
    local actual_code
    "$@" >/dev/null 2>&1
    actual_code=$?
    if [[ "$expected_code" == "$actual_code" ]]; then
        echo -e "${GREEN}PASS${NC}: $description"
        ((++PASS))
    else
        echo -e "${RED}FAIL${NC}: $description (expected exit $expected_code, got $actual_code)"
        ((++FAIL))
    fi
}

assert_output_contains() {
    local description="$1"
    local expected="$2"
    shift 2
    local output
    output=$("$@" 2>&1)
    if echo "$output" | grep -q "$expected"; then
        echo -e "${GREEN}PASS${NC}: $description"
        ((++PASS))
    else
        echo -e "${RED}FAIL${NC}: $description"
        echo "  Expected to contain: $expected"
        echo "  Actual output: $output"
        ((++FAIL))
    fi
}

# Setup test fixtures
mkdir -p "$TMPDIR/sub"

# File with valid links
printf '# Test\n\n- [link](sub/target.md)\n- [external](https://example.com)\n' > "$TMPDIR/valid.md"
printf '# Target\n' > "$TMPDIR/sub/target.md"

# File with broken link
printf '# Test\n\n- [broken](sub/nonexistent.md)\n' > "$TMPDIR/broken.md"

# File with no trailing newline
printf '# No newline' > "$TMPDIR/no-newline.md"

# File with multiple links (valid and broken)
printf '# Mixed\n\n- [ok](sub/target.md)\n- [bad](missing.md)\n' > "$TMPDIR/mixed.md"

# File with anchor link (should be skipped)
printf '# Anchors\n\n- [anchor](#section)\n- [valid](sub/target.md)\n' > "$TMPDIR/anchors.md"

# File with no links
printf '# Empty\n\nNo links here.\n' > "$TMPDIR/empty.md"

echo "=== Testing valid links ==="

assert_exit_code "File with valid links passes" 0 \
    bash "$SCRIPT" "$TMPDIR/valid.md"

assert_exit_code "File with no links passes" 0 \
    bash "$SCRIPT" "$TMPDIR/empty.md"

assert_exit_code "File with anchor links passes" 0 \
    bash "$SCRIPT" "$TMPDIR/anchors.md"

echo ""
echo "=== Testing broken links ==="

assert_exit_code "File with broken link fails" 1 \
    bash "$SCRIPT" "$TMPDIR/broken.md"

assert_output_contains "Broken link is reported" "BROKEN" \
    bash "$SCRIPT" "$TMPDIR/broken.md"

assert_exit_code "File with mixed links fails" 1 \
    bash "$SCRIPT" "$TMPDIR/mixed.md"

echo ""
echo "=== Testing trailing newline ==="

assert_exit_code "File without trailing newline fails" 1 \
    bash "$SCRIPT" "$TMPDIR/no-newline.md"

assert_output_contains "Missing newline is reported" "NO NEWLINE" \
    bash "$SCRIPT" "$TMPDIR/no-newline.md"

echo ""
echo "=== Testing missing file ==="

assert_exit_code "Nonexistent file fails" 1 \
    bash "$SCRIPT" "$TMPDIR/does-not-exist.md"

assert_output_contains "Missing file is reported" "MISSING" \
    bash "$SCRIPT" "$TMPDIR/does-not-exist.md"

echo ""
echo "=== Testing no arguments ==="

assert_exit_code "No arguments fails" 1 \
    bash "$SCRIPT"

echo ""
echo "=== Testing multiple links per line ==="

# File with two links on one line, second is broken
printf '# Multi\n\n- [ok](sub/target.md) and [bad](missing.md)\n' > "$TMPDIR/multi-link.md"

assert_exit_code "Two links per line, second broken, fails" 1 \
    bash "$SCRIPT" "$TMPDIR/multi-link.md"

# File with two valid links on one line
printf '# Multi\n\n- [a](sub/target.md) and [b](sub/target.md)\n' > "$TMPDIR/multi-link-ok.md"

assert_exit_code "Two valid links per line passes" 0 \
    bash "$SCRIPT" "$TMPDIR/multi-link-ok.md"

# File with two links on one line, first is broken
printf '# Multi\n\n- [bad](missing.md) and [ok](sub/target.md)\n' > "$TMPDIR/multi-link-first-broken.md"

assert_exit_code "Two links per line, first broken, fails" 1 \
    bash "$SCRIPT" "$TMPDIR/multi-link-first-broken.md"

echo ""
echo "=== Testing multiple files ==="

assert_exit_code "Multiple valid files pass" 0 \
    bash "$SCRIPT" "$TMPDIR/valid.md" "$TMPDIR/empty.md"

assert_exit_code "Mix of valid and broken fails" 1 \
    bash "$SCRIPT" "$TMPDIR/valid.md" "$TMPDIR/broken.md"

echo ""
echo "================================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
