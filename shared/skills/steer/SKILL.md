---
# Copyright 2026 Resolve AI, Inc.
# SPDX-License-Identifier: Apache-2.0
name: steer
description: Steer a Resolve investigation by sending it a new finding, hypothesis, or directive to redirect it. Use when the user wants to promote a local observation back to Resolve — phrases like "tell Resolve I found X", "steer this investigation", "send Resolve this observation", or "promote this back to Resolve".
version: 0.1.0
argument-hint: <message>
license: Apache-2.0
---

# Steer Investigation

Send a directive to an active investigation. This is the canonical channel for promoting local observations into Resolve's investigation flow.

## Arguments

If `$ARGUMENTS` is non-empty, use it as the base of the steer message. Enrich with conversation context as below before calling `steer_investigation`.

If `$ARGUMENTS` is empty, ask the user once what they want to steer Resolve with. Treat their next reply as the base.

## Enriching with conversation context

Before calling the tool, expand the base message with conversation signals **that directly support the finding being promoted**. Be ruthlessly selective:

- Specific file paths or code snippets that demonstrate the finding
- Error messages or log lines from this conversation that back up the observation
- Git context (branch, commit) if the finding is tied to a local change
- URLs the user referenced that informed the finding

If a piece of context doesn't strengthen the steer, leave it out.

## Composing the message

A good steer message is:

- **Specific.** "Latency spike correlates with the 14:52 deploy of the affected service" beats "I think it's the deploy."
- **Anchored.** Reference times, services, files, or theory IDs from `get_investigation` when relevant.
- **Actionable.** Either an observation Resolve should integrate, or a directive for the agent teams ("focus on the connection pool theory").
- **Markdown.** Bullets, file paths, code references — anything the human side of an investigation would benefit from.

## After steering

Effects surface via:

- The activity timeline — re-read via `read_file` on the timeline path from `get_investigation`.
- Updated theories on next `get_investigation`.
- **Live, if the user wants to watch the effect land:** follow any returned stream with the host's long-running command mechanism.
