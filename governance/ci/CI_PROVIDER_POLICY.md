# Codex Factory V3.1 — CI Provider Policy

## Provider Types

| Provider | Status | Description |
|----------|--------|-------------|
| `local-ci-simulated` | AVAILABLE | Local CI simulation, captures artifacts to `artifacts/ci-runs/` |
| `github-actions-template` | TEMPLATE_ONLY | Generates `.github/workflows/` YAML, NOT executed locally |
| `external-ci-placeholder` | NOT_IMPLEMENTED | Reserved for future CI provider integration |

## CI Job Requirements

1. Every CI job MUST produce a `ci-receipt.json` matching `ci-job-receipt.schema.json`
2. `exit_code != 0` MUST result in `status: FAIL`
3. Missing artifacts MUST result in `status: BLOCKED`
4. CRITICAL / L_CLASS CI jobs MUST have a linked review receipt
5. Snapshot verifier MUST pass as preflight

## Non-Claims

- `local-ci-simulated` is NOT a real CI provider
- `github-actions-template` is a template, NOT an executed run
- `external-ci-placeholder` has NO external CI connected
- NO cloud runner, NO remote execution, NO production CI pipeline

## Secret Policy

- All CI artifacts scanned before sync
- `secretPresent=true/false` only — NEVER dump key content
- `command_redacted` field removes API keys/tokens from logs
- `secrets_detected=true` blocks artifact sync

## Artifact Sync Rules

- `no artifacts = no PASS`
- `secrets detected = BLOCKED`
- `sync failure = PARTIAL / FAILED`, never PASS