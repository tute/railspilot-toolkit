---
name: rails-learn
description: Extracts reusable patterns from the current session — corrections, error resolutions, repeated workflows, Rails conventions. Use at the end of a productive session, when asked to "learn from this session", or when the Stop hook suggests it.
---

Extract patterns from the current session and recent observations, then persist
them into the appropriate place (patterns.md, CLAUDE.md, skills, or lessons.md).

## Workflow

1. **Gather observations** — read the JSONL observations file for the current
   project at `~/.claude/observations/<project-hash>.jsonl`. Focus on the last
   7 days, or since the last `/rails-learn` run (look for a `rails-learn-run`
   marker entry). Derive the project hash with:
   `git remote get-url origin | md5sum | cut -c1-12`

2. **Add temporal context** — before analyzing, pre-compute relative time for
   each observation and lesson entry. LLMs struggle with raw date math, so
   annotate the data:
   - Add relative labels: "today", "yesterday", "3 days ago", "2 weeks ago"
   - Insert gap markers between non-consecutive date groups: "[3 days later]"
   - Focus on 🔴 high-priority observations first (errors, failures), then
     🟡 medium (file changes), then 🟢 low (reads, routine successes)
   - Drop 🟢 low-priority observations older than 7 days from analysis

3. **Read existing documentation** — read `tasks/lessons.md`,
   `.claude/skills/railspilot-staff-review/patterns.md`, and `.claude/CLAUDE.md`
   to understand what's already captured. Skip anything already documented.

4. **Analyze the session** — look for these signal types, ranked by value:
   - **User corrections** (🔴) — the user said "no", "actually", "don't",
     "instead", or undid a change. Strongest signal of an undocumented
     preference.
   - **Error-then-fix sequences** (🔴→🟢) — a Bash tool failed (non-zero
     exit, priority: high), then subsequent tools resolved it.
   - **Repeated workflows** — same tool sequence used 3+ times.
   - **Rails-specific conventions** — service object naming, AR query patterns,
     test structure choices, migration conventions, Hotwire/Stimulus usage.

5. **Categorize findings** — for each pattern, determine where it belongs:
   - **patterns.md** — reusable code review patterns. Draft with proper format:
     `CATEGORY-NN: Title`, Applies to, Detection, Bad/Good Ruby examples.
     Categories: SEC, ARCH, SIMP, SCOPE, COMPLETE, or propose new ones
     (TEST, QUERY, HOTWIRE, MIGRATION).
   - **CLAUDE.md** — cross-session preferences and conventions.
   - **Skill improvements** — patterns specific to an existing skill (e.g.,
     testing patterns go to rspec-testing, not CLAUDE.md).
   - **lessons.md** — corrections from this session (format: date, title,
     what happened, correct approach, applies-to area).

6. **Present findings** — show each candidate with:
   - The observed pattern (with concrete examples from the session)
   - Where it should go and a draft of the text to add
   - Ask the user which to apply

7. **Apply approved changes** — update the relevant files. For patterns.md,
   follow the existing format exactly. For lessons.md, append new entries.

8. **Mark completion** — append a marker to the observations file:
   `{"type":"rails-learn-run","timestamp":"<now>"}`

## What makes a pattern worth capturing

- Corrections: always worth capturing (even once — the user had to fix Claude)
- Error resolutions: worth capturing if the same class of error appeared 2+ times
- Workflows: worth capturing if repeated 3+ times
- Conventions: worth capturing if they reflect a deliberate, non-default choice

## Priority reference

Observations are tagged by the hook:
- **high** — Bash errors (non-zero exit code)
- **medium** — file changes (Edit, Write)
- **low** — reads and successful commands
