---
description: Start planning process for new features, bug fixes, refactoring, or structural changes
argument-hint: [parent-plan-path]
---

# New Plan Skill

Initiates the planning process for any development task including new features, bug fixes, refactoring, or structural changes. Supports both top-level plans and sub-plans under existing plans.

## Arguments

- `$0`: Optional parent plan directory path (e.g., `docs/plans/2026/17-subscription-licensing/`)
  - If provided, creates a sub-plan under that plan's `plans/` directory

## Instructions

- Determine whether to create a top-level plan or sub-plan (see Mode Detection below)
- Conduct requirements interview to understand the task
- Determine appropriate directory name with sequential numbering
- Create the plan directory and initial draft of `README.md`
- Present drafts to user for review and feedback
- Make requested modifications to the documents
- Mark the planning documents as complete after user approval

## Mode Detection

- **Argument provided**: Create sub-plan under the specified parent plan
- **On a plan branch (no argument)**: Ask user — "Create sub-plan of the current plan?" or "Create a new top-level plan?"
- **Not on a plan branch, no argument**: Create top-level plan

## Interview Questions

When invoked, ask the user:

- **What type of work do you want to perform?**
  - New feature addition, bug fix, refactoring, structural changes, etc.

- **What is the specific content or purpose?**
  - Problems to solve or features to implement

- **What is the current situation or challenge?**
  - Issues with existing code or constraints

- **Are there any technical requirements or constraints?**
  - Compatibility with existing systems, performance requirements, etc.

- **What is the priority and implementation schedule?**

For sub-plans, some of these may be answered by the parent plan's context. Simplify the interview accordingly — skip questions already addressed in the parent.

## Directory Structure

### Top-Level Plans

- Determine the current year
- Create the year directory if it doesn't exist
- Check existing items in that year's directory to determine the next sequential number (starting from 1 for each year)
- Create project directory with format `{number}-{descriptive-name}`

### Sub-Plans

- Create a `plans/` directory under the parent plan if it doesn't exist
- Check existing items in `{parent}/plans/` to determine the next sequential number (starting from 1)
- Create sub-plan directory with format `{number}-{descriptive-name}`
- Sub-plans follow the same structure and can themselves contain nested `plans/` directories

```
docs/plans/{year}/{parent-number}-{parent-name}/
├── README.md
├── adr.md
└── plans/
    ├── 1-sub-plan-a/
    │   ├── README.md
    │   └── plans/
    │       └── 1-deeper-plan/
    │           └── README.md
    └── 2-sub-plan-b/
        └── README.md
```

## Document Structure

Each plan (top-level or sub-plan) will contain:
- `README.md`: Main planning document with requirements, implementation plan, and timeline
  - Must include `Status: Draft` immediately after the heading (see Status Field below)
  - Use bullet points instead of numbered lists for easy maintenance
  - Use 'points' instead of 'days' for timeline estimates
- `adr.md`: Architecture Decision Record
  - Only created when there are multiple technical approaches to compare with pros/cons analysis
  - Documents decisions made after struggling with difficult choices between alternatives

**Important**: When `adr.md` exists, the `README.md` must reflect and be consistent with the decisions made in the ADR. Any technical approaches, implementation methods, or architectural choices documented in the ADR should be accurately represented in the planning document to avoid contradictions.

## Status Field

Every plan README.md must include a `Status` line immediately after the `#` heading:

```markdown
# Plan Title

Status: Draft
```

Valid values:
- `Draft` — Plan is being written, not yet reviewed
- `Open` — Plan is reviewed and ready for implementation
- `Completed` — Plan has been fully implemented
- `Cancelled` — Plan was abandoned
