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

2. **Read existing documentation** — read `tasks/lessons.md`,
   `.claude/skills/railspilot-staff-review/patterns.md`, and `.claude/CLAUDE.md`
   to understand what's already captured. Skip anything already documented.

3. **Analyze the session** — look for these signal types, ranked by value:
   - **User corrections** — the user said "no", "actually", "don't", "instead",
     or undid a change. These are the strongest signal of an undocumented
     preference.
   - **Error-then-fix sequences** — a Bash tool failed (non-zero exit), then
     subsequent tools resolved it. The resolution is the pattern.
   - **Repeated workflows** — same tool sequence used 3+ times (e.g., always
     running tests after editing a model).
   - **Rails-specific conventions** — service object naming, AR query patterns,
     test structure choices, migration conventions, Hotwire/Stimulus usage,
     controller organization.

4. **Categorize findings** — for each pattern, determine where it belongs:
   - **patterns.md** — reusable code review patterns. Draft with proper format:
     `CATEGORY-NN: Title`, Applies to, Detection, Bad/Good Ruby examples.
     Categories: SEC, ARCH, SIMP, SCOPE, COMPLETE, or propose new ones
     (TEST, QUERY, HOTWIRE, MIGRATION).
   - **CLAUDE.md** — cross-session preferences and conventions.
   - **Skill improvements** — patterns specific to an existing skill (e.g.,
     testing patterns go to rspec-testing, not CLAUDE.md).
   - **lessons.md** — corrections from this session (format: date, title,
     what happened, correct approach, applies-to area).

5. **Present findings** — show each candidate with:
   - The observed pattern (with concrete examples from the session)
   - Where it should go and a draft of the text to add
   - Ask the user which to apply

6. **Apply approved changes** — update the relevant files. For patterns.md,
   follow the existing format exactly. For lessons.md, append new entries.

7. **Mark completion** — append a marker to the observations file:
   `{"type":"rails-learn-run","timestamp":"<now>"}`

## What makes a pattern worth capturing

- Corrections: always worth capturing (even once — the user had to fix Claude)
- Error resolutions: worth capturing if the same class of error appeared 2+ times
- Workflows: worth capturing if repeated 3+ times
- Conventions: worth capturing if they reflect a deliberate, non-default choice
