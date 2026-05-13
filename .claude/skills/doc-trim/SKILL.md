---
name: doc-trim
description: Trim editorial bloat from technical docs (integration writeups, ADRs, investigation notes, READMEs). Proposes a unified diff with per-cut rationale and waits for approval. Use when asked to "trim this doc", "tighten this writeup", "filter pass on X.md", "prune the doc", or "cut the slop from this writeup".
---

# Doc trim

Editorial pass on a single doc file. Propose a unified diff, tag each cut, and stop. Do not write until the user approves.

## Rules

- One file at a time. Ask for the path if unclear.
- Deletions only (no reorders, no rewrites, no new sections). Add only the minimal join words needed for grammar.
- Never cut: runnable code, fact tables, links, dates, version numbers, copy-paste commands.
- Preserve voice. If a sentence has personality and carries signal, keep it.

## Cut tags

Each cut must match one. If none fits, do not cut.

- `meta`: sentences about the doc itself ("this page records...", "we document the gap so...").
- `restates-obvious`: editorial coda re-asserting what the reader just read.
- `justification-chain`: extra clauses piled on after the conclusion already lands.
- `wrapper-boilerplate`: shell/runner wrapping around a snippet the reader can re-wrap.
- `duplicate-section`: section whose content is implied or already stated.
- `prelude-padding`: "in case you wondered" clauses that delay the operative sentence.

## Output

Fenced unified diff for the file, then per-hunk rationale:

    hunk @@ L11-L12: meta
    hunk @@ L37: restates-obvious
    hunk @@ L70-L78: wrapper-boilerplate

Stop. Wait for "apply" / "go" / specific hunks to skip. Then write.

## Push back

- Already tight: say so in one line and stop.
- Cut would change meaning: flag with `RISK:` and let the user decide.
