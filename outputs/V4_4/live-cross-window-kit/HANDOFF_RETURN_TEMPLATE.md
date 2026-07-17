# Handoff Return Template — V4.4

## What to Copy Back from Each Worker Window

When a worker finishes in their Codex window, copy the following:

### From Each Worker's Output
1. **worker-handoff.json** — the handoff JSON they produced
2. **Artifact list** — which artifacts they created
3. **Files changed** — which files they modified
4. **Any blockers** — if they were blocked

### Where to Save
Place each worker's handoff file into:
```
runs/v44-live-cross-window/live-handoffs/
├── worker-backend-handoff.json
├── worker-frontend-handoff.json
└── worker-qa-handoff.json
```

### Handoff JSON Format (remind workers)
```json
{
  "worker_id": "<their worker id>",
  "task_ids": ["T3","T4",...],
  "status": "COMPLETED or BLOCKED or PARTIAL",
  "files_changed": [...],
  "artifacts_produced": [...],
  "tests_run": 0,
  "tests_passed": 0,
  "tests_failed": 0,
  "validation_result": "PASS or FAIL or PENDING",
  "blockers": [],
  "assumptions": [],
  "handoff_notes": "...",
  "next_agent": "integrator",
  "timestamp": "..."
}
```

### VALIDATION NOTE
Placeholder handoffs (with "FILL IN" or empty arrays) will be REJECTED.
Only genuine worker outputs are accepted.
