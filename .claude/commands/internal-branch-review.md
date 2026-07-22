---
name: internal-branch-review
description: Local review workflow for contributor branches pushed to a fork. All work stays local or on the internal fork; never acts on upstream.
---

Run the automated review workflow for a contributor branch.

Usage: /internal-branch-review <branch>

## Boundaries

This workflow is strictly local + fork-only:
- Never open PRs on the upstream repo (no `gh pr create`).
- Never push to the upstream remote.
- Never act as the user on the upstream GitHub repo.
- The only remote writes are pushes to the fork remote.

If the user wants to open a PR upstream, they do it manually after the workflow completes.

## Prerequisites

Infer from git context:
- **Upstream remote**: `origin` (override with `IBR_UPSTREAM_REMOTE`)
- **Fork remote**: first non-origin remote (override with `IBR_FORK_REMOTE`)
- **Base branch**: from `origin/HEAD` (override with `IBR_BASE_BRANCH`)
- **Upstream repo**: from `git remote get-url origin` (read-only, for context)
- **Jira key**: extracted from branch name (pattern: `[A-Z][A-Z0-9]*-[0-9]+`)

Run `git remote -v` and `git remote show origin` to determine these before starting.

## Step 1 — Setup
```bash
.claude/scripts/internal-branch-review <branch> --only 1
```

## Step 2 — Rebase-check
```bash
.claude/scripts/internal-branch-review <branch> --only 2
```

## Step 3 — Acceptance Criteria
Use Atlassian MCP to fetch the Jira ticket. Read its Acceptance Criteria.
Run `git diff <upstream>/<base>...HEAD` and compare each AC item to the implementation.
Report per item: ✅ implemented | ❌ missing | ⚠️ partial (with concrete detail).
Number each item. Ask the user to confirm before proceeding.

## Step 4 — Test coverage
Map each changed file to its test file(s) (using the project's conventions).
Run the project's test suite for those files.
Report coverage gaps (behaviors changed or added without tests).
Ask the user: write missing tests now, skip, or abort.

## Step 5 — Staff review
Invoke the `staff-engineer-reviewer` agent on `git diff <upstream>/<base>...HEAD`.
Output findings as a numbered list.
Ask the user: "Enter suggestion numbers to apply (space-separated, 'all', or Enter to skip)."
Apply only the selected suggestions.

## Step 6 — Simplify + commit
Run `/simplify` on the current diff.
Then run `/commit` for each logical unit of change, one at a time.
Include the Jira link in at least one commit body (if a Jira key was found).

## Step 7 — Push to fork
Show commit count ahead of base. If more than one, offer to squash.
If squashing: generate a commit message (why-focused, Jira link in body), confirm with user, then squash.
Ask for confirmation before pushing. Then:
```bash
git push <fork_remote> HEAD:<branch> --force-with-lease
```
After pushing, print a summary the user can copy if they choose to open a PR manually:
- Branch: `<fork_user>:<branch>`
- Base: `<base_branch>`
- Suggested title: `[<KEY>] <commit subject>`
- Jira link: `<jira_link>`
