---
name: write-adr
description: Write an architecture decision record / architecture document that drives an async decision. Presents a recommendation and concrete alternatives with pros/cons so a single decision-maker can approve without a meeting. Use when asked to "write an ADR", "draft an architecture document", "write up this design decision", or "document this architecture proposal".
---

# Write an architecture decision record

An ADR is a decision-making tool: it reduces a problem to its essentials so one
person can approve the path without a meeting. Present a mature draft with a
recommendation and real alternatives. Do not open with questions; describe a path
forward.

Based on https://withatwist.dev/writing-architecture-documents-for-developers

## Length: a couple of sheets

The whole document fits on two sheets of paper, three at the most. Many people
read it many times, so make it succinct enough that they actually do. A
relatively simple problem yields a short document; if a small decision ran to
seven pages, it was over-written. No sentence, paragraph, or section should be
one you could cut without losing signal. When in doubt, cut.

## Audience: one senior reader

Write for a single decision-maker, and assume a senior engineer / tech lead who
knows the codebase. Let that assumption shape every sentence; it removes most of
the bulk:

- Don't explain what they already know (what AES-GCM is, how a service worker
  caches). No glossary, no background tutorial, no writing for non-devs.
- Give them your thought process, the decision, and why you weigh each trade-off
  as an advantage or a disadvantage. Little else belongs.

## What to include

- The decision, stated up front in one line.
- Just enough context to see the problem, at the reader's level.
- The recommended path.
- The real alternatives, in enough detail to compare and to show why you rejected
  them. Not a full spec of the option you didn't pick.
- The trade-offs, and residual risk only when the reader would otherwise approve
  blind to a real cost. Skip it when the risk is obvious or already implicit in
  why you rejected the alternatives; never add a "Residual risk" header
  reflexively.
- A pre-mortem when it earns its place, e.g. to show a proposed control is
  unnecessary because it does not address the real risk.
- A single bounded check to run before the decision is final, but only when you
  genuinely cannot settle it yourself. If an authoritative source you can reach
  (the standard, the contract, the code) answers it, read that source, resolve
  it, and fold the finding into the recommendation rather than leaving a section
  that punts the question upward. Keep a go/no-go item only for what truly needs
  someone else's input, never open ideation.

Structure serves these; it is not a checklist. Don't force a fixed set of headed
sections onto a small decision: that scaffolding is itself slop. Use the lightest
structure that carries the reasoning.

Lead with the recommendation, then give each option its own argued heading rather
than a generic "Alternatives" bucket: name the rejected option and why not (`Why
not client-side encryption`), then the chosen one and why (`Why wipe on logout`).
A short `Implementation note` pointing at the hook the work attaches to earns its
place. A `References` section does too, but only for external sources the reader
must verify to trust the decision (a standard, a contract, a benchmark). The
ticket and sibling docs are not that: the reader already has the ticket, and an
adjacent doc is better linked inline where you mention it. A references list of
those is padding.

## Cut these (they read as AI slop)

- Restating the problem again in the conclusion.
- Comparison tables and "how this shifts under different constraints" matrices
  nobody asked for.
- Talk about the document itself: "this document tests...", "captured honestly",
  "a reader can run this in their head".
- Defining standard terms, citing chapter-and-verse, exhaustive reference lists.
- Three examples where one lands.
- Enumerating the mechanism behind a principle you already stated. Once you've
  written "every design choice serves crossing the boundary," the list of those
  choices is slop; so is naming every table or field a rule touches. State the
  principle and stop.

## Do / don't

- Do prescribe a recommended path, and back the claims a skeptical reader would
  doubt.
- Don't ask open-ended questions or invite early ideation; that is code-review
  style, not this.
- Don't pad to look thorough. Thoroughness is having considered the alternatives,
  not having printed them.

## Output

Markdown under `docs/adr/`. Follow the repo's existing ADR filename convention
(e.g. `NNNN-slug.md` or `YYYY_MM_slug.md`) and header style; match what's there
rather than impose one, and never renumber. A superseded ADR stays in place and
links to the one that replaces it. Maintain a `docs/adr/README.md` index only if
the repo already keeps one; don't introduce it otherwise.

Header is three lines, a blank line, then the one-line decision, then the
reasoning:

    # <Title>

    Status: Proposed
    Date: <YYYY-MM-DD>
    Ticket: <id>

    Decision: <the choice, in one line>

Status is one of Proposed, Accepted, Superseded. Ask for the project context,
the candidate solutions, and the single decision-maker if any is not provided.
