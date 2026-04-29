---
name: railspilot-staff-review
description: Analyzes code against staff-engineer patterns (security, architecture, simplicity, completeness, hygiene). Use when asked for a staff or senior code review, "staff review", "pattern review", or "review this like a staff engineer". This is the most thorough single-agent review — for multi-agent reviews, use full-code-review.
argument-hint: "[<commit-sha> | last-N | <base>..<head> | (empty for branch vs main)]"
allowed-tools: Bash, Read, Edit, Write, Task, AskUserQuestion
---

Orchestration skill for comprehensive staff-engineer code reviews using RailsPilot's pattern library. Launches the `staff-engineer-reviewer` agent to evaluate code against established patterns.

## Workflow

**Step 1: Determine Review Scope**

Parse `$ARGUMENTS` to pick the diff:

- A 40-character hex string: treat as a commit SHA, review `git show <sha>`
- `last-N` or `last N commits`: review `git log -p -<N>` (or `git diff HEAD~N..HEAD`)
- A range like `<base>..<head>` or `<base>...<head>`: pass directly to `git diff`
- Empty: review current branch against the base branch. Default base is `main`; fall back to `master` if `main` does not exist via `git rev-parse --verify`

If parsing is ambiguous (e.g. a non-SHA string that is not a recognized form), confirm scope with AskUserQuestion before continuing. If the resolved diff is empty, report that and stop without dispatching the agent.

**Step 2: Launch Staff Engineer Reviewer Agent**

Use the Agent tool to launch `staff-engineer-reviewer` with:
- Git diff of the changes to review
- Patterns file path: `${SKILL_ROOT}/references/patterns.md`

The agent will:
- Load the entire patterns.md file containing all known patterns
- Analyze each changed file against applicable patterns
- Apply the "How RailsPilot Thinks" philosophy
- Return findings organized by severity/category with pattern IDs, file references, and concrete suggestions

**Step 3: Check Previous Decisions**

Before consolidating findings, check for previous reviews. The decision log lives at `tasks/code_review_decisions.md` (project root). If the file does not exist, treat the history as empty and continue. If it exists, read it and note any previously-decided concerns so the same finding is not surfaced twice.

**Step 4: Consolidate Findings**

Merge and organize the agent's findings:
- Remove duplicate concerns from the decision log
- Organize by category and severity (Critical, High, Medium, Low)
- Highlight critical issues requiring immediate attention
- Note positive observations

**Step 5: Confirm and Implement Selected Findings**

Review is read-only by default. Before any code changes happen, present the actionable findings to the user and let them choose which to apply.

1. Group actionable findings by concern (one concern = one commit). For each concern, classify the fix:
   - High confidence: mechanical fix (e.g., missing authorization check, exposed secret, missing test assertion)
   - Medium confidence: fix is clear but touches more code (e.g., extracting a service object, adding error handling)
   - Low confidence / design call: requires product or architectural input — never auto-applied

2. Use AskUserQuestion (`multiSelect: true`) to present the high/medium concerns, grouped by priority. Include a "Skip — leave all as recommendations" option. Low-confidence findings are listed in the report only, not offered as selectable options.

3. For each concern the user approves:
   - Make the code change
   - Run relevant tests to verify correctness. If tests fail, stop after the first failure, report which finding broke them, and skip remaining selected fixes — do not commit a broken state.
   - Commit by invoking the `/commit` skill (see ~/.claude/skills/commit/SKILL.md). Reference the pattern ID (e.g. `SEC-02`) in the commit title.

4. Findings the user does not select stay in the consolidated report as recommendations the developer can act on later.

If the user declines all findings, skip directly to Step 6 with no commits.

**Step 6: Update Decision Tracking**

Append (do not overwrite) to `tasks/code_review_decisions.md` at the project root. Create the file if it is missing.

Each entry uses this schema:

```markdown
## YYYY-MM-DD HH:MM — <scope reviewed: SHA, range, or "branch vs main">

- <pattern-id>: <one-line summary>
  - decision: applied | recommended | dismissed
  - commit: <sha if applied, otherwise empty>
  - rationale: <why this decision>
```

Group entries newest-on-top. Include every actionable finding from Step 4 — applied, left as recommendation, and dismissed alike — so future reviews can suppress redundancy.

## Error Handling

- Empty diff: stop after Step 1 and tell the user there is nothing to review.
- Agent returns no findings: skip Steps 5-6 and report "no actionable findings".
- Tests fail during Step 5: stop applying fixes, leave the broken-test finding in the report, do not commit, do not proceed to Step 6 for the failing concern.
- `${SKILL_ROOT}/references/patterns.md` missing: report the missing path and stop — the agent cannot operate without the library.
- `tasks/code_review_decisions.md` missing in Step 3: treat as empty history. In Step 6, create the file with a top-level header before appending the first entry.
- `/commit` skill unavailable: fall back to a direct `git commit` with a message that still references the pattern ID, and note the fallback in the decision log entry.

## Review Methodology

The `staff-engineer-reviewer` agent handles all review methodology. See that agent's documentation for:
- The "How RailsPilot Thinks" philosophy (9 core principles)
- Detailed review process (pattern matching, completeness checks, security-first approach)
- Output format and presentation standards
- How patterns are applied and referenced

## Pattern Library

All patterns are stored in `${SKILL_ROOT}/references/patterns.md` and cover:

- **General**: How RailsPilot Thinks philosophy
- **Security**: Data encryption, credential handling
- **Architecture**: Error handling, service objects
- **Simplicity**: Keeping jobs thin, avoiding unnecessary complexity
- **Completeness**: Tests, edge cases, Stimulus patterns
- **Testing**: Proper test structure, system under test protection
- **Scope & Discipline**: One concern per commit, ticket scope adherence

## Extending the Library

To add new patterns learned from future reviews:
1. Edit `${SKILL_ROOT}/references/patterns.md`
2. Add new pattern following existing format
3. Include ID, category, applies-to scope, and concrete examples
4. Each staff review is an opportunity to add patterns
