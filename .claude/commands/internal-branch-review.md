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
  tests added or deleted, fixes applied, findings dropped in verification, and
  low-value items skipped.

## Progress

After each step print the checklist (✅ done, ➡️ next, ⬜ remaining), then continue:

```
Progress: ✅1 Setup ✅2 Rebase ✅3 AC ➡️4 Tests ⬜5 Staff review ⬜6 Simplify ⬜7 Wrap-up
```

## Context

Infer from git, with env overrides:
- Remote: `origin` (`IBR_UPSTREAM_REMOTE`). The branch lives there. If it isn't
  on the remote, use the local branch or commit.
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
   its findings rated medium and above.
6. **Simplify (do not skip)**: run the full `/simplify` workflow with its three
   subagents (quality, performance, reuse), even if the diff looks clean. Verify
   their findings rated medium and above and apply the survivors.
7. **Wrap-up**: list the commits ahead of base and print branch, base, suggested
   title `[<KEY>] <subject>` and Jira link.

## Verify findings

Before you apply a finding from step 5 or 6, try to kill it:
- Open the cited lines and trace the path from the diff to the failure.
- Look for an upstream guard: a validation, a DB constraint, an authorization
  check, a caller contract, or no caller that reaches the path. If a guard
  exists, drop the finding. Do not downgrade it.
- A surviving finding states what breaks, for whom, and how often.

Then cut the survivors as a set. Keep a finding only if a thoughtful author
would change the code because of it. A long list against a small diff means
the bar drifted: re-apply it. Report each dropped item in one line.

Commit with `/commit`. Include the Jira link in at least one commit body.
