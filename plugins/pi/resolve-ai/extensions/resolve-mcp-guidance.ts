/**
 * Copyright 2026 Resolve AI, Inc.
 * SPDX-License-Identifier: Apache-2.0
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"

const RESOLVE_MCP_GUIDANCE = `Resolve AI Pi integration:
- Resolve skills are written around a $ARGUMENTS placeholder, but Pi does not substitute it. Pi appends any text typed after the skill command as the user's input, so treat that trailing text as $ARGUMENTS wherever a skill refers to it; only follow the "empty arguments" branch when no such text was provided.
- Resolve skills refer to other Resolve skills with host namespaces like resolve-ai:ask or resolve-ai-admin:debug-integration. In Pi, those handoffs mean the un-namespaced Pi skill command /skill:<name>, for example /skill:ask or /skill:debug-integration.
- Resolve skills refer to Resolve MCP tools by their MCP names, such as list_alerts, list_investigations, get_investigation, ask, start_investigation, steer_investigation, read_file, upload_attachment, and submit_feedback.
- In Pi, use the mcp proxy tool to access those tools. The Pi MCP adapter exposes Resolve MCP tools with the resolve_ prefix, for example resolve_list_alerts, resolve_list_investigations, resolve_get_investigation, and resolve_ask.
- If the resolve server is not connected, connect it first with the mcp tool or /mcp reconnect resolve.
- When calling Resolve tools through the mcp proxy, prefer server "resolve" and pass tool arguments as a JSON string.
- Some Resolve tools (ask, start_investigation, steer_investigation) return a stream_command to follow an investigation or chat live. Run it verbatim in a detached tmux session (or another terminal) so it does not block the Pi turn, preserving its quoting and token exactly, and relay notable progress via tmux capture-pane / pipe-pane. If tmux is unavailable, ask the user to run it in a separate terminal and paste back the result.
- Do not invent Resolve IDs, citation paths, or canvas URLs. Use only values returned by Resolve MCP tools.`

export default function resolveMcpGuidance(pi: ExtensionAPI) {
  pi.on("before_agent_start", event => ({
    systemPrompt: `${event.systemPrompt}\n\n${RESOLVE_MCP_GUIDANCE}`,
  }))
}
