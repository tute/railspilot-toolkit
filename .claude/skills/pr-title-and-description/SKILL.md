---
name: pr-title-and-description
description: Generates a PR title and bullet-point description from the current branch diff, matching the project's tone. Use when asked to make a PR, create a PR, open a PR, or generate a PR title/description.
---

Generate a short PR title + explanatory but concise PR description for the current git branch.

Constraints:

- Match previous commit messages tone/style (scan recent git log main -10 for examples).
- Use 1 title line and a handful bullet points in the description.
- Base it on git diff origin/main...HEAD and branch commits; don't mention unrelated untracked files.
- Focus on user-visible changes + any notable config/dependency bumps.
