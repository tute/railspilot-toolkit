---
name: update-CLAUDE
description: Analyzes recent commits to surface unique coding patterns and adds them to CLAUDE.md or skills. Use when asked to update CLAUDE.md, extract patterns from commits, or "learn from my code". Also use when the user says "what patterns do I follow" or "update my preferences".
---

Analyze recent commits to discover coding patterns worth codifying in CLAUDE.md
or existing skills, so future sessions follow the same conventions automatically.

## Workflow

1. **Read current CLAUDE.md** to understand what's already documented.

2. **Examine recent commits** — run `git log --oneline -10` to see subjects, then
   `git show <sha>` for each to read the actual diffs. Focus on the user's commits
   (match against `git config user.email`), not bot or CI commits.

3. **Identify patterns** — look for recurring choices that reflect intentional
   preferences, not one-off decisions. Good candidates:
   - Naming conventions (e.g., always `#call` on service objects)
   - Code structure choices (e.g., early returns, guard clauses)
   - Testing patterns (e.g., specific factory usage, assertion style)
   - Architecture decisions (e.g., where business logic lives)
   - Formatting or style preferences not covered by linters

4. **Filter against what's already in CLAUDE.md** — only surface patterns that
   aren't already documented. Skip anything that's just standard Rails convention
   unless the user deviates from it in a consistent, intentional way.

5. **Present findings** — show each candidate pattern with a code example from the
   commits. Ask the user which ones to add.

6. **Apply approved patterns** — add to CLAUDE.md under the appropriate section, or
   update a relevant skill if the pattern is skill-specific (e.g., a testing
   pattern goes in rspec-testing, not CLAUDE.md).

## What makes a pattern worth capturing

- It appears in 2+ commits (not a one-off)
- It reflects a deliberate choice (not just default behavior)
- Future sessions would benefit from knowing it
- It's specific enough to be actionable
