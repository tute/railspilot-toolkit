---
name: clean
description: "Cleans up after a merged branch: confirms the PR actually merged, closes the Linear or Jira issue, and deletes the worktree and the branch. Asks the developer to approve before deleting anything. Invoke it by hand once the PR is merged. It never merges anything itself."
argument-hint: "[ISSUE-KEY | empty: infer from the current worktree]"
disable-model-invocation: true
allowed-tools: Bash, Read, AskUserQuestion, TodoWrite
---

Runs after the merge, never before it. `task-implement` stops at a pushed branch and an open PR, a
human merges it, and this is what you invoke afterwards so nothing is left for the next lane to
collide with.

It does not merge, implement, review, or fix a red suite. If a PR is still open, say so and stop.

## Step 1: Resolve the issue and its branch

With an argument, that is the key. Without one, scan the branch's own commits, never the worktree
slug, which does not name the issue:

```bash
git log --format='%s%n%b' $(git merge-base main HEAD)..HEAD | grep -oE '[A-Z]+-[0-9]+' | sort -u
```

The key is not in every commit, which is why the scan reads the whole branch rather than the tip.
No key: stop and say which branch you looked at. More than one: ask which issue is being cleaned.

One issue is one branch and one PR. Find it:
`gh pr list --search "KEY" --state all --json number,state,headRefName,mergedAt`. More than one
comes back when an earlier attempt was abandoned, so check the head ref rather than taking the
first row.

## Step 2: Confirm the PR merged. Refuse rather than repair.

Fast-forward the main checkout first (`git checkout main && git pull`), so the checks below read
merged history rather than a stale one. Then, any of these stops the run:

- The PR is OPEN or CLOSED rather than MERGED. Cleaning up a closed-unmerged PR throws the work
  away.
- The tree is dirty (`git status --porcelain`). Never `git stash`, `git checkout .`,
  `git reset --hard` or `git clean` to get past it. A subagent's stash wipes a sibling lane's work.
  Commit it, or hand it back.
- `git log --oneline main.."$BRANCH"` is not empty. The merge did not carry everything, and
  `git branch -d` is about to refuse. Investigate before deleting.

## Step 3: Approval gate

Deleting is the irreversible part. Put the whole plan to the developer with AskUserQuestion, in one
question, naming the branch and worktree that will be deleted and the issue that will close.

Proceed only on approval, and only with what was approved. Anything the plan did not name, ask
again. Silence is not approval.

## Step 4: Close the issue

Linear: `mcp__linear__update_issue` with the Done state id.
Jira: `acli jira workitem transition --key KEY --status Done --yes`.

Name any acceptance criteria still unverified rather than closing over them.

## Step 5: Delete the worktree and the branch

```bash
git worktree remove .claude/worktrees/"$SLUG"
git branch -d "$BRANCH"
git fetch --prune
git worktree list
```

`-d`, never `-D`. `-d` refuses a branch whose commits are not in `main`, and that refusal is the
last check that the merge really happened. If it refuses, investigate; do not force.

A worktree outside `.claude/worktrees/` is a long-lived checkout somebody works in, not a lane.
Never remove one on your own. Ask, and if the answer is to keep it, leave it parked on `main` and
delete only the branch.

## Step 6: Report

Which PR merged, with its sha. The issue transition. What was deleted, and anything you declined
to delete with the reason.

## What /clean never does

Merge a PR. Implement, review, simplify, or fix a failing test. Stash, reset, checkout or clean a
dirty tree. `git branch -D`. Delete anything the developer did not approve in Step 3.
