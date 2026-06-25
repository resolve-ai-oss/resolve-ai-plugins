<!--
Copyright 2026 Resolve AI, Inc.
SPDX-License-Identifier: Apache-2.0
-->

<p align="center">
  <img src="./assets/resolve-logo.svg" alt="Resolve logo" width="72" />
</p>

<h1 align="center">Resolve AI</h1>

<p align="center">
  <strong>Machines on call for humans.</strong>
</p>

<p align="center">
  AI agents that run your software, so your engineers can get back to building — now inside Claude Code, Codex, Cursor, and Pi.
</p>

---

Resolve is an AI SRE for production. Its agents join every on-call rotation to triage and investigate alerts, work alongside your engineers to get to root cause and fix, and capture the tribal knowledge of your systems along the way — trusted by world-class engineering teams to drive up to **5× faster MTTR**.

This plugin brings that into your coding agent over MCP: open and steer investigations, ask follow-up questions, pull production context, and turn root-cause findings into pull requests without leaving your editor.

```text
https://app0.resolve.ai/mcp/v2
```

## Contents

- [How It Works](#how-it-works)
- [Install](#install)
- [Migrating from v1](#migrating-from-v1)
- [Authentication](#authentication)
- [Skills](#skills)
- [Live Progress](#live-progress)
- [Admin Plugin](#admin-plugin)
- [FAQ](#faq)

## How It Works

Ask your agent to:

```text
Show me recent Resolve investigations.
Summarize this investigation: https://app0.resolve.ai/chat/<investigation_id>
Ask Resolve what changed around the latency alert.
Apply the fix from this Resolve root-cause analysis.
```

The plugin connects your agent to Resolve over MCP and installs skills for listing alerts, reading investigations, starting new root-cause analyses, following live progress, asking questions, steering active investigations, reading cited files, and submitting feedback.

## Install

### Claude Code

```text
/plugin marketplace add resolve-ai-oss/resolve-ai-plugins
```

```text
/plugin install resolve-ai@resolve-ai-plugins
```

Restart Claude Code after installation. `/mcp` should show `resolve` connected.

### Codex

```sh
codex plugin marketplace add resolve-ai-oss/resolve-ai-plugins
codex plugin add resolve-ai@resolve-ai-plugins
codex mcp login resolve
```

Restart Codex after installation. `/mcp` should show `resolve` connected.

### Cursor

Cursor support is still being tested. Unless you are validating Cursor distribution, use Claude Code or Codex today. Treat these steps as the intended install path once marketplace distribution is fully validated.

1. In the Cursor Dashboard, open Plugins and add a team marketplace.
2. Import this repository:

   ```text
   https://github.com/resolve-ai-oss/resolve-ai-plugins
   ```

   Cursor reads `.cursor-plugin/marketplace.json`, which exposes both `resolve-ai` and `resolve-ai-admin`.

3. Assign the marketplace to the right distribution groups, then install `resolve-ai` from Cursor's marketplace panel. Restart Cursor — the `resolve` MCP server should appear in Settings → MCP.

For local testing before marketplace distribution, clone the repository and symlink the Cursor plugin directories into `~/.cursor/plugins/local`, then restart Cursor.

Cursor MCP install links and `cursor --add-mcp` install only an MCP server definition, not Resolve's skills — use the plugin marketplace for the full plugin. To re-discover new plugins added to the repository later, re-import the repository URL.

### Pi

Pi uses `pi-mcp-adapter` plus a Pi package manifest; it does not read the Claude/Codex/Cursor plugin manifests.

```sh
pi install npm:pi-mcp-adapter
pi install git:github.com/resolve-ai-oss/resolve-ai-plugins
```

`pi install` loads the skills and Pi guidance extension but does **not** merge MCP servers into your Pi config. Add a `resolve` HTTP MCP server pointing at the [Resolve MCP URL](#other-mcp-clients) to your Pi config (`~/.pi/agent/mcp.json`).

Restart Pi, then run `/mcp reconnect resolve` (or ask Pi to connect Resolve); the first connection opens the browser OAuth flow — no API key needed. Resolve skills appear as Pi commands such as `/skill:overview` and `/skill:ask`.

## Migrating from v1

Resolve MCP moved to `/mcp/v2`, with OAuth and the plugin install flow above.

### Claude Code, Codex, or Cursor

If you previously configured Resolve MCP manually:

1. Remove the old Resolve MCP server entry.
2. Remove any old `RESOLVE_API_KEY` from your shell profile or host config.
3. Install `resolve-ai` from the plugin marketplace using [Install](#install).
4. Sign in with OAuth when prompted.
5. Restart your host. `/mcp` should show `resolve` connected.

### Other MCP clients

For MCP clients that do not support this plugin, point the client at:

```text
https://app0.resolve.ai/mcp/v2
```

These clients get the same Resolve MCP tools, but not the bundled plugin skills. Authenticate with a `RESOLVE_API_KEY` ([how to generate one](#how-do-i-generate-a-resolve-api-key)) sent as a bearer token. Most hosts take either a static header or a token env var:

```jsonc
// header-based hosts
"resolve": {
  "type": "http",
  "url": "https://app0.resolve.ai/mcp/v2",
  "headers": { "Authorization": "Bearer ${RESOLVE_API_KEY}" }
}
```

```toml
# Codex-style hosts
[mcp_servers.resolve]
url = "https://app0.resolve.ai/mcp/v2"
bearer_token_env_var = "RESOLVE_API_KEY"
```

```jsonc
// Cursor mcp.json — references env vars as ${env:NAME}, not the bare ${NAME}
"resolve": {
  "type": "http",
  "url": "https://app0.resolve.ai/mcp/v2",
  "headers": { "Authorization": "Bearer ${env:RESOLVE_API_KEY}" }
}
```

### REST API only

If you only call the Resolve REST API and do not use MCP, no action is needed.

## Authentication

The MCP transport uses OAuth. On first connect, Claude Code, Codex, Cursor, or Pi discovers Resolve OAuth from `https://app0.resolve.ai/mcp/v2` and prompts you to sign in.

You do not need to generate or export `RESOLVE_API_KEY` for normal plugin usage. Identity and access scope come from the OAuth sign-in.

Cursor uses a fixed OAuth callback for all MCP servers:

```text
cursor://anysphere.cursor-mcp/oauth/callback
```

If a Resolve deployment whitelists redirect URIs instead of relying only on Dynamic Client Registration, that callback must be registered on the Resolve OAuth app.

## Skills

| Skill            | Use it for                                                                                            |
| ---------------- | ----------------------------------------------------------------------------------------------------- |
| `alerts`         | List and filter firing alerts by team, time range, label, severity, or auto-investigation status.     |
| `ask`            | Ask Resolve a question, either in a new chat or as a follow-up to an existing chat or investigation.  |
| `apply-fix`      | Translate Resolve's root-cause findings into local code changes and a PR.                             |
| `chats`          | List recent Resolve chats and see which ones are still running.                                       |
| `demo`           | Run a guided tour of Resolve using live data from the connected org.                                  |
| `feedback`       | Capture a verdict on an investigation, chat answer, or the product when work wraps up, and submit it. |
| `help-resolve`   | Explain Resolve and route the user to the right workflow.                                             |
| `investigate`    | Open an existing Resolve investigation or start a new RCA from a problem description.                 |
| `investigations` | List and filter recent investigations by team, run type, use case, and time range.                    |
| `overview`       | Get a compact snapshot of investigations, alerts, and chats.                                          |
| `prod-context`   | Pull production context before implementing a risky code, infra, config, or migration change.         |
| `steer`          | Send a finding, hypothesis, or directive into an active Resolve investigation.                        |

The underlying MCP tools include `get_investigation`, `start_investigation`, `ask`, `get_chat`, `list_chats`, `list_investigations`, `list_alerts`, `steer_investigation`, `read_file`, `upload_attachment`, and `submit_feedback`.

## Live Progress

Some Resolve operations are long-running. `ask`, `start_investigation`, and `steer_investigation` may return a `stream_command`, which is a self-contained `curl` command for following live progress.

The host agent runs that command in the background and reads stdout until the operation completes. The command carries a short-lived scoped watch token, so no API key is needed.

## Admin Plugin

This marketplace also ships `resolve-ai-admin`, a companion plugin for administrators who manage Resolve integrations.

| Skill                | Use it for                                                                                                 |
| -------------------- | ---------------------------------------------------------------------------------------------------------- |
| `create-integration` | Route a new data source to the right setup path: SaaS REST API, satellite-backed config, or UI/OAuth flow. |
| `debug-integration`  | Diagnose or explain a failing or quiet integration.                                                        |
| `satellite-configs`  | Edit a satellite Helm `values.yaml` for satellite-backed integrations and networking.                      |

`resolve-ai-admin` has no MCP server of its own. It reuses the `resolve-ai` plugin's `/mcp/v2` connection and hands off to `resolve-ai:ask`, so install `resolve-ai` first.

```text
/plugin install resolve-ai-admin@resolve-ai-plugins
```

For Cursor, install `resolve-ai-admin` from the same team marketplace after `resolve-ai`. Keep it optional unless every developer in the group manages Resolve integrations.

## FAQ

### How do I generate a Resolve API key?

If you use the plugin in Claude Code, Codex, Cursor, or Pi, you don't need one — sign-in is handled by OAuth (see [Authentication](#authentication)), and normal plugin usage never needs an API key.

For MCP-only clients or direct REST API access, create a personal API token in Resolve:

1. Sign in to Resolve and open **Personal API Tokens** at `https://app0.resolve.ai/personal-tokens`.
2. Click **Create Personal Token** and copy the value — it's shown only once, so if you lose it you'll need to generate a new one.

Use that token as your `RESOLVE_API_KEY`.

### Do I need to clone the repo?

No for Codex and Claude Code — both add the GitHub marketplace directly. For Cursor, no-clone install requires the public Cursor Marketplace or a team/private marketplace; local testing still uses a checkout.

### Does `resolve-ai-admin` replace `resolve-ai`?

No. `resolve-ai-admin` is optional and requires `resolve-ai` to be installed alongside it.
