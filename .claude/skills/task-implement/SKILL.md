---
name: task-implement
description: Implements a Linear or Jira issue end-to-end: branch, TDD, parallel code reviews, PR. Auto-detects task manager from recent commits. Use when given an issue ID (e.g., TRA-9, PROJ-456) and asked to implement it.
disable-model-invocation: true
---

# Issue Implementation (Linear / Jira)

## Overview

This skill provides a comprehensive workflow for implementing issues from **Linear** or **Jira** with professional software engineering practices. It automates the entire development lifecycle from issue analysis through PR creation, ensuring quality through test-driven development, parallel code reviews, and systematic validation.

**The skill automatically detects which task manager to use** by examining recent commit messages on the master branch for Linear or Jira URLs.

## When to Use This Skill

Use this skill when:
- User provides an issue ID (format: `TRA-9`, `DEV-123`, `PROJ-456`, etc.)
- User requests implementation of a Linear or Jira issue
- User wants a structured TDD approach with code review
- User needs automated workflow from issue to PR

Examples:
- "Implement TRA-142"
- "Help me build the feature in DEV-89"
- "Work on issue PROJ-456"

## Core Workflow

The skill follows a 15-step process:

1. **Detect Task Manager** - Examine recent commits on master to identify Linear or Jira
2. **Fetch Issue** - Retrieve complete issue details via appropriate MCP/API
3. **Gather Additional Context** - Search Obsidian, Sentry, and GitHub for related information
4. **Move to In Progress** - Update issue status to indicate active work
5. **Create Feature Branch** - Use task manager's branch naming convention
6. **Analyze & Plan** - Break down requirements and create implementation plan
7. **Save to Memory** - Store plan in memory graph for tracking
8. **Review Plan** - Present plan for user confirmation
9. **TDD Implementation** - Invoke `tdd-skill` skill for test-driven development
10. **Parallel Code Reviews** - Invoke `full-code-review` skill for comprehensive analysis
11. **Address Feedback** - Systematically fix issues from code reviews
12. **Validation** - Ensure all tests and linters pass
13. **Logical Commits** - Create meaningful commit history
14. **Create PR** - Generate comprehensive pull request with task manager linking
15. **Final Verification** - Confirm CI/CD pipeline and task manager integration

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

#### If Linear:
```
mcp__linear__get_issue(id: <issue-id>)
```

Extract key information:
- Title and description
- Current status and priority
- Suggested git branch name (`branchName` field)
- Team and project context
- Attachments or related work
- Labels and assigned team members

#### If Jira:
```
mcp__jira__get_issue(issue_key: <issue-key>)
```

Or via REST API:
```bash
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  "https://$JIRA_DOMAIN/rest/api/3/issue/<issue-key>"
```

Extract key information:
- Summary and description
- Current status and priority
- Issue type (Story, Bug, Task, etc.)
- Sprint and project context
- Attachments or linked issues
- Labels, components, and assignee

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

Update the issue status to reflect active development.

#### If Linear:
1. Identify the team ID from the issue
2. Retrieve "In Progress" state using `mcp__linear__list_issue_statuses(team: <team-id>)`
3. Update issue using `mcp__linear__update_issue(id: <issue-id>, state: <in-progress-state-id>)`

#### If Jira:
1. List available transitions: `mcp__jira__get_transitions(issue_key: <issue-key>)`
2. Find the "In Progress" transition ID
3. Transition issue: `mcp__jira__transition_issue(issue_key: <issue-key>, transition_id: <id>)`

Or via REST API:
```bash
# Get available transitions
curl -s -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  "https://$JIRA_DOMAIN/rest/api/3/issue/<issue-key>/transitions"

# Execute transition
curl -s -X POST -u "$JIRA_EMAIL:$JIRA_API_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"transition":{"id":"<transition-id>"}}' \
  "https://$JIRA_DOMAIN/rest/api/3/issue/<issue-key>/transitions"
```

This provides visibility to team members that work has begun.

### Step 5: Create Feature Branch

Create a git branch using the task manager's naming convention.

#### If Linear:
Use Linear's suggested branch name from the `branchName` field:
```bash
# Ensure on main and up-to-date
git checkout main
git pull origin main

# Get branch name from Linear's branchName field
BRANCH_NAME="<from Linear branchName field>"

# Create branch if new, or checkout if exists (idempotent)
git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"

# Verify correct branch
git branch --show-current
```

#### If Jira:
Create branch with Jira naming convention:
```bash
# Ensure on main and up-to-date
git checkout main
git pull origin main

# Create branch with Jira naming: <initials>/<issue-key>-<slugified-summary>
BRANCH_NAME="<initials>/<issue-key>-<slugified-summary>"

# Create branch if new, or checkout if exists (idempotent)
git checkout -b "$BRANCH_NAME" 2>/dev/null || git checkout "$BRANCH_NAME"

# Verify correct branch
git branch --show-current
```

**Branch Naming Examples:**
- Linear: `dg/tra-142-user-notification-service`
- Jira: `jd/PROJ-142-user-notification-service`

This pattern ensures:
- Reuse of existing branches
- Consistent task manager-linked naming
- Idempotent operations (safe to re-run)
- Always working from latest main

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

### Step 9: Test-Driven Development Implementation

Upon approval, invoke the TDD workflow skill:

```
Invoke the Skill tool with: tdd-skill
```

The TDD workflow skill enforces:
- Red-Green-Refactor cycles
- Test pyramid strategy (unit → integration → system)
- Writing tests before implementation
- Comprehensive test coverage including system specs

**Expected Outcomes:**
- Complete test coverage for new functionality
- Implementation following project POODR principles
- Result pattern for operations that can fail
- Clean, maintainable code structure

### Step 10: Parallel Subagent Code Reviews

After implementation, invoke the parallel code review skill:

```
Invoke the Skill tool with: full-code-review
```

This launches specialized review subagents in parallel:

**Security Review:**
- OWASP Top 10 vulnerabilities
- Multi-tenant security (ActsAsTenant verification)
- XSS, CSRF, SQL injection prevention
- Authentication and authorization checks
- Sensitive data handling

**Rails Best Practices Review:**
- POODR principles (SRP, dependency management, Tell Don't Ask)
- Rails 7+ conventions
- N+1 query prevention
- ActiveRecord optimization
- Service object patterns
- Result pattern usage

**Frontend Review (if applicable):**
- ViewComponent best practices
- Tailwind CSS conventions
- StimulusJS patterns
- Accessibility (ARIA attributes)

**Output:**
- Consolidated review report
- Decision tracking to prevent redundancy
- Prioritized feedback by severity and impact

### Step 11: Address Review Feedback

Systematically address feedback from the code reviews:

**Process:**
1. Parse and prioritize feedback by impact and effort
2. Identify common refactoring patterns
3. Implement fixes incrementally with test validation
4. Ensure backward compatibility
5. Update documentation as needed

**Architectural Feedback is MANDATORY:**
- Extract service objects if controllers/models have too many responsibilities
- Apply Result pattern for operations that can fail
- Refactor to improve testability and maintainability
- Add comprehensive specs for new service objects

**Note:** Do NOT create PR until all architectural feedback is implemented.

### Step 12: Validation and Quality Assurance

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

### Step 13: Create Logical Commits

Create meaningful commits that tell the implementation story:

**Commit Strategy:**
1. **Test commits**: Add failing tests for new functionality
2. **Implementation commits**: Add code to make tests pass
3. **Refactor commits**: Improve code structure
4. **Security fixes**: Address security review feedback
5. **Pattern improvements**: Implement OOP/Rails pattern suggestions
6. **Documentation commits**: Update docs if needed

**Commit Message Format:**

#### If Linear:
```
Present-tense summary under 50 characters

- Detailed explanation if needed (under 72 chars per line)
- Reference which review feedback was addressed
- Note any breaking changes or migration requirements

Linear issue: <Linear issue URL>
Implemented with Claude Code
```

#### If Jira:
```
<ISSUE-KEY> Present-tense summary under 50 characters

- Detailed explanation if needed (under 72 chars per line)
- Reference which review feedback was addressed
- Note any breaking changes or migration requirements

Jira issue: <Jira issue URL>
Implemented with Claude Code
```

**Use heredoc for proper formatting:**

#### Linear Example:
```bash
git commit -m "$(cat <<'EOF'
Add user notification service

- Extract notification logic from controller
- Apply Result pattern for error handling
- Add comprehensive RSpec tests with edge cases

Linear issue: https://linear.app/company/issue/TRA-142
Implemented with Claude Code
EOF
)"
```

#### Jira Example (Smart Commits):
```bash
git commit -m "$(cat <<'EOF'
PROJ-142 Add user notification service

- Extract notification logic from controller
- Apply Result pattern for error handling
- Add comprehensive RSpec tests with edge cases

Jira issue: https://company.atlassian.net/browse/PROJ-142
Implemented with Claude Code
EOF
)"
```

### Step 14: Create Pull Request

Generate comprehensive PR with task manager integration.

#### If Linear:
**PR Creation Command:**
```bash
gh pr create --title "<concise-title>" --body "$(cat <<'EOF'
## Summary
- Concise bullet points of what was implemented
- Key technical decisions made

## Implementation Details
- Architecture approach and patterns used
- Services/models/controllers added or modified
- Database changes (if applicable)

## Testing Strategy
- Test coverage added (unit, integration, system)
- Edge cases covered
- Manual testing performed

## Code Review Process
- Security review findings and resolutions
- Rails best practices review findings and resolutions
- Performance considerations addressed

## Breaking Changes
[None or list any breaking changes]

## Linear Issue
Closes <Linear issue URL>

---
Implemented with Claude Code following TDD methodology with parallel code reviews.
EOF
)"
```

**Linear Integration:**
- Include `Closes <Linear-issue-URL>` in PR body
- Linear automatically links and updates issue status when PR merges

#### If Jira:
**PR Creation Command:**
```bash
gh pr create --title "<ISSUE-KEY>: <concise-title>" --body "$(cat <<'EOF'
## Summary
- Concise bullet points of what was implemented
- Key technical decisions made

## Implementation Details
- Architecture approach and patterns used
- Services/models/controllers added or modified
- Database changes (if applicable)

## Testing Strategy
- Test coverage added (unit, integration, system)
- Edge cases covered
- Manual testing performed

## Code Review Process
- Security review findings and resolutions
- Rails best practices review findings and resolutions
- Performance considerations addressed

## Breaking Changes
[None or list any breaking changes]

## Jira Issue
Closes [<ISSUE-KEY>](<Jira issue URL>)

---
Implemented with Claude Code following TDD methodology with parallel code reviews.
EOF
)"
```

**Jira Integration:**
- Include issue key in PR title (e.g., `PROJ-142: Add user notification service`)
- Include issue link in PR body
- Jira automatically links PR when issue key is mentioned
- Issue may auto-transition when PR merges (depends on Jira configuration)

**PR Description Includes:**
- Summary of implementation
- Technical approach and key decisions
- Testing strategy and coverage
- Code review findings and resolutions
- Security considerations addressed
- Breaking changes or migration notes
- Screenshots/demos if applicable

### Step 15: Final Verification

Verify PR setup and completion:

**Final Checks:**
- CI/CD pipeline triggered successfully
- Task manager issue linked and updated
- All tests passing in CI environment
- Code review assignees notified
- Branch protection rules satisfied
- Security and pattern reviews documented

**Completion Summary:**
Present checklist to user:
- Issue analyzed and planned
- Solution implemented with TDD
- Comprehensive system specs added
- Security review completed
- Rails/OOP patterns review completed
- All review feedback addressed
- All tests and linting pass
- Logical commit history created
- PR created with task manager integration

## Integration with Other Skills

This skill orchestrates multiple specialized skills:

**tdd-skill:**
- Enforces Red-Green-Refactor cycles
- Ensures test-first development
- Guides test pyramid strategy

**full-code-review:**
- Runs security and Rails reviews concurrently
- Consolidates findings to avoid redundancy
- Provides prioritized feedback

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
- Repository configured for PR creation

**Skills:**
- `tdd-skill` skill available
- `full-code-review` skill available

## Error Handling

**Common Issues and Solutions:**

**Task Manager Not Detected:**
- Ensure recent commits on master contain task manager URLs
- If no URLs found, the skill will ask which task manager to use
- You can also specify explicitly: "Implement TRA-142 (Linear)" or "Implement PROJ-123 (Jira)"

**Linear Issue Not Found:**
- Verify issue ID format (e.g., `TRA-9`, not `tra-9`)
- Confirm Linear MCP integration is working
- Check user has access to the team/issue

**Jira Issue Not Found:**
- Verify issue key format (e.g., `PROJ-123`, not `proj-123`)
- Confirm Jira MCP or REST API credentials are configured
- Check user has access to the project/issue

**Jira Transition Not Available:**
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
- Only create PR after all feedback implemented

## Example Workflow

**User Request:**
```
Implement TRA-142
```

**Skill Response:**
1. Detects task manager from recent commits on master (finds `linear.app` URLs)
2. Fetches TRA-142 from Linear
3. Gathers additional context:
   - Searches Obsidian vault for "TRA-142" and related keywords
   - Fetches Sentry issue details (if referenced)
   - Retrieves GitHub PR discussions (if referenced)
4. Updates issue to "In Progress"
5. Creates branch `dg/tra-142-user-notification-service` (Linear's suggested name)
6. Analyzes requirements and creates plan (informed by gathered context)
7. Saves plan to memory graph
8. Presents plan: "This will create a new service object for user notifications using the Result pattern..."
9. **Waits for user approval**
10. Upon approval, invokes `tdd-skill` skill
11. After implementation, invokes `full-code-review` skill
12. Reviews identify: "Extract notification logic to service object, apply Result pattern"
13. Addresses feedback from code reviews
14. Runs validation: `bundle exec rspec`, `bin/lint`
15. Creates logical commits with proper messages
16. Creates PR with comprehensive description and Linear linking
17. Presents completion checklist

**Jira Example:**
```
Implement PROJ-456
```

**Skill Response:**
1. Detects task manager from recent commits on master (finds `atlassian.net` URLs)
2. Fetches PROJ-456 from Jira
3. Gathers additional context (Obsidian, Sentry, GitHub)
4. Transitions issue to "In Progress"
5. Creates branch `jd/PROJ-456-user-notification-service`
6. Analyzes requirements and creates plan
7. Saves plan to memory graph
8. Presents plan for approval
9. **Waits for user approval**
10. Implements with TDD, runs code reviews, addresses feedback
11. Runs validation
12. Creates logical commits with Jira smart commit format
13. Creates PR with `PROJ-456:` in title and Jira link in body
14. Presents completion checklist

**Final Output:**
- Working feature branch with complete implementation
- All tests passing
- All linting passing
- Comprehensive PR with task manager integration
- Issue automatically updated when PR merges

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

**PR Creation:**
- Write comprehensive descriptions
- Document review findings and resolutions
- Include manual testing notes
- Ensure task manager linking is correct (Linear URL or Jira issue key)

**Quality Gates:**
- Never create PR with failing tests
- Never create PR with linting errors
- Never create PR without addressing architectural feedback
- Never skip validation steps
