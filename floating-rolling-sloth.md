# Plan: stop the toolkit from generating low-value tests

## Context

A review of dermrx on 2026-10-21 cut 935 tests to 794 in six commits, and coverage held (99.66% to 99.47%; the 0.19 points are dead code). The cut tests came from four skills that tell the agent to test every declaration and treat more tests as more complete. The project CLAUDE.md forbids both, but the skills are procedural and they win.

| Cut in dermrx | Skill that produced it |
|---|---|
| 35 framework tests (enums, defaults, `belongs_to`, presence) | `tdd-skill` "one piece" list; `rspec-testing` enum and shoulda examples |
| 23 duplicates across layers | `task-implement` runs TDD at each layer and never checks across them |
| ~30 copy and markup tests deleted, ~40 trimmed | `tdd-skill` says nothing about where a view test turns red; `rspec-testing` shows `have_content` as good |
| 9 tests that pass against broken code | No step breaks the code to prove a test |
| Impossible-state tests | `tdd-skill` "nil inputs"; staff review COMPLETE-02 |

The goal: an agent using these skills writes tests that catch production bugs, at one layer each, and the reviewer asks for fewer tests as readily as for more.

## Where

Repo: `/home/tute/Code/railspilot/toolkit`, new branch `tc-test-value`. One commit per skill. Everything below is under `.claude/skills/`.

## Steps

### 1. `tdd-skill/SKILL.md`

- Replace the "What counts as one piece" list with: one branch of logic we wrote; one error a caller can cause; one step of a workflow; one database constraint, tested at the database.
- Add a "Do not write" section:
  - A test that is red only because a declaration is missing (`belongs_to`, `enum`, presence, a one-clause scope, a column default). Write the declaration with no test.
  - A test of a state no caller can produce, and the guard that would make it reachable.
  - A test of a branch that already has a test at another layer. Grep first.
- Red step: name the production bug the test catches. If there is none, skip the test.
- Add a view rule: a view test turns red on a status, a redirect, record state, a form action, a field name, accessibility wiring, or which record's data shows. Never on copy or CSS. Required disclosures are the one exception, and the plan names them.
- Add a layer rule: test branches in the unit. The integration test covers the wiring only: one success, one refusal, and authorization.
- Refactor step: once a test is green, break the production line it covers, see the test fail, then restore the line.
- "When to stop": replace "nil inputs, empty collections" with "every state a caller can produce".
- Change `rspec <file>:<line>` to "the project's test command", since dermrx uses Minitest.

### 2. `rspec-testing/SKILL.md`

- Delete "Testing Enums", "Using Shoulda Matchers" and the presence example in "Testing Validations".
- Add "Testing our constraints": conditional and custom validations, and `RecordNotUnique` or `StatementInvalid` against the migration, run with `update_column` or raw SQL to get past the validation.
- In "Avoid CSS Class Testing", move `have_content('Success message')` to Bad. Add `have_field`, the form action, and record state to Good.
- Add one line to "What to Avoid" that points to the "Do not write" list in `tdd-skill`.

### 3. `railspilot-staff-review/references/patterns.md`

- COMPLETE-01: "Behavior" means a branch we wrote. New detection rule: a new conditional, rescue or query in `app/` with no test that fails without it. Remove "a model validation without a model spec".
- COMPLETE-02: Remove "count the contexts" and "nil inputs, missing associations". Keep boundary values and permission failures a caller can reach.
- Add a new pattern, TEST-xx "Test that cannot fail". Signals:
  - copy or CSS assertions
  - tests of declarations or column defaults
  - a test whose name claims an order but which checks presence only
  - assertions on a fake's own return value
  - `refute_empty` or `assert_kind_of` as the only assertion
  - the same branch tested at two layers
  - a test that passes when the method under test is deleted

  The fix for each is to delete the test or rewrite it, never to add one.

### 4. `task-implement/SKILL.md`

- Add a new step 6b, "Prune tests", between TDD and the staff review:
  - List the tests the branch adds: `git diff main --stat -- test spec`, then the names of the new tests.
  - For each one, name the bug it catches and say whether another layer already catches it. Delete what fails either question.
  - Break the code for any test whose value is unclear.
- Step 12: the PR body states the change in test count.

## Verification

- Run `claude plugin eval` if the toolkit has an eval suite for these skills. Otherwise do a dry run: in a scratch worktree of dermrx at `b132068`, give `tdd-skill` one small backlog item. Check that it writes no enum, default or copy tests and no duplicate integration test.
- Read the four diffs together for contradictions: `rspec-testing` and the staff review must not ask for anything `tdd-skill` forbids.

## Out of scope

- The dermrx tests themselves. That cleanup is done.
- Other skills that mention tests in passing (`code-review`, `simplify`). Revisit if the dry run still produces cut-worthy tests.

## Assumption

`rspec-testing` is RSpec-only, but dermrx uses Minitest. The test-value rules live in `tdd-skill` because it is framework-neutral, and `rspec-testing` points to them.
