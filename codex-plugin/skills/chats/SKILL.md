---
# Copyright 2026 Cloud Data Labs, Inc.
# SPDX-License-Identifier: Apache-2.0
name: chats
description: List recent Resolve chats. Use when the user asks "show me my chats", "what chats are in flight", "any chats running", "chats from last week", or wants a focused chat list (separate from a full overview snapshot).
version: 0.1.0
argument-hint: <optional time range, e.g. "last 7 days">
license: Apache-2.0
---

# List Resolve Chats

Wraps `list_chats`.

## Arguments

If `$ARGUMENTS` is non-empty, parse it into filter intent. Empty → call with defaults.

`list_chats` has no server-side `status` filter. When the user asks for "running" / "in flight" / "errored", fetch and post-filter on `status`.

## Output

- Count + time range covered.
- Status breakdown when informative; surface `running` first — the agent is still working.
- Per-chat one-liner: `name`, `status`, `updated_at`, canvas URL (`<your-resolve-host>/chat/<chat_id>`).
- Preserve `[label](path)` citations verbatim.

## Handoffs

- Read what Resolve said on a chat → `get_chat` with the `chat_id`.
- Send a new message in a chat → `resolve:ask` with the `chat_id`.
- Investigations view → `resolve:investigations`.
- Alerts view → `resolve:alerts`.
