---
name: investigations
description: List recent Resolve investigations. Use when the user asks "show me investigations", "list my team's investigations", "investigations from last week", "what auto-investigations ran today", "any manual investigations this month", or wants a focused investigations view (separate from a full overview snapshot).
version: 0.1.0
argument-hint: <optional filter description>
---

# List Resolve Investigations

Wraps `list_investigations`.

## Arguments

If `$ARGUMENTS` is non-empty, parse it into filter intent and call `list_investigations` with what you extract.

If `$ARGUMENTS` is empty, call `list_investigations` with no parameters (defaults to last 24h, no filters, limit 50). Only ask the user to narrow if the result set is overwhelming.

## Filter surface

Map common phrasings to these parameters:

- **`time_range`** — `last_24h` (default) / `last_7d` / `last_30d` / `custom`. For `custom`, pass `from_iso` (required, ISO 8601) and optionally `to_iso` (defaults to now). Use this when the user says "last week", "this month", a specific date range, etc.
- **`team_id`** — scope to a specific team. Omit for the caller's full org.
- **`run_type`** — `AUTO` (alert-triggered) or `MANUAL` (human-started). Use when the user distinguishes "auto-investigations" vs "investigations I/we started".
- **`use_case`** — `ALERT` / `CHAT_INVESTIGATION` / `INCIDENT`. Use when the user references the source: "investigations from alerts", "chat-started ones", "incidents".
- **`triage_only: true`** — return only investigations running in triage-only mode.
- **`limit`** — default 50, hard ceiling 500.

Filters compose with AND semantics. Results come sorted newest-first by `created_at`.

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
- "What chats are in flight?" — `list_chats` directly, or `resolve:overview` for the unified view.
