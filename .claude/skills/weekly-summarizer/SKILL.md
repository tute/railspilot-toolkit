---
name: weekly-summarizer
description: Creates a weekly engineering digest for this repository, summarizing meaningful changes from the last 7 days. Use when asked for a weekly digest, engineering summary, or what changed recently.
---

You create an engineering digest for this repository.

## Goal

Produce a concise, high-signal summary of what changed in the last 7 days.

## What to include

- Major merged PRs and their user or system impact.
- Notable bug fixes, incidents, and risky areas touched.
- Security or dependency-related changes.
- Follow-ups worth attention (tests missing, rollout risk, possible regressions).

## Quality bar

- Prioritize signal over completeness.
- Cluster related changes into themes.
- Do not invent details; cite concrete evidence from commits/PRs.
- Keep the digest easy to skim.

## Output format

Post one Slack message with:
- Date range covered
- 3-7 key bullets of meaningful changes
- "Watchlist" section with 1-3 risks or pending follow-ups

## Instructions

### 1. Gather data

Use `git log` to fetch commits from the last 7 days:

```
git log --since="7 days ago" --pretty=format:"%h %s (%an, %ar)" --no-merges
```

Also check for merged PRs:

```
git log --since="7 days ago" --merges --pretty=format:"%h %s"
```

For each significant commit or PR, read the diff to understand the actual changes:

```
git show --stat <commit_hash>
git show <commit_hash>
```

### 2. Analyze and cluster

- Group related commits into themes (e.g., "Authentication overhaul", "Performance fixes", "Dependency updates").
- Identify the user-facing or system impact of each theme.
- Flag any security-related changes (auth, permissions, dependencies, secrets).
- Note any areas with missing test coverage or rollout risk.

### 3. Compose the digest

Format the output as a Slack message:

```
*Engineering Digest — [date range]*

*Key Changes*
- [Theme]: [1-2 sentence summary with PR/commit references]
- [Theme]: [1-2 sentence summary with PR/commit references]
- ...

*Watchlist*
- [Risk or follow-up item with evidence]
- [Risk or follow-up item with evidence]
```

### 4. Output report

Output the digest to the terminal for the user to copy.


### 5. Edge cases

- If no commits in the last 7 days, state "No changes in the last 7 days" and skip the digest.
- If only trivial changes (typo fixes, formatting), note "Quiet day — only minor housekeeping" with a brief list.
- If Slack posting fails, display the formatted message in the terminal.
