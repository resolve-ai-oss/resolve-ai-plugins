---
# Copyright 2026 Cloud Data Labs, Inc.
# SPDX-License-Identifier: Apache-2.0
name: alerts
description: List and filter alerts in Resolve. Use when the user asks "show me alerts", "any new alerts", "alerts on <team>", "find the alert matching <pattern>", "alerts that auto-investigated", "alerts where <label> is critical/missing", or wants a focused alerts view (separate from a full overview snapshot).
version: 0.1.0
argument-hint: <optional filter description>
license: Apache-2.0
---

# List Resolve Alerts

Use for focused alert listings and alert drill-downs.

## Arguments

If `$ARGUMENTS` is non-empty, translate it into `list_alerts` filters.

If `$ARGUMENTS` is empty, call `list_alerts` with the tool defaults. Only ask the user to narrow if the result set is overwhelming.

## Filter Intent

Map common phrasings to the right filter family:

- **Time** — "today", "last week", "since deploy", explicit date ranges.
- **Ownership** — team, alert rule, alert ID, or entity.
- **Investigation state** — auto-investigated alerts, alerts with or without linked investigations.
- **Labels** — severity, service, environment, team, missing labels, or substring matches.

Examples:

- "critical alerts in the last hour" → time filter + severity label.
- "alerts where `service` is missing" → missing-label filter.
- "alerts containing 'timeout'" → substring label filter on the best matching message/description label.
- "alerts for High CPU rule" → rule key if known, otherwise filter by rule/title labels.

For unsupported inverse filters, fetch a reasonable recent set and post-filter locally.

## Output

Summarize compactly:

- Count + the time range covered.
- Severity / action breakdown when it's informative.
- Per-alert one-liner: `time`, `title`, `severity`, `action`, `is_auto_investigated`, `entity_key`, `source_url`.
- Surface investigation links only when the result includes an `investigation_id`; never fabricate one.
- Preserve any `[label](path)` citations verbatim.

If the list is long, group by `alert_rule_key` or a salient label and offer to narrow further.

## Handoffs

- "Show me everything happening in Resolve" — broader than just alerts → `resolve-ai:overview`.
- "Open the investigation for this alert" — use the alert's `investigation_id` directly → `resolve-ai:investigate <investigation_id>`.
- "Tell Resolve about this alert" — promote a finding into that investigation → `resolve-ai:steer`.
