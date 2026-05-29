# Resolve Everywhere Plugin

[Resolve](https://resolve.ai) is an AI DevOps investigation platform: structured RCAs on production incidents, alert correlation, theory cards with citations, and chat-driven follow-up. This plugin wires Resolve into Claude Code and Codex over MCP so you can open investigations, ask follow-up questions, apply fixes locally, and steer in-flight investigations without leaving your editor.

## What's included

Eight skills your host agent can engage:

- **investigate** — open an existing investigation or start a new one from a URL, ID, or problem description
- **ask** — send a follow-up question to an active investigation or chat
- **alerts** — list and filter firing alerts (by team, time range, label, auto-investigated, …)
- **investigations** — list and filter recent investigations (by team, time range, run type, use case)
- **overview** — big-picture snapshot of open investigations, recent alerts, and in-flight chats
- **steer** — promote a local finding or directive into an active investigation
- **apply-fix** — translate Resolve's findings into local code edits
- **help-resolve** — intro and routing skill for new users

Plus the underlying MCP tools (`get_investigation`, `start_investigation`, `ask`, `get_chat`, `list_chats`, `steer_investigation`, `read_file`, …), `shared/bin/resolve-watch` for following a Resolve chat to completion asynchronously, and `shared/bin/resolve-watch-investigation` for subscribing to an investigation's live trace stream (theory cards + evidence trail + phase).

## Prerequisites

- Node 20+ on `PATH` (the watcher in `shared/bin/resolve-watch` is a Node script)
- A Claude Code or Codex install
- A Resolve API token (see [Authentication](#authentication))

## Configuration

Two pieces, set once per Resolve deployment:

1. **Host MCP URL.** Set the `url` field in the `.mcp.json` for whichever host you use to `<your-resolve-host>/mcp/v2`:
   - Claude Code: `claude-code-plugin/.mcp.json`
   - Codex: `codex-plugin/.mcp.json`
2. **Watcher base URL.** Set `baseUrl` in `shared/config.json` to the same `<your-resolve-host>`:
   ```json
   { "baseUrl": "https://rocket.resolve.ai" }
   ```
   The watcher reads this to construct its REST calls (`<baseUrl>/api/resolve-mcp/v2/...`, a different path on the same host than the MCP transport).

Restart Claude Code / Codex after editing so it reloads the MCP config.

## Codex

Register this directory as a Codex marketplace and install:

```sh
codex plugin marketplace add <path-to-this-plugin>
# restart Codex, then:
codex plugin install resolve@resolve-everywhere
```

The marketplace appears as `resolve-everywhere`.

## Claude Code

Register this directory as a Claude Code marketplace and install:

```sh
claude plugin marketplace add <path-to-this-plugin> --scope user
claude plugin install resolve@resolve-everywhere
```

Then restart Claude Code. `/mcp` will show `resolve` connected.

## Authentication

The MCP transport authenticates with **OAuth** — on first connect the host (Claude Code / Codex) runs OAuth discovery against the Resolve deployment in `config.json` and prompts you to sign in. No API key to generate or export. Identity and scoping come from that sign-in.

## Watcher

`shared/bin/resolve-watch <chat_id> --watch-token <token>` follows a Resolve chat to completion. It streams Resolve's formatted output to stdout, creates a temporary state directory, prints `state_dir=<path>`, and writes structured snapshots to `<state_dir>/state.json`. It reads its base URL from `config.json` — the same host the MCP server connects to.

The `--watch-token` is the short-lived, chat-scoped token returned by the `ask` tool (`watch_token` / the ready-to-run `watch_command`) — no API key needed. The host agent surfaces the command; you just run it.

## Investigation subscriber

`shared/bin/resolve-watch-investigation <investigation_id> --watch-token <token>` subscribes to an agent-teams investigation's live trace stream — the same data the UI's War Room renders. It streams theory-card updates, evidence-trail entries, and phase changes to stdout, and refreshes a structured `get_investigation` snapshot (report + theory cards + alerts + mitigations + status) to `<state_dir>/state.json` from time to time.

The server owns termination: the subscription follows the investigation until it reaches `CONCLUDED` (plus a short linger to capture the trailing finalize pass), a 1-hour hard cap, or the process disconnects — reconnecting across the upstream's idle gaps in between. The `--watch-token` is the short-lived, investigation-scoped token returned by `start_investigation` / `steer_investigation` (`watch_token` / the ready-to-run `watch_command`) — no API key needed.
