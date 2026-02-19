# wc -m Locale Issue in statusline.sh

## Overview

`vlen()` in `statusline.sh` uses `wc -m` to count visible character width after stripping ANSI escapes. On Linux, when the locale is C/POSIX (common in Claude Code's execution environment), `wc -m` counts bytes instead of characters. This inflates width measurements for multi-byte UTF-8 characters, breaking the left-right alignment of the status line.

## Root Cause

The bar component uses Unicode block drawing characters that are 3 bytes each in UTF-8:

| Character | Code Point | UTF-8 Bytes | Description |
|---|---|---|---|
| `▕` | U+2595 | 3 | Right one eighth block |
| `█` | U+2588 | 3 | Full block (filled) |
| `░` | U+2591 | 3 | Light shade (empty) |
| `▏` | U+258F | 3 | Left one eighth block |

Each bar contains 12 characters (2 borders + 10 blocks). Under byte counting, `vlen()` returns 36 instead of the correct 12, inflating `rw` (right-side width) by 24.

## How Alignment Breaks

The `lr()` function computes padding as:

```
pad = COLS - lw - rw
```

When `rw` is inflated by 24 bytes, `pad` shrinks by 24. If the left side is long enough (e.g., a deep directory path), `pad` goes negative and is clamped to 1:

```
Line 1 (long path): lw=36, rw=60, pad=max(80-36-60, 1) = 1   ← clamped
Line 2 (spacer):    lw=1,  rw=59, pad=80-1-59              = 20
Line 3 (branch):    lw=4,  rw=59, pad=80-4-59              = 17
```

This causes Line 1's right side to start at a completely different column than Lines 2-3, misaligning the bars, percentages, and reset timers.

With correct character counting:

```
Line 1 (long path): lw=36, rw=36, pad=80-36-36 = 8
Line 2 (spacer):    lw=1,  rw=35, pad=80-1-35  = 44
Line 3 (branch):    lw=4,  rw=35, pad=80-4-35  = 41
```

All bars align at the same column (48).

## Why macOS Was Unaffected

macOS sets a UTF-8 locale by default (typically `en_US.UTF-8` or the user's regional UTF-8 locale). The `wc -m` command in a UTF-8 locale correctly counts characters, not bytes, so the width calculation was accurate.

On Linux, Claude Code may execute the statusline command in a minimal environment where `LANG` and `LC_ALL` are unset, defaulting to the C/POSIX locale.

## Fix

Set `LC_ALL=C.UTF-8` explicitly for the `wc -m` invocation in `vlen()`:

```bash
# Before
printf '%b' "$1" | sed $'s/\033\[[0-9;]*m//g' | wc -m | tr -d ' '

# After
printf '%b' "$1" | sed $'s/\033\[[0-9;]*m//g' | LC_ALL=C.UTF-8 wc -m 2>/dev/null | tr -d ' '
```

`C.UTF-8` is a pseudo-locale available on most modern Linux distributions without requiring locale installation. The `2>/dev/null` suppresses warnings if the locale is unavailable, falling back to the current behavior.

## General Lesson

When writing shell scripts that process Unicode text and may run in environments with unknown locale settings (CI, plugins, editor extensions), always set `LC_CTYPE` or `LC_ALL` explicitly for commands that distinguish bytes from characters. Key commands affected:

- `wc -m` (character count)
- `cut -c` (character-based cutting)
- `sort` (collation order)
- `grep -P` (Perl-compatible regex with Unicode)
- `awk length()` (string length)
- `${#var}` in bash (parameter length)
