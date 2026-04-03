# Lessons Learned

Corrections and patterns from sessions. Reviewed at session start.
New entries added after corrections per CLAUDE.md self-improvement loop.

---

<!-- Format:
### YYYY-MM-DD: Short title

What happened, what was wrong, what's the correct approach.

**Applies to:** [area — e.g., testing, architecture, Rails conventions]
-->

### 2026-03-31: Prefer merging synergistic skills over keeping them separate

When two skills operate on overlapping data or are meant to run at the same
time (e.g., weekly-summarizer + evolve-patterns), merge them into one skill
that cross-references both data sources. Separate skills that "should be run
together" create friction — a single skill with clear sections is better.

**Applies to:** skill design, toolkit architecture

### 2026-04-03: Global Claude config lives in toolkit, not ~/.claude

`bin/install` symlinks `~/.claude/settings.json` → toolkit. Edit the toolkit copy.

**Applies to:** configuration
