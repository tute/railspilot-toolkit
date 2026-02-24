---
name: pr-title-and-description
description: Generate a short PR title and concise PR description for the current git branch. Use when the user asks for a PR title, PR description, or pull request summary.
disable-model-invocation: true
---

Generate a short PR title + explanatory but concise PR description for the current git branch.

Constraints:

- Match previous commit messages tone/style (scan recent git log main -10 for examples).
- Use 1 title line and a handful bullet points in the description.
- Base it on git diff origin/main...HEAD and branch commits; don't mention unrelated untracked files.
- Focus on user-visible changes + any notable config/dependency bumps.
