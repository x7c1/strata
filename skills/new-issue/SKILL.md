---
description: Start planning process for new features, bug fixes, refactoring, or structural changes
disable-model-invocation: true
---

# New Issue Planning Skill

Initiates the planning process for any development task including new features, bug fixes, refactoring, or structural changes.

## Instructions

- Conduct requirements interview to understand the task
- Determine appropriate directory name with sequential numbering
- Create project directory structure in `docs/issues/{year}/{number}-{descriptive-name}/`
- Create initial draft of planning document (`plan.md`)
- Present drafts to user for review and feedback
- Make requested modifications to the documents
- Mark the planning documents as complete after user approval

## Interview Questions

When invoked, ask the user:

1. **What type of work do you want to perform?**
   - New feature addition, bug fix, refactoring, structural changes, etc.

2. **What is the specific content or purpose?**
   - Problems to solve or features to implement

3. **What is the current situation or challenge?**
   - Issues with existing code or constraints

4. **Are there any technical requirements or constraints?**
   - Compatibility with existing systems, performance requirements, etc.

5. **What is the priority and implementation schedule?**

## Directory Structure

Based on the information gathered:
- Determine the current year
- Create the year directory if it doesn't exist
- Check existing items in that year's directory to determine the next sequential number (starting from 1 for each year)
- Create project directory with format `{number}-{descriptive-name}`
- Create initial draft of `plan.md` within the project directory
- Present the drafts for review and incorporate any requested changes
- Mark the documents as complete once approved

## Document Structure

Each planning project will contain:
- `plan.md`: Main planning document with requirements, implementation plan, and timeline
  - Use bullet points instead of numbered lists for easy maintenance
  - Use 'points' instead of 'days' for timeline estimates
- `adr.md`: Architecture Decision Record
  - Only created when there are multiple technical approaches to compare with pros/cons analysis
  - Documents decisions made after struggling with difficult choices between alternatives

**Important**: When `adr.md` exists, the `plan.md` must reflect and be consistent with the decisions made in the ADR. Any technical approaches, implementation methods, or architectural choices documented in the ADR should be accurately represented in the planning document to avoid contradictions.
