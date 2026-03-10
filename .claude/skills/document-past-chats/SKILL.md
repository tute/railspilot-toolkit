---
name: document-past-chats
description: Analyzes past conversations to surface repeating patterns and learnings worth capturing. Use when asked to review or learn from past chats, "what have we been working on", "find patterns in my sessions", or "what should I remember".
---

Analyze past Claude Code conversations to surface repeating patterns, corrections,
and learnings worth persisting into CLAUDE.md, skills, or memory files.

## Workflow

1. **Gather conversation history** — read recent session transcripts from
   `~/.claude/projects/*/conversations/`. Focus on the last 2 months or whatever
   timeframe the user specifies.

2. **Identify repeating patterns** — look for:
   - Corrections the user made repeatedly (these are the highest-signal items —
     they indicate preferences Claude keeps getting wrong)
   - Workflows the user follows consistently (e.g., always runs tests before
     committing, always asks for a specific review format)
   - Questions the user asks often (FAQ = missing documentation)
   - Tools or commands used frequently
   - Mistakes or anti-patterns that came up multiple times

3. **Categorize findings**:
   - **CLAUDE.md candidates**: Preferences and rules that apply across all sessions
   - **Skill improvements**: Patterns specific to an existing skill
   - **New skill candidates**: Repeated multi-step workflows not yet captured
   - **Memory file candidates**: Project-specific context worth persisting

4. **Present findings** — for each finding, show:
   - The pattern observed (with examples from conversations)
   - Where it should be captured (CLAUDE.md, a skill, memory)
   - A draft of the text to add

5. **Apply approved changes** — update the relevant files with user-approved
   patterns.

## What to prioritize

Corrections > repeated workflows > frequently asked questions. A correction means
the user explicitly told Claude to do something differently — that's the clearest
signal of an undocumented preference.
