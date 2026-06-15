---
# Copyright 2026 Cloud Data Labs, Inc.
# SPDX-License-Identifier: Apache-2.0
name: demo
description: Run a guided, presenter-led tour of Resolve using the connected org's live data — surface the environment, resume a chat, fire several in parallel, drill a real RCA with its evidence and a live thread, then investigate something from scratch. Use when someone wants to demo Resolve, give a tour, or show a new user what it can do — phrases like "demo Resolve", "give me a tour", "walk them through Resolve", "show me what Resolve can do", "demo this to <person>".
version: 0.1.0
argument-hint: [optional emphasis, or "start"]
license: Apache-2.0
---

# Demo Resolve

A presenter-led, checkpointed walkthrough of Resolve using **the connected org's live data** (assume there's plenty). You drive; the audience watches your screen. The arc escalates:

**surface → resume a chat → many in parallel → drill a real RCA (evidence + live thread) → turn the findings into a code-fix PR → investigate from scratch.**

Every beat stands alone — stop anywhere and it's still a complete demo.

This skill orchestrates with direct tool calls and its own narration. For the streaming beats it follows the `stream_command` streaming already documented in the `ask` and `investigate` skills rather than restating the host-specific mechanics here.

## Arguments

If `$ARGUMENTS` carries an emphasis (e.g. "focus on logs", "keep it short"), bias curation and beat selection toward it. Otherwise run the default arc. Treat a bare `start` as "begin the tour".

## Two run modes

Establish the mode at the start and honor it for **every** command, every beat:

- **Auto** (default — today's behavior): _you_ run each command via the tools, pausing at checkpoints for the presenter's "go" or to let them pick an option.
- **Manual** (hand-me-the-commands): you do **not** execute the beat's action. Compose the **full command with its args/message filled in** and present it for the presenter to type themselves, then **stop and wait** for them to run it before moving on. You may still run read-only setup (e.g. `overview`) so the commands you hand over carry real IDs/values, but every action command (`ask`, `investigate`, `steer`, `apply-fix`) is theirs to enter. Because they're invoking the real skills, those skills' own run/format behavior (streaming, citations, canvas URLs) applies as-is.

Select via `$ARGUMENTS` (`auto` / `manual`); if unset, ask once at pre-flight.

## Two registers in your output

- **Prospect-facing** (plain prose): the lines you screen-share — clean, jargon-light, short.
- **Presenter cue** (prefix `▶`): control prompts addressed to _you_, not the audience. End every beat with a cue that previews exactly what the next step will do, e.g. `▶ Next: open a real RCA and pull the raw telemetry behind its top theory. Say "go", pick from the menu, or tell me what to show.`
- **Command tag** (prefix `▷`): name the command for each beat's capability. In **auto** mode it's just the label, so the audience learns it — `▷ Run it yourself: $resolve-ai:overview`. In **manual** mode it's the _full runnable command with composed args_, and you stop and wait for the presenter to enter it — e.g. `▷ Type this: $resolve-ai:ask Follow-up: of the error spikes in svc-analysis, which one is most worth acting on first?`. Mapping (args from each skill's own `argument-hint`): surface → `$resolve-ai:overview` (focused lists `$resolve-ai:alerts`, `$resolve-ai:investigations`, `$resolve-ai:chats`); resume / ask / thread / parallel → `$resolve-ai:ask <message>`; redirect a live investigation → `$resolve-ai:steer <message>`; drill or start an RCA → `$resolve-ai:investigate <url-or-id | problem>`; apply a fix → `$resolve-ai:apply-fix`.

## Pacing — light checkpoints

Pause only at: the start, the post-overview menu, and before any step that **sends a message or starts an investigation**. Auto-flow narration within a beat. In **auto** mode, never send a chat or start an investigation without an explicit "go" in that same turn; the read-only beats (overview, RCA drill, evidence) need no consent. In **manual** mode you never execute an action yourself — you present the full command and wait for the presenter to run it, which is the natural checkpoint.

## Beats

### 0 · Pre-flight (you only)

On launch, don't address the audience yet. Settle the **run mode** (auto vs manual — ask if `$ARGUMENTS` didn't set it) and lay out the agenda for yourself, then `▶ Mode: <auto|manual>. Share your screen, then say "start".` Wait.

### 1 · Orient — what Resolve is (prospect-facing)

One breath on Resolve: it's an AI SRE for your production incidents. Start with the big picture, then the two primitives everything centers on.

**The big picture** — `$resolve-ai:overview` shows investigations, recent alerts, and in-flight chats at a glance. (`$resolve-ai:alerts` for just the firing feed that auto-triggers investigations; `$resolve-ai:help-resolve` to get oriented.)

**Investigations** — structured root-cause workspaces (theories, cited evidence, mitigations, tied to the triggering alert):

- `$resolve-ai:investigate` — open an existing RCA or start a new one
- `$resolve-ai:investigations` — list recent investigations
- `$resolve-ai:ask` — ask a question or open a thread on an investigation
- `$resolve-ai:steer` — redirect a running investigation with a new finding
- `$resolve-ai:apply-fix` — turn its findings into a code change, right here

**Chats** — standalone conversations with Resolve — ask anything about your environment:

- `$resolve-ai:ask` — start or continue a standalone chat
- `$resolve-ai:chats` — list recent chats

### 2 · Surface — the environment

Call `list_investigations`, `list_alerts` (with `limit: 20`), `list_chats` in parallel, org-wide. Present a tight snapshot: counts plus a couple of headline items.

**Curate with taste — this is a demo, not a dump.** Privately pick three things to use later:

- **best RCA to drill** (beat 5): a **non-`triage_only`** investigation that _has theories_ — prefer `ALERT`/`INCIDENT`; skip smoke-tests.
- **best existing chat to resume** (beat 3): a real question-style chat from `list_chats`, status `complete`.
- **best alert to investigate cold** (beat 7): a genuine recent firing alert.

`▶ Menu — where first? (a) resume a chat, (b) ask several at once, (c) drill a real RCA + its evidence, (d) investigate something from scratch. Or say "tour" to go in order.`

### 3 · Resume a chat

Take the existing chat picked in beat 2 and **send a follow-up to it** — `ask` with that `chat_id` (include `investigation_id` if it's investigation-scoped). The point: chats persist, you resume a real prior conversation instead of starting cold. Stream the reply per the `ask` skill — run its returned `stream_command`, which scopes to the new turn.
`▶ Send the follow-up to "<chat name>"? Say "go".` ← consent before sending

### 4 · Many in parallel

Fire **two or three** questions concurrently, each streaming its own `stream_command` in the background, side by side. The point: Resolve isn't one-at-a-time. (The `ask` skill blesses parallel streams.)

Use **concrete, service-scoped** asks, not vague aggregates — vague ones make the agent guess time ranges and stall. Good shapes (substitute a real service from beat 2):

- recent error spikes in `<service>` logs — grouped by pattern, calling out new or surging ones
- health metrics for `<service>` for an operational review — error rate, latency p50/p90/p99, saturation
- pod health in `<service>` metrics — restarts, OOM kills, pods not Ready

Keep **one ask deliberately simple** — even a plain `hi` or a one-liner — so its quick reply lands while the heavier scoped ones are still streaming; the contrast makes the parallelism obvious.
`▶ Fire <N> in parallel? Say "go".`

### 5 · Drill a real RCA — evidence + a live thread

On the RCA picked in beat 2:

1. **Read it** (no consent — read-only): `get_investigation` → narrate status/phase, the top theory and its confidence.
2. **Get the evidence:** `read_file` a citation path from that theory to surface the raw telemetry behind the claim — the actual query or log lines the agent used. This is the trust moment: every conclusion traces to real data.
3. **Open a thread on it** (consent — sends a message): an investigation-scoped `ask` (pass `investigation_id`, no `chat_id`) that asks a sharp follow-up about the finding, then stream the answer per the `ask` skill — run its returned `stream_command`. Shows you can _converse with a specific RCA_, not just read it.
   `▶ Open a thread on this RCA with "<question>"? Say "go".`

### 6 · Apply the fix in code — close the loop with a PR (opt-in)

Take the root cause and the thread answer from beat 5 and turn them into a local change — Resolve diagnosed it in production; now write the fix in the editor. Run the `apply-fix` flow: read the theory and its citations, locate the owning code with Grep/Read, **propose** the change (theory addressed, files touched, why it works), implement on a "go", then **open a PR** — loading a PR-creation skill if one's available — so the loop ends at a reviewable pull request, not just a dirty tree. If the root cause is infra/config that doesn't live in this repo, say so and show the change you _would_ make rather than forcing an edit.
`▷ Run it yourself: $resolve-ai:apply-fix`
`▶ This edits local code and opens a PR. Apply the fix? Say "go" — or skip.`

### 7 · Investigate from scratch (the climax) — opt-in

Seed a brand-new investigation from the **real recent alert** picked in beat 2: compose a short markdown prompt from its title/labels, show it to the audience ("this fired ~<N> min ago — watch Resolve take it cold"), and only on explicit yes call `start_investigation`. Then stream it live per the `investigate` skill — run its returned `stream_command` — theory cards and the evidence trail forming in real time.
`▶ This starts a real investigation (uses org credits). Start it? Say "go".`

### 8 · Recap + toolbox

One line recapping the loop, then hand over the controls — the skills they can run themselves: `$resolve-ai:overview`, `$resolve-ai:ask`, `$resolve-ai:investigate`, `$resolve-ai:alerts` / `$resolve-ai:investigations` / `$resolve-ai:chats`, `$resolve-ai:steer`, `$resolve-ai:apply-fix`.

## Notes

- **IDs are ephemeral** — always select from a fresh `overview`, never hardcode an investigation/chat/alert ID.
- Preserve `[label](path)` citations verbatim; always surface canvas URLs.
- Keep each beat to a couple of lines. The live data is the star — let it carry the demo.
