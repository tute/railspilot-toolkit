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
ln -s ~/Code/ai/railspilot/.claude/commands
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

### Commands

- `/today`: Daily task summary from Calendar, Gmail, and Jira
- `/task-implement`: TDD workflow for Linear/Jira issue implementation
- `/full-code-review`: Parallel security + Rails best practices review
- `/code-review`: Focused code review for correctness, edge cases, and performance
- `/git-commit`: Commit with a well-structured message explaining the why
- `/pr-title-and-description`: Generate PR title and description from branch changes (useful when it needs to contain many commits)
- `/fix-merge-conflicts`: Non-interactive merge conflict resolution
- `/visualize`: Mermaid diagram for data lineage visualization
- `/update-CLAUDE`: Extract patterns from recent work into CLAUDE.md/skills
- `/document-past-chats`: Analyze chat history for recurring patterns and insights

### Skills

- `tdd-skill`: Red-Green-Refactor methodology
- `rspec-testing`: RSpec best practices (Better Specs, thoughtbot)
- `frontend`: Anti-"AI slop" design principles
- `task-implement`: Issue-to-PR implementation workflow
- `railspilot-staff-review`: Staff engineer code review lens

## Docs

- [MCP server setup](docs/mcps.md)
- [Onboarding checklist](docs/onboarding.md)
