---
name: commit
description: Stages and commits to git current work with a message explaining the why, architecture decisions, and user flow. Also generates GitHub PR titles and descriptions as copy-pasteable markdown. Use when asked to commit, save progress, or when the user says "commit this", "save my changes", "make a PR", "create a PR", "open a PR", "PR this", "ready for review", or "open a pull request".
effort: low
---

Stage and commit the current work with a well-crafted commit message.

## Workflow

1. Run `git status` and `git diff` (staged + unstaged) to understand all changes.
2. Run `git log --oneline -5` to match the repository's commit message style.
3. Decide what to stage. Prefer adding specific files by name — avoid `git add -A`
   which can accidentally include sensitive files (.env, credentials) or large
   binaries. If changes span multiple concerns, suggest separate commits.
4. Draft a commit message following the format below.

If the user is asking for a **GitHub PR title and description** (e.g. "make a
PR", "PR this", "ready for review", "open a pull request"), then:
generate the PR title and description, then **output it inside a single
fenced markdown code block** so the user can copy-paste it directly into
GitHub; do not render the content verbatim in chat.

If the user is asking to **do the commit**, then:

a. Stage the files and commit. Use a HEREDOC for the message to preserve formatting.
b. Run `git status` after committing to verify success.


## Commit message format

The title explains the *why*, not the *what*. The body adds architecture context
and user-facing flow when relevant. Wrap all lines at 72 characters.

```
Succinct title explaining the why (under 50 chars ideal)

Why this change matters, wrapping lines to 72 characters. Focus on
the motivation and context, not a line-by-line description of what
changed.

- Key architecture decisions or trade-offs
- Notable patterns introduced

User flow (when applicable):

1. User does X
2. System responds with Y

https://link-to-issue-tracker (when applicable)
```

## Rules

- Never commit files that likely contain secrets (.env, credentials.json, etc.)
- Never skip hooks (--no-verify) unless explicitly asked
- If a pre-commit hook fails, fix the issue and create a NEW commit — never amend
