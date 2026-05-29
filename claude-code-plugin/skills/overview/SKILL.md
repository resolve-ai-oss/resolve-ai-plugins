---
name: overview
description: Get the big-picture view across all of Resolve — open investigations, recent alerts, in-flight chats. Not for the status of a single investigation or chat.
version: 0.1.0
---

# Resolve Overview

## Tools

- `list_investigations`
- `list_alerts`
- `list_chats`

Fire in parallel. Don't infer scope from prior turns — overview means org-wide unless the user is explicit about narrowing.

## Output

Three sections — Investigations, Alerts, Chats — each with a count and one tight line per item carrying the fields that matter (title/name · status/phase · severity · URL).

## Handoffs

- Specific investigation → `resolve:investigate <id>`.
- Specific chat → `get_chat` with the `chat_id`.
- Just alerts → `resolve:alerts`. Just investigations → `resolve:investigations`. Just chats → `resolve:chats`.
