---
# Copyright 2026 Cloud Data Labs, Inc.
# SPDX-License-Identifier: Apache-2.0
name: investigations
description: List recent Resolve investigations. Use when the user asks "show me investigations", "list my team's investigations", "investigations from last week", "what auto-investigations ran today", "any manual investigations this month", or wants a focused investigations view (separate from a full overview snapshot).
version: 0.1.0
argument-hint: <optional filter description>
license: Apache-2.0
---

# List Resolve Investigations

Wraps `list_investigations`.

## Arguments

If `$ARGUMENTS` is non-empty, translate it into `list_investigations` filters.

If `$ARGUMENTS` is empty, call `list_investigations` with the tool defaults. Only ask the user to narrow if the result set is overwhelming.

## Filter Intent

Map common phrasings to the right filter family:

- **Time** — "today", "last week", explicit date ranges, or "since deploy".
- **Ownership** — team, service, or alert context.
- **Run origin** — auto-investigations vs human-started investigations.
- **Source** — alert-driven, chat-started, incident, or triage-only.
- **Volume** — use a limit when the user asks for "top", "latest N", or a short list.

## Output

Summarize compactly:

- Count + the time range covered.
- Per-investigation one-liner: `title`, `phase`, `stop_reason` (if terminal), `run_type`, `use_case`, `team`, primary alert summary if present, `created_at`, and the canvas URL (`<your-resolve-host>/chat/<investigation_id>`).
- When the list is long, group by `phase`, `team`, or `run_type` and offer to narrow.
- Always surface canvas URLs — they're the user's drill-in path.
- Preserve any `[label](path)` citations verbatim.

After listing, offer the next step: `resolve:investigate <id>` to load one, or `resolve:ask` if the user wants to follow up on a specific investigation.

## Handoffs

- "Show me everything happening in Resolve" — broader snapshot → `resolve:overview`.
- "Open this one" — drill in → `resolve:investigate <id>`.
- "Show me firing alerts" — alerts-focused view → `resolve:alerts`.
- "What chats are in flight?" — `resolve:chats`, or `resolve:overview` for the unified view.
