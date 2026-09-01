---
name: task-implement
description: "Takes a Linear or Jira issue from its own worktree to a merged PR: fetch, grill into a plan, TDD, staff review, simplify, validate, PR, then delete the worktree and branch and close the issue. Auto-detects the tracker from recent commits. Use when given an issue key (e.g. TRA-9, PROJ-456) and asked to implement it."
argument-hint: "<ISSUE-KEY>"
disable-model-invocation: true
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, Agent, AskUserQuestion, Skill, TodoWrite
---

Implements one issue end to end, in its own worktree.

## Worktree

Every issue gets one, so several lanes can run at once and none is editing the checkout another
agent is testing in.

```bash
git fetch origin
git worktree add -b "$BRANCH" .claude/worktrees/"$SLUG" origin/main
cd .claude/worktrees/"$SLUG" && bin/setup
```

`bin/setup` is what `.cursor/worktrees.json` runs: it installs and links whatever the repo
gitignores that the build needs. Add `.claude/worktrees/` to `.gitignore` if it is not there. Smoke
one spec file before going further, because a worktree that cannot run tests fails at TDD, an hour
in.

Inside a worktree, never `git stash`, `git checkout .`, `git reset --hard` or `git clean`. A
subagent's stash wipes a sibling lane's work. Commit instead.

Branch name: Linear supplies one in the issue's `branchName`. For Jira derive
`<initials>/<KEY>-<slugified-summary>`.

## Steps

1. Detect the tracker:
   `git log main --oneline -30 | grep -io "linear.app\|atlassian.net" | head -1`. Linear means the
   Linear MCP server, Jira means `acli`. No match, ask.
2. Fetch the issue: `mcp__linear__get_issue(id:)` or `acli jira workitem view KEY --json`. The
   description is the acceptance criteria unless it says otherwise.
3. Move it to In Progress. Linear: `mcp__linear__update_issue` with a state id from
   `mcp__linear__list_issue_statuses`. Jira:
   `acli jira workitem transition --key KEY --status "In Progress" --yes`.
4. Plan with `/grill-with-docs`. It works the issue as a design tree, resolves each branch, and
   dispatches subagents for whatever the environment can answer instead of asking, which is where
   the Obsidian notes, the referenced Sentry issue and the linked PRs get read. Its output is the
   plan. Grilling settles the decisions, not the sequencing, so finish with a test strategy and an
   ordered list of steps as a TodoList. Commit the ADRs it writes under `docs/adr/`; leave
   `CONTEXT.md` untracked.
5. Get the plan approved before writing code.
6. Implement with `tdd-skill`: strict red-green-refactor, one cycle at a time. No skipped tests.
7. Review with `railspilot-staff-review` in a separate agent. Pass `a11y` when the project's
   `CLAUDE.md` names WCAG, or the user asked for an accessibility pass. YOU choose which findings
   to apply and you apply them, in the same pass. Verify each against the code first, drop what does
   not survive, and say how many you dropped. Do not hand back a menu: deciding which proposals are
   real is the job. Stop and ask only when a finding is a product or architectural call the code
   cannot settle.
8. Simplify with `simplify` on what survives. Quality only, never behavior. Same rule: it proposes,
   you pick and apply. Twelve edits returned is not authority to make twelve edits.
9. Validate: `bin/ci` if the repo has one, otherwise `mise exec -- rspec`. Green, or say plainly
   which part is not.
10. Commit and open the PR with the `commit` skill. Jira prefixes the subject with the key
    (`PROJ-142 Add notification service`), Linear does not; the issue URL goes on the last line.

## Landing

An issue is not finished when the branch is green. It is finished when the branch is gone. Landing
is part of the same unit of work, not a second request the user has to make. A green branch left
behind leaves the tracker lying about what is left, and a worktree the next lane collides with.

1. Re-check the base. `main` moves while a lane runs, sometimes from another session shipping the
   adjacent half of the same feature. Diff as `git diff $(git merge-base main HEAD)..HEAD`, never
   `main..HEAD`, or unrelated files read as the branch's own changes and the review chases them.
   Test the merge before proposing it:
   `git merge-tree --write-tree main "$BRANCH" | grep -c CONFLICT`.
2. Resolve conflicts by composing, not choosing. Two commits touching one method usually carry two
   different concerns and both belong.
3. Rebase on current `main` and re-run the suite. A green branch and a green merge are different
   facts.
4. Once the PR merges, remove the worktree and branch:
   `git worktree remove .claude/worktrees/"$SLUG" && git branch -d "$BRANCH"`, then
   `git worktree list` to confirm nothing is left.
5. Close the issue. Name any acceptance criteria still unverified rather than closing over them.

## Report

What shipped, what the reviews changed, and anything left out with the reason. Record corrections
in `tasks/lessons.md`.
