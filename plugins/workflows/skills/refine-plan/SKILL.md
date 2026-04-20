---
name: refine-plan
description: Auto-refine a plan against design guidelines and quality checks, marking judgment calls for user confirmation
argument-hint: <plan-directory>
---

# Refine Plan Skill

## Overview

Refines a plan against the Design Guidelines and Quality Checks. All fixes are applied directly, with every choice driven by the Design Guidelines. Judgment calls are marked with `refine-plan:confirm` and listed in the final report for user confirmation.

## Arguments

- `$0`: Path to the plan directory (required, e.g., `docs/plans/2026/001-add-feature/`)

## Instructions

- Read all documents in the plan directory (`README.md`, `adr.md`, and any `plans/` sub-plans)
- Apply the Design Guidelines first — an edit here often resolves what a later check would have flagged
- Then apply the Quality Checks to verify the plan is sound given that intent
- Always apply a fix directly. Never leave a finding unedited.
- Every judgment call must be made on the basis of the Design Guidelines, not on minimum effort, minimum diff, or implementation convenience. If a minimum-effort option and a system-shape option both exist, choose the system-shape option.
- When the fix involves a judgment call (naming, concept boundaries, or any choice with defensible alternatives), insert a `refine-plan:confirm` marker next to the edit so the user can review it
- Report the applied edits and all `refine-plan:confirm` markers at the end

## Design Guidelines

Apply these first. A guideline edit often shifts what the Quality Checks need to verify.

### 1. Concept Design First

Decide whether new concepts are needed before deciding how to implement.

Check:

- Does the plan's behavior map to an existing domain concept, or does it require a new one?
- If new: is the concept named, scoped, justified, and clearly distinct from neighboring concepts?
- If existing: does the plan link to the concept's current definition and state the reuse explicitly?

Fix:

- Add a concept section when the plan silently introduces new vocabulary
- When the plan reuses an existing concept without saying so, state the reuse and link to its definition

### 2. System-Shape Thinking

**System-shape thinking** means deciding what the system *should* look like after the change and aiming for that — rather than deciding what the smallest edit is and letting the existing structure dictate the result.

Check:

- Does the rationale appeal to "minimum change" or "avoid touching X"? That's a red flag.
- Will the chosen shape still make sense once the change lands and someone reads the code fresh?
- Is the plan bolting behavior onto a structure that's already a poor fit?

Fix:

- Rewrite rationale so it describes the system-shape the plan is aiming for, not the smallest change
- When the current structure resists the change, call it out — then either defend the existing shape or plan to reshape it (see Guideline 3)

### 3. Refactor Extraction

When a plan needs preliminary refactoring to land cleanly, put the refactor in its own sub-plan rather than embedding it in the main plan.

Check:

- Is the plan mixing groundwork with feature delivery?
- Are there steps with no value on their own beyond enabling the main change?

Fix:

- Move such steps to a sub-plan at `plans/NNN-<refactor-name>/`
- Stub its `README.md` with `Status: Draft`, scope, and motivation — enough for `new-plan` or a human to expand later
- Update the parent plan to list the sub-plan as a dependency

## Quality Checks

Apply these after the guidelines. Skip anything already handled there — concept naming, approach rationale, and sub-plan extraction are out of scope for this pass.

### 1. Document Consistency

Verify the documents agree with each other, given the concepts and system-shape now set.

- Does `README.md` reflect the decisions in `adr.md` (chosen approach, trade-offs)?
- Is terminology used uniformly across documents?
- Do scope boundaries and estimates match between documents?

### 2. Technical Feasibility

Verify the approach is actually achievable (approach *selection* belongs to Guideline 2).

- Are there overlooked technical constraints?
- Are dependencies and prerequisites identified, and are they available?
- Are assumptions about external systems (APIs, libraries, infrastructure) stated explicitly?

### 3. Implementation Clarity

Verify a developer can start without guessing.

- Are acceptance criteria concrete and testable?
- Are edge cases and error handling covered?
- Are interface shapes (signatures, schemas, message formats) specified where modules meet?

### 4. Completeness

Verify nothing mechanical is missing.

- Is a `Status:` line present immediately after the heading?
- Are TODOs and placeholders resolved, or explicitly deferred with a reason?
- Are all required sections present?

### 5. Parent-SubPlan Health

Applies when the plan already has sub-plans in a `plans/` subdirectory. Stubs freshly created by Guideline 3 are not in scope.

- Does the parent still cover everything its sub-plans together cover?
- Do sub-plans avoid overlap?
- Do sub-plan requirements trace back to parent requirements?
- Are there parts of the parent scope not covered by any sub-plan?

## Auto-Edit Policy

Every finding results in an edit. The choice between options is driven by the Design Guidelines — **never** by minimum effort, minimum diff, or implementation convenience. When the choice is a judgment call among guideline-aligned options, apply the edit and add a `refine-plan:confirm` marker so the user can review it.

### Apply silently (no marker needed)

When the fix is unambiguous — only one sensible outcome given the plan's content — apply the edit without a marker.

- Rewriting rationale to focus on the target system-shape rather than minimum change
- Adding, updating, or removing descriptions of structs, functions, traits, or modules to match a guideline
- Aligning terminology across documents when the correct term is unambiguous
- Adding a missing `Status:` line when the plan is clearly still a draft
- Resolving TODOs and placeholders when the answer is clear from context
- Adding missing required sections as empty stubs

### Apply with a `refine-plan:confirm` marker

When multiple options are defensible under the Design Guidelines, pick the one that best serves them (not the easiest or smallest), apply it, and mark it. User confirmation is required before the plan is considered settled.

- Naming or concept dilemmas where several options are defensible
- Choices that shape future design direction
- Feasibility trade-offs that depend on runtime behavior, external systems, or non-obvious constraints
- TODOs whose resolution requires a decision the plan has not yet made — fill in your best guess and mark it
- Extracting prerequisite refactors into sub-plan stubs (the extraction itself, and the stub's scope)
- Parent-subplan gap fixes that go beyond a trivial stub

### Marker Format

Schema:

```
<!-- refine-plan:confirm — <decision> (Guideline <N>: <rationale>) -->
```

Required fields:

- `refine-plan:confirm` — fixed tag (enables `grep`-based discovery)
- `<decision>` — what you chose, in one line
- `(Guideline <N>: <rationale>)` — which Design Guideline drove the choice, and why this option serves it best

Placement:

- On the line immediately **after** the edited content
- For list items: as a new line following the item, at the same indent level
- For inline edits within a paragraph: at the end of the paragraph

Example in context:

```markdown
## Worker Pool

The system uses a `WorkerPool` to manage parallel tasks.
<!-- refine-plan:confirm — chose `WorkerPool` over `JobRunner` (Guideline 1: aligns with the existing `Pool` concept) -->
```

Markers are invisible in rendered Markdown but `grep`-able. After the user confirms, they can be removed in one pass.

## Final Report

After edits are applied, report in this structure:

### Applied Edits

For each edit:

- Location (file and section)
- One-line summary of what changed
- Which guideline or check drove it

### Items to Confirm

Every `refine-plan:confirm` marker must appear here. For each:

- Location (file and section)
- What you decided (e.g., "chose `WorkerPool` over `JobRunner`")
- Options considered, with trade-offs
- Which Design Guideline drove the decision, and why this option serves it best
- Final call is the user's — confirm or redirect

## Example Usage

```
/refine-plan docs/plans/2026/001-add-feature/
```
