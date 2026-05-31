---
name: investigate
description: Have Resolve run a root-cause investigation — open an existing canvas, or start a new one. Use when the user pastes a Resolve URL, names an investigation ID, references an alert, or describes a problem — phrases like "investigate X", "look into Y", "have Resolve check Z", "start an investigation", "rca this", or "root cause this".
version: 0.1.0
argument-hint: <resolve-url | investigation-id | problem-description>
---

# Investigate with Resolve

Opens an existing investigation, or starts a new one after first discovering whether Resolve is already working on the same thing. **Starting a new investigation kicks off a real run — always confirm explicitly with the user before doing so.**

## Arguments

If `$ARGUMENTS` is non-empty, treat it as the input and route immediately (see below).

If `$ARGUMENTS` is empty, ask the user what they want to investigate (a URL, an ID, or a problem description). Treat their next reply as the input.

## Routing

**Path A — Input is a Resolve URL or canvas ID** (URLs follow `<your-resolve-host>/chat/<id>`; the ID is the last path segment, or the user may give you just the ID directly).

1. Extract the canvas ID.
2. Call `get_investigation`.
3. Summarize state for the user: status, phase, top theories, alerts. Include the canvas URL.
4. Drill into specific theories, the report, or evidence via `read_file` when the user asks.

No confirmation needed — this path is read-only.

**Path B — Input is a free-form problem description** (e.g. "frontend is slow", "DB queries timing out", an alert name).

Before starting fresh, **always check whether Resolve is already working on this**.

1. **Discover existing candidates first.** If recent `list_alerts` / `list_investigations` output is already in the conversation (e.g. from a prior `overview`, `alerts`, or `investigations` call), reuse it — do not re-fetch. Otherwise call those tools for recent activity. Either way, match the returned items against the user's input locally (by title, alert rule, labels, and recency) to find anything Resolve is already working on. Read-only — costs nothing and prevents duplicating in-flight work.
2. **If candidates exist**, surface the top matches with their canvas URLs and ask the user: "Open one of these, or start a new investigation?" Wait for an explicit answer. If they pick one, switch to Path A on that ID. Otherwise fall through.
3. **Compose the investigation prompt.** Resolve is starting from a blank slate — include grounded context generously. Better to over-include than under-include:
   - File paths, services, components, or subsystems the user pointed at
   - Error messages, log lines, stack traces, exception types (paste them verbatim)
   - Symptoms: what's broken, who's affected, when it started, what changed recently
   - Git context (branch, recent commits, working changes) when the issue may be tied to a local change
   - URLs the user referenced (Slack threads, dashboards, alert pages, related canvases)
   - Suspected causes, hypotheses, or ruled-out paths the user has already explored
   - Reproduction steps, environment details, or scope (single user vs widespread)

   Format as markdown with clear sections (e.g. `## Symptom`, `## What I've checked`, `## Suspected area`) — the prompt seeds the investigation, so structure helps Resolve route to the right agents.

4. **Confirmation gate (required).** Show the user the composed prompt and ask explicitly: "Start a new investigation with this?" Wait for an unambiguous yes. Do not proceed on tacit agreement, silence, or "go ahead" inferred from earlier turns.
5. Only on explicit yes, call `start_investigation`.
6. Surface the returned canvas URL.

After either path you're engaged with that investigation. Subsequent follow-ups use `ask`.

## Following the investigation live (optional)

`start_investigation` — and `get_investigation` on a still-running investigation — return a ready-to-run `stream_command`: a self-contained `curl` that streams the investigation's live trace (theory-card updates, evidence-trail entries, phase changes) to stdout. When the user wants to follow progress, run that `stream_command` as a long-running background process (Claude Code: `Bash` with run_in_background; Codex: a long-running `exec_command`, not shell backgrounding). It needs only `curl` — no bundled binary. If the connection drops before the investigation concludes, just re-run it to resume. For the condensed final state, call `get_investigation` on a later turn.
