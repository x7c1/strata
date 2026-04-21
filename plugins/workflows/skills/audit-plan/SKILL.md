---
name: audit-plan
description: Read-only audit of a plan against refine-plan's Design Guidelines — returns JSON verdicts for each refine-plan:confirm marker
argument-hint: <plan-directory>
---

# Audit Plan Skill

## Overview

Reads a plan directory and evaluates every `refine-plan:confirm` marker strictly against the Design Guidelines defined in the refine-plan skill. For each marker, returns a structured verdict:

- If the guidelines determine a single answer, the verdict includes a precise edit so the caller can apply the fix and remove the marker.
- If multiple options remain genuinely defensible, the verdict keeps the marker for interactive user confirmation.

This skill is read-only. It never modifies any files. The caller — typically the refine-plan self-audit loop — is responsible for applying the edits.

## Arguments

- `$0`: Path to the plan directory (required, e.g., `docs/plans/2026/001-add-feature/`)

## Instructions

- Read all documents in the plan directory (`README.md`, `adr.md`, and any nested `plans/` sub-plans)
- Locate the refine-plan skill's SKILL.md via Glob (`**/refine-plan/SKILL.md`) and read its `## Design Guidelines` section as the authoritative criteria
- Find every `refine-plan:confirm` marker in the plan documents — record the file path and line number for each
- For each marker, apply a strict evaluation:
  - Does the current choice reflect minimum-effort or implementation-convenience bias? (A common Guideline 2 violation — the plan may have taken the smallest edit rather than the system-shape edit.)
  - Do the Design Guidelines, strictly applied, determine a single answer?
  - Are there genuinely multiple defensible options under the guidelines?
- Output a single JSON code block containing an array of verdicts following the schema below
- Do not modify any files

## Verdict Schema

Each verdict in the output array takes one of two shapes.

### Silent fix — guidelines determine a single answer

```json
{
  "marker_location": "README.md:42",
  "marker_text": "<full text of the marker comment>",
  "action": "silent_fix",
  "guideline": "Guideline 2: System-Shape Thinking",
  "rationale": "<specific reason — why this choice is guideline-determined, not generic>",
  "edit": {
    "file": "README.md",
    "old_string": "<exact text to replace; include enough surrounding context to be unique, and include the marker line so it is removed>",
    "new_string": "<replacement text with the marker removed>"
  }
}
```

### Keep — genuine judgment call

```json
{
  "marker_location": "adr.md:77",
  "marker_text": "<full text of the marker comment>",
  "action": "keep",
  "reason": "<why both options remain genuinely defensible under the guidelines>"
}
```

## Output Format

Output a single JSON code block with a top-level array:

```json
[
  { ... verdict 1 ... },
  { ... verdict 2 ... }
]
```

- If no markers are present in the plan, output an empty array: `[]`
- If the plan directory cannot be read, output an error object instead of an array: `{ "error": "<description>" }`

## Notes

- `edit.old_string` must be unique in the file; include enough surrounding context to disambiguate
- The edit must remove the marker as part of the fix — that is, the marker line must be present in `old_string` and absent from `new_string`
- Do not propose edits outside the scope of the marker being resolved
- Rationale text should cite the specific guideline violation or application, not restate the guideline verbatim

## Example Usage

```
/audit-plan docs/plans/2026/001-add-feature/
```
