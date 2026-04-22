# Architecture Decisions

Status: Completed

## Overview

Records the design decisions behind the plan-review restructure that separates criteria from orchestration. Each entry captures the alternatives considered, the chosen option, and the reasoning. Decisions here drive the specification in `README.md`.

## Context

The three skills — `refine-plan`, `audit-plan`, `review-plan` — were introduced incrementally. `refine-plan`'s SKILL.md grew to ~250 lines, embedding the full criteria, auto-edit policy, marker handling, and self-audit loop in one document. `review-plan` repeated much of the criteria in its own words. `audit-plan` was extracted recently but remains scoped only to marker re-evaluation.

The observation driving this plan: after running `refine-plan` on a plan, running `review-plan` still surfaces new issues. The two skills claim identical review perspectives, so the gap is structural, not definitional.

## Decision 1: Separate criteria from orchestration

All review criteria move to `audit-plan` as the single source of truth. `refine-plan` and `review-plan` reference `audit-plan` rather than duplicating definitions.

**Alternatives considered**:

- Keep criteria in `refine-plan` (status quo). Rejected — duplicated with `review-plan`, diluting both.
- Keep criteria in `review-plan`. Rejected — `refine-plan` still needs the criteria for its reshape work, so duplication returns.

**Rationale**: `audit-plan` is already read-only and stateless. Promoting it to criteria SSoT preserves that property and gives both orchestrators a single endpoint to query.

## Decision 2: Audit the whole plan each iteration, not just markers

The current `refine-plan` self-audit loop re-examines only `refine-plan:confirm` markers. The new design has `audit-plan` audit the entire plan on every invocation and return all findings.

**Alternatives considered**:

- Keep marker-only audit; add a separate "full review" pass at the end. Rejected — splits the audit surface across two mechanisms without clear benefit.

**Rationale**: cold-read of the whole plan is what catches the issues `review-plan` currently finds. Limiting audit to markers is the structural gap that causes `review-plan` to surface new issues after `refine-plan`.

## Decision 3: Prefer marker over silent_fix

When the criteria permit any defensible alternative, `audit-plan` emits `action=marker` rather than `action=silent_fix`. Silent fixes are reserved for strictly mechanical corrections.

**Alternatives considered**:

- Aggressive silent_fix (apply whenever a plausible fix exists). Rejected — skips the deliberation that the loop is designed to provide.
- Marker-only (never silent_fix). Rejected — drowns the user in Phase 2 confirmations for trivial mechanical fixes.

**Rationale**: deliberation happens through multiple cold-read iterations of the loop, not within a single audit. Defaulting to marker ensures the loop has material to deliberate on; the `marker_verdicts` mechanism downgrades markers to silent fixes when subsequent iterations converge.

## Decision 4: Stability gate for multi-file silent_fix

Multi-file silent fixes (sub-plan extraction, directory reorganization) apply only after the same finding appears as silent_fix in two consecutive iterations. Single-file silent fixes apply immediately.

**Alternatives considered**:

- Never apply multi-file silent fixes; always require user confirmation. Rejected — contradicts the goal of automating the whole review workflow.
- Apply on first sighting. Rejected — `audit-plan`'s first-pass judgment on complex restructures is less reliable; committing to multi-file operations without a confirming iteration is risky.

**Rationale**: the plan directory is uncommitted and all operations are reversible via git, so the safety cost of automation is low but not zero. Requiring two cold-read iterations to agree is a lightweight trust signal that exploits the loop's existing deliberation property.

## Decision 5: Drop severity from the finding schema

An earlier draft included a `severity` field (critical / warning / suggestion / question). Dropped in favor of `action` alone.

**Alternatives considered**:

- Keep both `severity` and `action`. Rejected — severity's only role was Phase 2 presentation order, which `category` already provides. Two axes would invite `audit-plan` to spend judgment on which severity label to assign rather than on substance.

**Rationale**: the triage decision is driven by `action` (silent_fix / marker / ask). Phase 2 ordering can use `category` (guideline-* before check-*). A separate severity axis adds noise without improving behavior.

## Decision 6: Marker format stays in refine-plan

The `<!-- refine-plan:confirm — ... -->` format is defined in `refine-plan`'s SKILL.md. `audit-plan` cross-references it.

**Alternatives considered**:

- Move the format to `audit-plan` (treat `audit-plan` as the marker authority). Rejected — `refine-plan` is the skill that writes markers; ownership should follow production.
- Extract the format to a shared reference document. Rejected — one definition, two consumers; the duplication cost is near zero.

**Rationale**: `refine-plan` writes markers. `audit-plan` only parses existing ones. Ownership tracks the writer.

## Decision 7: No schema version field

The `audit-plan` JSON output does not include a `schema_version` field.

**Alternatives considered**:

- Include `schema_version` for forward compatibility. Rejected — the three skills ship together and there are no external consumers of `audit-plan`'s output.

**Rationale**: git history captures schema evolution. A version field is only necessary when out-of-lockstep consumers exist.

## Decision 8: Content-based stable ID

The finding ID is computed as `sha1(file + category + normalized_affected_text[0:80])[:8]`, not from location.

**Alternatives considered**:

- `sha1(file + line_start + normalized_description)`. Rejected — line numbers shift when upstream edits apply, and `description` is `audit-plan`'s narration, which drifts across cold reads.
- Sequential numeric IDs. Rejected — not stable across iterations; the loop cannot correlate.

**Rationale**: the ID must identify "the same issue" across iterations even as the plan changes. Tying ID to the flagged text (which changes only when the issue is addressed) rather than to location or narration gives the right semantics — stable while the problem persists, different once the text is edited.
