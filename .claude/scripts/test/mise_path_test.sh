#!/usr/bin/env bash
set -u

HOOK="$(cd "$(dirname "$0")/.." && pwd)/mise-path"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/bin" "$WORK/nomise" "$WORK/project"
for tool in bash paste; do
  ln -s "$(command -v "$tool")" "$WORK/bin/$tool"
  ln -s "$(command -v "$tool")" "$WORK/nomise/$tool"
done

cat > "$WORK/bin/mise" <<'EOF'
#!/usr/bin/env bash
[ "$1" = bin-paths ] || exit 1
[ "${MISE_OFFLINE-}" = 1 ] || exit 1
[ "$PWD" = "$EXPECTED_DIR" ] || exit 1
printf '%s' "${FAKE_PATHS-/mise/ruby/bin
/mise/node/bin
}"
EOF
chmod +x "$WORK/bin/mise"

failures=0

check() {
  if [ "$2" = "$3" ]; then echo "ok   $1"; else echo "FAIL $1: got [$2], want [$3]"; failures=$((failures + 1)); fi
}

run() {
  : > "$WORK/env"
  env PATH="$WORK/bin" CLAUDE_ENV_FILE="$WORK/env" CLAUDE_PROJECT_DIR="$WORK/project" EXPECTED_DIR="$WORK/project" "$@" bash "$HOOK" < /dev/null
  echo $?
}

check "exits 0" "$(run)" 0
check "puts mise tool dirs first" "$(cat "$WORK/env")" 'export PATH="/mise/ruby/bin:/mise/node/bin:$PATH"'

check "no tools exits 0" "$(run FAKE_PATHS=)" 0
check "no tools writes nothing" "$(cat "$WORK/env")" ""

check "no mise exits 0" "$(run PATH="$WORK/nomise")" 0
check "no mise writes nothing" "$(cat "$WORK/env")" ""

: > "$WORK/env"
env -u CLAUDE_ENV_FILE PATH="$WORK/bin" CLAUDE_PROJECT_DIR="$WORK/project" EXPECTED_DIR="$WORK/project" bash "$HOOK" < /dev/null
check "no env file exits 0" "$?" 0

[ "$failures" -eq 0 ]
