---
name: railspilot-staff-review
description: Analyzes code against staff-engineer patterns (security, architecture, simplicity, completeness, hygiene). Use when asked for a staff or senior code review, "staff review", "pattern review", or "review this like a staff engineer". This is the most thorough single-agent review — for multi-agent reviews, use full-code-review.
---

Orchestration skill for comprehensive staff-engineer code reviews using RailsPilot's pattern library. Launches the `staff-engineer-reviewer` agent to evaluate code against established patterns.

## Workflow

**Step 1: Determine Review Scope**

Identify what to review:
- If user provides a commit SHA or 'last N commits', review that diff
- Otherwise, review current branch changes against the base branch (main)

**Step 2: Launch Staff Engineer Reviewer Agent**

Use the Agent tool to launch `staff-engineer-reviewer` with:
- Git diff of the changes to review
- Patterns file path: `.claude/skills/railspilot-staff-review/patterns.md`

The agent will:
- Load the entire patterns.md file containing all known patterns
- Analyze each changed file against applicable patterns
- Apply the "How RailsPilot Thinks" philosophy
- Return findings organized by severity/category with pattern IDs, file references, and concrete suggestions

**Step 3: Check Previous Decisions**

Before consolidating findings, check for previous reviews:
- Read decision log file (if exists): `code_review_decisions.md`
- Note any previously-decided concerns to avoid redundancy

**Step 4: Consolidate Findings**

Merge and organize the agent's findings:
- Remove duplicate concerns from the decision log
- Organize by category and severity (Critical, High, Medium, Low)
- Highlight critical issues requiring immediate attention
- Note positive observations

**Step 5: Update Decision Tracking**

For decisions made during the review:
- Update `code_review_decisions.md` with audit trail
- Include rationale and context

## Review Methodology

The `staff-engineer-reviewer` agent handles all review methodology. See that agent's documentation for:
- The "How RailsPilot Thinks" philosophy (9 core principles)
- Detailed review process (pattern matching, completeness checks, security-first approach)
- Output format and presentation standards
- How patterns are applied and referenced

## Pattern Library

All patterns are stored in `.claude/skills/railspilot-staff-review/patterns.md` and cover:

- **General**: How RailsPilot Thinks philosophy
- **Security**: Data encryption, credential handling
- **Architecture**: Error handling, service objects
- **Simplicity**: Keeping jobs thin, avoiding unnecessary complexity
- **Completeness**: Tests, edge cases, Stimulus patterns
- **Testing**: Proper test structure, system under test protection
- **Scope & Discipline**: One concern per commit, ticket scope adherence

## Extending the Library

To add new patterns learned from future reviews:
1. Edit `.claude/skills/railspilot-staff-review/patterns.md`
2. Add new pattern following existing format
3. Include ID, category, applies-to scope, and concrete examples
4. Each staff review is an opportunity to add patterns
