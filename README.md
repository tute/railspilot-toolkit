# [RailsPilot.ai](https://www.railspilot.ai/)

A collection of specialized agents skills, configurations, and rules for
RailsPilot work. Includes agents for code review, security auditing,
feature development, and refactoring following Rails conventions and POODR
principles.

## Installation

Symlink to these Claude Code and Cursor configurations:

```bash
cd ~/.cursor
ln -s ~/Code/ai/railspilot/.cursor/rules
ln -s ~/Code/opensource/dotfiles/cursor/settings.json
ln -s ~/Code/ai/railspilot/.cursor/worktrees.json

cd ~/.claude
ln -s ~/Code/ai/railspilot/.claude/CLAUDE.md
ln -s ~/Code/ai/railspilot/.claude/agents
ln -s ~/Code/ai/railspilot/.claude/settings.json
ln -s ~/Code/ai/railspilot/.claude/skills
```

## What's Included

### Agents

- `rails-feature-developer`: TDD-driven Rails feature development with Hotwire
- `rails-code-reviewer`: Code review for Rails conventions and POODR principles
- `rails-security-reviewer`: Security auditing and multi-tenant data isolation
- `refactor-planner`: Safe, incremental refactoring plans
- `railspilot-progress-reporter`: Monthly client progress reports
- `calendar-fetcher` / `gmail-fetcher` / `jira-fetcher`: Lightweight data fetchers for `/today`

### Skills

**Development Workflow**
- `task-implement`: Full issue-to-PR workflow from a Linear/Jira issue (TDD, code reviews, PR creation)
- `tdd-skill`: Red-Green-Refactor TDD methodology
- `fix-merge-conflicts`: Non-interactive merge conflict resolution

**Code Quality**
- `code-review`: Focused diff review for bugs, edge cases, and performance
- `full-code-review`: Parallel security + Rails best practices review
- `railspilot-staff-review`: Code review through a staff engineer's lens
- `rspec-testing`: RSpec best practices (Better Specs, thoughtbot)
- `frontend`: Anti-"AI slop" design principles

**Git & PR**
- `git-commit`: Commit with a well-structured message explaining the why
- `pr-title-and-description`: PR title and description from branch diff

**Utilities**
- `today`: Daily task summary from Calendar, Gmail, and Jira
- `visualize`: Mermaid diagram for data lineage and architecture
- `update-CLAUDE`: Extract patterns from recent commits into CLAUDE.md/skills
- `document-past-chats`: Analyze chat history for recurring patterns and insights

## Docs

- [MCP server setup](docs/mcps.md)
- [Onboarding checklist](docs/onboarding.md)
