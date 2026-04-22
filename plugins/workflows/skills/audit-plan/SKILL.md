---
name: audit-plan
description: Read-only audit of a plan against the plan review criteria — returns findings and marker verdicts as JSON
argument-hint: <plan-directory>
---

# Audit Plan Skill

## Overview

Stateless, read-only audit of a plan directory against the plan review criteria. Returns structured JSON: new findings against the plan's current content, plus re-evaluations (marker verdicts) of any `refine-plan:confirm` markers already in the plan.

This skill owns all review criteria — the Design Guidelines, Quality Checks, and broader Review Perspectives consolidated in one place. `refine-plan` and `review-plan` invoke this skill and orchestrate the response; they do not restate criteria.

This skill never modifies files. The caller applies the edits.

## Arguments

- `$0`: Path to the plan directory (required, e.g., `docs/plans/2026/001-add-feature/`)

## Instructions

- Read all documents in the plan directory (`README.md`, `adr.md`, and any `plans/` sub-plans recursively)
- Locate every `refine-plan:confirm` marker in those documents and record its file path and line number
- Evaluate the plan against the Criteria below
- For each issue discovered, emit a finding with the appropriate `action` (`silent_fix` / `marker` / `ask`) per the Action Policy
- For each existing marker, emit a marker verdict (`silent_fix` to resolve and remove, `keep` to retain)
- Output a single JSON code block containing `findings` and `marker_verdicts`
- Do not modify any files

## Criteria

Eight categories. Each finding names exactly one.

### Guideline 1: Concept Design First

New behaviors must map to a named concept.

- Does the plan's behavior map to an existing domain concept, or does it require a new one?
- If new: is the concept named, scoped, justified, and clearly distinct from neighbors?
- If existing: does the plan link to the concept's current definition and state the reuse explicitly?

### Guideline 2: System-Shape Thinking

Rationale should describe the target system-shape — what the system should look like after the change — not the minimum edit or "avoid touching X" framing.

- Does the rationale appeal to "minimum change"? Red flag.
- Will the chosen shape still make sense once the change lands and someone reads the code fresh?
- Is the plan bolting behavior onto a structure that is already a poor fit?

### Guideline 3: Refactor Extraction

Preparatory refactoring belongs in its own sub-plan, not the main plan.

- Is the plan mixing groundwork with feature delivery?
- Are there steps with no value on their own beyond enabling the main change?

### Check 1: Document Consistency

Documents in the plan directory agree with each other.

- Does `README.md` reflect the decisions in `adr.md` (chosen approach, trade-offs)?
- Is terminology used uniformly across documents?
- Do scope boundaries and estimates match?

### Check 2: Technical Feasibility

The approach is achievable.

- Are technical constraints stated?
- Are dependencies and prerequisites identified?
- Are assumptions about external systems (APIs, libraries, infrastructure) explicit?

### Check 3: Implementation Clarity

A developer can start without guessing.

- Are acceptance criteria concrete and testable?
- Are edge cases and error handling covered?
- Are interface shapes (signatures, schemas, message formats) specified where modules meet?

### Check 4: Completeness

Nothing mechanical is missing.

- Is a `Status:` line present immediately after the heading?
- Are TODOs and placeholders resolved or explicitly deferred with a reason?
- Are all required sections present?

### Check 5: Parent-SubPlan Health

Applies when the plan has sub-plans in `plans/`.

- Does the parent cover the union of what its sub-plans cover?
- Do sub-plans avoid overlap?
- Do sub-plan requirements trace back to parent requirements?
- Are there parts of the parent scope not covered by any sub-plan?

## Action Policy

Each finding carries an `action` that drives caller triage.

- `silent_fix` — the criteria determine a single correct answer and the edit is mechanical. Safe to apply automatically.
- `marker` — multiple options are defensible under the criteria. The caller inserts a `refine-plan:confirm` marker so the user decides.
- `ask` — the criteria alone cannot decide. Information outside the plan (external systems, stakeholder intent) is needed. The caller surfaces this as an open question.

### Prefer marker over silent_fix

Default to `marker` when any doubt exists. Reserve `silent_fix` for strictly mechanical, unambiguous corrections:

- Typographical and grammatical fixes
- Missing mandatory structure (Status line, required sections as empty stubs)
- Terminology unification when one term dominates and the outlier is clearly a slip
- Applying user-confirmed edits pointed to by existing markers

Rationale rewrites, concept renaming, sub-plan extraction, scope shifts — always `marker`, even when a plausible answer exists. Deliberation is the role of the loop (multiple cold-read iterations), not a single audit.

## Output Schema

Output a single JSON code block:

```json
{
  "findings": [ ... ],
  "marker_verdicts": [ ... ]
}
```

- `findings` — issues discovered by this audit.
- `marker_verdicts` — re-evaluations of existing `refine-plan:confirm` markers.

Error case: output `{ "error": "<description>" }` instead.

### Finding

```json
{
  "id": "a3f2c1d8",
  "category": "guideline-2",
  "category_name": "System-Shape Thinking",
  "location": { "file": "README.md", "line_start": 42, "line_end": 45 },
  "title": "Rationale appeals to minimum change",
  "description": "The scope section justifies the approach by noting it avoids touching the existing scheduler.",
  "rationale": "Guideline 2 flags rationale anchored on minimum change rather than target system-shape.",
  "recommendation": "Rewrite rationale to describe the target system-shape, or defend the existing structure explicitly.",
  "action": "silent_fix",
  "edit": { ... }
}
```

- `id` — see Stable ID below. Callers use it to correlate findings across iterations.
- `category` — one of `guideline-1` / `guideline-2` / `guideline-3` / `check-1` / `check-2` / `check-3` / `check-4` / `check-5`.
- `category_name` — human-readable label for display.
- `location` — where the issue lives.
- `title` — short label.
- `description` — what is wrong, specifically.
- `rationale` — why this violates the criterion. Name the specific rule; do not restate it verbatim.
- `recommendation` — what should change.
- `action` — see Action Policy.
- `edit` — present only when `action == silent_fix`.

### Marker Verdict

```json
{
  "marker_location": "README.md:42",
  "marker_text": "<!-- refine-plan:confirm — ... -->",
  "verdict": "silent_fix",
  "guideline": "Guideline 2",
  "rationale": "On re-reading, the decision is guideline-determined.",
  "edit": { ... }
}
```

- `verdict` — `silent_fix` to resolve and remove the marker; `keep` if the judgment call still stands.
- `edit` — present only when `verdict == silent_fix`. The edit must include the marker line in `old_string` and omit it from `new_string`, so the marker is removed as part of the fix.

### Edit

Supports multi-file operations.

```json
{
  "operations": [
    { "op": "replace", "file": "README.md", "old_string": "...", "new_string": "..." },
    { "op": "create", "file": "plans/001-extract-x/README.md", "content": "..." },
    { "op": "delete", "file": "README.md" }
  ]
}
```

- `replace` — equivalent to the Edit tool's `old_string`/`new_string` replacement. `old_string` must be unique within the file.
- `create` — create a new file with the given content. Fails if the file exists.
- `delete` — remove a file.

Complex reshapes (sub-plan extraction, directory reorganization) express as ordered operations. Callers apply multi-file edits subject to their own stability gate (see `refine-plan`'s SKILL.md).

## Stable ID

```
id = sha1(file + category + normalized_affected_text[0:80])[:8]
```

- `file` — the file the finding targets.
- `category` — the criteria category string (e.g., `guideline-2`).
- `normalized_affected_text[0:80]` — the first 80 characters of the text being flagged, normalized by collapsing whitespace, stripping punctuation, and lowercasing.

Properties:

- Stable across iterations even when line numbers shift due to applied edits above the finding.
- Stable across minor wording drift in `description` (this skill's narration varies; the plan text does not).
- Changes when the flagged text is edited — correct, since after an edit the finding is no longer about the same problem state.

This skill computes the ID; callers treat it as opaque.

## Marker Format

Defined in `refine-plan`'s SKILL.md. This skill only parses existing markers; it does not author them. Callers own marker insertion.

## Example Usage

```
/audit-plan docs/plans/2026/001-add-feature/
```

## Notes

- Output exactly one JSON code block. No prose outside the code block.
- `old_string` in any `replace` operation must be unique within the file; include enough surrounding context to disambiguate.
- When resolving a marker, the edit must include the marker line in `old_string` and omit it from `new_string`.
- Rationale text must cite the specific criterion the plan violates, not restate the criterion verbatim.
