---
name: weekly-review
description: Weekly engineering review. Summarizes what changed (commits/PRs) and what we learned (lessons/observations), then grows the pattern library. Use when asked for a weekly review, weekly digest, "what changed this week", or "evolve patterns".
---

Combines the engineering digest with pattern evolution into a single weekly
ritual. Part 1 answers "what happened?", Part 2 answers "what did we learn?",
and they cross-reference each other for richer context.

## Scope

Determine the scope automatically:

- Single repo: current directory is inside a git repo (i.e.,
  `git rev-parse --is-inside-work-tree` succeeds). Use `git` commands directly.
- Multi-repo: current directory is NOT a git repo, or user explicitly says
  "all repos", "across projects", or names a parent folder. Discover repos
  under the current directory and aggregate.

For multi-repo, discover git repos under the target folder:

```bash
find ~/Code -maxdepth 3 -name .git -type d 2>/dev/null | xargs -I{} dirname {}
```

Then run Part 1 data gathering for each repo, and collect all observations
from `~/.claude/observations/`. Derive each repo's hash:
`git -C <repo-path> remote get-url origin 2>/dev/null | md5sum | cut -c1-12`

Group the digest by repo, but cross-reference patterns across all repos.

## Author filter (avoid team noise)

When a repo belongs to a team (e.g., a client project), `git log` returns
everyone's commits and drowns the signal from your own work. Always filter
by author:

1. If `.claude/authors.txt` exists in the repo, read it. Each non-empty,
   non-comment (`#`) line becomes a `--author=<value>` flag. Values can be
   full emails, usernames, or regex patterns.
2. Otherwise, default to the current user: `--author="$(git config user.email)"`.

Build the filter once per repo:

```bash
build_author_filter() {
  local repo="$1"
  if [ -f "$repo/.claude/authors.txt" ]; then
    grep -vE '^\s*(#|$)' "$repo/.claude/authors.txt" \
      | sed 's/^/--author=/' \
      | tr '\n' ' '
  else
    echo "--author=$(git -C "$repo" config user.email)"
  fi
}
```

Apply `$AUTHOR_FILTER` to every `git log` invocation in Part 1.

## Part 1: Engineering Digest

### 1. Gather data

For each repo in scope:

```bash
AUTHOR_FILTER=$(build_author_filter "$repo")
git -C "$repo" log --since="7 days ago" $AUTHOR_FILTER \
  --pretty=format:"%h %s (%an, %ar)" --no-merges
git -C "$repo" log --since="7 days ago" $AUTHOR_FILTER \
  --merges --pretty=format:"%h %s"
```

For each significant commit or PR, read the diff with `git show <hash>`.

If a repo has zero commits after filtering, note that the week was quiet for
you in that repo and skip to the next one.

### 2. Analyze and cluster

- Group related commits into themes (e.g., "Auth overhaul", "Performance").
- Identify user-facing or system impact per theme.
- Flag security-related changes (auth, permissions, dependencies, secrets).
- Note areas with missing test coverage or rollout risk.

### 3. Compose the digest

```
Engineering Digest: [date range]

Key Changes
- [Theme]: [1-2 sentence summary with commit/PR references]

Watchlist
- [Risk or follow-up with evidence]
```

In multi-repo mode, group changes by repo. Skip repos with no commits.
If no commits across any repo in scope, state that and skip to Part 2.

## Part 2: Pattern Evolution

### 4. Read learning sources

- Read `tasks/lessons.md` to identify recurring corrections (same area,
  2+ times).
- Read observations for each repo in scope from
  `~/.claude/observations/<hash>.jsonl`. Derive hash:
  `git -C <repo> remote get-url origin | md5sum | cut -c1-12`. In multi-repo
  mode, read all observation files and tag findings by repo.
- Read `.claude/skills/railspilot-staff-review/patterns.md` to understand
  existing coverage and ID numbering.

Before analyzing, add temporal context to observations and lessons:

- Pre-compute relative time labels ("today", "3 days ago", "2 weeks ago").
- Insert gap markers between non-consecutive date groups ("[5 days later]").
- Focus on 🔴 high-priority observations (errors) first, then 🟡 medium
  (file changes), skip 🟢 low-priority older than 7 days.

### 5. Cross-reference digest with lessons

This is where the two parts synergize:

- For each theme from the digest, check if any lessons.md entries relate to
  it. A bug fix theme plus a correction about the same area is a strong
  pattern candidate.
- For commits that touched areas with known pattern violations, flag them.
- For repeated error→fix sequences in observations that align with commit
  themes, the pattern is especially worth codifying.

### 6. Identify pattern candidates

For each recurring correction or cross-referenced finding:

- Draft a new pattern entry following the exact format in patterns.md:
  `### CATEGORY-NN: Title`, `Applies to:`, description, `Detection:`, and
  Bad/Good Ruby code blocks.
- Assign to existing category (SEC, ARCH, SIMP, SCOPE, COMPLETE) or propose
  new ones (TEST, QUERY, HOTWIRE, MIGRATION).
- Use the next available number in that category.
- Note observation count as confidence indicator.

### 7. Check violated existing patterns

Cross-reference lessons.md against patterns.md. If the same pattern keeps
getting violated:

- Suggest strengthening its Detection hints.
- Suggest promoting it to CLAUDE.md for proactive enforcement.

### 8. Present everything

Output a single report with two sections:

Section A, This Week's Digest: the engineering summary from Part 1.

Section B, Learning & Patterns. For each candidate:

- The drafted pattern entry (ready to paste).
- Evidence: which lessons, observations, or digest themes triggered it.
- Whether it's new or strengthening an existing pattern.

Ask which pattern candidates to apply.

### 9. Apply approved changes

- Append approved patterns to `patterns.md` under the appropriate category.
- For promoted patterns, add to `CLAUDE.md` under the relevant section.

## When to run

- Weekly (e.g., Friday or Monday).
- After a batch of `/rails-learn` runs have accumulated new lessons.
- When asked for a weekly summary, digest, or pattern evolution.
