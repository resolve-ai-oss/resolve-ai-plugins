---
name: ask
description: Send Resolve a question or a request to investigate — continuing an existing chat or investigation, or starting a fresh one. Use when the user wants to send a message to Resolve — phrases like "ask Resolve about X", "follow up with Resolve", "what does Resolve think about Y", "have Resolve check Z", or wants Resolve to clarify a finding.
version: 0.1.0
argument-hint: <message>
---

# Ask Resolve

Use when the user wants Resolve to answer a question or do more investigation work.

## Arguments

If `$ARGUMENTS` is non-empty, use it as the user's base message and proceed (enrich with conversation context as below, then call `ask`).

If `$ARGUMENTS` is empty (skill invoked without a clear question), ask the user once what they want to ask Resolve. Treat their next reply as the base message.

## Composing the message

Before calling `ask`, enrich the user's base message with context from the current conversation **that directly supports the specific question being asked**.

**Be ruthlessly selective.** Do not dump every file you've read, every command you've run, or the conversation transcript. Include only what makes the question more answerable. If a piece of context isn't load-bearing for this specific message, leave it out.

Candidates to consider (include only those tied to the question):

- File paths the user opened or edited **in the path of investigating this exact issue**
- Error messages, log lines, or stack traces that name the symptom the user is asking about
- Git context (branch, recent commits, working changes) **when the question is about a change being made**
- URLs the user referenced that frame this question (Slack threads, dashboards, related canvases)
- A one-line framing of what the user is working on — only if the question doesn't stand on its own

Format the enriched message as the user's question first, then a brief `## Local context` block with only the relevant items. Most asks need 1–3 lines of context, not a dump.

## Picking scope

Default to whatever investigation/chat is currently in context:

- The user just engaged an investigation via `investigate` → scope the ask to it.
- A chat is already in flight under that investigation → continue it.
- The user switches to a different investigation mid-conversation → start fresh there.
- No active context → standalone Resolve chat.

## After asking

`ask` is non-blocking — it returns immediately, then Resolve takes seconds to minutes to respond.

- Surface the canvas URL.
- **Follow the response (primary).** `ask` returns a ready-to-run `stream_command` — a self-contained `curl` that streams the reply (needs only `curl`). Run it verbatim as a long-running Codex command: call `functions.exec_command` with the `stream_command`, `yield_time_ms: 1000`, `sandbox_permissions: "require_escalated"`, a short network justification, and an appropriate `max_output_tokens`. It calls Resolve's stream endpoint directly, so default sandbox networking may fail with a `curl` network error. Do not use shell backgrounding (`&`, `nohup`, zsh job control); Codex's command session is the background primitive.
- **For the live transcript**, read the output returned by `functions.exec_command`. If it returns a `session_id`, poll that session with `functions.write_stdin` using empty `chars` until the command exits. The stream ends with `[done]` when the turn succeeds or `[error: …]` if it failed — judge the outcome from that marker, not the process exit code. If in doubt, confirm with `get_chat`.
- **For the final state**, call `get_chat` once the chat has finished — it returns the same conversation in condensed form. Use it also if the `stream_command` can't be run.
- For multiple chats in flight, `list_chats` shows what's settled.
