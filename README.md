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
- `jira-fetcher`: Lightweight Jira data fetcher for `/today`

### Skills

#### Development Workflow

- `task-implement`: Full issue-to-PR workflow from a Linear/Jira issue (TDD, code reviews, PR creation)
- `tdd-skill`: Red-Green-Refactor TDD methodology
- `fix-merge-conflicts`: Non-interactive merge conflict resolution
- `to-tickets`: Split work into tracer-bullet tickets with blocking edges. Ours,
  taking the splitting rules from [mattpocock/skills](https://github.com/mattpocock/skills)
  v1.2.3 and dropping its tracker integration

#### Code Quality

- `code-review`: Focused diff review for bugs, edge cases, and performance
- `frontend`: Anti-"AI slop" design principles
- `full-code-review`: Parallel security + Rails best practices review
- `railspilot-staff-review`: Code review through a staff engineer's lens
- `rspec-testing`: RSpec best practices (Better Specs, thoughtbot)
- `vulnerability-scan`: Whole-project security audit (CVEs, secrets, dangerous patterns)
- `best-practices`: Modern web security, compatibility, and code quality
- `ponytail`, `ponytail-review`, `ponytail-audit`, `ponytail-debt`, `ponytail-help`: Pushback on over-engineering, plus diff review, repo audit, and a debt ledger

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
- `railspilot-progress-report`: Monthly client progress reports from merged PRs

### Commands

- `internal-branch-review`: Full review workflow for contributor branches pushed to a fork — setup, rebase-check, AC verification, test coverage, staff review, simplify+commit, and PR creation (7 steps, resumable with `--from N`)

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

## Vendored skills

Some skills come from other repos. They are copied into `.claude/skills/` and
pinned in `skills-lock.json` with their source repo and tag. Manage them with
the [`skills` CLI](https://github.com/vercel-labs/skills):

```bash
# add or re-add a pinned set
npx skills add https://github.com/OWNER/REPO/tree/TAG -a claude-code --copy -y -s NAME

# refresh at the pinned tag
npx skills update -y

# drop one
npx skills remove NAME -a claude-code -y
```

Rules:

- Never hand-edit a vendored skill. `skills update` overwrites it with no
  warning. Repo-specific notes belong here, not in the skill file.
- Always pass `--copy`. Symlinks do not survive `bin/install`.
- To upgrade, re-run `add` with the new tag and review the diff. `skills
  update` stays on the pinned tag.
- `skills remove` leaves a stale entry in `skills-lock.json`. Delete it by hand.
- To change a vendored skill's behaviour, fork it: keep the file, delete its
  lockfile entry, and record the divergence under "Forked skills" below. A fork
  is ours to maintain. `skills update` no longer touches it, and no longer
  brings it upstream fixes either.

New machines need no extra step. The skill files are committed, and
`bin/install` symlinks the whole directory into `~/.claude/`. Cloning the repo
installs them. `skills-lock.json` records where each one came from, for
updates, not for installs.

Inside Claude Code, these commands need the sandbox off. `.claude/skills` is
protected from sandboxed shell commands and no setting overrides it.

Vendored today:

- `ponytail*` at v4.7.0 from
  [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail).
  `ponytail-help` describes a plugin marketplace auto-update. Ignore it, this
  toolkit vendors the skills instead.
- `grilling`, `grill-with-docs`, `domain-modeling` and
  `improve-codebase-architecture` at v1.2.3 from
  [mattpocock/skills](https://github.com/mattpocock/skills). Upstream ships
  more of these. We vendor only what `/grill-with-docs` and
  `/improve-codebase-architecture` need, and skip the issue-tracker ones
  (`to-spec`, `triage`, `setup-matt-pocock-skills`, and upstream's
  `to-tickets`, which we replaced with our own one-file version).

`domain-modeling` writes a `CONTEXT.md` glossary into whatever repo it runs in.
`CONTEXT.md` stays gitignored: `bin/install` links `git/ignore` into
`~/.config/git/ignore`, which git applies to every repo on the machine.

### Forked skills

`codebase-design` started as the v1.2.3 skill of the same name from
[mattpocock/skills](https://github.com/mattpocock/skills). We modified the
original and now maintain it here, so it has no `skills-lock.json` entry and
`skills update` leaves it alone.

What we changed and why:

- It explains, it does not edit. The upstream skill is a design tool. Ours is
  a read-only one: it describes how a system is put together, where the seams
  fall, and what a change would buy, then stops at the recommendation.
- It keeps units small. Upstream argues for depth without saying what depth
  costs, which reads as a licence to grow classes. Ours states that depth is a
  property of the public interface, not of the units behind it, and rules out
  "collapse these classes into one" as a route to depth.

`improve-codebase-architecture` is vendored and calls `codebase-design` by
name, so the fork keeps the original name on purpose. Renaming it would break
that reference.

## Docs

- [External tools](docs/external-tools.md)
- [Onboarding checklist](docs/onboarding.md)
