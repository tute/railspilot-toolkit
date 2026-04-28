---
name: weekly-review
description: Weekly engineering review. Summarizes what changed (commits/PRs) and what we learned (lessons), then grows the pattern library. Use when asked for a weekly review, weekly digest, "what changed this week", or "evolve patterns".
---

Combines the engineering digest with pattern evolution into a single weekly
ritual. Part 1 answers "what happened?", Part 2 answers "what did we learn?",
and they cross-reference each other.

## Scope

- Single repo: current directory is inside a git repo.
- Multi-repo: current directory is not a git repo, or the user explicitly says
  "all repos", "across projects", or names a parent folder. Ask the user for
  the parent folder if not given, then discover repos beneath it
  (`find <folder> -maxdepth 3 -name .git -type d`) and aggregate per-repo,
  then cross-reference patterns across all repos.

## Author filter

Always filter `git log` by `--author="$(git config user.email)"` so team
commits don't drown out your own work. In multi-repo mode, run `git config`
inside each repo so per-repo identities are respected.

## Temporal context

Before analyzing lessons or commits, pre-compute relative time labels
("today", "3 days ago", "2 weeks ago") and insert gap markers between
non-consecutive date groups ("[5 days later]"). LLMs struggle with raw date
math, so annotate before reasoning.

## Part 1: Engineering Digest

1. Gather data. For each repo in scope, collect commits from the last 7 days
   filtered by author. Read the diff of each significant commit or PR. If a
   repo has zero commits after filtering, note the week was quiet there and
   skip to the next one.

2. Analyze and cluster.
   - Group related commits into themes (e.g., "Auth overhaul", "Performance").
   - Identify user-facing or system impact per theme.
   - Flag security-related changes (auth, permissions, dependencies, secrets).
   - Note areas with missing test coverage or rollout risk.

3. Compose the digest. Output Key Changes and Watchlist sections, grouped by
   repo in multi-repo mode. Skip repos with no commits. If no commits across
   any repo in scope, state that and skip to Part 2.

## Part 2: Pattern Evolution

4. Read learning sources:
   - `tasks/lessons.md` for recurring corrections (same area, 2+ times).
   - `.claude/skills/railspilot-staff-review/patterns.md` for existing
     coverage and ID numbering.

5. Cross-reference digest with lessons. A bug-fix theme plus a correction in
   the same area is a strong pattern candidate. For commits that touched
   areas with known pattern violations, flag them.

6. Identify and draft pattern candidates:
   - Follow the existing format in patterns.md exactly: `### CATEGORY-NN:
     Title`, Applies to, description, Detection, Bad/Good Ruby code blocks.
   - Use existing categories (SEC, ARCH, SIMP, SCOPE, COMPLETE) or propose
     new ones (TEST, QUERY, HOTWIRE, MIGRATION).
   - If the same pattern keeps getting violated in lessons.md, suggest
     strengthening its Detection hints or promoting it to CLAUDE.md.

7. Present everything in a single report:
   - Section A: This Week's Digest (from Part 1).
   - Section B: Learning & Patterns. For each candidate include the drafted
     entry, the evidence (lessons or digest themes that triggered it), and
     whether it's new or strengthening an existing pattern.

   Ask which candidates to apply.

8. Apply approved changes: append patterns to patterns.md; promote to
   CLAUDE.md when warranted. After a lesson from `tasks/lessons.md` has been
   promoted into patterns.md, CLAUDE.md, or a skill, delete it from
   `tasks/lessons.md` so the file stays a short queue of pending corrections,
   not an unbounded log.

## When to run

- Weekly (e.g., Friday or Monday).
- After a batch of `/rails-learn` runs has accumulated lessons.
- When asked for a weekly summary, digest, or pattern evolution.
