#!/usr/bin/env bash
# Bash investigation subscriber. Mirrors resolve-watch-investigation without
# requiring Node.
#
# Usage: resolve-watch-investigation.sh <investigation_id> --watch-token <token>
# The watch token (from start_investigation / steer_investigation) is sent as
# ?watch_token=; the base URL comes from config.json.

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_PATH="${PLUGIN_ROOT}/config.json"
SNAPSHOT_INTERVAL_SECONDS=20

main() {
  local base_url state_dir query get_url stream_url exit_code timer_pid curl_status
  parse_args "$@"

  base_url="$(resolve_base_url)" || exit 1
  state_dir="$(mktemp -d "${TMPDIR:-/tmp}/resolve-watch-inv-XXXXXX")"

  query=""
  query="$(append_param "$query" "watch_token" "$watch_token")"
  get_url="${base_url}/api/resolve-mcp/v2/investigations/$(url_encode "$investigation_id")?${query}"
  stream_url="${base_url}/api/resolve-mcp/v2/investigations/$(url_encode "$investigation_id")/stream?${query}"

  printf 'resolve-watch-investigation: streaming %s/api/resolve-mcp/v2/investigations/%s/stream\n' "$base_url" "$(url_encode "$investigation_id")" >&2
  printf 'state_dir=%s\n' "$state_dir" >&2
  printf 'resolve-watch-investigation: state at %s/state.json\n' "$state_dir" >&2

  snapshot "$state_dir" "$get_url" "initial" >/dev/null || true

  periodic_snapshots "$state_dir" "$get_url" &
  timer_pid=$!
  trap 'kill "$timer_pid" 2>/dev/null || true' EXIT INT TERM HUP

  exit_code=0
  curl -sS -L -N -f -H 'Accept: text/event-stream' "$stream_url"
  curl_status=$?
  if [[ "$curl_status" -ne 0 ]]; then
    printf 'resolve-watch-investigation: stream error: curl exited with status %s\n' "$curl_status" >&2
    exit_code=1
  fi

  kill "$timer_pid" 2>/dev/null || true
  wait "$timer_pid" 2>/dev/null || true
  trap - EXIT INT TERM HUP

  snapshot "$state_dir" "$get_url" "final" >/dev/null || true

  exit "$exit_code"
}

usage() {
  printf '%s\n' "Usage: resolve-watch-investigation.sh <investigation_id> --watch-token <token>" >&2
  printf '%s\n' "The watch token is returned by start_investigation / steer_investigation (no API key)." >&2
  exit 2
}

parse_args() {
  [[ $# -gt 0 ]] || usage
  investigation_id="$1"
  shift
  [[ -n "$investigation_id" && "$investigation_id" != --* ]] || usage

  watch_token=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --watch-token)
        shift
        [[ $# -gt 0 && -n "$1" ]] || usage
        watch_token="$1"
        ;;
      *)
        usage
        ;;
    esac
    shift
  done

  [[ -n "$watch_token" ]] || usage
}

resolve_base_url() {
  local raw base_url
  if [[ ! -f "$CONFIG_PATH" ]]; then
    printf 'resolve-watch-investigation: %s is missing\n' "$CONFIG_PATH" >&2
    exit 1
  fi
  raw="$(tr -d '\n' < "$CONFIG_PATH")"
  base_url="$(printf '%s' "$raw" | sed -n 's/.*"baseUrl"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  if [[ -z "$base_url" ]]; then
    printf 'resolve-watch-investigation: %s is missing a string "baseUrl" field\n' "$CONFIG_PATH" >&2
    exit 1
  fi
  printf '%s' "${base_url%/}"
}

append_param() {
  local current="$1"
  local name="$2"
  local value="$3"
  local encoded
  encoded="$(url_encode "$value")"
  if [[ -n "$current" ]]; then
    printf '%s&%s=%s' "$current" "$name" "$encoded"
  else
    printf '%s=%s' "$name" "$encoded"
  fi
}

url_encode() {
  local LC_ALL=C
  local raw="$1"
  local length="${#raw}"
  local i char
  for ((i = 0; i < length; i++)); do
    char="${raw:i:1}"
    case "$char" in
      [a-zA-Z0-9.~_-]) printf '%s' "$char" ;;
      *) printf '%%%02X' "'$char" ;;
    esac
  done
}

snapshot() {
  local state_dir="$1"
  local get_url="$2"
  local label="$3"
  local error_output
  if ! error_output="$(write_state_from_url "$get_url" "$state_dir" 2>&1)"; then
    printf 'resolve-watch-investigation: %s get_investigation failed: get_investigation %s\n' "$label" "$error_output" >&2
    return 1
  fi
  return 0
}

periodic_snapshots() {
  local state_dir="$1"
  local get_url="$2"
  while :; do
    sleep "$SNAPSHOT_INTERVAL_SECONDS" || exit 0
    snapshot "$state_dir" "$get_url" "periodic" >/dev/null || true
  done
}

write_state_from_url() {
  local url="$1"
  local state_dir="$2"
  local body_path status tmp_path final_path curl_status
  body_path="${state_dir}/state.json.body.$$.$RANDOM"
  tmp_path="${state_dir}/state.json.$$.$RANDOM.tmp"
  final_path="${state_dir}/state.json"

  status="$(curl -sS -L -o "$body_path" -w '%{http_code}' "$url")"
  curl_status=$?
  if [[ $curl_status -ne 0 ]]; then
    rm -f "$body_path"
    return "$curl_status"
  fi
  if [[ ! "$status" =~ ^2 ]]; then
    printf 'HTTP %s %s' "$status" "$(cat "$body_path")" >&2
    rm -f "$body_path"
    return 22
  fi
  mv "$body_path" "$tmp_path"
  mv "$tmp_path" "$final_path"
}

main "$@"
