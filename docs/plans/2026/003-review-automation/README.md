# Automate plan review by separating criteria from orchestration

Status: Completed

## Overview

Restructure the three plan-review skills by separating criteria from orchestration, so that `refine-plan` can fully automate what `review-plan` currently does interactively.

- `audit-plan` becomes the single source of truth for review criteria. Stateless, read-only, returns JSON.
- `refine-plan` becomes a thin orchestrator that loops `audit-plan` until findings converge, applying fixes automatically.
- `review-plan` becomes a human-in-the-loop orchestrator that calls `audit-plan` once and walks every finding with the user.

This eliminates the dilution in the current `refine-plan` (which mixes reshape, QA, and marker handling in one pass) and closes the audit gap that causes `review-plan` to surface new issues after `refine-plan` has run.

## Background

### Problem

- `review-plan` walks every finding with the user. This is tedious and defeats the purpose of having a skill do the analysis.
- `refine-plan` was introduced to automate this, but running `review-plan` after `refine-plan` still surfaces new issues.

### Root causes

- The current `refine-plan` self-audit loop (Phase 1.5) re-examines only `refine-plan:confirm` markers. Anything silently fixed or never flagged in iteration 1 does not get a cold-read review. `review-plan` is the first skill that audits the whole plan with independent context.
- `refine-plan` mixes two mental modes — reshape (Design Guidelines: concept naming, system-shape, sub-plan extraction) and QA (Quality Checks: consistency, feasibility, clarity, completeness) — in one pass. The SKILL.md has grown to ~250 lines, and instructions compete for attention.
- `review-plan`'s Review Perspectives and `refine-plan`'s Quality Checks are duplicated definitions. When criteria evolve, both must be updated in lockstep, which rarely happens.

## Design

### Skill responsibilities

- **audit-plan** — read-only skill that reads a plan directory and returns structured findings against the review criteria. Stateless; each invocation is independent. Callers invoke it via the Agent tool with a general-purpose subagent, so audit runs with cold context.
- **refine-plan** — automation orchestrator. Invokes `audit-plan` in a loop, applies silent fixes, adds markers, then walks remaining markers with the user.
- **review-plan** — human-in-the-loop orchestrator. Invokes `audit-plan` once, walks every finding with the user, offers an optional re-audit at the end.

### Why cold-read audit matters

Running `audit-plan` in a subagent gives it independent context — it does not inherit the parent conversation's reasoning about why certain decisions were made. Each audit is therefore a fresh read of the plan as it currently stands. This catches issues that the authoring context had rationalized into acceptance. The current `refine-plan` self-audit has this property but applies it only to markers; the new design applies it to the whole plan.

### Criteria location

`audit-plan` owns all criteria — absorbing the current Design Guidelines, Quality Checks, and Review Perspectives. `refine-plan` and `review-plan` reference `audit-plan` instead of restating them. This resolves the duplicate-definition problem.

## audit-plan specification

### Input

- Argument: plan directory path (e.g., `docs/plans/2026/003-review-automation/`)

### Output

A single JSON code block:

```json
{
  "findings": [ ... ],
  "marker_verdicts": [ ... ]
}
```

- `findings` — issues discovered by the audit.
- `marker_verdicts` — re-evaluations of existing `refine-plan:confirm` markers in the plan.

They are separated because provenance and handling differ: findings may become new markers or silent fixes; marker verdicts either remove or retain existing markers.

Error case: return `{ "error": "<description>" }` instead.

### Finding schema

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

- `id` — stable identifier; see Stable ID below. Callers use this to correlate findings across iterations.
- `category` — one of `guideline-1` / `guideline-2` / `guideline-3` / `check-1` / `check-2` / `check-3` / `check-4` / `check-5`.
- `category_name` — human-readable equivalent for display.
- `location` — where the issue lives.
- `title` — short label.
- `description` — what is wrong, specifically.
- `rationale` — why this violates the criterion. Must name the specific rule, not restate it.
- `recommendation` — what should change.
- `action` — one of `silent_fix` / `marker` / `ask`. Drives caller triage.
- `edit` — present only when `action == silent_fix`.

### Marker verdict schema

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

- `verdict` — `silent_fix` if the marker should be resolved and removed; `keep` if the judgment call still stands.
- `edit` — present only when `verdict == silent_fix`. The edit must include the marker line in `old_string` and omit it from `new_string`, so the marker is removed as part of the fix.

### Edit schema

Supports multi-file operations:

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
- `create` — create a new file with given content. Fails if the file exists.
- `delete` — remove a file.

Complex reshapes (sub-plan extraction, directory reorganization) express as ordered operations. See Stability gate below for how callers apply multi-file edits.

### Action semantics

- `silent_fix` — the criteria determine a single correct answer and the edit is mechanical. Safe to apply automatically.
- `marker` — multiple defensible options exist under the criteria. Callers add a `refine-plan:confirm` marker for later user confirmation.
- `ask` — the criteria alone cannot decide. Information outside the plan (external systems, stakeholder intent) is needed. Callers surface this as an open question.

### Criteria

`audit-plan`'s SKILL.md owns the full criteria. Summary:

- **Guideline 1: Concept Design First** — new concepts must be named, scoped, and distinguished from neighbors; reuse of existing concepts must be explicit.
- **Guideline 2: System-Shape Thinking** — rationale should describe the target system-shape, not the minimum edit.
- **Guideline 3: Refactor Extraction** — preparatory refactoring belongs in sub-plans, not the main plan.
- **Check 1: Document Consistency** — documents agree with each other; terminology and scope match.
- **Check 2: Technical Feasibility** — approach is achievable; dependencies are identified.
- **Check 3: Implementation Clarity** — acceptance criteria concrete; edge cases covered; interface shapes specified.
- **Check 4: Completeness** — Status line present; TODOs resolved or deferred; required sections present.
- **Check 5: Parent-SubPlan Health** — parent covers union of sub-plans; sub-plans do not overlap; sub-plan requirements trace to parent.

### Policy: prefer marker over silent_fix

`audit-plan` defaults to `action=marker` when any doubt exists. `silent_fix` is reserved for strictly mechanical, unambiguous corrections:

- Typographical and grammatical fixes.
- Missing mandatory structure (Status line, required sections as empty stubs).
- Terminology unification when one term dominates and the outlier is clearly a slip.
- Applying user-confirmed edits pointed to by existing markers.

Rewrites of rationale, concept renaming, sub-plan extraction, scope shifts — always `marker`, even when `audit-plan` can see a plausible answer. Deliberation is the role of the loop (multiple cold-read iterations), not a single audit.

### Stable ID

```
id = sha1(file + category + normalized_affected_text[0:80])[:8]
```

- `file` — the file the finding targets.
- `category` — the criteria category.
- `normalized_affected_text[0:80]` — the first 80 characters of the text being flagged, normalized by collapsing whitespace, stripping punctuation, and lowercasing.

Properties:

- Stable across iterations even when line numbers shift due to applied edits above the finding.
- Stable across minor wording drift in `description` (audit-plan's narration varies; the plan text does not).
- Changes when the flagged text is edited — correct, since after an edit the finding is no longer about the same problem state.

`audit-plan` computes the ID; callers treat it as opaque.

## refine-plan specification

### Phase 1: Audit loop

Repeat until converged or 5 iterations reached:

- Invoke `audit-plan` via the Agent tool with `subagent_type: general-purpose`. The subagent's prompt passes only the plan directory — no reasoning, no edit history — so each iteration runs with cold context.
- Parse the returned JSON.
- Apply silent fixes:
  - For findings with `action == silent_fix`, apply the `edit` operations (subject to the stability gate for multi-file edits).
  - For marker verdicts with `verdict == silent_fix`, apply the `edit` (which includes removing the marker).
- Add markers:
  - For findings with `action == marker`, insert a `refine-plan:confirm` marker at the indicated location.
- Record asks:
  - For findings with `action == ask`, record as an open question for Phase 2.
- Check convergence:
  - No silent fixes applied this iteration AND all marker verdicts were `keep` AND the set of new-finding IDs matches the previous iteration's set.

When converged or the iteration cap is reached, exit the loop. Any multi-file silent fixes still blocked by the stability gate escalate to markers.

### Stability gate for multi-file silent_fix

- Single-file silent_fix (one `replace` operation) applies immediately.
- Multi-file silent_fix (any combination involving `create`, `delete`, or multiple `replace` ops) does not apply on first sighting.
- The caller tracks which multi-file silent-fix IDs appeared as silent_fix in the immediately previous iteration.
- Apply only when the same ID is reported as silent_fix again. If the next iteration downgrades the finding to marker, revert to marker.
- At least two consecutive cold-read audits must agree before a multi-file change executes silently.

### Phase 2: Interactive confirmation

- Resolve open questions first. For each, ask the user via AskUserQuestion; apply the resulting edit.
- Walk remaining markers one at a time. For each, present location, decision, alternatives considered, and driving criterion. Use AskUserQuestion with choices `Confirm` / `Revise` / `Discuss further`.
  - `Confirm`: remove the marker from the plan.
  - `Revise`: ask the user for the desired decision, apply it, remove the marker.
  - `Discuss further`: offer additional context or alternatives, then re-prompt.

Do not advance to the next marker until the current one is resolved.

### Phase 3: Wrap-up

- Verify no `refine-plan:confirm` markers remain.
- Report a summary: silent fixes applied, markers resolved, open questions answered.

## review-plan specification

### Phase 1: Audit

- Invoke `audit-plan` via the Agent tool with `subagent_type: general-purpose`. A single call, no loop.
- Parse the JSON.

### Phase 2: Interactive walkthrough

- Present findings and marker verdicts together, sorted by category (`guideline-*` first, then `check-*`). Items with `action == ask` appear after the categorical items.
- For each item, use AskUserQuestion:
  - For `action == silent_fix`: `Apply as recommended` / `Revise` / `Skip`.
  - For `action == marker`: `Accept the decision` / `Revise` / `Discuss further`.
  - For `action == ask`: present as an open question and collect the answer.
- Apply each decision immediately after the user responds.

### Phase 3: Optional re-audit

- After all items are resolved, ask the user via AskUserQuestion: `Re-audit now` / `Skip re-audit`.
- `Re-audit now` re-enters Phase 1 once. Limit: a single re-audit per invocation.

### Phase 4: Wrap-up

- Verify no `refine-plan:confirm` markers remain.
- If the assessment is ready and the user approves, change `Status: Draft` to `Status: Open`.

## Marker format

Defined in `refine-plan`'s SKILL.md. `audit-plan` cross-references this definition rather than duplicating.

```
<!-- refine-plan:confirm — <decision> (<category>: <rationale>) -->
```

- `<decision>` — what the caller chose, in one line.
- `<category>` — the `audit-plan` category that drove the choice (`Guideline 2`, `Check 3`, etc.).
- `<rationale>` — why this option serves the category best.

Placement:

- Immediately after the edited content line.
- For list items, on a new line at the same indent level.
- For inline edits inside a paragraph, at the end of the paragraph.

## Content duplication across skills

`refine-plan` and `review-plan` each embed `audit-plan` invocation logic independently (subagent invocation, JSON parse, edit application). This duplicates ~15–20 lines per skill. The alternative — a shared reference document — was rejected because the duplication volume is small and cross-file references add load-order complexity without meaningful benefit at this scale.

## Out of scope

- Changes to skills other than `audit-plan` / `refine-plan` / `review-plan`.
- Converting existing plans that contain `refine-plan:confirm` markers — the marker format does not change, so existing plans remain compatible.
- Interactive UI changes beyond AskUserQuestion semantics.
- Schema versioning for `audit-plan` output — there are no external consumers; skills ship together.

## Work items

- Rewrite `plugins/workflows/skills/audit-plan/SKILL.md` — absorb criteria, define new output schema, document ID algorithm, document the prefer-marker policy.
- Rewrite `plugins/workflows/skills/refine-plan/SKILL.md` — thin orchestrator. Target ~100 lines (from ~250).
- Rewrite `plugins/workflows/skills/review-plan/SKILL.md` — `audit-plan` consumer. Target ~80 lines.
- Verify cross-references are consistent: marker format ownership, `audit-plan` ID contract, category naming.
- Verify the three SKILL.md files agree on action semantics, convergence rules, and the stability gate.
