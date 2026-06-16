---
# Copyright 2026 Resolve AI, Inc.
# SPDX-License-Identifier: Apache-2.0
name: satellite-configs
description: Edit a Resolve satellite's Helm values.yaml — add or modify integrations on the satellite, configure networking, set environment variables. Use when the user mentions editing satellite config — phrases like "edit satellite values.yaml", "add Tempo to my satellite", "configure satellite networking", "satellite chart values", "satellite helm config", or "wire up a satellite integration".
version: 0.1.0
argument-hint: <task-description>
license: Apache-2.0
---

# Edit satellite Helm values

Resolve satellites run in the customer's Kubernetes cluster. Their configuration lives in a Helm `values.yaml` the customer owns. This skill helps the user edit that file correctly — for adding integrations, configuring networking, or tuning resource settings.

This is a **local-file-editing** skill — it doesn't call Resolve MCP tools. The flow is:

1. Find the `values.yaml` (typically `helm/values/satellite/<env>/values.yaml` in the customer's infra repo, or wherever they manage their Helm releases).
2. Make the edit.
3. Apply via `helm upgrade` (the user handles deploy — you don't run it).
4. Verify the satellite picks up the change by asking Resolve (`resolve-ai-admin:debug-integration`) to inspect the satellite-backed integration.

## Arguments

If `$ARGUMENTS` is non-empty, treat it as the task description and proceed.

If `$ARGUMENTS` is empty, ask the user what they want to change. Treat their next reply as the input.

## Common edits

### Adding a satellite-backed integration

Satellite integrations live under the `integrations:` block in the values.yaml. Pattern:

```yaml
integrations:
  <integration-key>:
    type: <integration-key>
    create: true
    connection:
      url: <url>
      # ... other fields per the integration's connection schema
```

To learn the exact `connection` schema for a given integration, ask Resolve via `resolve-ai:ask` ("What fields does the Tempo connection schema require?"). The agent will return the schema with field descriptions.

For integration keys + example shapes, see the auto-generated catalog at `docs/Integrations.md` in the devops-copilot repo (or the customer-facing equivalent).

### Configuring satellite networking

Satellite pods need to reach (a) Resolve cloud and (b) the customer's internal services (their Grafana, their Prometheus, etc.). Common knobs:

- `satellite.proxy.*` — outbound HTTP proxy if the customer requires one for egress
- `satellite.tls.*` — custom CA bundle for internal HTTPS endpoints with private certs
- `satellite.networkPolicy.*` — NetworkPolicies allowing the satellite namespace to reach customer-side services

Confirm specifics by asking Resolve via `resolve-ai:ask` ("What proxy/TLS knobs does the satellite chart support?") — the agent has the chart's schema.

### Setting environment-specific overrides

Use per-environment values files (`helm/values/satellite/<env>/values.yaml`) and apply with `helm upgrade --values <env>/values.yaml`.

## Workflow

1. **Locate** the values.yaml in the user's repo (use `Read`, `Grep`, `Glob`).
2. **Read** the current state before editing — show the user what's there.
3. **Propose** the edit as a diff. Don't apply blindly; let the user confirm.
4. **Apply** the edit via `Edit` once confirmed.
5. **Hand off** to the user for `helm upgrade` (they own the deploy step).
6. **Verify** post-deploy by handing off to `resolve-ai-admin:debug-integration` to inspect the resulting integration.

## Out of scope

- **Creating SaaS (direct-to-cloud) integrations** → `resolve-ai-admin:create-integration` (uses REST API, not satellite values).
- **Diagnosing a failing satellite integration** → `resolve-ai-admin:debug-integration` (uses Resolve's agent with satellite log access).
- **Running `helm upgrade`** — that's the user's responsibility. You propose the edit; they deploy.
- **Editing Resolve's hosted infrastructure** — the satellite chart is the customer's; you're editing their files, not Resolve's.

If the user wants to _create_ an integration and isn't sure whether it goes via values.yaml or REST, hand off to `resolve-ai-admin:create-integration` to disambiguate.
