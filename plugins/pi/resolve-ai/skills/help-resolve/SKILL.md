---
# Copyright 2026 Resolve AI, Inc.
# SPDX-License-Identifier: Apache-2.0
name: help-resolve
description: Introduce Resolve (the AI DevOps investigation platform) and route the user to the right next step — investigate, ask, apply a fix, or get an overview. Use when the user mentions "Resolve", "resolve.ai", asks "what is Resolve" or "how do I use Resolve", pastes a Resolve URL, or describes a production incident or active investigation they want Resolve to help with.
version: 0.1.0
license: Apache-2.0
---

# Resolve

Resolve (resolve.ai) is an AI DevOps investigation platform. It runs structured RCAs on production incidents, surfaces alert correlations, builds theory cards with citations, and lets you chat with the investigation as it works.

When the user mentions production incidents, alerts, active investigations, or asks about Resolve, this skill engages. From here:

- User pasted a Resolve URL or named an investigation → `resolve-ai:investigate` to load and summarize it.
- User described a problem with no existing URL → `resolve-ai:investigate` to compose a prompt and (with confirmation) kick off a new investigation.
- User wants to translate findings to local code changes → `resolve-ai:apply-fix`.

## Response Style

Preserve `[label](path)` markdown citations verbatim — they're paths the user can drill into via `read_file`. Always surface canvas URLs. Keep replies concise; let the user drive depth.
