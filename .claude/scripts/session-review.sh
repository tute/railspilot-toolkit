#!/usr/bin/env bash
# Stop hook: reminds to run /rails-learn after productive sessions
set -euo pipefail

INPUT=$(cat)

# Prevent infinite loops — if Stop hook already fired, exit silently
STOP_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_ACTIVE" = "true" ]; then
  exit 0
fi

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
if [ -z "$SESSION_ID" ]; then
  exit 0
fi

OBS_DIR="$HOME/.claude/observations"
PROJECT_HASH=$(git remote get-url origin 2>/dev/null | md5sum | cut -c1-12)
if [ -z "$PROJECT_HASH" ]; then
  PROJECT_HASH=$(git rev-parse --show-toplevel 2>/dev/null | md5sum | cut -c1-12)
fi

OBS_FILE="$OBS_DIR/${PROJECT_HASH}.jsonl"
if [ ! -f "$OBS_FILE" ]; then
  exit 0
fi

# Count observations from this session
COUNT=$(grep -c "\"session\":\"$SESSION_ID\"" "$OBS_FILE" 2>/dev/null || echo "0")

if [ "$COUNT" -gt 20 ]; then
  jq -n -c --arg reason "Productive session ($COUNT tool uses). Consider running /rails-learn to extract patterns before ending." \
    '{"decision": "block", "reason": $reason}'
fi
