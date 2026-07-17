# V3.3 — Cross-Machine Snapshot Hash Comparison

## Status

**REMOTE_ARTIFACT_NOT_PROVIDED** — no remote artifact to compare against.

## Local Snapshot

| File | Status |
|------|--------|
| V2_9_IMMUTABLE_SNAPSHOT_MANIFEST.json | PRESENT |
| Local key file hashes | 6/6 available |
| AGENTS.md | Hash available |
| execution-runner.ps1 | Hash available |
| expert-pack-registry.json | Hash available |
| DEPRECATED_LOCKS.md | Hash available |
| claim-snapshot.json | Hash available |
| codex-factory-ci.yml | Hash available |

## Cross-Machine Comparison

| Check | Result |
|-------|--------|
| Remote artifact present | NOT_PROVIDED |
| Cross-machine comparison | SKIPPED |

## How to Complete

1. Run the CI workflow on GitHub Actions
2. Download the artifact ZIP
3. Place it at `artifacts/remote/<run-id>/artifact.zip`
4. Run: `powershell -File runtime/cross-machine-snapshot-comparison.ps1 -RemoteArtifactDir "artifacts/remote/<run-id>/extracted"`

## Non-Claims

- Without remote artifact, comparison is LOCAL_ONLY
- LOCAL_ONLY does not constitute cross-machine trust
- SNAPSHOT_MATCH requires real remote snapshot verifier output