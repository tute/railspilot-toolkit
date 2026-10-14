#!/usr/bin/env bash
set -u

HOOK="$(cd "$(dirname "$0")/.." && pwd)/rtk-rewrite.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/nortk"
for tool in bash jq cat grep sort head; do
  ln -s "$(command -v "$tool")" "$WORK/bin/$tool"
  ln -s "$(command -v "$tool")" "$WORK/nortk/$tool"
done

cat > "$WORK/bin/rtk" <<'EOF'
#!/usr/bin/env bash
if [ "$1" = --version ]; then echo "rtk ${FAKE_VERSION:-0.42.2}"; exit 0; fi
printf '%s' "${FAKE_REWRITE-rtk $2}"
exit "${FAKE_EXIT:-0}"
EOF
chmod +x "$WORK/bin/rtk"

failures=0

check() {
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2], want [$3]"; failures=$((failures + 1)); fi
}

run() {
  local input=$1; shift
  printf '%s' "$input" | env PATH="$WORK/bin" "$@" bash "$HOOK" > "$WORK/out"
  echo $?
}

INPUT='{"tool_input":{"command":"git status","description":"Show status"}}'

status=$(run "$INPUT")
check "rewrite exits 0" "$status" 0
check "rewrite replaces the command" "$(jq -r .hookSpecificOutput.updatedInput.command "$WORK/out")" "rtk git status"
check "rewrite keeps other input" "$(jq -r .hookSpecificOutput.updatedInput.description "$WORK/out")" "Show status"
check "rtk exit 0 allows" "$(jq -r .hookSpecificOutput.permissionDecision "$WORK/out")" allow

run "$INPUT" FAKE_EXIT=3 > /dev/null
check "rtk exit 3 rewrites" "$(jq -r .hookSpecificOutput.updatedInput.command "$WORK/out")" "rtk git status"
check "rtk exit 3 leaves the decision to the allow list" "$(jq -r '.hookSpecificOutput | has("permissionDecision")' "$WORK/out")" false

for code in 1 2; do
  status=$(run "$INPUT" FAKE_EXIT=$code)
  check "rtk exit $code exits 0" "$status" 0
  check "rtk exit $code passes the command through" "$(cat "$WORK/out")" ""
done

run '{"tool_input":{"command":"git status","dangerouslyDisableSandbox":true}}' > /dev/null
check "unsandboxed rewrites" "$(jq -r .hookSpecificOutput.updatedInput.command "$WORK/out")" "rtk git status"
check "unsandboxed never allows" "$(jq -r '.hookSpecificOutput | has("permissionDecision")' "$WORK/out")" false

run "$INPUT" FAKE_REWRITE="git status" > /dev/null
check "unchanged command prints nothing" "$(cat "$WORK/out")" ""

run '{"tool_input":{}}' > /dev/null
check "no command prints nothing" "$(cat "$WORK/out")" ""

run "$INPUT" FAKE_VERSION=0.41.9 > /dev/null
check "old rtk prints nothing" "$(cat "$WORK/out")" ""

status=$(printf '%s' "$INPUT" | env PATH="$WORK/nortk" bash "$HOOK" 2> /dev/null > "$WORK/out"; echo $?)
check "no rtk exits 0" "$status" 0
check "no rtk prints nothing" "$(cat "$WORK/out")" ""

echo
[ "$failures" -eq 0 ] && echo "all passed" || { echo "$failures failed"; exit 1; }
