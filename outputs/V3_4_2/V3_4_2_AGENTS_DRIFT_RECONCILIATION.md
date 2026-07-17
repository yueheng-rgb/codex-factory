# Codex Factory V3.4.2 — AGENTS Drift Reconciliation Report

## Root Cause
AGENTS.md SHA256 mismatch between local (Windows CRLF) and remote (Linux LF)
is caused by line-ending normalization differences.

- **Local hash**:  FF12D30467A08A756DE8BCA4DB8DCE9608C4D47909E316021D5BD8F98899C7D2  (CRLF, matches V2_9 manifest)
- **Remote hash**: 6BDA8B2D13BD14F7078933FD06C832F5DD1BBF3D19BBB0EEC50ADC2AAE40347B  (LF, from GitHub Actions Linux runner)
- **Git config**:  core.autocrlf=true (Windows default)
- **V2_9 manifest**: frozen from Windows (CRLF hashes)

## Resolution: Option A — Legitimate Governance Change
Add `.gitattributes` to normalize line endings to LF, regenerate frozen manifest.
This ensures cross-platform hash consistency.

## Actions
1. Add .gitattributes with LF normalization
2. Regenerate V2_9_IMMUTABLE_SNAPSHOT_MANIFEST.json with LF-based hashes
3. Fix snapshot-verifier.ps1 strictness
4. Push and requeue GitHub Actions

## V2_9 Manifest Hash Reconciliation
| File | Old Hash (CRLF) | New Hash (LF) | Status |
|---|---|---|---|
| AGENTS.md | FF12D304... | Will be recomputed after .gitattributes | PENDING |
