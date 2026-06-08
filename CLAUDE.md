<!--
Copyright 2026 Cloud Data Labs, Inc.
SPDX-License-Identifier: Apache-2.0
-->

# Resolve Everywhere Plugin Guidance

## Skill vs Tool Description Boundary

Skills are shipped less often than MCP tools and server behavior. Keep skills focused on stable workflow guidance:

- When to use a workflow and when to hand off to another skill.
- How to translate user intent into the right class of tool call.
- How to compose high-quality prompts/messages from local context.
- Human-facing output shape and follow-up behavior.
- Confirmation gates for mutating or credit-consuming actions.
- Host-specific execution hints only when the host truly differs.

Put volatile or API-specific details in MCP tool descriptions or server-side code instead:

- Exact parameters, enums, defaults, limits, sort order, and return fields.
- Stream protocol details, including terminal markers and failure semantics.
- REST endpoints, payload schemas, authentication, and feature gates.
- Current backend limitations or behavior that can change independently of plugin releases.
- Tool-specific examples that are mostly schema examples rather than workflow examples.

Shared stream-command behavior belongs in the MCP server instructions, condensed; `ask` carries the full execution semantics since tool descriptions arrive complete at call time. Other tool descriptions should only say whether the tool returns a `stream_command` and what live state it follows.

If a skill starts restating a tool schema, trim the skill and improve the server instructions or tool description instead.

### Host size limits

Hosts truncate MCP guidance text: Claude Code cuts server instructions and each tool description at 2KB; Codex prioritizes the first 512 characters of instructions. Keep server instructions under 2KB with the most important guidance first (enforced by `packages/svc-mcp-server/__tests__/v2HttpTransport.test.ts`). Never duplicate text between instructions and a tool description — the instructions copy is the one at truncation risk, so it should hold only cross-tool guidance.

Example boundary:

- Bad skill text: "Pass `run_type` as `AUTO`, `MANUAL`, or `EVAL`."
- Better skill text: "Filter to the run types the user means; leave exact accepted values to the MCP schema."

## Shared Skill Workflow

Most skills are authored under `shared/skills` and copied into both host plugin directories.

- Edit shared skills first.
- Run `pnpm run sync:resolve-everywhere-plugin` after changing shared skills.
- Run `pnpm run check:resolve-everywhere-plugin` before pushing.
- Do not hand-edit generated host copies unless the sync script marks them host-owned.
- The sync script is the source of truth for host-owned files; run `pnpm run check:resolve-everywhere-plugin` to validate the current set.

## Skill Style

- Prefer durable intent language over implementation detail.
- Use examples to show user intent mapping, not to mirror full schemas.
- Preserve confirmation requirements for destructive, mutating, or credit-consuming flows.
- Keep Resolve citations and returned IDs/paths as opaque handles; never teach agents to fabricate them.
