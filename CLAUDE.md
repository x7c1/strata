# Project Guidelines

## Documentation Standards

### SKILL.md Files
- Use bullet points (`-`) instead of numbered lists for Instructions section
- This makes it easier to add/remove items without renumbering

### README.md Files
- Use bullet points (`-`) for all lists
- Avoid numbered lists to facilitate easier maintenance

### Markdown Files (100+ lines)
- Always include an Overview section at the beginning
- The Overview should summarize the document's purpose and key points
- This is critical because automated tools may read only the beginning of .md files
- Without an Overview at the top, tools cannot understand the document's content

## Development Workflow

### Test-First (Red-Green)
- When fixing bugs or adding behavior changes, always follow this order:
  - First: Add tests and confirm they **fail**
  - Then: Apply the fix and confirm the tests **pass**
- This proves the fix is what makes the tests pass, not that the tests were trivially correct from the start
