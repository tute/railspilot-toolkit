# RailsPilot.ai Toolkit

This repo is a **configuration/dotfiles toolkit** (not a runnable app). It
contains AI agent definitions, skills, Cursor rules, and an install script that
symlinks these configs into development environments.

- There is n**o application code, no tests, no build step.** (no Gemfile,
  package.json, Rakefile, or test suite)
- **`bin/install [path]`** symlinks `.cursor/` and `.claude/` configs into
  `~/.cursor/` and `~/.claude/`, and optionally links `conductor.json` into an
  app directory. It expects the repo to be cloned at
  `~/Code/railspilot/toolkit`. Cloud Agent environments don't need to run this
  installation step (but may run it to ensure it works)
- **Tool versions** are managed by `mise` (see `.mise.toml`): Node.js (latest),
  Python 3.12, and uv (latest). Use `mise exec --` to run project binaries.
- **External services**: `gws` CLI for Google Workspace (Calendar, Gmail),
  Jira MCP server via `npx`. Both require API credentials and are optional
  for toolkit development.

### Lint / test / build / run

| Action | Command | Notes |
|--------|---------|-------|
| Lint | N/A | No lintable source code in this repo |
| Test | N/A | No test suite |
| Build | N/A | No build step |
| Run | `bin/install [target-app-path]` | Creates symlinks; see README.md |
| Verify tools | `mise ls` | Confirms node/python/uv versions |
