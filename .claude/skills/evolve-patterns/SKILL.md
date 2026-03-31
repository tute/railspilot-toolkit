---
name: evolve-patterns
description: Grows the staff review pattern library by analyzing lessons.md and observations for recurring corrections. Use periodically (weekly), when asked to "evolve patterns", "grow the pattern library", or "what patterns should we add".
---

Analyze accumulated lessons and observations to identify patterns worth adding
to `.claude/skills/railspilot-staff-review/patterns.md`. This is the pattern
library growth engine — it turns repeated corrections into codified review rules.

## Workflow

1. **Read lessons.md** — read `tasks/lessons.md` and identify recurring
   corrections. A lesson that appears 2+ times (same area, same type of mistake)
   is a strong candidate for a pattern.

2. **Read observations** — read `~/.claude/observations/<project-hash>.jsonl`
   to identify error patterns and repeated workflows across multiple sessions.
   Derive project hash with: `git remote get-url origin | md5sum | cut -c1-12`

3. **Read current patterns.md** — read
   `.claude/skills/railspilot-staff-review/patterns.md` to understand:
   - Which categories exist and their ID numbering (SEC-02, ARCH-02, etc.)
   - What's already covered (avoid duplicates)
   - The exact format: `### CATEGORY-NN: Title`, `**Applies to:**`,
     description, `**Detection:**`, and Bad/Good Ruby code blocks

4. **Identify pattern candidates** — for each recurring correction or error:
   - Draft a new pattern entry following the exact existing format
   - Assign to an existing category if it fits (SEC, ARCH, SIMP, SCOPE,
     COMPLETE) or propose a new one (TEST, QUERY, HOTWIRE, MIGRATION)
   - Use the next available number in that category
   - Write concrete Detection hints (what to grep for, what to look at)
   - Write realistic Bad/Good Ruby code examples from actual corrections
   - Note how many times the pattern was observed (confidence)

5. **Check for violated existing patterns** — cross-reference lessons.md
   against patterns.md. If the same pattern keeps getting violated:
   - Suggest strengthening its Detection hints
   - Suggest promoting it to CLAUDE.md for proactive enforcement (so Claude
     follows it during implementation, not just during review)

6. **Present candidates** — for each candidate show:
   - The drafted pattern entry (ready to paste)
   - Evidence: which lessons/observations triggered it
   - Observation count as confidence indicator
   - Whether it's a new pattern or a strengthening of an existing one

7. **Apply approved changes** — append approved patterns to patterns.md under
   the appropriate category section. For promoted patterns, add to CLAUDE.md
   under the relevant section.

## Pattern ID format

Follow the existing convention exactly:
- 3-5 letter uppercase prefix: `SEC`, `ARCH`, `SIMP`, `SCOPE`, `COMPLETE`
- Hyphen and 2-digit number: `-01`, `-02`, etc.
- Example: `QUERY-01: Avoid N+1 Queries in Controllers`

## When to run

- Weekly, alongside `/weekly-summarizer`
- After a batch of `/rails-learn` runs have accumulated new lessons
- When the user asks to review or grow the pattern library
