# Worker Handoff Protocol (V4.2)

## Purpose

The handoff protocol is the structured interface between workers and the
integrator in Codex Factory's multi-agent execution model. Each worker MUST
produce a handoff JSON file before their work is considered for integration.

## Schema

See `schemas/worker-handoff.schema.json` for the full JSON schema.

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `worker_id` | string | Worker identifier (e.g. `worker-backend`) |
| `task_ids` | string[] | Task IDs covered by this handoff |
| `status` | enum | COMPLETED, PARTIAL, BLOCKED, or FAILED |
| `timestamp` | string | ISO 8601 timestamp |
| `next_agent` | string | Intended recipient (usually `integrator`) |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `files_changed` | string[] | Files modified during execution |
| `artifacts_produced` | string[] | Artifact names produced |
| `tests_run` | integer | Total tests executed |
| `tests_passed` | integer | Tests that passed |
| `tests_failed` | integer | Tests that failed |
| `validation_result` | enum | PASS, FAIL, SKIPPED, or PENDING |
| `blockers` | string[] | Issues preventing completion |
| `assumptions` | string[] | Assumptions made during work |
| `handoff_notes` | string | Free-form notes for next agent |

## Status Values

- **COMPLETED**: All assigned tasks done, all required artifacts produced
- **PARTIAL**: Some tasks done, but not all — integration may still proceed
- **BLOCKED**: Cannot proceed due to issues listed in `blockers`
- **FAILED**: Work attempted but failed — requires investigation

## Validation Rules

When `validate-handoff` runs, it checks:

1. Required fields present (worker_id, task_ids, status, next_agent)
2. Status is not still PENDING (template placeholder)
3. If COMPLETED: all `required_output_artifacts` from the worker capsule are
   listed in `artifacts_produced`
4. No file in `files_changed` matches any `forbidden_files` pattern
5. `handoff_notes` is not the template placeholder

## File Boundary Enforcement

Each worker capsule defines `allowed_files` and `forbidden_files`. The handoff
validator checks `files_changed` against `forbidden_files` using glob-like
matching. Any boundary violation is a FAIL.

Example:
- `forbidden_files: ["src/*/auth*"]`
- `files_changed: ["src/backend/auth.ts"]` → VIOLATION (matches `src/*/auth*`)

## Integrator Rules

The integrator (or integration phase) validates:
- All workers have produced handoffs
- No handoff has unresolved blockers
- All required artifacts are claimed
- No file boundary violations exist

The integrator does NOT write code — it validates completeness and coherence.

## Non-Claims

- A handoff is a claim by the worker, not an automatic acceptance
- The integrator / main agent has final decision authority
- Missing handoff = blocked integration
- Missing artifact = blocked validation
- No artifact = no PASS (always)
