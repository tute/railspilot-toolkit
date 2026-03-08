# Issue Implementation Skill (Linear / Jira)

A Claude Code skill for implementing Linear or Jira issues with a complete TDD workflow, automated planning, parallel code reviews, and PR creation with task manager integration.

**Auto-detects task manager** by examining recent commits on master for Linear or Jira URLs.

## Quick Start

This skill automates the entire development lifecycle from issue to merged PR. Invoke the skill:

```
Implement TRA-142
Implement PROJ-456
/implement https://your-site.atlassian.net/browse/PROJ-123-613
```

Claude will auto-detect whether the project uses Linear or Jira, fetch the issue, gather context from Obsidian/Sentry/GitHub, create a branch, plan the implementation, write tests first, implement the feature, run parallel code reviews, address feedback, and create a comprehensive PR.

## What It Does

The skill orchestrates a 15-step professional software engineering workflow:

1. **Detect Task Manager** - Examines recent commits on master to identify Linear or Jira
2. **Fetch Issue** - Retrieves complete issue details via Linear MCP or `acli` CLI
3. **Gather Additional Context** - Searches Obsidian, Sentry, and GitHub for related information
4. **Move to In Progress** - Updates issue status for team visibility
5. **Create Feature Branch** - Uses task manager's branch naming convention
6. **Analyze & Plan** - Creates detailed implementation plan informed by gathered context
7. **Save to Memory** - Stores plan in memory graph for tracking
8. **Review Plan** - Presents plan for your confirmation before coding
9. **TDD Implementation** - Test-first development with Red-Green-Refactor
10. **Parallel Code Reviews** - Security and Rails best practices reviews run concurrently
11. **Address Feedback** - Systematically implements review suggestions
12. **Validation** - Ensures all tests and linters pass
13. **Logical Commits** - Creates meaningful commit history
14. **Create PR** - Opens pull request with proper task manager linking
15. **Final Verification** - Confirms CI/CD and task manager integration

## Benefits

- **Consistent Quality** - Every feature follows the same rigorous process
- **Security by Default** - Parallel security review catches vulnerabilities early
- **Best Practices Enforced** - Rails/OOP patterns review ensures clean architecture
- **Full Traceability** - Task manager integration provides complete audit trail
- **Time Savings** - Automated workflow handles boilerplate tasks
- **Flexible** - Works with both Linear and Jira projects

## Usage

The skill activates when you ask Claude to implement an issue:

```
Implement TRA-142
Help me build the feature in DEV-89
Work on issue PROJ-456
```

Or use the command directly:
```
/task-implement TRA-142
/task-implement PROJ-456
```

Claude will:
- Auto-detect task manager from commit history
- Pause at the planning phase for your approval
- Show progress through each workflow step
- Present code review findings before addressing them
- Provide a completion checklist when done

## Workflow Highlights

### Task Manager Detection

The skill automatically detects which task manager your project uses:
- Examines last 20 commits on master branch
- Looks for `linear.app` URLs (Linear) or `atlassian.net` URLs (Jira)
- Falls back to asking if no URLs found

### Context Gathering

Before planning, the skill automatically gathers relevant context:

**Obsidian Vault Search:**
- Searches by issue ID (e.g., "TRA-142" or "PROJ-456")
- Searches by keywords from the issue title/description
- Finds related meeting notes, architecture decisions, and previous work

**Sentry Integration (if referenced):**
- Fetches error stack traces and frequency
- Identifies affected users and environments
- Provides debugging context for bug fixes

**GitHub References (if referenced):**
- Retrieves PR discussions and review feedback
- Fetches issue comments and design decisions
- Gathers context from related code changes

### Test-Driven Development

The skill enforces strict TDD methodology:
- Write failing tests first (Red)
- Implement minimal code to pass (Green)
- Refactor while keeping tests green (Refactor)
- Include system specs for end-to-end coverage

### Parallel Code Reviews

Two specialized review agents run concurrently:

**Security Review:**
- OWASP Top 10 vulnerabilities
- Multi-tenant data isolation
- Authentication/authorization patterns
- Input validation and sanitization

**Rails Best Practices Review:**
- POODR principles (SRP, dependency management)
- Service object patterns
- N+1 query prevention
- Result pattern usage

### Task Manager Integration

**Linear:**
- Creates branches using Linear's suggested `branchName`
- Updates issue status to "In Progress" automatically
- Links PRs to issues with `Closes <Linear-URL>`
- Issues auto-update when PRs merge

**Jira:**
- Creates branches with format `<initials>/<issue-key>-<description>`
- Transitions issue to "In Progress" via workflow
- Uses Jira Smart Commits (issue key in commit messages)
- Links PRs with issue key in title and URL in body
- Issues auto-link when PR is created

## Requirements

This skill requires one of the following task manager integrations:

| Task Manager | Option 1 | Option 2 |
|--------------|----------|----------|
| **Linear** | Linear MCP server | - |
| **Jira** | `acli` CLI (Atlassian CLI) | - |

Additional MCP servers (optional but recommended):

| Requirement | Purpose | Documentation |
|-------------|---------|---------------|
| **Sentry MCP** | Gather error context when issues reference Sentry | [docs.sentry.io/product/sentry-mcp](https://docs.sentry.io/product/sentry-mcp/) |
| **GitHub CLI** | Create PRs and fetch referenced PR/issue discussions | [cli.github.com](https://cli.github.com/) |

Additionally:
- **Obsidian Vault** - For searching related notes and documentation
- **Git Repository** - Current directory must be a git repo
- **Testing Tools** - `bundle exec rspec` available
- **Linting** - `bin/lint` script available

## Documentation

- **[SKILL.md](./SKILL.md)** - Complete workflow guide with detailed steps, error handling, and project-specific conventions

## Example Output

After asking Claude to "Implement TRA-142" or "Implement PROJ-456":

```
Task manager detected: Linear (from commit history)
Issue fetched
Context gathered (Obsidian notes, Sentry errors, GitHub discussions)
Implementation planned and approved
Solution implemented with TDD
Comprehensive system specs added
Security review completed
Rails/OOP patterns review completed
All review feedback addressed
All tests and linting pass
Logical commit history created
PR created with task manager integration

PR: https://github.com/org/repo/pull/123
```

## Best Practices

- Review the plan carefully before approving
- Check code review findings for critical issues
- Verify the PR description is accurate before merging
- Use for features that benefit from structured development

---

**Note:** This skill is optimized for Ruby on Rails projects following POODR principles. It integrates with the project's existing testing and linting infrastructure.
