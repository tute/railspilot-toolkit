---
name: tdd-skill
description: Guides TDD implementation via strict Red-Green-Refactor cycles, one piece at a time. Use when implementing features or fixes with TDD, or whenever CLAUDE.md says to use TDD. This skill applies to ALL implementation work — features, bug fixes, refactors with behavior changes. Even "simple" changes benefit from the discipline.
---

Implement using strict test-driven development: one Red-Green-Refactor cycle at a
time. The discipline is the point — it prevents writing more code than needed and
catches design problems early.

## The cycle

1. **Red**: Write the simplest test for ONE discrete piece of functionality. Run
   it with `mise exec -- rspec <file>:<line>` and verify it fails with the
   expected error message. If it fails for the wrong reason, fix the test first.

2. **Green**: Write the minimum code to make that one test pass. Resist the urge
   to implement more than what the test demands. Run the test again to confirm it
   passes.

3. **Refactor**: With the test green, look for opportunities to clean up — both
   in the production code and the test. Remove duplication, improve naming,
   extract methods. Run the test again to verify nothing broke.

4. **Repeat**: Pick the next piece of functionality and start a new cycle.

## What counts as "one piece"

- One validation rule
- One branch of a conditional
- One association or scope
- One method on a service object
- One error/edge case
- One step in a multi-step workflow

If you're unsure whether something is one piece or two, err on the side of
smaller. You can always go faster; you can't easily undo a big untested jump.

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
- Edge cases are handled (nil inputs, empty collections, unauthorized access)

## Rules

- Never write an entire test file up front
- Never implement more than one discrete piece of functionality per cycle
- Never write production code without a failing test demanding it
- Run only the relevant spec file during cycles, not the full suite (save that
  for the end)
