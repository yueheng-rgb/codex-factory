# V2.9 — Restore / Verify Checklist

**Snapshot**: CODEX-FACTORY-V2-20260717
**Date**: 2026-07-17

---

## New Window / New Machine Recovery

### Step 1: Verify Snapshot Manifest
```powershell
# Check manifest exists
Test-Path outputs/V2_9/V2_9_IMMUTABLE_SNAPSHOT_MANIFEST.json

# Verify SHA256 for a sample file
$manifest = Get-Content outputs/V2_9/V2_9_IMMUTABLE_SNAPSHOT_MANIFEST.json | ConvertFrom-Json
$expected = ($manifest.categories.governance_core | Where-Object { $_.path -eq "AGENTS.md" }).sha256
$actual = (Get-FileHash AGENTS.md -Algorithm SHA256).Hash
if ($expected -eq $actual) { "PASS" } else { "FAIL: AGENTS.md hash mismatch" }
```

### Step 2: Verify Bundle Index
```powershell
Test-Path outputs/V2_9/V2_9_BUNDLE_INDEX.json
# Check all 8 bundles referenced
$bundles = (Get-Content outputs/V2_9/V2_9_BUNDLE_INDEX.json | ConvertFrom-Json).bundles
$bundles.Count  # Should be 8
```

### Step 3: Verify Artifact Store
```powershell
Test-Path artifacts/RUN-V2_1-20260712-002853
(Get-ChildItem artifacts/RUN-V2_1-20260712-002853 -Recurse -File).Count  # Should be 21
```

### Step 4: Verify Review Receipts
```powershell
# V2.2 receipts
Test-Path reviews/REV-0001.json
Test-Path reviews/REV-0002.json
Test-Path reviews/REV-0003.json
Test-Path reviews/REV-0004.json
Test-Path reviews/demo-to-receipt-mapping.json
# V2.7 receipts
Test-Path reviews/V2_7-REV-001-security.json
Test-Path reviews/V2_7-REV-002-business-invariant.json
Test-Path reviews/V2_7-REV-003-production-readiness.json
Test-Path reviews/V2_7-REV-004-release-risk.json
```

### Step 5: Verify Audit Ledger
```powershell
# Cross-pack integration ledgers
Test-Path testbeds/cross-pack-cpm-001/integration-ledger.json
Test-Path testbeds/cross-pack-cpm-004/integration-ledger.json
```

### Step 6: Verify Deprecated Locks
```powershell
# Check AGENTS.md contains search doctrine
Select-String -Path AGENTS.md -Pattern "Independent Search Agent|Dual Search Channel|Firecrawl" | Measure-Object
# Should return >= 3 matches

# Check V2.0 deprecated lock
Test-Path outputs/V2_0_DEPRECATED_DIRECTIONS_FINAL_LOCK.md
```

### Step 7: Confirm No Secrets Leaked
```powershell
# Scan for API key patterns (redacted check)
Select-String -Path outputs/ -Recurse -Pattern "sk-[A-Za-z0-9]{20,}" | Measure-Object
# Should return 0

Select-String -Path reviews/ -Recurse -Pattern "sk-[A-Za-z0-9]{20,}" | Measure-Object
# Should return 0
```

### Step 8: Confirm Report Counts Match Artifacts
```powershell
# V2.0: 14 report files
(Get-ChildItem outputs/V2_0_*).Count  # Should be 14

# V2.4: 1 report
Test-Path outputs/V2_4/V2_4_RUNTIME_VALIDATION_BATCH_REPORT.md

# V2.8: 8 report files (6 audit + 1 main + 1 risk)
(Get-ChildItem outputs/V2_8/ -File).Count  # Should be >= 7
```

### Step 9: Confirm READY_FOR_PRODUCTION_REVIEW Not Exaggerated
```powershell
# Check V2.7 release gate
$gate = Get-Content outputs/V2_7/V2_7_RELEASE_GATE_DECISION.json | ConvertFrom-Json
$gate.final_gate_decision  # Should be "READY_FOR_PRODUCTION_REVIEW" NOT "READY_FOR_PRODUCTION"
$gate.non_claims.Count  # Should be >= 4
```

### Step 10: Confirm Compression Summary Cannot Override Trusted State
```powershell
# Resume gate exists
Test-Path runtime/resume-gate.ps1
# Memory admission gate exists
Test-Path runtime/memory-admission-gate.ps1
```

---

## Quick Validation Command
```powershell
# Run the snapshot verifier
powershell -File runtime/snapshot-verifier.ps1
```

## Expected Result
All checks should PASS or PARTIAL_WITH_REASON. No FAIL unless files have been modified or deleted.
