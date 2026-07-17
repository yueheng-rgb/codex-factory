# Cross-Window Worker Execution (V4.3)

## Overview

Codex Factory V4.3 enables distributing worker capsules to multiple Codex
windows for parallel task execution. Each window runs one worker, isolated
from others, with strict file boundaries enforced by the handoff protocol.

## How It Works

1. **Generate worker kits** from V4.2 capsules (7 files per worker)
2. **Distribute** each kit to a separate Codex window
3. **Each worker** works only on their assigned tasks within allowed files
4. **Workers produce** artifacts + handoff JSON + worker log
5. **Integrator collects** handoffs, validates, and merges

## Worker Kit Contents

Each worker receives:
- `WORKER_CAPSULE.md` — role, tasks, rules
- `WORKER_TASKS.json` — structured task data
- `ALLOWED_FILES.md` — what you may modify
- `FORBIDDEN_FILES.md` — what you MUST NOT touch
- `REQUIRED_ARTIFACTS.md` — what you must produce
- `HANDOFF_TEMPLATE.json` — fill in when done
- `WORKER_PROMPT.md` — ready-to-paste prompt for Codex

## Avoiding Context Pollution

Each Codex window should ONLY receive its own worker kit. Do NOT:
- Paste other workers' capsules into the same window
- Share internal drafts between workers
- Let workers see the integrator's full view

## Avoiding Worker Overreach

Workers are constrained by:
- `forbidden_files` patterns (checked by validate-handoff)
- `allowed_files` directories (checked by boundary test)
- `forbidden_actions` list (e.g., cannot self-approve)
- Capsule explicitly states: "You are NOT the final decision maker"

## Handoff Collection

After all workers complete:
1. Copy each worker's handoff JSON to a shared `mailbox/`
2. Run `validate-handoff` on each
3. Rejected handoffs (boundary violations) block integration
4. Accepted handoffs feed into integrator report

## Manual Cross-Window Execution

This is NOT fully autonomous. The user must:
1. Open separate Codex windows
2. Paste each worker's WORKER_PROMPT.md
3. Collect outputs manually
4. Run integrator

Future: agent-adapter mode may automate worker dispatch via spawn_agent.
