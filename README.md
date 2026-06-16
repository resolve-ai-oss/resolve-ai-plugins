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
  AI agents that run your software, so your engineers can get back to building — now inside Claude Code, Codex, and Cursor.
</p>

---

Resolve is an AI SRE for production. Its agents join every on-call rotation to triage and investigate alerts, work alongside your engineers to get to root cause and fix, and capture the tribal knowledge of your systems along the way — trusted by world-class engineering teams to drive up to **5× faster MTTR**.

This plugin brings that into your coding agent over MCP: open and steer investigations, ask follow-up questions, pull production context, and turn root-cause findings into pull requests without leaving your editor.

```text
https://app0.resolve.ai/mcp/v2
```

## Contents

- [What It Does](#what-it-does)
- [Install](#install)
- [Skills](#skills)
- [Admin Plugin](#admin-plugin)
- [Authentication](#authentication)
- [Migrating from v1](#migrating-from-v1)
- [Live Progress](#live-progress)
- [FAQ](#faq)

## What It Does

Ask your agent to:

```text
Show me recent Resolve investigations.
```

```text
Summarize this investigation: https://app0.resolve.ai/chat/<investigation_id>
```

```text
Ask Resolve what changed around the latency alert.
```

```text
Apply the fix from this Resolve RCA.
```

The plugin gives your agent Resolve tools for listing alerts, reading investigations, starting new RCAs, following live progress, asking questions, steering active investigations, reading cited files, and submitting feedback.

## Install

### Claude Code

```text
/plugin marketplace add resolve-ai-oss/resolve-ai-plugins
/plugin install resolve-ai@resolve-ai-plugins
```

Restart Claude Code after installation. `/mcp` should show `resolve` connected.

### Codex

```sh
codex plugin marketplace add resolve-ai-oss/resolve-ai-plugins
codex
```

Open `/plugins`, select the Resolve AI marketplace, and install `resolve-ai`. Restart Codex after installation.

### Cursor

Cursor support is still being tested; treat these steps as the intended install path until marketplace distribution is fully validated.

1. In the Cursor Dashboard, open Plugins and add a team marketplace.
2. Import this repository:

   ```text
   https://github.com/resolve-ai-oss/resolve-ai-plugins
   ```

   Cursor reads `.cursor-plugin/marketplace.json`, which exposes both `resolve-ai` and `resolve-ai-admin`.

3. Assign the marketplace to the right distribution groups, then install `resolve-ai` from Cursor's marketplace panel. Restart Cursor — the `resolve` MCP server should appear in Settings → MCP.

For local testing before marketplace distribution, clone the repository and symlink the Cursor plugin directories into `~/.cursor/plugins/local`, then restart Cursor.

Cursor MCP install links and `cursor --add-mcp` install only an MCP server definition, not Resolve's skills — use the plugin marketplace for the full plugin. To re-discover new plugins added to the repository later, re-import the repository URL.

## Skills

| Skill            | Use it for                                                                                           |
| ---------------- | ---------------------------------------------------------------------------------------------------- |
| `alerts`         | List and filter firing alerts by team, time range, label, severity, or auto-investigation status.    |
| `ask`            | Ask Resolve a question, either in a new chat or as a follow-up to an existing chat or investigation. |
| `apply-fix`      | Translate Resolve's root-cause findings into local code changes and a PR.                            |
| `chats`          | List recent Resolve chats and see which ones are still running.                                      |
| `demo`           | Run a guided tour of Resolve using live data from the connected org.                                 |
| `help-resolve`   | Explain Resolve and route the user to the right workflow.                                            |
| `investigate`    | Open an existing Resolve investigation or start a new RCA from a problem description.                |
| `investigations` | List and filter recent investigations by team, run type, use case, and time range.                   |
| `overview`       | Get a compact snapshot of investigations, alerts, and chats.                                         |
| `prod-context`   | Pull production context before implementing a risky code, infra, config, or migration change.        |
| `steer`          | Send a finding, hypothesis, or directive into an active Resolve investigation.                       |

The underlying MCP tools include `get_investigation`, `start_investigation`, `ask`, `get_chat`, `list_chats`, `list_investigations`, `list_alerts`, `steer_investigation`, `read_file`, `create_attachment_upload`, and `submit_feedback`.

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

## Authentication

The MCP transport uses OAuth. On first connect, Claude Code, Codex, or Cursor discovers Resolve OAuth from `https://app0.resolve.ai/mcp/v2` and prompts you to sign in.

You do not need to generate or export `RESOLVE_API_KEY` for normal plugin usage. Identity and access scope come from the OAuth sign-in.

Cursor uses a fixed OAuth callback for all MCP servers:

```text
cursor://anysphere.cursor-mcp/oauth/callback
```

If a Resolve deployment whitelists redirect URIs instead of relying only on Dynamic Client Registration, that callback must be registered on the Resolve OAuth app.

## Migrating from v1

Resolve's MCP moved to the `/mcp/v2` endpoint, with OAuth and the plugin experience above. How you migrate depends on your client.

### Claude Code, Codex, or Cursor

Remove your old manually configured Resolve MCP server, then install the plugin as shown in [Install](#install). The plugin already targets `/mcp/v2` and signs you in via OAuth, so you don't configure a URL by hand. Delete your old MCP key or token from wherever you set it — an old MCP server entry, or `RESOLVE_API_KEY` in your shell profile — since normal plugin usage no longer needs it. Restart your host so it reloads the MCP server definition.

### Other MCP clients (Devin, Gemini CLI, Antigravity, …)

These clients connect to Resolve directly without the plugin. Point your client's MCP configuration at:

```text
https://app0.resolve.ai/mcp/v2
```

They don't run the plugin's OAuth flow, so keep authenticating with your existing `RESOLVE_API_KEY`. You get the same Resolve MCP tools, but the bundled skills aren't installed for you — copy the skill files you want from this repository's `claude-code-plugin/skills/` directory (they're plain Markdown) into whatever instructions or skills mechanism your client supports. If you have workflows hardcoded to v1 tool names, update them to the tool names the server advertises after you connect.

### REST API only

If you only call the Resolve REST API and don't use MCP, nothing changes.

## Live Progress

Some Resolve operations are long-running. `ask`, `start_investigation`, and `steer_investigation` may return a `stream_command`, which is a self-contained `curl` command for following live progress.

The host agent runs that command in the background and reads stdout until the operation completes. The command carries a short-lived scoped watch token, so no API key is needed.

## FAQ

### How do I generate a Resolve API key?

If you use the plugin in Claude Code, Codex, or Cursor, you don't need one — sign-in is handled by OAuth (see [Authentication](#authentication)), and normal plugin usage never needs an API key.

For MCP-only clients or direct REST API access, create a personal API token in Resolve:

1. Sign in to Resolve and open **Personal API Tokens** at `https://app0.resolve.ai/personal-tokens`.
2. Click **Create Personal Token** and copy the value — it's shown only once, so if you lose it you'll need to generate a new one.

Use that token as your `RESOLVE_API_KEY`.

### Do I need to clone the repo?

No for Codex and Claude Code — both add the GitHub marketplace directly. For Cursor, no-clone install requires the public Cursor Marketplace or a team/private marketplace; local testing still uses a checkout.

### Does `resolve-ai-admin` replace `resolve-ai`?

No. `resolve-ai-admin` is optional and requires `resolve-ai` to be installed alongside it.
