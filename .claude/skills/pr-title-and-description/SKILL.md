---
name: pr-title-and-description
description: Generates a PR title and bullet-point description from the current branch diff, matching the project's tone. Use when asked to make a PR, create a PR, open a PR, or generate a PR title/description. Also use when the user says "PR this", "ready for review", or "open a pull request".
---

Generate a PR title and description for the current branch, ready to paste into
GitHub.

## Workflow

1. Run `git log main --oneline -10` to understand the repo's commit message tone
   and style.
2. Run `git log main..HEAD --oneline` to see all commits on this branch.
3. Run `git diff origin/main...HEAD --stat` for a file-level summary.
4. Run `git diff origin/main...HEAD` to read the actual changes.
5. Generate the title and description following the format below.

## Output format

```
Title: <short title, under 70 characters>

Description:
## Summary
- <bullet point describing a user-visible change or key technical change>
- <another bullet point>
- <etc.>

## Test plan
- [ ] <how to verify this works>
```

## Rules

- Title under 70 characters — use the description for details, not the title
- Match the repo's existing tone (scan recent commits)
- Focus on user-visible changes and notable config/dependency bumps
- Don't mention unrelated untracked files
- If there's a linked issue (Linear, Jira), include the URL at the bottom
- Keep bullet points concise — one line each
