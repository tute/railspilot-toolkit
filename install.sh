#!/usr/bin/env sh
set -eu

cd ~/.cursor
ln -sfn ~/Code/ai/railspilot/.cursor/rules rules
ln -sfn ~/Code/opensource/dotfiles/cursor/settings.json settings.json
ln -sfn ~/Code/ai/railspilot/.cursor/worktrees.json worktrees.json

cd ~/.claude
ln -sfn ~/Code/ai/railspilot/.claude/CLAUDE.md CLAUDE.md
ln -sfn ~/Code/ai/railspilot/.claude/agents agents
ln -sfn ~/Code/ai/railspilot/.claude/settings.json settings.json
ln -sfn ~/Code/ai/railspilot/.claude/skills skills

if [ -n "${1:-}" ]; then
  cd "$1"
  ln -sfn ~/Code/ai/railspilot/conductor.json conductor.json
fi
