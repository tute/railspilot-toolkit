#!/usr/bin/env bash
# PostToolUse hook: logs minimal observation entries to ~/.claude/observations/
# Receives JSON on stdin with tool_name, tool_input, session_id, etc.
set -euo pipefail

INPUT=$(cat)

OBS_DIR="$HOME/.claude/observations"
mkdir -p "$OBS_DIR"

# Derive project hash from git remote (portable across machines)
PROJECT_HASH=$(git remote get-url origin 2>/dev/null | md5sum | cut -c1-12)
if [ -z "$PROJECT_HASH" ]; then
  PROJECT_HASH=$(git rev-parse --show-toplevel 2>/dev/null | md5sum | cut -c1-12)
fi
if [ -z "$PROJECT_HASH" ]; then
  exit 0
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

if [ -z "$TOOL_NAME" ]; then
  exit 0
fi

# Extract minimal metadata based on tool type
case "$TOOL_NAME" in
  Bash)
    FILE_PATH=""
    EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exitCode // .tool_response.exit_code // empty')
    ;;
  Edit|Write|Read)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    EXIT_CODE=""
    ;;
  *)
    FILE_PATH=""
    EXIT_CODE=""
    ;;
esac

# Build and append JSONL entry
ENTRY=$(jq -n -c \
  --arg ts "$TIMESTAMP" \
  --arg tool "$TOOL_NAME" \
  --arg sid "$SESSION_ID" \
  --arg file "$FILE_PATH" \
  --arg exit "$EXIT_CODE" \
  '{timestamp: $ts, tool: $tool, session: $sid} +
   (if $file != "" then {file: $file} else {} end) +
   (if $exit != "" then {exit_code: ($exit | tonumber)} else {} end)')

echo "$ENTRY" >> "$OBS_DIR/${PROJECT_HASH}.jsonl"
