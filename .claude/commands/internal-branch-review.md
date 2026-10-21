---
name: internal-branch-review
description: Local review workflow for a contributor branch or commit. Fetches, reviews, and commits improvements locally; never pushes.
---

Review a contributor branch and commit improvements locally.

Usage: /internal-branch-review <branch>

## Rules

- The only remote operation is `git fetch`. No pushes, no PRs; the user does those.
- Never stop to ask, except on rebase conflicts. Apply every improvement of medium
  value or higher, each in its own commit; the user reviews the commits afterwards.
- End each step's output with what it found and did: missing or partial AC,
  tests added or deleted, fixes applied, and low-value items skipped.

## Progress

After each step print the checklist (✅ done, ➡️ next, ⬜ remaining), then continue:

```
Progress: ✅1 Setup ✅2 Rebase ✅3 AC ➡️4 Tests ⬜5 Staff review ⬜6 Simplify ⬜7 Wrap-up
```

## Context

Infer from git, with env overrides:
- Upstream remote: `origin` (`IBR_UPSTREAM_REMOTE`).
- Branch remote (`IBR_FORK_REMOTE`): handle both setups. With a contributor fork,
  it's the first non-origin remote and both are fetched. With a single remote, the
  branch is on `origin`. If it isn't on any remote, use the local branch or commit.
- Base branch: from `origin/HEAD` (`IBR_BASE_BRANCH`).
- Jira key: from the branch name (`[A-Z][A-Z0-9]*-[0-9]+`).

## Steps

1. **Setup**: `.claude/scripts/internal-branch-review <branch> --only 1`
2. **Rebase-check**: `.claude/scripts/internal-branch-review <branch> --only 2`.
   If it conflicts, stop and tell the user so the contributor can rebase.
3. **Acceptance criteria**: fetch the Jira ticket (Atlassian MCP) and compare each
   AC item to `git diff <upstream>/<base>...HEAD`: ✅ implemented, ❌ missing,
   ⚠️ partial, numbered. Report gaps and keep going.
4. **Tests**: run the tests for the changed files. Add missing tests that protect
   behavior that matters, and delete low-value ones (e.g. asserting static page
   copy, or a new test file just for a config change). Skip gaps you'd rate low.
5. **Staff review**: run the `staff-engineer-reviewer` agent on the diff and apply
   its medium and high findings.
6. **Simplify (do not skip)**: run the full `/simplify` workflow with its three
   subagents (quality, performance, reuse) and apply their medium and high fixes,
   even if the diff looks clean.
7. **Wrap-up**: list the commits ahead of base and print branch, base, suggested
   title `[<KEY>] <subject>` and Jira link.

Commit with `/commit`. Include the Jira link in at least one commit body.
