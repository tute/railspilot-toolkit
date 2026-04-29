---
name: rails-learn
description: Extracts reusable patterns from the current session. Covers corrections, error resolutions, repeated workflows, Rails conventions. Use at the end of a productive session or when asked to "learn from this session".
---

Extract patterns from the current session and recent commits, then persist them
into the appropriate place (patterns.md, CLAUDE.md, a skill, or lessons.md).

## Workflow

1. Gather context: read `tasks/lessons.md`,
   `.claude/skills/railspilot-staff-review/patterns.md`, and `.claude/CLAUDE.md`
   to see what is already captured. Skip anything already documented.

2. Scan recent work: `git log --since="7 days ago"` and skim the diffs of any
   commits whose messages reference fixes, reverts, or "actually". Pair each
   with the conversation context from this session.

3. Look for these signal types, ranked by value:
   - User corrections: "no", "actually", "don't", "instead", or undone changes.
     Strongest signal of an undocumented preference.
   - Error then fix sequences: a command failed, then subsequent steps resolved
     it.
   - Repeated workflows: same tool sequence used 3+ times.
   - Rails conventions: service object naming, AR query patterns, test
     structure, migration conventions, Hotwire/Stimulus usage.

4. Categorize each candidate by destination:
   - patterns.md: reusable code review patterns. Follow the existing format
     and categories, or propose new ones.
   - CLAUDE.md: cross-session preferences and conventions.
   - Skill improvements: testing patterns into rspec-testing, etc.
   - `tasks/lessons.md`: corrections from this session (date, title, what
     happened, correct approach, applies-to area).

5. Present findings. For each candidate show the observed pattern with a
   concrete example, the proposed destination, and the draft text. Ask the
   user which to apply.

6. Apply approved changes:
   - Append new corrections to `tasks/lessons.md`.
   - For patterns.md, follow the file's existing layout exactly.
   - When a lesson from `tasks/lessons.md` is promoted into patterns.md,
     CLAUDE.md, or a skill, delete it from `tasks/lessons.md`. The promoted
     destination is now the source of truth, so the file stays a short
     queue of pending corrections rather than an unbounded log.

## What's worth capturing

- Corrections: always, even once (the user had to fix Claude).
- Error resolutions: same class of error 2+ times.
- Workflows: same sequence 3+ times.
- Conventions: deliberate, non-default choices only.
