# Worker Handoff Protocol (V4.2)

> This is the hardened legacy compatibility protocol. New projects should use
> the V5 automatic control plane documented in
> [`CONTROL_PLANE_V5_GUIDE.zh-CN.md`](CONTROL_PLANE_V5_GUIDE.zh-CN.md). A V4
> handoff can reach `READY_FOR_INTEGRATION`, but it can never certify V5
> `EXECUTION_VERIFIED` acceptance.

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
| `artifacts_produced` | string[] | Run-local paths/names; each must resolve to a non-empty file below `runs/<run-id>/artifacts/` |
| `tests_run` | integer | Total tests executed |
| `tests_passed` | integer | Tests that passed |
| `tests_failed` | integer | Tests that failed |
| `validation_result` | enum | PASS, FAIL, SKIPPED, or PENDING |
| `blockers` | string[] | Issues preventing completion |
| `assumptions` | string[] | Assumptions made during work |
| `handoff_notes` | string | Free-form notes for next agent |

## Status Values

- **COMPLETED**: All assigned tasks done, all required artifacts produced
- **PARTIAL**: Some tasks done, but not all — integration remains blocked
- **BLOCKED**: Cannot proceed due to issues listed in `blockers`
- **FAILED**: Work attempted but failed — requires investigation

## Validation Rules

When `validate-handoff` runs, it checks:

1. Required fields present (worker_id, task_ids, status, next_agent)
2. Status is one of COMPLETED/PARTIAL/BLOCKED/FAILED; only COMPLETED can pass task validation
3. Every `files_changed` path is relative, remains inside the project, and exists physically
4. Every declared artifact is a non-empty physical file below the current run's `artifacts/` directory; absolute paths and `..` traversal are rejected
5. If COMPLETED, every `required_output_artifact` from the capsule and validation plan is both declared and physically present
6. Test counters are coherent, failed-test count is zero, blockers are empty, and worker self-validation says PASS
7. No changed file matches a capsule `forbidden_files` pattern
8. `handoff_notes` is meaningful and is not a template placeholder

Worker counters are still claims. When a validation plan requires `test`,
`review`, `static_check`, or `manual_instruction`, the compatibility runtime
also requires a JSON receipt at:

```text
runs/<run-id>/validation/<task-id>-<method>-receipt.json
```

Test/static receipts require a real command and `exit_code: 0`; test receipts
also require a non-zero test count with all tests passed. Review/manual receipts
require a `reviewer_id` different from the worker. Required global gates use
`runs/<run-id>/validation/gates/<gate>-receipt.json` and require an independent
`verified_by` identity.

## File Boundary Enforcement

Each worker capsule defines `allowed_files` and `forbidden_files`. The handoff
validator checks `files_changed` against `forbidden_files` using glob-like
matching. Any boundary violation is a FAIL.

Example:
- `forbidden_files: ["src/*/auth*"]`
- `files_changed: ["src/backend/auth.ts"]` → VIOLATION (matches `src/*/auth*`)

## Integrator Rules

The integrator (or integration phase) validates:
- The handoff worker set exactly matches the capsule worker set (no missing, duplicate, or unknown worker)
- Every handoff is COMPLETED and passes physical-file/boundary checks
- All required artifacts exist and have SHA-256 evidence
- All task methods and required gates passed
- The current input/capsule/handoff/artifact/changed-file/receipt snapshot hash matches the validation snapshot

Changing evidence after validation makes the integration report stale. Run
`validate` and `integrate` again before `close`.

The integrator does NOT write code — it validates completeness and coherence.

## Non-Claims

- A handoff is a claim by the worker, not an automatic acceptance
- The integrator / main agent has final decision authority
- Missing handoff = blocked integration
- Missing artifact = blocked validation
- No artifact = no PASS (always)
