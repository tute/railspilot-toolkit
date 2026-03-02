---
name: task-implement
description: Implements a Linear or Jira issue end-to-end: branch, TDD, code reviews. Auto-detects task manager from recent commits. Use when given an issue ID (e.g., TRA-9, PROJ-456) and asked to implement it.
disable-model-invocation: true
---

# Issue Implementation (Linear / Jira)

## Overview

This skill provides a comprehensive workflow for implementing issues from **Linear** or **Jira** with professional software engineering practices. It automates the entire development lifecycle from issue analysis through PR title and description delivery, ensuring quality through test-driven development, parallel code reviews, and systematic validation.

**The skill automatically detects which task manager to use** by examining recent commit messages on the master branch for Linear or Jira URLs.

## Core Workflow

The skill follows a 17-step process:

1. **Detect Task Manager** - Examine recent commits on master to identify Linear or Jira
2. **Fetch Issue** - Retrieve complete issue details via appropriate MCP/API
3. **Gather Additional Context** - Search Obsidian, Sentry, and GitHub for related information
4. **Move to In Progress** - Update issue status to indicate active work
5. **Create Feature Branch** - Use task manager's branch naming convention
6. **Analyze & Plan** - Break down requirements and create implementation plan
7. **Save to Memory** - Store plan in memory graph for tracking
8. **Review Plan** - Present plan for user confirmation
9. **TDD Implementation** - Invoke `tdd-skill` skill for test-driven development
10. **Code Simplification** - Invoke `simplify` skill to review for reuse, quality, and efficiency
11. **Full Code Review** - Invoke `full-code-review` skill (security + Rails best practices)
12. **Address Code Review Feedback** - Fix high priority issues from simplify and full code review. Ask for confirmation for lower priority ones
13. **Staff Engineer Review** - Invoke `railspilot-staff-review` skill (final validation on clean code)
14. **Address Staff Review Feedback** - Fix high priority issues from staff engineer review. Ask for confirmation for lower priority ones
15. **Validation & Linting** - Ensure all tests and linters pass on the new changes
16. **Create PR title and description** - Invoke `pr-title-and-description` skill
17. **Completion Summary** - Present PR title and description wich a checklist of all completed steps

## Workflow Implementation Details

### Step 1: Detect Task Manager

Before fetching the issue, detect which task manager (Linear or Jira) the project uses by examining recent commit messages on the master branch.

**Detection Command:**
```bash
git log master --oneline -20 --grep="linear.app\|atlassian.net" --all-match 2>/dev/null || git log master --oneline -20
```

**Detection Logic:**
1. Search recent commits on master for task manager URLs
2. Look for patterns:
   - **Linear**: `linear.app` URLs (e.g., `https://linear.app/company/issue/TRA-142`)
   - **Jira**: `atlassian.net` URLs (e.g., `https://company.atlassian.net/browse/PROJ-123`)
3. The first match determines the task manager for this project
4. If no URLs found, ask the user which task manager to use

**Example Detection:**
```bash
# Check for Linear URLs
git log master --oneline -20 | grep -i "linear.app" | head -1

# Check for Jira URLs
git log master --oneline -20 | grep -i "atlassian.net" | head -1
```

**Store Result:**
After detection, store the task manager type for use throughout the workflow:
- `TASK_MANAGER=linear` or `TASK_MANAGER=jira`
- Extract domain for Jira (e.g., `company.atlassian.net`)

### Step 2: Fetch Issue Details

Retrieve the complete issue using the detected task manager's API.

| | Linear | Jira |
|---|---|---|
| **API call** | `mcp__linear__get_issue(id: <issue-id>)` | `mcp__jira__jira_get(path: "/rest/api/3/issue/<issue-key>")` |
| **Title** | `title` | `fields.summary` |
| **Branch hint** | `branchName` field | Derive: `<initials>/<issue-key>-<slugified-summary>` |

Extract key information:
- Title/summary and description
- Current status and priority
- Branch naming hint (see table above)
- Team/sprint and project context
- Issue type (Jira: Story, Bug, Task, etc.)
- Attachments, linked issues, or related work
- Labels, components, and assigned team members

### Step 3: Gather Additional Context

Before planning, gather related context from multiple sources to inform the implementation approach.

#### Search Obsidian Vault

Search for any existing notes that might be related to this issue:

```
# Search by issue ID
Search Obsidian vault for: "TRA-142"

# Search by issue summary/keywords
Search Obsidian vault for: "<keywords from issue title/description>"
```

Look for:
- Previous meeting notes discussing this feature
- Architecture decisions or technical notes
- Related implementation notes from similar work
- User research or requirements documentation

#### Fetch Sentry Context (if referenced)

If the Linear issue references any Sentry issues or error tracking:

```
mcp__sentry__get_issue(issue_id: <sentry-issue-id>)
```

Extract from Sentry:
- Error stack traces and frequency
- Affected users and environments
- Related events and breadcrumbs
- Any existing comments or assignments

This context helps understand:
- The root cause of bugs
- Which code paths are affected
- How frequently the issue occurs
- Environmental factors to consider

#### Fetch GitHub Context (if referenced)

If the Linear issue references GitHub pull requests, issues, or discussions:

```bash
# View PR details and discussion
gh pr view <pr-number>

# View PR comments and review threads
gh pr view <pr-number> --comments

# View issue details
gh issue view <issue-number>

# View issue comments
gh issue view <issue-number> --comments
```

Extract from GitHub:
- Previous implementation attempts
- Review feedback and concerns raised
- Design discussions and decisions
- Related code changes or context

**Context Summary:**

After gathering context, summarize:
- Relevant information found in Obsidian
- Sentry error details (if applicable)
- GitHub discussion insights (if applicable)
- How this context affects the implementation approach

### Step 4: Move Issue to In Progress

Update the issue status to reflect active development. This provides visibility to team members that work has begun.

**Linear:**
1. Get team ID from issue → `mcp__linear__list_issue_statuses(team: <team-id>)` → `mcp__linear__update_issue(id: <issue-id>, state: <in-progress-state-id>)`

**Jira:**
1. `mcp__jira__jira_get(path: "/rest/api/3/issue/<issue-key>/transitions")` → find "In Progress" transition → `mcp__jira__jira_post(path: "/rest/api/3/issue/<issue-key>/transitions", body: {"transition":{"id":"<id>"}})`

### Step 5: Create Feature Branch

Create a git branch using the task manager's naming convention.

**Branch name source:**
- **Linear**: Use `branchName` field from the issue (e.g., `dg/tra-142-user-notification-service`)
- **Jira**: Derive as `<initials>/<issue-key>-<slugified-summary>` (e.g., `jd/PROJ-142-user-notification-service`)

```bash
git checkout main
git pull origin main
BRANCH_NAME="<branch name from above>"
git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"
git branch --show-current
```

This pattern ensures idempotent operations (reuses existing branches) and always starts from latest main.

### Step 6: Analyze and Plan Solution

Break down the issue into an actionable implementation plan:

**Analysis Process:**
1. Extract specific requirements from issue description
2. Identify affected components and systems
3. Determine testing strategy (unit → integration → system)
4. Plan implementation approach following project patterns
5. Identify potential risks and dependencies

**Planning Output:**
- **Goal**: Clear statement of implementation objective
- **Requirements**: Specific functional and technical requirements
- **Architecture**: How solution fits existing codebase (models, services, controllers)
- **Test Strategy**: Comprehensive testing including system specs
- **Implementation Steps**: Ordered list of development tasks
- **Acceptance Criteria**: Definition of done

### Step 7: Save Plan to Memory

Store the implementation plan using memory MCP tools:

```
mcp__memory__create_entities(entities: [
  {
    name: "Issue <issue-id>",
    entityType: "implementation-plan",
    observations: [
      "Task Manager: <linear|jira>",
      "Requirements: <requirements>",
      "Architecture: <architecture-decisions>",
      "Test Strategy: <test-approach>",
      "Status: planning-complete"
    ]
  }
])
```

This creates permanent tracking of:
- Issue context and requirements
- Implementation approach and reasoning
- Progress throughout development
- Lessons learned for future work

### Step 8: Review Plan with User

Present the complete plan for confirmation:

**Plan Presentation:**
- Summary of what will be implemented
- Key technical decisions and rationale
- Testing strategy and expected coverage
- Estimated complexity and identified risks
- Explicit confirmation request

**User Options:**
- Approve to proceed with implementation
- Request modifications to approach
- Add requirements or constraints
- Ask clarifying questions

### Step 9: TDD Implementation

### Step 10: Code Simplification

### Step 11: Full Code Review

After code simplification, invoke the full code review skill:

```
Invoke the Skill tool with: full-code-review
```

**full-code-review** launches specialized review subagents in parallel:

**Security Review (rails-security-reviewer):**

**Rails Best Practices Review (rails-best-practices-reviewer):**

-**Frontend Review (if applicable):**
-- ViewComponent best practices
-- Tailwind CSS conventions
-- StimulusJS patterns
-- Accessibility (ARIA attributes)

**Output:**
- Consolidated security and Rails best practices findings
- Decision tracking to prevent redundancy
- Prioritized feedback by severity and impact

### Step 12: Address Code Review Feedback

Before the staff engineer review, address all findings from simplify and full code review so the staff review sees clean code:

**Process:**
1. Review any feedback from simplify that couldn't be auto-fixed
2. Parse and prioritize feedback from full-code-review
3. Implement fixes incrementally with test validation
4. Ensure backward compatibility

**Architectural Feedback is MANDATORY:**
- Extract service objects if controllers/models have too many responsibilities
- Apply Result pattern for operations that can fail
- Refactor to improve testability and maintainability
- Add comprehensive specs for new service objects

**Note:** Do NOT proceed to staff review until all code review feedback is addressed.

### Step 13: Staff Engineer Review

After all code review findings are resolved, invoke the staff engineer review skill on clean code:

```
Invoke the Skill tool with: railspilot-staff-review
```

**railspilot-staff-review** launches the staff-engineer-reviewer agent to analyze code against the RailsPilot pattern library:

- Security considerations and vulnerability detection
- Architecture decisions and design patterns
- Code simplicity and maintainability
- Completeness of implementation
- Code hygiene and consistency
- Robustness and error handling
- Test coverage and quality

The agent loads all patterns from `.claude/skills/railspilot-staff-review/patterns.md` and applies the "How RailsPilot Thinks" philosophy.

**Output:**
- Pattern-based findings organized by severity
- Pattern IDs for reference and learning
- Concrete code suggestions with examples

**Note:** Staff review runs LAST as the final validation gate. It reviews code that has already been simplified and had all senior-level findings resolved, so it can focus on architecture, patterns, and strategic concerns.

### Step 14: Address Staff Review Feedback

Address findings from the staff engineer review:

**Process:**
1. Parse and prioritize staff review findings by severity
2. Implement fixes incrementally with test validation
3. Ensure backward compatibility
4. Update documentation as needed

**Note:** Do NOT create PR until all staff review feedback is addressed.

### Step 15: Validation and Quality Assurance

Before creating commits, ensure everything passes:

**Validation Steps:**
```bash
# Run full test suite
bundle exec rspec

# Run linting (Standard, ERB, Brakeman)
bin/lint

# Fix any failures or warnings
# Verify system specs pass in clean environment
```

**Quality Checks:**
- Code follows project POODR principles
- Result pattern used appropriately
- No security vulnerabilities
- Performance impact considered (no N+1 queries)
- All subagent feedback addressed
- Test coverage sufficient

**Linting Notes:**
- Yarn failures can be ignored if only working on Rails code
- Warnings about `MigratedSchemaVersion` and `ContextCreatingMethods` are harmless
- **Actual offenses must be addressed** (look for file paths and line numbers)

**Commit Message Format:**

```
[Jira only: <ISSUE-KEY> ]Present-tense summary under 50 characters

- Detailed explanation if needed (under 72 chars per line)
- Reference which review feedback was addressed
- Note any breaking changes or migration requirements

Linear issue: <Linear issue URL>  OR  Jira issue: <Jira issue URL>
Implemented with Claude Code
```

**Differences:** Jira prefixes the subject with the issue key (e.g., `PROJ-142 Add user notification service`). Linear does not prefix.

### Step 16: Create PR title and description

Invoke the `pr-title-and-description` skill.

### Step 17: Completion Summary

Present checklist to user:
- Issue analyzed and planned
- Solution implemented with TDD
- Comprehensive system specs added
- Code simplification completed (simplify)
- Security and Rails review completed (full-code-review)
- Code review feedback addressed
- Staff engineer review completed (railspilot-staff-review) — final validation
- Staff review feedback addressed
- All tests and linting pass
- Logical commit history created
- PR created with task manager integration

## Integration with Other Skills

This skill orchestrates multiple specialized skills in a specific sequence:

**tdd-skill (Step 9):**
- Enforces Red-Green-Refactor cycles
- Ensures test-first development
- Guides test pyramid strategy

**commit (Steps 9 through 15):**
- Commit the changes
- Ensure meaningful commit history

**simplify (Step 11) + full-code-review (Step 12) → Address findings (Step 13):**
- Simplify auto-fixes code reuse, quality, and efficiency issues
- Full code review runs security and Rails reviews concurrently
- All findings from both are addressed before staff review sees the code

**railspilot-staff-review (Step 14) → Address findings (Step 15):**
- Launches staff-engineer-reviewer agent on already-clean code
- Focuses on architecture, patterns, and strategic concerns
- Runs as the final validation gate

## Project-Specific Conventions

This skill adheres to project guidelines from `CLAUDE.md`:

**Rails Patterns:**
- Service objects for business logic
- Result pattern for operations that can fail
- POODR principles (SRP, Tell Don't Ask, Law of Demeter)

**Multi-Tenant Security:**
- ActsAsTenant automatic scoping
- Tenant isolation verification
- No need for explicit tenant scoping in queries

**Testing:**
- RSpec with shoulda-matchers
- System specs for user workflows
- Avoid stubbing the system under test
- Use backdoor middleware for auth in request specs

**Code Style:**
- i18n for all user-facing text
- Timestamp columns instead of booleans
- Postgres enums for static values
- `ENV.fetch` for required environment variables

## Requirements

**Task Manager Integration (one of):**

**Linear MCP:**
- Linear MCP server must be configured and available
- Required tools: `mcp__linear__get_issue`, `mcp__linear__update_issue`, `mcp__linear__list_issue_statuses`

**Jira MCP or REST API:**
- Jira MCP server configured, OR
- Environment variables for REST API fallback:
  - `JIRA_EMAIL`: Your Atlassian account email
  - `JIRA_API_TOKEN`: API token from https://id.atlassian.com/manage-profile/security/api-tokens
  - `JIRA_DOMAIN`: Your Jira domain (e.g., `company.atlassian.net`)

**Git Repository:**
- Current directory must be a git repository
- `main` or `master` branch exists and is up-to-date
- Git configured with user credentials

**Testing and Linting:**
- `bundle exec rspec` available for testing
- `bin/lint` script available for linting
- Ruby/Rails development environment configured

**GitHub CLI:**
- `gh` CLI tool installed and authenticated

**Skills:**
- `tdd-skill` skill available
- `full-code-review` skill available
- `railspilot-staff-review` skill available
- `simplify` skill available
- `pr-title-and-description` skill available

## Error Handling

**Common Issues and Solutions:**

**Task Manager Not Detected:**
- Ensure recent commits on master contain task manager URLs
- If no URLs found, the skill will ask which task manager to use
- You can also specify explicitly: "Implement TRA-142 (Linear)" or "Implement PROJ-123 (Jira)"

**Issue Not Found:**
- Verify issue ID format is uppercase (e.g., `TRA-9` not `tra-9`, `PROJ-123` not `proj-123`)
- Confirm MCP integration is working (Linear MCP or Jira MCP)
- Check user has access to the team/project/issue

**Status Transition Not Available (Jira):**
- List available transitions for current issue status
- Some transitions require specific conditions (e.g., all subtasks complete)
- Contact Jira admin if workflow is blocking

**Branch Already Exists:**
- Expected behavior - workflow checks out existing branch
- Ensures work can be resumed safely
- Verifies branch is synced with remote

**Tests or Linting Fail:**
- Review failures and fix before creating PR
- Common linting issues: StandardRB, ERB Lint, Brakeman
- Never use `standardrb --fix` blindly - review changes

**Code Review Identifies Issues:**
- MUST address architectural feedback before PR
- Extract service objects as recommended
- Apply Result pattern where suggested

## Example Workflow

**User Request:** `Implement TRA-142` (Linear) or `Implement PROJ-456` (Jira)

**Skill Response:**
1. **Detect Task Manager** — finds `linear.app` or `atlassian.net` URLs in recent commits on master
2. **Fetch Issue** — retrieves issue details using detected task manager's API
3. **Gather Additional Context** — searches Obsidian vault, Sentry (if referenced), GitHub PRs (if referenced)
4. **Move to In Progress** — transitions issue status
5. **Create Feature Branch** — e.g., Linear: `dg/tra-142-...` from `branchName` / Jira: `jd/PROJ-456-...` derived
6. **Analyze & Plan** — breaks down requirements, creates implementation plan informed by gathered context
7. **Save to Memory** — stores plan in memory graph
8. **Review Plan** — presents plan for approval. **Waits for user confirmation.**
9. **TDD Implementation** — invokes `tdd-skill` skill
10. **Code Simplification** — invokes `simplify` skill, applies fixes
11. **Full Code Review** — invokes `full-code-review` skill (security + Rails best practices)
12. **Address Code Review Feedback** — fixes high priority issues, asks for confirmation on lower priority ones
13. **Staff Engineer Review** — invokes `railspilot-staff-review` skill (final validation on clean code)
14. **Address Staff Review Feedback** — fixes high priority issues, asks for confirmation on lower priority ones
15. **Validation & Linting** — runs `bundle exec rspec`, `bin/lint`, fixes any failures
16. **Create PR title and description** — invokes `pr-title-and-description` skill
17. **Completion Summary** — presents PR title and description with a checklist of all completed steps

**Final Output:**
- Working feature branch with complete implementation
- All tests passing
- All linting passing

## Best Practices

**Planning Phase:**
- Take time to understand requirements fully
- Identify edge cases and error conditions
- Consider multi-tenant implications
- Plan for comprehensive system specs

**Implementation Phase:**
- Follow TDD strictly - tests before code
- Keep commits small and logical
- Write self-documenting code
- Use i18n for all user-facing text

**Review Phase:**
- Address ALL architectural feedback
- Don't skip recommended refactoring
- Validate fixes with tests
- Consider performance implications
