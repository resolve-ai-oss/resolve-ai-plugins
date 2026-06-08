---
# Copyright 2026 Cloud Data Labs, Inc.
# SPDX-License-Identifier: Apache-2.0
name: create-integration
description: Connect a new data source (Datadog, Grafana, Prometheus, …) to Resolve. Use when the user wants to add a data source to Resolve — phrases like "create a Datadog integration", "set up Grafana in Resolve", "add a new integration", "connect Prometheus to Resolve", "configure SaaS integration", or "wire up <X>". Walks the user through the right path (SaaS REST API, satellite, or dedicated UI flow) for the integration they want.
version: 0.1.0
argument-hint: <integration-name>
license: Apache-2.0
---

# Create a Resolve integration

Use when the user wants to add a new integration instance. There are three paths, and the right one depends on what kind of integration:

| Integration type                                                                       | Path                                                                    |
| -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| **Direct-to-cloud SaaS** (Datadog, Grafana Cloud, New Relic, AWS, etc.)                | Resolve REST API or UI                                                  |
| **Satellite-backed** (Tempo, Loki, Prometheus on a satellite, etc.)                    | Edit the satellite's Helm values.yaml — see `resolve:satellite-configs` |
| **OAuth / app-install** (Slack, MS Teams, GitHub, GitHub Enterprise, MCP integrations) | Dedicated UI flow in the Resolve console                                |

The agent **cannot** create the integration for the user directly (no agent-mediated CRUD yet). This skill's job is to identify the right path and point the user at it.

## Arguments

If `$ARGUMENTS` is non-empty, treat it as the integration name or type and route immediately.

If `$ARGUMENTS` is empty, ask the user which integration they want to set up. Treat their next reply as the input.

## Routing

### Step 1 — Identify the integration class

If you're not sure which class the integration falls into, ask Resolve with `resolve:ask` ("Is the <X> integration direct-to-cloud, satellite-backed, or OAuth-flow?"). The agent can answer from its knowledge of Resolve's integration catalog.

### Step 2 — Pick the right path

**Direct-to-cloud SaaS:** Use the REST API at `/api/v1/integrations` (gated per-org by `integrations_api_enabled`). Example:

```bash
curl -sS -X POST https://<your-resolve-host>/api/v1/integrations \
  -H "Authorization: Bearer $RESOLVE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "integrationKey": "<key>",
    "name": "<name>",
    "connection": { ... }
  }' | jq .
```

The exact `connection` schema depends on the integration. To learn it, ask Resolve via `resolve:ask` ("What fields does the Datadog connection schema require?") — the agent will load the schema for you. Encrypted fields (apiKey, password, etc.) will be redacted on subsequent reads.

**Satellite-backed:** Hand off to `resolve:satellite-configs`. Integrations like Tempo, Loki, Prometheus, Kubernetes, DNS-tap, and Temporal must be created from a running satellite, not via REST.

**OAuth / app-install:** Tell the user to use the Resolve UI:

- Slack / MS Teams → Resolve console → Integrations → Add → choose the app and complete the OAuth handshake.
- GitHub / GitHub Enterprise → install the Resolve GitHub App via the UI.
- `mcp*` integrations (MCP-flavored Resolve connectors) → use their dedicated setup flow in the UI.

These can't be created via REST because they need token exchange or app-installation handshakes.

### Step 3 — Verify after creating

Once the integration is created, hand off to `resolve:debug-integration` and prompt the user to run a health check ("ask Resolve to debug my <X> integration"). Mode A diagnosis will confirm whether the connection is healthy.

## Out of scope

- **Editing an existing instance's connection** — currently REST `PATCH /api/v1/integrations/:id`. Agent-mediated updates are not yet supported.
- **Removing an integration** — REST `DELETE /api/v1/integrations/:id` (soft delete). Agent-mediated deletes are not yet supported.
- **Investigating a misconfigured integration** → `resolve:debug-integration`.
