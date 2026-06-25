---
# Copyright 2026 Resolve AI, Inc.
# SPDX-License-Identifier: Apache-2.0
name: apply-fix
description: Turn a Resolve investigation's root-cause findings into code changes in your local repo. Use when the user wants to translate findings into code changes — phrases like "fix this based on Resolve", "implement Resolve's mitigation", "apply the fix from this investigation", "remediate the root cause Resolve found", or wants to write code to address a theory Resolve identified.
version: 0.1.0
license: Apache-2.0
---

# Apply Fix from Resolve Findings

Bridges Resolve's production-side diagnosis to local code edits.

## Workflow

1. **Pick the target finding.** Usually a root-cause theory from `get_investigation`. If multiple, ask the user which to address.
2. **Read the theory and its citations** via `read_file` on the theory's path and its citation paths. Citations are log lines, queries, traces — the supporting evidence.
3. **Gather what's missing for a code change.** Theories describe what's broken in production, not what to write locally. You fill that in by reading local code: which file owns the relevant path, what the current implementation does, where the change goes.
4. **Optionally**, send a code-shaped question back to Resolve via `ask` for context you can't infer locally. Don't block on it — work in parallel.
5. **Locate the relevant local code** with Grep/Read.
6. **Propose the fix:** the theory addressed, the citations supporting it, the files being changed, why the change should work. Then implement.
7. **Open a PR.** If a PR-creation skill is available, load and use it to open the pull request; otherwise follow the repo's normal PR flow. Land the work as a reviewable PR, not a dirty working tree.
8. **Optionally** call `steer_investigation` with "Applied mitigation: <summary>" so the investigation records the fix.
