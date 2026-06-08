<!--
Copyright 2026 Cloud Data Labs, Inc.
SPDX-License-Identifier: Apache-2.0
-->

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

Plus the underlying MCP tools (`get_investigation`, `start_investigation`, `ask`, `get_chat`, `list_chats`, `steer_investigation`, `read_file`, …). Tools that follow live progress return a self-contained `curl` as `stream_command` in their response — the host agent runs it to stream an investigation's trace (theory cards + evidence trail + phase) or a chat to completion. No bundled watcher binaries.

## Prerequisites

- A Claude Code or Codex install
- A Resolve API token (see [Authentication](#authentication))

## Configuration

Set the `url` field in the `.mcp.json` for whichever host you use to `<your-resolve-host>/mcp/v2`:

- Claude Code: `claude-code-plugin/.mcp.json`
- Codex: `codex-plugin/.mcp.json`

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

The MCP transport authenticates with **OAuth** — on first connect the host (Claude Code / Codex) runs OAuth discovery against the Resolve deployment in the host's `.mcp.json` and prompts you to sign in. No API key to generate or export. Identity and scoping come from that sign-in.

## Following live progress

`ask`, `start_investigation`, and `steer_investigation` are long-running. Each returns a `stream_command` — a self-contained `curl` against the Resolve stream endpoint — which the host agent runs as a background process to follow the reply or the investigation's live trace (theory cards, evidence trail, phase) to completion. The server owns termination: an investigation stream follows until `CONCLUDED` (plus a short linger for the trailing finalize pass), a 1-hour hard cap, or disconnect. The command carries a short-lived, scoped watch token, so no API key is needed.
