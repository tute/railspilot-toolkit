---
name: task-implement
description: "Takes a Linear or Jira issue from its own worktree to an open PR: fetch, grill into a plan, TDD, staff review, simplify, validate, then push and open one PR whose commits are review-sized. Auto-detects the tracker from recent commits. Use when given an issue key (e.g. TRA-9, PROJ-456) and asked to implement it."
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
10. Size the commits, not the branch. One issue is one branch and one PR however large it gets,
    but no commit runs past roughly 250 lines. Commit that way as you go through step 6, in
    dependency order, models and shared code before the UI that consumes them; splitting a fat
    branch afterwards is much harder than never letting it get fat. Check before pushing with
    `git log --oneline main..HEAD` and `git show --shortstat` per commit. A reviewer scrolls past
    a 900-line diff and rubber stamps it; the same change read commit by commit gets reviewed.
11. Push and open the PR with the `commit` skill. Jira prefixes the subject with the key
    (`PROJ-142 Add notification service`), Linear does not; the issue URL goes on the last line.
    Keep the PR body to a few lines: what it does and why, not a retelling of the diff.

## Stop here

A pushed branch and an open PR is where this skill ends. It does not merge and it does not clean
up. A human merges the PR. `/clean` is invoked by hand afterwards, once it is merged, to close the
issue and remove the worktree and the branch.

## Report

What shipped, what the reviews changed, and anything left out with the reason. Record corrections
in `tasks/lessons.md`.
