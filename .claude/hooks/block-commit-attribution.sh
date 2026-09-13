#!/usr/bin/env bash
cmd=$(jq -r '.tool_input.command // ""')
echo "$cmd" | grep -qE 'git (.* )?commit|gh pr (create|edit)' || exit 0
if echo "$cmd" | grep -qiE 'Claude-Session:|claude\.ai/code/session_|Co-Authored-By: Claude|Generated with \[?Claude Code|Implemented with Claude Code'; then
  echo "Blocked: remove Claude attribution (Claude-Session, session URL, Co-Authored-By, Generated with) from the commit or PR text." >&2
  exit 2
fi
exit 0
