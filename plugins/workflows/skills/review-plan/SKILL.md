---
name: review-plan
description: Walk every audit-plan finding interactively with the user; optional re-audit at end
argument-hint: <plan-directory>
---

# Review Plan Skill

## Overview

Human-in-the-loop consumer of `audit-plan`. Invokes `audit-plan` once, walks every finding and marker verdict with the user, and optionally re-audits after resolution.

All review criteria are owned by `audit-plan`. This skill does not restate them.

## Arguments

- `$0`: Path to the plan directory (e.g., `docs/plans/2026/001-add-feature/`)
  - If not provided, derive the plan directory from the current branch name.

## Workflow

### Phase 1: Audit

- Invoke `audit-plan` via the `Agent` tool with `subagent_type: general-purpose`. A single call, no loop. The subagent invokes the `audit-plan` skill via the Skill tool and returns the JSON code block verbatim.
- Parse `findings` and `marker_verdicts` from the returned JSON.

### Phase 2: Interactive walkthrough

- Build a single queue from findings and marker verdicts, sorted by category — `guideline-*` items first (in numerical order), then `check-*` items. Items with `action == ask` appear after the categorical items.
- Walk items one at a time. For each, present the location, the issue or decision, and the driving category, then prompt via `AskUserQuestion`:
  - **silent_fix** (finding with `action == silent_fix`, or marker verdict with `verdict == silent_fix`) — choices: `Apply as recommended` / `Revise` / `Skip`.
    - `Apply as recommended` — execute the edit.
    - `Revise` — ask the user for the desired change, apply it. For marker-verdict items, the revised edit must also remove the marker.
    - `Skip` — leave the plan unchanged. For marker-verdict items, the marker stays in place.
  - **marker** (finding with `action == marker`, or marker verdict with `verdict == keep`) — choices: `Accept the decision` / `Revise` / `Discuss further`.
    - `Accept the decision` — for new findings, apply the recommendation as a regular edit (no marker needed, since the user has now confirmed it). For marker verdicts, remove the existing marker.
    - `Revise` — ask the user for the desired decision, apply it. For marker-verdict items, remove the existing marker.
    - `Discuss further` — offer additional context or alternatives, then re-prompt with the same choices.
  - **ask** (finding with `action == ask`) — present as an open question and collect the answer, then apply any resulting edit.
- Apply each decision immediately after the user responds. Do not move to the next item until the current one is resolved.

### Phase 3: Optional re-audit

- After all items are resolved, ask via `AskUserQuestion`: `Re-audit now` / `Skip re-audit`.
- `Re-audit now` — re-enter Phase 1 once. Limit: a single re-audit per invocation.
- `Skip re-audit` — proceed to Phase 4.

### Phase 4: Wrap-up

- Verify no `refine-plan:confirm` markers remain in the plan.
- If the review assessment is ready and the user approves, change `Status: Draft` to `Status: Open`.

## Marker Format

Defined in `refine-plan`'s SKILL.md. This skill references that definition rather than duplicating it.

## Example Usage

```
/review-plan docs/plans/2026/001-add-dark-mode/
```

Or, when on a plan branch:

```
/review-plan
```
