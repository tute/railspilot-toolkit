---
name: tdd-skill
description: Guides TDD implementation via strict Red-Green-Refactor cycles, one piece at a time. Use when implementing features or fixes with TDD, or whenever CLAUDE.md says to use TDD. This skill applies to ALL implementation work — features, bug fixes, refactors with behavior changes. Even "simple" changes benefit from the discipline.
---

Implement using strict test-driven development: one Red-Green-Refactor cycle at a
time. The discipline is the point — it prevents writing more code than needed and
catches design problems early.

## The cycle

1. **Red**: Name the production bug the test catches. If there is none, skip the
   test. Write the simplest test for ONE discrete piece of functionality. Run
   only that test with the project's test command and verify it fails with the
   expected error message. If it fails for the wrong reason, fix the test first.

2. **Green**: Write the minimum code to make that one test pass. Resist the urge
   to implement more than what the test demands. Run the test again to confirm it
   passes.

3. **Refactor**: Break the production line the test covers, see the test fail,
   then restore the line. Then look for opportunities to clean up, both in the
   production code and the test. Remove duplication, improve naming, extract
   methods. Run the test again to verify nothing broke.

4. **Repeat**: Pick the next piece of functionality and start a new cycle.

## What counts as "one piece"

- One branch of logic we wrote
- One error a caller can cause
- One step of a workflow
- One database constraint, tested at the database

If you're unsure whether something is one piece or two, err on the side of
smaller. You can always go faster; you can't easily undo a big untested jump.

## Do not write

- A test that is red only because a declaration is missing (`belongs_to`,
  `enum`, presence, a one-clause scope, a column default). Write the declaration
  with no test.
- A test of a state no caller can produce, and the guard that would make it
  reachable.
- A test of a branch that already has a test at another layer. Grep first.

## Layers

Test branches in the unit. The integration test covers the wiring only: one
success, one refusal, and authorization.

View and messaging tests belong at the integration layer, not in unit tests. A
view test turns red on a status, a redirect, record state, a form action, a field
name, accessibility wiring, or which record's data shows. Never on copy or CSS.
Required disclosures are the one exception, and the plan names them.

## When a test fails unexpectedly

- If the Red step fails with the wrong error: fix the setup, not the production
  code. The test should fail because the behavior isn't implemented yet, not
  because of a typo or missing factory.
- If the Green step breaks other tests: you've changed existing behavior. Stop,
  understand why, and decide whether the other tests need updating or your
  implementation approach is wrong.

## When to stop

- All acceptance criteria from the task are covered by tests
- You can't think of another meaningful behavior to test
- Every state a caller can produce is handled, unauthorized access included

## Rules

- Never write an entire test file up front
- Never implement more than one discrete piece of functionality per cycle
- Never write production code without a failing test demanding it, except the
  declarations listed in "Do not write"
- Run only the relevant test file during cycles, not the full suite (save that
  for the end)
