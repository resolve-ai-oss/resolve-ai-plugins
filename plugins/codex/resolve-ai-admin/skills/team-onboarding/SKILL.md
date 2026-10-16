---
# Copyright 2026 Resolve AI, Inc.
# SPDX-License-Identifier: Apache-2.0
name: team-onboarding
description: Set up or update a team in Resolve — create the team, set its members and roles, link an on-call (IRM) or identity-provider (SCIM) group, choose its Slack or Microsoft Teams channels, and define which alerts it owns. Use when the user wants to create/onboard a team in Resolve or asks to read, review, or change a team's Resolve settings.
version: 0.1.0
argument-hint: <optional team name or what to change>
license: Apache-2.0
---

# Team Onboarding

The `resolve-ai:ask` tool does the work - send every request through this tool. Your job is to relay the user's requests to Resolve in simple and direct language, and to guide the user through the various aspects of creating and setting up a team.

Do not overprompt Resolve - Resolve knows what to do. It will perform validation and verification of user provided requests and values, catch ambiguity, check permissions, etc. Simply relay messages between the user and Resolve in clear terms. If Resolve comes back with questions or issues, pass them on to the user.

When you ask Resolve to make a change, ask it to reply with the team's live settings and pending changes afterwards, so you can show the user where the team stands.

## Change only what the user explicitly asks for

Any request that changes a team needs the user's explicit instruction for that exact change on that exact team. This covers creating a team, saving a pending change, and applying or rejecting pending changes.

## Team setup flow

If `$ARGUMENTS` is non-empty, treat it as the team, or as the change the user wants, and start there.

If `$ARGUMENTS` is empty, ask the user for the team's name and whether it is new or already exists before sending anything to Resolve.

Then, send one `resolve-ai:ask` request. Open it with the line for the case:

- New team: `I am onboarding a new team.`
- Existing team: `I am onboarding an existing team, <team name>. Provide an overview of the team's live settings and pending changes.`
- The user answered without naming a team: `I am performing onboarding.`

Then add this text, verbatim:

```
Explain the steps to set up a team, and what each step consists of: the settings involved, what each setting does, and what the user needs to decide.
List every integration you have access to, such as alert sources, on-call tools, telemetry, communication channels and code.
```

Relay the team's state and the setup steps to the user. Keep the integration list for yourself, to guide the flow and spot gaps; show it only if the user asks. Then go one step at a time and let the user skip or revisit steps; each step is one `resolve-ai:ask` message. Before sending a step to Resolve, check the user's request against what Resolve said that step needs, and ask the user for anything missing. If you don't know what a setting needs or does, ask Resolve.

If the user asks you to recommend or explore settings and you have gaps in access that matter for the task and are covered by Resolve's integrations, point it out to the user. Suggest a specific next step, such as what you'd ask Resolve at a high level, and let the user decide.

## Changing an existing team

Changes to an existing team are saved as pending and go live only after the user reviews and approves them. You must facilitate this review process between Resolve and the user.

- Relay the team's live settings and pending changes that Resolve reports directly to the user - preserve Resolve's format and structure, and do not alter or summarize away details.
- Relay review questions, requests, and approvals from the user directly to Resolve. Never confirm on the user's behalf and do not alter user intent.

## Response style

Keep each turn short and focused on the current step. Always surface the team's Resolve URL when Resolve returns one.
