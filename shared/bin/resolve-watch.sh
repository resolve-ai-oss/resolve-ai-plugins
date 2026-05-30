#!/usr/bin/env bash
# Bash watcher CLI. Mirrors resolve-watch without requiring Node.
#
# Usage: resolve-watch.sh <chat_id> --watch-token <token> [--investigation <id>] [--message-id <id>]
# Auth:  --watch-token, the short-lived chat-scoped token returned by `ask`
#        (no personal API key). Sent as the ?watch_token= query param.
# Files: <state-dir>/state.json (atomic; before and after snapshots)

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CONFIG_PATH="${PLUGIN_ROOT}/config.json"

main() {
  local base_url state_dir query get_query get_url stream_url exit_code stream_errored curl_status error_output
  parse_args "$@"

  base_url="$(resolve_base_url)" || exit 1
  state_dir="$(mktemp -d "${TMPDIR:-/tmp}/resolve-watch-XXXXXX")"

  query=""
  query="$(append_param "$query" "watch_token" "$watch_token")"
  if [[ -n "$investigation_id" ]]; then
    query="$(append_param "$query" "investigation_id" "$investigation_id")"
  fi
  get_query="$query"
  if [[ -n "$message_id" ]]; then
    query="$(append_param "$query" "messageId" "$message_id")"
  fi

  get_url="${base_url}/api/resolve-mcp/v2/chats/$(url_encode "$chat_id")?${get_query}"
  stream_url="${base_url}/api/resolve-mcp/v2/chats/$(url_encode "$chat_id")/stream?${query}"

  printf 'resolve-watch: streaming %s/api/resolve-mcp/v2/chats/%s/stream\n' "$base_url" "$(url_encode "$chat_id")" >&2
  printf 'state_dir=%s\n' "$state_dir" >&2
  printf 'resolve-watch: state at %s/state.json\n' "$state_dir" >&2

  if ! error_output="$(write_state_from_url "$get_url" "$state_dir" 2>&1)"; then
    printf 'resolve-watch: initial get_chat failed: %s (continuing)\n' "$error_output" >&2
  fi

  exit_code=0
  stream_errored=0
  curl -sS -L -N -f -H 'Accept: text/event-stream' "$stream_url"
  curl_status=$?
  if [[ "$curl_status" -ne 0 ]]; then
    printf 'resolve-watch: stream error: curl exited with status %s\n' "$curl_status" >&2
    stream_errored=1
    exit_code=1
  fi

  if ! error_output="$(write_state_from_url "$get_url" "$state_dir" 2>&1)"; then
    printf 'resolve-watch: final get_chat failed: %s\n' "$error_output" >&2
    if [[ "$stream_errored" -eq 0 ]]; then
      exit_code=1
    fi
  elif [[ "$stream_errored" -eq 0 ]] && top_level_status_is_errored "${state_dir}/state.json"; then
    exit_code=1
  fi

  exit "$exit_code"
}

usage() {
  printf '%s\n' "Usage: resolve-watch.sh <chat_id> --watch-token <token> [--investigation <id>] [--message-id <id>]" >&2
  printf '%s\n' "The watch token is returned by \`ask\` (no API key)." >&2
  exit 2
}

parse_args() {
  [[ $# -gt 0 ]] || usage
  chat_id="$1"
  shift
  [[ -n "$chat_id" && "$chat_id" != --* ]] || usage

  investigation_id=""
  message_id=""
  watch_token=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --investigation)
        shift
        [[ $# -gt 0 && -n "$1" ]] || usage
        investigation_id="$1"
        ;;
      --message-id)
        shift
        [[ $# -gt 0 && -n "$1" ]] || usage
        message_id="$1"
        ;;
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
    printf 'resolve-watch: %s is missing\n' "$CONFIG_PATH" >&2
    exit 1
  fi
  raw="$(tr -d '\n' < "$CONFIG_PATH")"
  base_url="$(printf '%s' "$raw" | sed -n 's/.*"baseUrl"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  if [[ -z "$base_url" ]]; then
    printf 'resolve-watch: %s is missing a string "baseUrl" field\n' "$CONFIG_PATH" >&2
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

write_state_from_url() {
  local url="$1"
  local state_dir="$2"
  local body_path status final_path curl_status
  body_path="${state_dir}/state.json.body.$$"
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
  mv "$body_path" "$final_path"
}

top_level_status_is_errored() {
  local json_path="$1"
  awk '
    BEGIN {
      depth = 0
      in_string = 0
      escape = 0
      expect = ""
      key = ""
      str = ""
      string_depth = 0
      found = 0
    }
    {
      for (i = 1; i <= length($0); i++) {
        ch = substr($0, i, 1)
        if (in_string) {
          if (escape) {
            str = str ch
            escape = 0
            continue
          }
          if (ch == "\\") {
            escape = 1
            continue
          }
          if (ch == "\"") {
            in_string = 0
            if (string_depth == 1) {
              if (expect == "key") {
                key = str
                expect = "colon"
              } else if (expect == "value" && key == "status") {
                found = str == "errored" ? 1 : -1
                exit
              }
            }
            continue
          }
          str = str ch
          continue
        }

        if (ch == "\"") {
          in_string = 1
          escape = 0
          str = ""
          string_depth = depth
        } else if (ch == "{" || ch == "[") {
          depth++
          if (depth == 1 && ch == "{") expect = "key"
        } else if (ch == "}" || ch == "]") {
          depth--
        } else if (depth == 1 && ch == ":" && expect == "colon") {
          expect = "value"
        } else if (depth == 1 && ch == ",") {
          key = ""
          expect = "key"
        }
      }
    }
    END { exit found == 1 ? 0 : 1 }
  ' "$json_path"
}

main "$@"
