---
name: refine-plan
description: Auto-refine a plan by looping audit-plan until findings converge, then walk remaining judgment calls with the user
argument-hint: <plan-directory>
---

# Refine Plan Skill

## Overview

Automation orchestrator for plan review. Invokes `audit-plan` in a cold-read loop, applies silent fixes, adds markers for judgment calls, records open questions, and then walks remaining markers with the user.

All review criteria are owned by `audit-plan`. This skill does not restate them — it orchestrates the response.

## Arguments

- `$0`: Path to the plan directory (required, e.g., `docs/plans/2026/001-add-feature/`)

## Workflow

### Phase 1: Audit loop

Repeat until converged or 5 iterations reached.

- Invoke `audit-plan` via the `Agent` tool with `subagent_type: general-purpose`. The subagent's prompt passes only the plan directory path — no reasoning history, no edit summary — so each iteration runs with cold context. The subagent invokes the `audit-plan` skill via the Skill tool and returns the JSON code block verbatim.
- Parse `findings` and `marker_verdicts` from the returned JSON.
- Apply silent fixes:
  - For findings with `action == silent_fix`, apply the `edit` operations (subject to the Stability Gate).
  - For marker verdicts with `verdict == silent_fix`, apply the `edit` (which removes the marker as part of the change).
- Add markers:
  - For findings with `action == marker`, insert a `refine-plan:confirm` marker at the indicated location using the Marker Format below. Record the decision, category, and rationale from the finding.
- Record asks:
  - For findings with `action == ask`, record as open questions for Phase 2. Do not edit the plan.
- Check convergence:
  - No silent fixes applied this iteration AND all marker verdicts were `keep` AND the set of new-finding IDs matches the previous iteration's set.

On exit (converged or iteration cap reached), any multi-file silent fix still blocked by the Stability Gate escalates to a marker.

### Stability Gate

Mechanical single-file fixes apply immediately. Multi-file reshapes must be confirmed by a second cold-read before applying silently.

- **Single-file silent_fix** (one `replace` operation) — apply immediately.
- **Multi-file silent_fix** (any combination of `create`, `delete`, or multiple `replace` ops) — do not apply on first sighting.
  - Track which multi-file silent-fix IDs appeared as `silent_fix` in the immediately previous iteration.
  - Apply only when the same ID is reported as `silent_fix` again. If the next iteration downgrades the finding to `marker`, follow the downgrade.
  - At least two consecutive cold-read audits must agree before a multi-file change executes silently.

### Phase 2: Interactive confirmation

- Resolve open questions (findings with `action == ask`) first. Present each via `AskUserQuestion`; apply the resulting edit.
- Walk remaining `refine-plan:confirm` markers one at a time. For each, present the location, the decision, alternatives considered, and the driving category. Ask via `AskUserQuestion` with choices `Confirm` / `Revise` / `Discuss further`.
  - `Confirm` — remove the marker from the plan.
  - `Revise` — ask the user for the desired decision, apply it, remove the marker.
  - `Discuss further` — offer additional context or alternatives, then re-prompt with the same choices.

Do not move to the next marker until the current one is resolved.

### Phase 3: Wrap-up

- Verify no `refine-plan:confirm` markers remain in the plan.
- Report a summary: silent fixes applied, markers resolved, open questions answered.

## Marker Format

Schema:

```
<!-- refine-plan:confirm — <decision> (<category>: <rationale>) -->
```

- `<decision>` — what was chosen, in one line.
- `<category>` — the `audit-plan` category that drove the choice (`Guideline 2`, `Check 3`, etc.).
- `<rationale>` — why this option serves the category best.

Placement:

- Immediately after the edited content line.
- For list items, on a new line at the same indent level.
- For inline edits inside a paragraph, at the end of the paragraph.

Example in context:

```markdown
## Worker Pool

The system uses a `WorkerPool` to manage parallel tasks.
<!-- refine-plan:confirm — chose `WorkerPool` over `JobRunner` (Guideline 1: aligns with the existing `Pool` concept) -->
```

Markers are invisible in rendered Markdown but `grep`-able. After Phase 2 resolution, they are removed.

## Example Usage

```
/refine-plan docs/plans/2026/001-add-feature/
```
