---
description: Review plan documents for consistency, feasibility, and clarity
argument-hint: <plan-directory>
---

# Review Plan Skill

Reviews all documents in a plan directory to ensure quality before implementation begins.

## Arguments

- `$0`: Path to the plan directory (e.g., `docs/plans/2026/001-add-feature/`)
  - If not provided, uses current branch to determine plan path

## Instructions

- Identify the plan directory from argument or current branch name
- Read ALL documents in the plan directory (README.md, adr.md, research notes, etc.)
- Check for a `plans/` subdirectory — if sub-plans exist, read those as well
- Analyze documents from multiple review perspectives
- Compile all issues, warnings, suggestions, and open questions
- Walk through each item **one at a time** with the user, asking for their input before moving to the next
- After resolving all items, update the plan document to reflect decisions made
- If the review assessment is "Ready" and the user approves, change the plan's `Status:` from `Draft` to `Open`

## Review Perspectives

### 1. Consistency Between Documents

- Do README.md and adr.md align?
- If ADR chooses approach A, does README.md reflect approach A (not B or C)?
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

### 5. Parent-SubPlan Consistency

Only applicable when the plan has a `plans/` subdirectory containing sub-plans:

- Does the parent plan's scope cover the union of all sub-plans?
- Are sub-plan boundaries clearly delineated (no overlap between sub-plans)?
- Do sub-plan requirements trace back to parent plan requirements?
- Is the breakdown logical — could the sub-plans be implemented independently?
- Are there gaps — areas in the parent plan not covered by any sub-plan?

## Output Format

### Phase 1: Internal Analysis

Silently analyze all documents and compile a list of items to discuss. Categorize each as:

- **Critical Issue**: Must be resolved before implementation
- **Warning**: Should be addressed but not blocking
- **Suggestion**: Optional improvement
- **Open Question**: Needs clarification from the plan author

### Phase 2: Interactive Walkthrough

Present items to the user **one at a time**, starting with critical issues:

- State the item clearly (category, location, description)
- Explain why it matters
- **Present your own recommendation first with reasoning**, then ask the user for their decision or input
- After the user responds, update the plan document immediately if a change was agreed upon
- Then move to the next item

### Phase 3: Final Verification

After all items are resolved:

- Show the checklist verification with results
- If all checks pass, ask the user whether to change `Status: Draft` to `Status: Open`

### Checklist

- [ ] Documents are internally consistent
- [ ] Technical approach is feasible
- [ ] Implementation details are clear
- [ ] Scope is well-defined
- [ ] Sub-plans are consistent with parent plan (if applicable)
- [ ] README.md has a `Status:` line after the heading

## Example Usage

```
/review-plan docs/plans/2026/001-add-dark-mode/
```

Or, when on a plan branch:

```
/review-plan
```
