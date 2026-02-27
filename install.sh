#!/usr/bin/env sh
set -eu

cd ~/.cursor
ln -s ~/Code/ai/railspilot/.cursor/rules
ln -s ~/Code/opensource/dotfiles/cursor/settings.json
ln -s ~/Code/ai/railspilot/.cursor/worktrees.json

cd ~/.claude
ln -s ~/Code/ai/railspilot/.claude/CLAUDE.md
ln -s ~/Code/ai/railspilot/.claude/agents
ln -s ~/Code/ai/railspilot/.claude/settings.json
ln -s ~/Code/ai/railspilot/.claude/skills

if [ -n "${1:-}" ]; then
  cd "$1"
  ln -s ~/Code/ai/railspilot/conductor.json conductor.json
fi
