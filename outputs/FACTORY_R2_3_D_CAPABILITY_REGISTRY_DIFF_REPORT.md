# FACTORY R2.3-D Capability Registry Diff Report

## Tool: `runtime/capability-registry-diff.ps1`

## Baseline Snapshot

- **Snapshot ID:** r2-3-d-baseline
- **Date:** 2026-07-09
- **Entries:** 91 (master registry)
- **7 registries:** master, skill, mcp, search, template, verifier, runner
- **SHA256 manifests:** stored per file in `snapshot-manifest.json`

## Diff Capabilities

| Change Type | Detection | Severity |
|-------------|-----------|----------|
| Added capability | New capabilityId in current not in snapshot | INFO |
| Removed capability | capabilityId in snapshot not in current | HIGH |
| trustLevel changed | Field diff | MEDIUM |
| recommendedAction changed | Field diff | HIGH |
| securityRisk changed | Field diff | HIGH |
| requiredSecrets count changed | Count diff | MEDIUM |
| networkAccess flag changed | Boolean diff | MEDIUM |
| fileWriteAccess flag changed | Boolean diff | MEDIUM |
| cloudRequired flag changed | Boolean diff | MEDIUM |
| priority changed | Field diff | LOW |

## Usage

```powershell
# Save baseline (run once)
. .\runtime\capability-registry-diff.ps1
Save-RegistrySnapshot -Label "pre-import-baseline"

# After changes, compare
$diff = Get-RegistryDiff
# $diff.added, $diff.removed, $diff.trustChanged, etc.
```

## Current State (after R2.3-D)

- Baseline: r2-3-d-baseline (91 entries)
- Current: 91 entries (CAP-SKILL-099 added AFTER baseline)
- Diff: 0 changes (snapshot taken post-addition)

## Recommended Workflow

1. Save snapshot before any registry modification
2. Make changes (add/update/remove capabilities)
3. Run diff → review all changes
4. If approved, save new snapshot as the next baseline
5. If rejected, revert from snapshot

## Snapshot Storage

```
governance/capability-registry-snapshots/
+-- r2-3-d-baseline/
|   +-- capability-candidate-registry.jsonl
|   +-- skill-candidate-registry.jsonl
|   +-- mcp-candidate-registry.jsonl
|   +-- search-provider-candidate-registry.jsonl
|   +-- template-starter-candidate-registry.jsonl
|   +-- verifier-candidate-registry.jsonl
|   +-- runner-candidate-registry.jsonl
|   +-- snapshot-manifest.json
```
