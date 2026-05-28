---
name: overview
description: Get the big-picture view across all of Resolve — open investigations, recent alerts, in-flight chats. The zoomed-out workspace view, distinct from drilling into one investigation or chat. Use when the user asks "what's going on in Resolve", "any active investigations", "show me alerts", "recent chats with Resolve", "what investigations are open", or wants a snapshot of recent Resolve activity.
version: 0.1.0
---

# Resolve Overview

Show the user the big-picture view of what's happening across Resolve.

## Tools to call

- `list_chats(investigation_id?)` — chats in flight (status: running/complete/errored). Pass an `investigation_id` if the user is focused on one; otherwise lists their recent standalone chats.
- `list_investigations` — active investigations across the user's team with status/phase/severity.
- `list_alerts` — recently-firing alerts.

## Workflow

1. Call all three tools in a single parallel batch — they're independent, so don't wait for one before firing the next. Pass scope when the user has expressed one (e.g., they mentioned a specific investigation).
2. Summarize in three sections — Investigations, Alerts, Chats — each with a count and one line per item carrying the fields that matter (e.g. investigations: title · phase · severity · URL; alerts: title · severity · whether auto-investigating · URL; chats: name · status · last updated). Keep each line tight, but don't collapse the list into bare counts — the user is scanning for which items need attention.
