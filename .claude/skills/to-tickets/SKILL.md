---
name: to-tickets
description: Break a plan, spec, or the current conversation into tracer-bullet tickets, each declaring what blocks it. Use when the user wants work split into tickets, issues, or a build order.
disable-model-invocation: true
---

# To Tickets

Break work into tickets: vertical slices, each declaring the tickets that block
it.

> Ours. Takes the ticket-splitting half of `to-tickets` in
> [mattpocock/skills](https://github.com/mattpocock/skills) v1.2.3 and stops
> there. No tracker config, no labels, no publishing.

## 1. Gather context

Work from what is already in the conversation. If the user passes a reference,
a spec path, an issue number, a URL, read it in full, comments included.

Explore the code if you have not already. Titles and descriptions use the
project's own vocabulary. Look for a prefactor that makes the change easy
first.

## 2. Draft vertical slices

Each slice:

- Cuts a narrow but complete path through every layer: schema, model,
  controller, view, tests. Vertical, never one horizontal layer.
- Is demoable or verifiable on its own.
- Fits in one fresh context window.
- Comes after any prefactor it needs.

Give each ticket its blocking edges: the tickets that must finish before it can
start. A ticket with no blockers starts immediately.

## 3. Wide refactors are the exception

A wide refactor is one mechanical change whose blast radius fans across the
codebase. Renaming a column, retyping a shared symbol. One edit breaks
thousands of call sites, so no vertical slice can land green.

Sequence it expand, migrate, contract:

- Expand: add the new form beside the old. Nothing breaks.
- Migrate: move call sites in batches sized by blast radius. One ticket per
  batch, each blocked by the expand. CI stays green because the old form is
  still there.
- Contract: delete the old form once no caller remains. Blocked by every
  migrate batch.

When the batches cannot stay green alone, keep the sequence but share an
integration branch, and let every batch block a final integrate-and-verify
ticket. Green is promised only there.

## 4. Present and iterate

Show the breakdown as a numbered list in dependency order, blockers first. Per
ticket:

- Title
- Blocked by, or nothing
- What it delivers, as end-to-end behaviour

Then ask:

- Is the granularity right, too coarse or too fine?
- Does each ticket depend only on what genuinely gates it?
- Should any be merged or split further?

Iterate until the user approves.

## 5. Write them down, if asked

Only when the user asks for files. One per ticket under
`.scratch/<feature>/NN-<slug>.md`, numbered in dependency order.

```markdown
# NN. Title

What to build: the end-to-end behaviour this ticket makes work, from the
user's point of view. Not a layer-by-layer implementation list.

Blocked by: the tickets that gate this one, or nothing.

- [ ] Acceptance criterion
- [ ] Acceptance criterion
```

Avoid file paths and code snippets. They go stale. The exception is a snippet
that encodes a decision more precisely than prose can: a state machine, a
schema, a type shape. Trim it to the decision, not a working demo.
