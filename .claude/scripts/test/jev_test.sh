#!/usr/bin/env bash
set -u

JEV="$(cd "$(dirname "$0")/.." && pwd)/jev"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin"

cat > "$WORK/bin/curl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$FAKE_DIR/args"
cat > "$FAKE_DIR/body"
printf '%s' "$FAKE_RESPONSE"
printf '\n%s' "$FAKE_STATUS"
EOF
chmod +x "$WORK/bin/curl"

REQUEST='{"state":"adds a password column","questions":{"sec":{"type":"noul","instructions":"Does this store a secret?"}}}'
ANSWERED='{"model":"typesafe/jev-1.13","answers":{"sec":{"type":"noul","noul":0.93}}}'
failures=0

check() {
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2], want [$3]"; failures=$((failures + 1)); fi
}

run() {
  printf '%s' "$REQUEST" | PATH="$WORK/bin:$PATH" FAKE_DIR="$WORK" "$@" "$JEV" > "$WORK/out" 2> "$WORK/err"
  echo $?
}

status=$(run env JEV_ENABLE=1 OPENROUTER_API_KEY=sk-or-test FAKE_RESPONSE="$ANSWERED" FAKE_STATUS=200)
check "answers exit 0" "$status" 0
check "prints answers only" "$(jq -c . "$WORK/out")" '{"sec":{"type":"noul","noul":0.93}}'
check "posts to decisions" "$(grep -c '^https://openrouter.ai/api/alpha/decisions$' "$WORK/args")" 1
check "sends the key" "$(grep -c '^Authorization: Bearer sk-or-test$' "$WORK/args")" 1
check "default model" "$(jq -r .model "$WORK/body")" typesafe/jev-1.13
check "no data collection" "$(jq -c .provider "$WORK/body")" '{"data_collection":"deny"}'
check "keeps questions" "$(jq -r .questions.sec.type "$WORK/body")" noul

run env JEV_ENABLE=1 JEV_MODEL=typesafe/jev-next OPENROUTER_API_KEY=k FAKE_RESPONSE="$ANSWERED" FAKE_STATUS=200 > /dev/null
check "model override" "$(jq -r .model "$WORK/body")" typesafe/jev-next

status=$(run env -u JEV_ENABLE OPENROUTER_API_KEY=k FAKE_RESPONSE="$ANSWERED" FAKE_STATUS=200)
check "off by default exits 3" "$status" 3
check "off by default prints nothing" "$(cat "$WORK/out")" ""

status=$(run env -u OPENROUTER_API_KEY JEV_ENABLE=1 FAKE_RESPONSE="$ANSWERED" FAKE_STATUS=200)
check "no key exits 3" "$status" 3

status=$(run env JEV_ENABLE=1 OPENROUTER_API_KEY=k FAKE_RESPONSE='{"error":{"message":"User not found."}}' FAKE_STATUS=401)
check "http error exits 1" "$status" 1
check "http error prints nothing" "$(cat "$WORK/out")" ""
check "http error explains" "$(grep -c 401 "$WORK/err")" 1

echo
[ "$failures" -eq 0 ] && echo "all passed" || { echo "$failures failed"; exit 1; }
