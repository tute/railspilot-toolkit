#!/usr/bin/env bash
command -v rtk >/dev/null && command -v jq >/dev/null || exit 0

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

rewritten=$(rtk rewrite "$cmd" 2>/dev/null)
case $? in
  0 | 3) ;;
  *) exit 0 ;;
esac
[ "$cmd" = "$rewritten" ] && exit 0

jq -c --arg cmd "$rewritten" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    updatedInput: (.tool_input + {command: $cmd})
  }
}' <<<"$input"
