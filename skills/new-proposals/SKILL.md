---
description: Generate improvement proposals from codebase review or user ideas
argument-hint: [scope-or-idea]
---

# New Proposals Skill

Generates improvement proposals by analyzing the codebase or capturing user ideas, and writes them to `docs/proposals/`.

## Arguments

- `$0`: Optional scope or idea description
  - If empty or a scope (e.g., "error handling", "test coverage"): runs codebase review mode
  - If a concrete idea description: runs manual input mode

## Mode 1: Codebase Review

Analyze the codebase for improvement opportunities and generate proposals as a batch.

### Instructions

- Determine the review scope (entire codebase or specific area from argument)
- Read existing proposals in `docs/proposals/` (including rejected/deferred) to avoid duplicates
- Analyze the codebase for improvement opportunities:
  - Code quality issues
  - Missing features or documentation
  - Reliability and error handling gaps
  - Compatibility concerns
  - Architectural improvements
- Generate proposals for each finding
- Present all generated proposals to the user for review before writing files
- After user approval, write proposals to `docs/proposals/{YYYY-MM-DD}-{context}/`

### Context Naming

- Use a descriptive context based on the review scope
- Examples: `codebase-review`, `error-handling-review`, `test-coverage-review`

## Mode 2: Manual Input

Capture a user's idea and format it into a proposal.

### Instructions

- Parse the user's idea from the argument
- Ask clarifying questions if needed:
  - Priority (Low/Medium/High)
  - Category (Feature/Documentation/Reliability/Quality/Compatibility)
  - Specific problems or motivations
- Read existing proposals in `docs/proposals/` (including rejected/deferred) to avoid duplicates
- If a similar proposal already exists, inform the user and ask how to proceed
- Format the idea into a proposal
- Present the proposal to the user for review before writing
- After user approval, write proposal to `docs/proposals/{YYYY-MM-DD}-{context}/`
  - Reuse today's batch directory if one already exists and the context fits
  - Otherwise create a new batch directory

## Proposal File Format

```markdown
# Title

## Overview

[2-3 sentence summary]

## Priority

[Low/Medium/High]

## Effort

[Low/Medium/High/Unknown]

## Category

[Feature/Documentation/Reliability/Quality/Compatibility]

## Problem

[Detailed description of the problem or opportunity]

## Proposed Actions

[Bulleted list of specific actions]

## Decision

- [ ] Accept
- [ ] Reject
- [ ] Defer

**Notes**:
```

## Proposal Directory Structure

```
docs/proposals/
  {YYYY-MM-DD}-{context}/
    {descriptive-name}.md
    {descriptive-name}.md
```

- Batch directory: `{date}-{context-description}` (e.g., `2026-02-06-codebase-review`)
- Proposal files: `{descriptive-name}.md` (e.g., `improve-error-handling.md`)
- No numbering — file names should be descriptive kebab-case

## Key Rules

- Always check existing proposals in `docs/proposals/` (all statuses) before generating new ones to avoid duplicates
- Decision checkboxes are always unchecked — triaging is done by `review-proposals`
- Present generated proposals to the user for review before writing any files
- In codebase review mode, generate all proposals as a batch in a single directory
- In manual input mode, reuse today's batch directory when appropriate

## Example Usage

Codebase review (full):
```
/new-proposals
```

Codebase review (scoped):
```
/new-proposals error handling
```

Manual idea:
```
/new-proposals Add support for exporting settings as JSON for backup and sharing
```
