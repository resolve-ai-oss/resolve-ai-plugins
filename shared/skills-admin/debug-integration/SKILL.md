---
# Copyright 2026 Cloud Data Labs, Inc.
# SPDX-License-Identifier: Apache-2.0
name: debug-integration
description: Figure out why a Resolve integration is failing or quiet, or explain what its settings do. Use when the user mentions a Resolve integration failing or wants to understand its configuration — phrases like "debug my <X> integration", "what's wrong with my Datadog", "why is my Tempo quiet", "my satellite isn't sending data", "explain the fields on my Grafana integration", or "what does <field> do on my <integration>". Read-only.
version: 0.1.0
argument-hint: <integration-name or question>
license: Apache-2.0
---

# Debug a Resolve integration

Use when the user wants Resolve to diagnose or explain one of their integrations. The Resolve agent has internal tools to list integrations, load schema + redacted values + last health check + satellite scope, and (for satellite-backed integrations) read pod logs scoped to the right namespace.

This skill is read-only. To create or mutate integrations, see `resolve-admin:create-integration`. To edit satellite Helm values, see `resolve-admin:satellite-configs`.

## Arguments

If `$ARGUMENTS` is non-empty, treat it as the user's question and proceed.

If `$ARGUMENTS` is empty (skill invoked without a clear question), ask the user once what's wrong with which integration. Treat their next reply as the base message.

## Composing the ask

Compose one message for `resolve:ask`. The agent will discover the target integration internally (`list_integrations` → `get_integration_details`) and invoke its own integration-debug skill to apply the diagnostic discipline (kubectl scoping rules, structured output formats).

You don't need to specify the integration instance id — describing the integration by name and symptom is sufficient. The agent will resolve which instance the user means.

Enrich the base message with conversation context **that directly supports debugging this integration**. Be ruthlessly selective:

- Error messages, log lines, or stack traces the user has shown that name the symptom
- Recent changes (deploys, config edits) that might be tied to the failure
- Health-check output the user pasted, if any

Format the enriched message as the user's question first, then a brief `## Local context` block with only the relevant items. Hand that single composed message to `resolve:ask`; it owns sending, scoping, streaming, and canvas URL handling.

## After asking

Once `resolve:ask` has produced its streamed or settled answer, expect a **Mode A 4-block diagnosis** (starts with `**What's failing:**` and includes Evidence / Likely cause / Suggested next step) when the user asked about a failure, or a **Mode B field tour** when they asked about config fields. Surface this verbatim — don't paraphrase the structured blocks.

## Out of scope for this skill

- **Creating** an integration → `resolve-admin:create-integration`.
- **Editing** an integration's connection config → currently the REST API (see `resolve-admin:create-integration` for the link) or the Resolve UI. Agent-mediated updates are not yet supported.
- **Editing satellite Helm values** → `resolve-admin:satellite-configs`.
- **Investigating production incidents** that aren't specifically about an integration → Resolve's investigate workflow (the `resolve` plugin, if installed).

If the user's question doesn't fit integration debugging, redirect to the right skill and stop.
