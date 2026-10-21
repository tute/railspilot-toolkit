---
name: report-plan
description: "Summarise a plan document as a short decision list for a staff engineer: each decision and its why in one or two lines. Use when asked to report a plan, summarise a plan for review, brief someone on a plan, or when the user says /report-plan."
---

# Report a plan

Turn a plan document into the list a staff engineer reads before a review. They
have not read the plan and will not. They want to know what was decided, why,
and where to push back.

## Which plan

Take the path if the user gives one. Otherwise find the plan for the current
branch: look in `docs/plans/`, then for any `*.plan.md` or `*plan*.md` in the
repository, and prefer the newest one whose name or heading matches the branch's
ticket id. Read the whole file before writing anything. If two plans match, ask
which rather than guessing.

## What to include

One bullet per decision that a reviewer could reasonably have made differently.
A decision qualifies when reversing it would change the code, the schema, the
route, the vocabulary, or what ships. Everything else is detail the plan already
holds.

Include, whenever the plan contains them:

- Departures from the ticket, the source document, or an earlier plan.
- Choices between two APIs that look interchangeable and are not.
- Rules the plan knowingly leaves unenforced, and what makes that safe.
- Work the plan defers, and which ticket owns it. Say so plainly when none does.
- Lines from the ticket the plan drops as unsatisfiable, and why.
- The branch's base, when it is not the default branch.

Leave out test lists, file inventories, verification steps, and anything whose
answer is the framework's default.

## Shape

A flat bullet list, ordered by how likely the reader is to argue with it. No
headings, no nesting, no preamble, no closing summary.

Each bullet is one line, under 20 words: the decision, then the reason, joined
by a full stop. Drop class names unless the reviewer argues about them. The reason carries the fact that forces it. Name the constraint,
the file, the invariant or the failure it avoids. A bullet that could be written
without having read the plan is not worth sending.

Write in the user's house style: short sentences, active voice, no bold, no
em-dashes in prose. Say what things are, not what they are not.

## Check before sending

- Every bullet names a why that a reader could disagree with. Cut any that
  restate what the code does.
- No bullet repeats another's reason.
- Fewer than ten bullets, every one of high importance. Rank all decisions by how
  much reversing them would change, keep the top nine at most, and cut the rest.
  If more than nine survive, the plan holds more than one ticket: say so in one
  line after the list.
