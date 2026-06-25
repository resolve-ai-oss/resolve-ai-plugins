---
# Copyright 2026 Resolve AI, Inc.
# SPDX-License-Identifier: Apache-2.0
name: create-skill
description: Write or tune a skill for the Resolve plugin — encoding workflow guidance, not tool API details.
version: 0.1.0
license: Apache-2.0
---

# Write or Tune a Plugin Skill

**New skill** — draft a `SKILL.md` for the workflow the user describes.

**Tuning an existing skill** — read the skill the user points at, apply the boundary rules below, and trim anything that belongs in a tool description instead.

## Before writing

1. **Read the relevant Resolve MCP tool descriptions** — know exactly what each tool already documents so you don't repeat it in the skill.
2. **Read all the existing skills from this plugin** — know what's already covered so you hand off rather than duplicate.

## What does NOT go in a skill

**Don't repeat tool descriptions** for any tools the skill uses — Resolve MCP, Grafana, Slack, or anything else. Anything the tool description already says stays there:

- Parameter names, enums, defaults, or limits.
- Stream semantics or protocol details.

**Don't repeat other skills.** If the workflow needs to query Resolve or continue a conversation, hand off to `resolve-ai:ask` rather than re-describing how it works. Skills compose; they don't duplicate.
