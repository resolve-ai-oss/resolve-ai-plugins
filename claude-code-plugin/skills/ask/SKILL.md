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
- Use the bundled watcher:

  ```sh
  WATCHER="${CLAUDE_PLUGIN_ROOT}/bin/resolve-watch.sh"
  ```

- Launch it in the background: `"$WATCHER" <chat_id> --watch-token <watch_token> [--investigation <id>] --message-id <message_id>` (add `--investigation <id>` for investigation-scoped chats). Pass `watch_token` and `message_id` from `ask`'s response — `watch_token` authenticates the watcher (no API key), and `--message-id` makes the stream emit only the new turn, not a full replay of prior history. It streams Resolve's response as human-readable text to stdout, creates a temporary state directory, prints `state_dir=<path>`, and writes two structured snapshots to `<state_dir>/state.json` — one before the stream opens and one when it closes. Spawn with `Bash(run_in_background: true)`. Safe to run multiple in parallel for different chats.
- **For the live transcript** (mid-flight progress, what Resolve is currently saying or which tool it's running), read the watcher's stdout via your host's background-process output API (Claude Code: `BashOutput`).
- **For the structured chat state** (full message list, tool history, status), read `state.json` from the watcher's state directory. Note: mid-flight it reflects the pre-stream seed; only after the watcher exits does it contain the final state.
- The watcher exits when Resolve's current turn completes (`status` becomes `complete` or `errored`). If the host re-engages automatically on background process exit, surface the final state then; otherwise surface it on the next user-driven turn. Exit code 0 = success, 1 = errored.
- Fallback if the watcher fails to spawn: call `get_chat` on subsequent turns.
- For multiple chats in flight, `list_chats` (or each chat's `state.json`) shows what's settled.
