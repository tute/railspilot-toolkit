#!/usr/bin/env bash
command -v rtk >/dev/null && command -v jq >/dev/null || exit 0

min_version=0.42.2
version=$(rtk --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
[ "$(printf '%s\n' "$min_version" "$version" | sort -V | head -1)" = "$min_version" ] || exit 0

input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

rewritten=$(rtk rewrite "$cmd" 2>/dev/null)
case $? in
  0) decision=allow ;;
  3) decision= ;;
  *) exit 0 ;;
esac
[ "$cmd" = "$rewritten" ] && exit 0

jq -c --arg cmd "$rewritten" --arg decision "$decision" '{
  hookSpecificOutput: ({
    hookEventName: "PreToolUse",
    updatedInput: (.tool_input + {command: $cmd})
  } + if $decision != "" and (.tool_input.dangerouslyDisableSandbox | not)
      then {permissionDecision: $decision}
      else {} end)
}' <<<"$input"
