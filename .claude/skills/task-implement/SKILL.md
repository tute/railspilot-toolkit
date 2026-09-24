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
   When the same spec fails twice with the same error, ask Jev before a third patch (see
   "Jev" below): `{"stop": {"type": "noul", "instructions": "Should this approach stop and be
   rethought?"}}`, with the error and one line per attempt as state. At >= 0.7, stop patching,
   re-read the plan and say what changes. Same rule for `bin/ci` in step 9.
7. Review with `railspilot-staff-review` in a separate agent. Pass `a11y` when the project's
   `CLAUDE.md` names WCAG, or the user asked for an accessibility pass. YOU choose which findings
   to apply and you apply them, in the same pass. Verify each against the code first, drop what does
   not survive, and say how many you dropped. Do not hand back a menu: deciding which proposals are
   real is the job. Stop and ask only when a finding is a product or architectural call the code
   cannot settle. To find those, ask Jev one noul per verified finding: "Is this a product or
   architectural call the code cannot settle?" At >= 0.8, put it in one AskUserQuestion batch.
8. Simplify with `simplify` on what survives. Quality only, never behavior. Same rule: it proposes,
   you pick and apply. Twelve edits returned is not authority to make twelve edits. Before you
   pick, ask Jev two nouls per proposed edit, with the edit's before and after text and the issue
   summary as state: "Could this edit change observable behavior?" (>= 0.5: drop it, or cover it
   with a test first) and "Is this edit outside the issue's scope?" (>= 0.8: drop it). Say how
   many each question dropped.
9. Validate: `bin/ci` if the repo has one, otherwise `mise exec -- rspec`. Green, or say plainly
   which part is not. Then check the acceptance criteria from step 2 against `git diff main...HEAD`.
   Ask Jev one noul per criterion, with the diff cut to 400 lines as state: "Does this diff fail
   to fully implement: <criterion>?" Read the code for each one >= 0.3. Fix what is missing, or
   name it in the report. Never call a criterion met on Jev alone.
10. Size the commits, not the branch. One issue is one branch and one PR however large it gets,
    but no commit runs past roughly 250 lines. Commit that way as you go through step 6, in
    dependency order, models and shared code before the UI that consumes them; splitting a fat
    branch afterwards is much harder than never letting it get fat. Check before pushing with
    `git log --oneline main..HEAD` and `git show --shortstat` per commit. A reviewer scrolls past
    a 900-line diff and rubber stamps it; the same change read commit by commit gets reviewed.
11. Push and open the PR with the `commit` skill. Jira prefixes the subject with the key
    (`PROJ-142 Add notification service`), Linear does not; the issue URL goes on the last line.
    Keep the PR body to a few lines: what it does and why, not a retelling of the diff.

## Jev

Steps 6, 7, 8 and 9 ask Jev through `~/.claude/scripts/jev`: JSON
`{"state": ..., "questions": {...}}` on stdin, answers on stdout. Batch every question of one step
into one call. Keep secrets and credentials out of the state. Jev never approves an irreversible
action. If `jev` exits nonzero (3 means it is off for this project), do the step as written, without it.

## Stop here

A pushed branch and an open PR is where this skill ends. It does not merge and it does not clean
up. A human merges the PR. `/clean` is invoked by hand afterwards, once it is merged, to close the
issue and remove the worktree and the branch.

## Report

What shipped, what the reviews changed, each acceptance criterion as met or not, and anything
left out with the reason. Record corrections
in `tasks/lessons.md`.
