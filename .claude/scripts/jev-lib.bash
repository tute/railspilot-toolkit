# Sourced by the Jev scripts, not run.

CUT=0.5
CAP=${MAX_DIFF_CHARS:-100000}
URL=${JEV_URL:-https://api.typesafe.ai/v1/systemone}
MODEL=${JEV_MODEL:-jev-latest}
TIMEOUT=20

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

is_score() {
  [[ $1 =~ ^[0-9]*[.]?[0-9]+$ ]]
}

# jev_post RESPONSE_FILE <PAYLOAD
jev_post() {
  local http
  http=$(curl -sS -o "$1" -w "%{http_code}" --max-time "$TIMEOUT" \
    "$URL" \
    -H "Authorization: Bearer ${TYPESAFE_API_KEY}" \
    -H "Content-Type: application/json" \
    --data-binary @-) || http=000
  if [[ $http != 200 ]]; then
    printf 'jev: check did not run (HTTP %s).\n' "$http" >&2
    [[ -s $1 ]] && { cat "$1"; printf '\n'; } >&2
    exit 1
  fi
}
