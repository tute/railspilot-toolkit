# [RailsPilot.ai](https://www.railspilot.ai/) Toolkit

A collection of specialized agents skills, configurations, and rules for
RailsPilot work. Includes agents for code review, security auditing,
feature development, and refactoring following Rails conventions and POODR
principles.

## Installation

Run the installer:

```bash
bin/install [path/to/rails-app]
```

Note that conductor workspaces will require `bin/dev` and `bin/setup` scripts to launch server and
setup workspaces respectively. `bin/dev` needs to pick `$CONDUCTOR_PORT` for the web server when
available (in Rails, it would take precedense before `$PORT`).

## What's Included

### Agents

- `rails-feature-developer`: TDD-driven Rails feature development with Hotwire
- `rails-code-reviewer`: Code review for Rails conventions and POODR principles
- `rails-security-reviewer`: Security auditing and multi-tenant data isolation
- `staff-engineer-reviewer`: Pattern-library review through a staff engineer's lens
- `layered-rails-gradual`: Phased roadmaps for incremental layered-architecture adoption
- `refactor-planner`: Safe, incremental refactoring plans
- `railspilot-progress-reporter`: Monthly client progress reports
- `jira-fetcher`: Lightweight Jira data fetcher for `/today`

### Skills

#### Development Workflow

- `task-implement`: Full issue-to-PR workflow from a Linear/Jira issue (TDD, code reviews, PR creation)
- `tdd-skill`: Red-Green-Refactor TDD methodology
- `fix-merge-conflicts`: Non-interactive merge conflict resolution

#### Code Quality

- `code-review`: Focused diff review for bugs, edge cases, and performance
- `frontend`: Anti-"AI slop" design principles
- `full-code-review`: Parallel security + Rails best practices review
- `railspilot-staff-review`: Code review through a staff engineer's lens
- `rspec-testing`: RSpec best practices (Better Specs, thoughtbot)
- `vulnerability-scan`: Whole-project security audit (CVEs, secrets, dangerous patterns)
- `best-practices`: Modern web security, compatibility, and code quality

#### Codebase Analysis

- `codebase-diagnostic`: Git-history diagnostics for churn, bus factor, and bug clusters
- `rails-codebase-audit`: Legacy Rails audit with prioritized fix-now/quarter/ignore tiers
- `weekly-review`: Weekly engineering digest plus pattern evolution from accumulated lessons

#### Web Quality

- `accessibility`: WCAG 2.2 audits and fixes
- `performance`: Page-speed and load-time optimization
- `core-web-vitals`: LCP, INP, and CLS optimization
- `seo`: Search visibility and structured data
- `web-quality-audit`: Combined performance/a11y/SEO/best-practices audit

#### Git & PR

- `commit`: Commit with a well-structured message explaining the why; also generates PR titles/descriptions

#### Productivity

- `today`: Daily task summary from Calendar, Gmail, and Jira
- `gws-gmail`: Send, read, and manage email
- `gws-gmail-triage`: Unread inbox summary
- `fact-checker`: Investigate a news article URL for accuracy and rhetorical manipulation

#### Meta

- `visualize`: Mermaid diagram for data lineage and architecture
- `rails-learn`: Extract patterns from the current session into patterns.md, CLAUDE.md, or skills
- `update-CLAUDE`: Extract patterns from recent commits into CLAUDE.md/skills
- `document-past-chats`: Analyze chat history for recurring patterns and insights
- `claude_deslop`: Audit your Claude setup for redundancy, conflicts, and dead weight
- `caveman`, `caveman-compress`, `caveman-help`: Token-compressed communication mode

## Docs

- [External tools](docs/external-tools.md)
- [Onboarding checklist](docs/onboarding.md)
