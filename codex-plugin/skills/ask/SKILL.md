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
- Start the installed Bash watcher as a long-running Codex command, not with shell backgrounding. Call `functions.exec_command` with the watcher command, `yield_time_ms: 1000`, `sandbox_permissions: "require_escalated"`, a short network justification, and an appropriate `max_output_tokens` value: `"$(ls -d "${CODEX_HOME:-$HOME/.codex}/plugins/cache/resolve-everywhere/resolve/"*/bin/resolve-watch.sh 2>/dev/null | sort -V | tail -n1)" <chat_id> --watch-token <watch_token> [--investigation <id>] --message-id <message_id>` (add `--investigation <id>` for investigation-scoped chats). Pass `watch_token` and `message_id` from `ask`'s response — `watch_token` authenticates the watcher (no API key), and `--message-id` makes the stream emit only the new turn, not a full replay of prior history. The watcher always creates a temporary state directory and prints `state_dir=<path>`. The watcher calls Resolve REST and stream endpoints directly, so default sandbox networking may fail with a `curl` network error. Avoid variables, `nohup`, trailing `&`, and zsh job control; Codex's command session is the background primitive.
- **For the live transcript** (mid-flight progress, what Resolve is currently saying or which tool it's running), read the output returned by `functions.exec_command`. If it returns a `session_id`, poll that session with `functions.write_stdin` using empty `chars` until the watcher exits.
- **For the structured chat state** (full message list, tool history, status), read `state.json` from the watcher's state directory. Note: mid-flight it reflects the pre-stream seed; only after the watcher exits does it contain the final state.
- The watcher exits when Resolve's current turn completes (`status` becomes `complete` or `errored`). If the Codex command session is still running, continue polling it rather than ending the turn with an active required process. Exit code 0 = success, 1 = errored.
- Fallback if the watcher fails to spawn: call `get_chat` on subsequent turns.
- For multiple chats in flight, `list_chats` (or each chat's `state.json`) shows what's settled.
