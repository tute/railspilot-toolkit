#!/usr/bin/env bash
set -u

CHECK="$(cd "$(dirname "$0")/../.." && pwd)/skills/jev-ac-check/check"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/home/.claude/scripts" "$WORK/repo"

cat > "$WORK/home/.claude/scripts/jev" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "${JEV_ENABLE:-}" "${JEV_TIMEOUT:-}" > "$FAKE_DIR/env"
cat > "$FAKE_DIR/body"
printf '%s' "$FAKE_ANSWERS"
exit "${FAKE_EXIT:-0}"
EOF
chmod +x "$WORK/home/.claude/scripts/jev"

git -C "$WORK/repo" init -q -b main
git -C "$WORK/repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m base
git -C "$WORK/repo" checkout -q -b feature
echo "validates email" > "$WORK/repo/user.rb"
git -C "$WORK/repo" add user.rb
git -C "$WORK/repo" -c user.name=t -c user.email=t@t commit -q -m change
printf 'Validates email\n\nSends a welcome mail\n' > "$WORK/ac"

ANSWERS='{"ac_1":{"type":"choice","choice":"met","confidence":0.934},"ac_2":{"type":"choice","choice":"missing","confidence":0.8}}'
failures=0

check() {
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2], want [$3]"; failures=$((failures + 1)); fi
}

run() {
  (cd "$WORK/repo" && env HOME="$WORK/home" FAKE_DIR="$WORK" "$@" "$CHECK" "$WORK/ac" main > "$WORK/out" 2> "$WORK/err")
  echo $?
}

status=$(run FAKE_ANSWERS="$ANSWERS")
check "answers exit 0" "$status" 0
check "one line per criterion" "$(cat "$WORK/out")" "$(printf '1\tmet\t0.93\tValidates email\n2\tmissing\t0.8\tSends a welcome mail')"
check "enables jev" "$(cut -d' ' -f1 "$WORK/env")" 1
check "default timeout" "$(cut -d' ' -f2 "$WORK/env")" 120
check "sends the diff" "$(jq -r .state.diff "$WORK/body" | grep -c '^+validates email$')" 1
check "asks one choice per criterion" "$(jq -c '.questions | keys' "$WORK/body")" '["ac_1","ac_2"]'
check "criterion in instructions" "$(jq -r .questions.ac_2.instructions.criterion "$WORK/body")" "Sends a welcome mail"

run JEV_TIMEOUT=30 FAKE_ANSWERS="$ANSWERS" > /dev/null
check "timeout override" "$(cut -d' ' -f2 "$WORK/env")" 30

status=$(run FAKE_ANSWERS= FAKE_EXIT=3)
check "jev unavailable exits 3" "$status" 3
check "jev unavailable explains" "$(grep -c OPENROUTER_API_KEY "$WORK/err")" 1

status=$(run FAKE_ANSWERS= FAKE_EXIT=1)
check "jev failure exits 1" "$status" 1

status=$(run MAX_DIFF_CHARS=5 FAKE_ANSWERS="$ANSWERS")
check "large diff exits 2" "$status" 2

echo
[ "$failures" -eq 0 ] && echo "all passed" || { echo "$failures failed"; exit 1; }
