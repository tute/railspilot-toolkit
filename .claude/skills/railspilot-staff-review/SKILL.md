---
name: railspilot-staff-review
description: Analyzes code against staff-engineer patterns (security, architecture, simplicity, completeness, hygiene). Use when asked for a staff or senior code review.
---

Goal is to catch issues a staff engineer would flag before they see your code.

## Workflow

**Step 1: Identify what to review**

Determine the scope:
- If the user provides a commit SHA, or mentions 'last N commits', review that diff
- If no SHA, review the current branch changes against the base branch

**Step 2: Load the patterns**

Read the patterns file at `.claude/skills/railspilot-staff-review/patterns.md`. Each
pattern has an ID, a category, a description, and detection hints.

**Step 3: Analyze each changed file**

For every file in the diff, check against ALL patterns in the patterns file. For each pattern:
1. Check if the pattern applies to this file type (Ruby, JS, ERB, migration, etc.)
2. Note the specific line(s) and what the improvement would look like

**Step 4: Apply "How RailsPilot Thinks"**

After pattern matching, re-read the "General: How RailsPilot Thinks" section and run through these questions for the entire diff:
- **Subtractive check:** Is there code here that could be deleted? Does anything duplicate what the framework or libraries provides?
- **Completeness check:** Does every behavior change have a corresponding test?
- **Security first-draft check:** Are there new fields, URLs, or user inputs that need validation or encryption in this commit?
- **Surface area check:** Is there anything in this diff that the ticket didn't ask for? Should we remove or extract into another task and commit?
- **View cleanliness check:** Is there logic in ERB that belongs in a presenter or helper?

**Step 5: Generate the review**

Output a review organized by severity:

```
## Staff Review: [branch or commit description]

### Security
- **[PATTERN-ID] [Pattern name]** — file.rb:42
  Current: [what the code does now]
  Suggested: [what a staff engineer would do]

### Architecture
- **[PATTERN-ID] [Pattern name]** — file.rb:15
  Current: [...]
  Suggested: [...]

### Simplicity
- ...

### Completeness
- ...

### Code Hygiene
- ...

### Robustness
- ...

### Testing
- ...
```

## Rules

- Show concrete code suggestions, not vague advice.
- For each finding, reference the specific pattern ID so the user can look up the full explanation.
- If the code is already good, say so. Don't force improvements where none are needed.
- When suggesting changes, show minimal diffs — just the relevant lines, not full file rewrites.
- Limit output to actionable findings. Aim for under 80 lines unless there are many real issues.

## Extending

To add new patterns learned from future reviews, edit
`.claude/skills/railspilot-staff-review/patterns.md` and add entries following the existing
format. Each review by a senior engineer is an opportunity to add patterns.
