---
# Copyright 2026 Resolve AI, Inc.
# SPDX-License-Identifier: Apache-2.0
name: feedback
description: Send Resolve your feedback — on an investigation's root cause, a chat answer, or the Resolve experience itself. Use when you've resolved or mitigated your issue, an investigation or chat wraps up, or you want to rate or comment on Resolve.
version: 0.1.0
argument-hint: <optional feedback text>
license: Apache-2.0
---

# Submit Feedback to Resolve

Wraps `submit_feedback`. Engage when work wraps up — the user fixed or mitigated the issue, or an investigation or chat concluded — or whenever they explicitly want to rate or comment on Resolve. Offer once; if they pass, drop it.

Route to what they're judging: an **investigation**'s root cause, a **chat** answer, or the **product** / MCP experience itself. If their intent spans more than one, send a separate call per target. Use only IDs returned by Resolve tools.

Two parts, handled differently:

- **Verdict** (good/bad) — the user's own judgment. Never guess or pre-fill it.
- **Note** — draft it from what you observed this session so they don't retype it; never invent diagnostics. If `$ARGUMENTS` is non-empty, use it as the note.

So: with session context, draft the note and ask only for the verdict in one turn. With none, ask briefly what they want to say and what it's about. Then submit, and tell the user in one line what you sent and where.
