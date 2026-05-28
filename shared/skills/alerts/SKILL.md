---
name: alerts
description: List and filter alerts in Resolve. Use when the user asks "show me alerts", "any new alerts", "alerts on <team>", "find the alert matching <pattern>", "alerts that auto-investigated", "alerts where <label> is critical/missing", or wants a focused alerts view (separate from a full overview snapshot).
version: 0.1.0
argument-hint: <optional filter description>
---

# List Resolve Alerts

Wraps `list_alerts` — the same data Resolve's `/alerts` page shows.

## Arguments

If `$ARGUMENTS` is non-empty, parse it into filter intent and call `list_alerts` with what you extract.

If `$ARGUMENTS` is empty, call `list_alerts` with no parameters (defaults to last 24h, no filters, limit 50). Only ask the user to narrow if the result set is overwhelming.

## Filter surface

Map common phrasings to these parameters:

- **`time_range`** — `last_24h` (default) / `last_7d` / `last_30d` / `custom`. For `custom`, pass `from_iso` (required, ISO 8601) and optionally `to_iso` (defaults to now).
- **`team_id`** — scope to a specific team's configured alert rules. Omit for the caller's full org.
- **`alert_rule_key`** — composite `Name::id` key for a single alert rule (e.g. `"High CPU::12345"`).
- **`alert_id`** — direct lookup of a single alert. Other filters still apply.
- **`only_auto_investigated: true`** — return only alerts that triggered an auto-investigation. There is no inverse filter; for "alerts that nobody auto-investigated", fetch the unfiltered set and post-filter on `is_auto_investigated: false`.
- **`label_filters[]`** — array of `{ label_name, operator, values }`. Filters across the array are AND'd; `values` within a filter are OR'd. Operators: `MATCHES` (exact), `NOT_MATCHES`, `CONTAINS` (substring), `NOT_CONTAINS`, `EXISTS` (label is present, `values` ignored), `NOT_EXISTS`. Severity, service, environment, and team are usually labels — use `label_filters` for "critical alerts", "alerts where `service` is missing", "alerts containing 'timeout'", etc.
- **`limit`** — default 50, hard ceiling 5000.

Examples:

- "critical alerts in the last hour" → `time_range: "custom"`, `from_iso: <one hour ago ISO>`, `label_filters: [{label_name: "severity", operator: "MATCHES", values: ["critical"]}]`.
- "alerts where `service` is missing" → `label_filters: [{label_name: "service", operator: "NOT_EXISTS", values: []}]`.
- "alerts containing 'timeout' in the message" → `label_filters: [{label_name: "<relevant label like 'description'>", operator: "CONTAINS", values: ["timeout"]}]`.
- "alerts for High CPU rule" → `alert_rule_key: "High CPU::<id>"` if known, otherwise filter on the rule's name label.

## Output

Summarize compactly:

- Count + the time range covered.
- Severity / action breakdown when it's informative.
- Per-alert one-liner: `time`, `title`, `severity`, `action`, `is_auto_investigated`, `entity_key`, `source_url`.
- When `is_auto_investigated: true`, the alert also carries `investigation_id` — the drill-in slug the UI uses for `/chat/<id>`. Surface it as the canvas URL (`<your-resolve-host>/chat/<investigation_id>`) and as the value the user can pass to `resolve:investigate <investigation_id>`, `ask`, or `steer_investigation`. Skip the URL when `investigation_id` is absent (rare: auto-investigated but only stub canvases) — don't fabricate one.
- Preserve any `[label](path)` citations verbatim.

If the list is long, group by `alert_rule_key` or a salient label and offer to narrow further.

## Handoffs

- "Show me everything happening in Resolve" — broader than just alerts → `resolve:overview`.
- "Open the investigation for this alert" — use the alert's `investigation_id` directly → `resolve:investigate <investigation_id>`.
- "Tell Resolve about this alert" — promote a finding into that investigation → `resolve:steer` (uses the same `investigation_id`).
