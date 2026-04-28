# RailsPilot Toolkit (this repo)

Configuration and dotfiles for AI-assisted work: not an application (no app
server, tests, or build). Changes here ship to dev machines via symlinks.

`README.md` file describes what's included and how to install.
**Human onboarding and tool notes:** `docs/onboarding-new-project.md`, `docs/external-tools.md`.

**Where things live**

- `.claude/`: agent definitions, skills, Claude settings, and general
  `.claude/CLAUDE.md` (symlinked to `~/.claude/` by install)
- `.cursor/`: Cursor rules, editor settings, worktrees config
- `bin/install`: links the above into `~/.cursor/`, `~/.claude/`,
  and optional `conductor.json` into a target app path
