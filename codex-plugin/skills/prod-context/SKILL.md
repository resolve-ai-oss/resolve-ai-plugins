---
# Copyright 2026 Cloud Data Labs, Inc.
# SPDX-License-Identifier: Apache-2.0
name: prod-context
description: Get production context from Resolve for the area you're about to change — so the work is grounded in what production looks like and aware of how the change could affect it, before you start rather than after the PR is up. Use before implementing a fix or feature, when finalizing a plan or approach, or before editing anything that affects a production system — application code, infrastructure, or config-as-code (Helm, Terraform, Dockerfiles, CI/CD, SQL/migrations, protos) — or when the user says "let's build/fix/implement X". Surfaces the area's normal operational profile (traffic and usage, telemetry coverage, baseline latency/error rate), the blast radius and regression risk of the change, plus any active alerts, open investigations, recent incidents or deploys, and known fragility.
version: 0.1.0
argument-hint: [optional focus, e.g. a service or concern]
license: Apache-2.0
---

# Pre-implementation production context

Ground a change in production reality **before** writing it: understand the area's normal
operational profile (is this a hot path? is it even observable?), check for any active trouble,
and weigh how the change itself could affect production. Resolve owns the telemetry and the
service-mapping; this skill's job is to (1) fire at the right moment, (2) pick the right kind of
question, and (3) make it exact with what's actually being changed.

## 1. When to trigger

The moment is the **plan → implement boundary**: the task is understood, the in-scope files or
areas are known, and code has not been written yet — so production reality can still shape the
approach, not just validate it afterwards.

**Skip** when the change is trivial (typo, comment, formatting, docs-only) or touches nothing a
production system would monitor.

## 2. The kinds of questions to ask

Three buckets — **know the area**, **check for trouble**, and **weigh your impact**. These are
the angles that change how you'd build the thing. **Pick the few that fit this change** — don't
ask all of them, and don't ask generically.

**Know the area (its normal life in production — independent of whether anything's wrong):**

- **Operational profile** — traffic and request volume, how heavily it's used, peak vs quiet, who
  or what calls it. (A high-traffic hot path demands far more care than a rarely-hit endpoint.)
- **Telemetry coverage** — how much observability exists here (logs, metrics, traces): will you be
  able to see your change's effect, and where are the blind spots?
- **Baseline behavior** — the normal latency / error rate / throughput, so you know what "good"
  looks like.

**Check for trouble (current state):**

- **Is the ground shaking?** — active alerts, ongoing incidents, or open investigations on the
  area. (Don't build on top of an active fire — or realize your change _is_ about it.)
- **In-flight overlap** — is an investigation or another effort already working this area.
  (Avoid collision; coordinate.)

**Weigh your impact (how this change could affect production):**

- **Blast radius & dependencies** — what calls or depends on what you're changing, and what could
  break downstream if it misbehaves. (Scopes the change, the rollout, and the testing.)
- **Regression risk & history** — recent deploys/incidents on these paths, and whether changing
  this area has caused incidents before. (Watch for collisions; build defensively where it's
  bitten before.)
- **What to verify after** — given the change, the signals to watch post-deploy.

## 3. Make it exact with the change context

Take what's being worked on and instantiate the chosen angles into one scoped `ask`. Gather a
tight bundle (be ruthlessly selective — no transcript dumps):

- **Task** — one line on what's being implemented.
- **In-scope files/areas** — the paths you've read or named. Paths are enough; do **not** map
  them to services yourself, Resolve does that.
- **Approach** — the intended plan, if there is one.
- **Symptoms/errors/tickets** — verbatim where they frame the change.
- **Git framing** — run `git rev-parse --abbrev-ref HEAD` and `git log --oneline -3` and include
  the branch + recent subjects.

Compose the message: the concrete question(s) first, then a short `## What I'm about to change`
block. Examples of instantiation:

- New feature/endpoint → _operational profile_ + _telemetry coverage_: "About to add `<X>` to
  `<service>`. How much traffic/usage does this area see, is it a hot path, and what telemetry
  already covers it — will I be able to observe this change?"
- Change to a shared/high-fanout component → _blast radius_ + _regression risk_: "About to change
  `<component>` in `<files>`. What depends on this and could break downstream, has changing it
  caused incidents before, and what should I watch after deploy?"
- Bugfix in a sensitive area → _ground shaking_ + _baseline_: "About to fix `<bug>` in `<files>`.
  Any open investigations or active alerts on `<area>`, and what's the normal error rate/latency
  so I can tell if the fix actually helps?"

Send the composed question via `resolve:ask`.

## 4. Fire and continue

Continue with planning/implementation unless the user explicitly wants to wait. When Resolve's
reply lands:

- Summarize what Resolve returned in 2–4 bullets.
- **Adjust the approach** and call out the adjustment explicitly — e.g. it's a high-traffic hot
  path so gate it behind a flag and test harder; lots depends on it downstream so stage the
  rollout; telemetry is thin so add instrumentation with the change; an open investigation
  overlaps the area; a recent deploy is already shaky.
- Fire at most one sharpening follow-up if something is directly relevant.

If it's an unremarkable, low-traffic, healthy area, say so in one line and carry on.
