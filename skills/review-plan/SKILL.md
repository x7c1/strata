---
description: Review plan documents for consistency, feasibility, and clarity
argument-hint: <plan-directory>
---

# Review Plan Skill

Reviews all documents in a plan directory to ensure quality before implementation begins.

## Arguments

- `$0`: Path to the plan directory (e.g., `docs/plans/2026/1-add-feature/`)
  - If not provided, uses current branch to determine plan path

## Instructions

- Identify the plan directory from argument or current branch name
- Read ALL documents in the plan directory (README.md/plan.md, adr.md, research notes, etc.)
- Analyze documents from multiple review perspectives
- Provide structured feedback with specific issues and suggestions

## Review Perspectives

### 1. Consistency Between Documents

- Do README.md/plan.md and adr.md align?
- If ADR chooses approach A, does the plan reflect approach A (not B or C)?
- Are terminology and naming consistent across all documents?
- Do estimates and scope match between documents?

### 2. Technical Feasibility

- Are proposed approaches technically possible?
- Are there any overlooked technical constraints?
- Are dependencies and prerequisites identified?
- Is the technology stack appropriate for the requirements?

### 3. Implementation Clarity

- Can a developer start implementation without guessing?
- Are acceptance criteria clear and testable?
- Are edge cases and error handling addressed?
- Is the scope well-defined (what's in vs out)?

### 4. Completeness

- Are all necessary sections present?
- Are there TODOs or placeholders that need resolution?
- Is the problem statement clear?
- Is the solution approach justified?

## Output Format

Provide feedback in the following structure:

```markdown
## Review Summary

[Overall assessment: Ready / Needs Minor Revision / Needs Major Revision]

## Critical Issues

[Issues that must be resolved before implementation]

- Issue 1: [description]
  - Location: [file and section]
  - Suggestion: [how to fix]

## Warnings

[Issues that should be addressed but are not blocking]

## Suggestions

[Optional improvements]

## Checklist Verification

- [ ] Documents are internally consistent
- [ ] Technical approach is feasible
- [ ] Implementation details are clear
- [ ] Scope is well-defined
```

## Example Usage

```
/review-plan docs/plans/2026/1-add-dark-mode/
```

Or, when on a plan branch:

```
/review-plan
```
