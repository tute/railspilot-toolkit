#!/usr/bin/env bash
# PostToolUse hook: logs prioritized observation entries to ~/.claude/observations/
# Receives JSON on stdin with tool_name, tool_input, session_id, etc.
# Priority: high (errors), medium (file changes), low (reads, successful bash)
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

# Extract metadata and assign priority based on tool type and outcome
PRIORITY="low"
case "$TOOL_NAME" in
  Bash)
    FILE_PATH=""
    EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exitCode // .tool_response.exit_code // empty')
    if [ -n "$EXIT_CODE" ] && [ "$EXIT_CODE" != "0" ]; then
      PRIORITY="high"
    fi
    ;;
  Edit|Write)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    EXIT_CODE=""
    PRIORITY="medium"
    ;;
  Read)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    EXIT_CODE=""
    ;;
  *)
    FILE_PATH=""
    EXIT_CODE=""
    ;;
esac

OBS_FILE="$OBS_DIR/${PROJECT_HASH}.jsonl"

# Build and append JSONL entry with priority
ENTRY=$(jq -n -c \
  --arg ts "$TIMESTAMP" \
  --arg tool "$TOOL_NAME" \
  --arg sid "$SESSION_ID" \
  --arg pri "$PRIORITY" \
  --arg file "$FILE_PATH" \
  --arg exit "$EXIT_CODE" \
  '{timestamp: $ts, tool: $tool, session: $sid, priority: $pri} +
   (if $file != "" then {file: $file} else {} end) +
   (if $exit != "" then {exit_code: ($exit | tonumber)} else {} end)')

echo "$ENTRY" >> "$OBS_FILE"

# Prune old low-priority observations every ~500 entries
LINE_COUNT=$(wc -l < "$OBS_FILE" 2>/dev/null || echo "0")
if [ "$LINE_COUNT" -gt 500 ]; then
  CUTOFF_30D=$(date -u -d "30 days ago" +"%Y-%m-%dT" 2>/dev/null || date -u -v-30d +"%Y-%m-%dT" 2>/dev/null || echo "")
  CUTOFF_90D=$(date -u -d "90 days ago" +"%Y-%m-%dT" 2>/dev/null || date -u -v-90d +"%Y-%m-%dT" 2>/dev/null || echo "")
  if [ -n "$CUTOFF_30D" ] && [ -n "$CUTOFF_90D" ]; then
    # Keep: all high, medium < 90 days, low < 30 days, markers
    jq -c "select(
      .priority == \"high\" or
      .type != null or
      (.priority == \"medium\" and (.timestamp > \"$CUTOFF_90D\")) or
      (.priority == \"low\" and (.timestamp > \"$CUTOFF_30D\")) or
      (.priority == null and (.timestamp > \"$CUTOFF_30D\"))
    )" "$OBS_FILE" > "${OBS_FILE}.tmp" && mv "${OBS_FILE}.tmp" "$OBS_FILE"
  fi
fi
