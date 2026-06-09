---
# Copyright 2026 Cloud Data Labs, Inc.
# SPDX-License-Identifier: Apache-2.0
name: prod-context
description: Get production context from Resolve for the area you're about to change — so the work is grounded in what production looks like and aware of how the change could affect it, before you start rather than after the PR is up. Use before implementing a fix or feature, when finalizing a plan or approach, or before editing anything that affects a production system — application code, infrastructure, or config-as-code (Helm, Terraform, Dockerfiles, CI/CD, SQL/migrations, protos) — or when the user says "let's build/fix/implement X". Surfaces the area's normal operational profile (traffic and usage, telemetry coverage, baseline latency/error rate), the regression risk of the change, plus any active alerts, open investigations, recent incidents or deploys, and known fragility.
version: 0.1.0
argument-hint: [optional focus, e.g. a service or concern]
license: Apache-2.0
---

# Pre-implementation production context

Before implementing a change to a production-facing path, get the runtime picture the code can't
show — real traffic, telemetry coverage, baselines, live trouble — and let it shape the approach.
Resolve owns the telemetry and the service map; query it only for what you can't read off the repo.

## When to trigger

Trigger at the **plan → implement boundary**: the task is understood, the in-scope files or areas
are known, and no code is written yet — so production reality can still shape the approach, not
just validate it afterwards.

Skip trivial changes (typo, comment, formatting, docs-only) and anything no production system
would monitor.

## Decide whether to ask

Ask Resolve only when a **production runtime unknown** would change how you build this. If the open
questions are answerable by reading the repo, or the area is quiet with no runtime unknowns, skip
the ask — say so in one line and continue with the work.

## Compose the ask

Pick the few angles that fit this change — don't ask all of them, and don't ask generically. Each
is something the code can't tell you.

Know the area:

- **Operational profile** — real traffic and request volume, peak vs quiet, how heavily it's
  exercised. A hot path demands far more care than a rarely-hit endpoint.
- **Telemetry coverage** — what observability exists here (logs, metrics, traces) and where the
  blind spots are: will you be able to see your change's effect?
- **Baseline behavior** — the normal latency / error rate / throughput, so you know what "good"
  looks like.

Check for trouble:

- **Is the ground shaking?** — active alerts, ongoing incidents, or open investigations on the
  area. Don't build on top of an active fire — or realize your change _is_ about it.
- **Regression history** — recent deploys and prior incidents on these paths; where it's bitten
  before, build defensively.
- **Runtime downstream fanout** — what actually gets hit downstream at volume, from traces and the
  service map. Scopes rollout and testing.
- **What to verify after** — given the change, the production signals to watch post-deploy.

Make it exact. Gather a tight bundle — be ruthlessly selective, no transcript dumps:

- **Task** — one line on what's being implemented.
- **In-scope files/areas** — the paths you've read or named. Paths are enough; don't map them to
  services yourself, Resolve does that.
- **Approach** — the intended plan, if there is one.
- **Symptoms/errors/tickets** — verbatim where they frame the change.
- **Git framing** — run `git rev-parse --abbrev-ref HEAD` and `git log --oneline -3`, and include
  the branch and recent subjects.

Put the concrete question(s) first, then a short `## What I'm about to change` block, and send via
`resolve:ask`. For example:

- New feature/endpoint → _operational profile_ + _telemetry coverage_: "About to add `<X>` to
  `<service>`. How much traffic/usage does this area see, is it a hot path, and what telemetry
  already covers it — will I be able to observe this change?"
- Change to a high-fanout component → _runtime fanout_ + _regression history_: "About to change
  `<component>` in `<files>`. What actually depends on this in production, has changing it caused
  incidents before, and what should I watch after deploy?"
- Bugfix in a sensitive area → _ground shaking_ + _baseline_: "About to fix `<bug>` in `<files>`.
  Any open investigations or active alerts on `<area>`, and what's the normal error rate/latency so
  I can tell if the fix actually helps?"

## After asking

Don't block. Fire the ask and immediately continue planning and implementing — never gate code
changes, the PR, or any other work on the reply. Pause only if the user explicitly asks to wait.

When the reply lands:

- Summarize what Resolve returned in 2–4 bullets.
- Adjust the approach and call out the change explicitly — e.g. it's a high-traffic hot path so
  gate it behind a flag and test harder; lots depends on it downstream so stage the rollout;
  telemetry is thin so add instrumentation with the change; an open investigation overlaps the
  area; a recent deploy is already shaky.
- Fire at most one sharpening follow-up if something is directly relevant.

If Resolve comes back unremarkable — low-traffic, healthy, nothing in flight — say so in one line
and carry on.
