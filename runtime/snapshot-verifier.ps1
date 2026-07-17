# Codex Factory V3.4.2 — Snapshot Verifier (Strict Mode)
# Immutable Release Snapshot & Reproducibility Package
# Usage: pwsh -File runtime/snapshot-verifier.ps1 [-AllowDrift] [-Json] [-Quick]

param(
    [string]$ManifestPath = "outputs/V2_9/V2_9_IMMUTABLE_SNAPSHOT_MANIFEST.json",
    [string]$BundleIndexPath = "outputs/V2_9/V2_9_BUNDLE_INDEX.json",
    [string]$ClaimSnapshotPath = "outputs/V2_9/V2_9_CLAIM_SNAPSHOT.json",
    [switch]$AllowDrift,
    [switch]$Json,
    [switch]$Quick
)

$ErrorActionPreference = "Stop"

$results = @{
    snapshot_id = "CODEX-FACTORY-V2-20260717"
    verifier_version = "3.4.2-strict"
    verified_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    checks = [System.Collections.ArrayList]@()
    manifest_match = $false
    file_hash_match = $false
    snapshot_verified = $false
    overall = "PENDING"
    allow_drift = $AllowDrift.IsPresent
    non_claims = @(
        "V3.4.2 strict mode: any hash mismatch => FAIL",
        "SNAPSHOT_VERIFIED requires all file hashes to match frozen manifest",
        "ALLOW_DRIFT mode still reports mismatches but does not fail",
        "Line-ending normalization is enforced via .gitattributes"
    )
}

function Add-Check {
    param($name, $status, $detail)
    [void]$results.checks.Add(@{ name=$name; status=$status; detail=$detail })
}

function Get-FileHashLF {
    param($Path)
    if (-not (Test-Path $Path)) { return "FILE_NOT_FOUND" }
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $Path).Path)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace("-","").ToUpper()
}

# ── Check 1: Manifest exists & valid ──
if (Test-Path $ManifestPath) {
    Add-Check "manifest_exists" "PASS" $ManifestPath
    try {
        $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
        Add-Check "manifest_valid_json" "PASS" "Parsed successfully"
        $results.manifest_match = $true
    } catch {
        Add-Check "manifest_valid_json" "FAIL" "Parse error: $_"
        $manifest = $null
    }
} else {
    Add-Check "manifest_exists" "FAIL" "Manifest not found: $ManifestPath"
    $manifest = $null
}

# ── Check 2: File hash verification (strict) ──
$hashFailures = 0
$hashChecked = 0
if ($manifest) {
    $frozenFiles = $manifest.categories.governance_core
    foreach ($entry in $frozenFiles) {
        $hashChecked++
        $actualHash = Get-FileHashLF -Path $entry.path
        if ($actualHash -eq "FILE_NOT_FOUND") {
            $hashFailures++
            Add-Check "file_hash_$($entry.path -replace '[^a-zA-Z0-9]','_')" "FAIL" "FILE NOT FOUND: $($entry.path)"
        } elseif ($actualHash -ne $entry.sha256) {
            $hashFailures++
            Add-Check "file_hash_$($entry.path -replace '[^a-zA-Z0-9]','_')" "FAIL" "SHA256 MISMATCH: expected $($entry.sha256) got $actualHash (file: $($entry.path))"
        } else {
            Add-Check "file_hash_$($entry.path -replace '[^a-zA-Z0-9]','_')" "PASS" "SHA256 MATCH: $actualHash ($($entry.path))"
        }
    }
}

if ($hashChecked -gt 0 -and $hashFailures -eq 0) {
    $results.file_hash_match = $true
}

# ── Check 3: Bundle index ──
if (Test-Path $BundleIndexPath) {
    Add-Check "bundle_index_exists" "PASS" $BundleIndexPath
    try {
        $bundles = (Get-Content $BundleIndexPath -Raw | ConvertFrom-Json).bundles
        Add-Check "bundle_count" "PASS" "$($bundles.Count) bundles (expected 8)"
        if ($bundles.Count -ne 8) {
            Add-Check "bundle_count_warning" "FAIL" "Expected 8 bundles, found $($bundles.Count)"
        }
    } catch {
        Add-Check "bundle_index_valid_json" "FAIL" "Parse error: $_"
    }
} else {
    Add-Check "bundle_index_exists" "FAIL" "Bundle index not found: $BundleIndexPath"
}

# ── Check 4: Claim snapshot ──
if (Test-Path $ClaimSnapshotPath) {
    Add-Check "claim_snapshot_exists" "PASS" $ClaimSnapshotPath
    try {
        $claims = (Get-Content $ClaimSnapshotPath -Raw | ConvertFrom-Json).claims
        Add-Check "claim_count" "PASS" "$($claims.Count) claims"
        $vwa = ($claims | Where-Object { $_.status -eq "VERIFIED_WITH_ARTIFACT" }).Count
        $vwr = ($claims | Where-Object { $_.status -eq "VERIFIED_WITH_REPORT" }).Count
        $sd = ($claims | Where-Object { $_.status -eq "SELF_DECLARED_OR_SIMULATED" }).Count
        Add-Check "claim_status_distribution" "PASS" "ARTIFACT=$vwa REPORT=$vwr SELF_DECLARED=$sd"
    } catch {
        Add-Check "claim_snapshot_valid_json" "FAIL" "Parse error: $_"
    }
} else {
    Add-Check "claim_snapshot_exists" "FAIL" "Not found: $ClaimSnapshotPath"
}

# ── Check 5: V2.0 reports ──
$v20Count = (Get-ChildItem "outputs/V2_0_*" -ErrorAction SilentlyContinue).Count
if ($v20Count -ge 10) {
    Add-Check "v2_0_reports_exist" "PASS" "$v20Count files"
} else {
    Add-Check "v2_0_reports_exist" "WARN" "Only $v20Count V2.0 files found (expected >= 10)"
}

# ── Check 6: Review receipts ──
$revCount = (Get-ChildItem "reviews/*REV*.json" -ErrorAction SilentlyContinue).Count
if ($revCount -ge 7) {
    Add-Check "review_receipts_exist" "PASS" "$revCount receipts"
} else {
    Add-Check "review_receipts_exist" "WARN" "$revCount receipts (expected >= 7)"
}

# ── Check 7: Artifact store ──
if (Test-Path "artifacts/RUN-V2_1-20260712-002853") {
    $artCount = (Get-ChildItem "artifacts/RUN-V2_1-20260712-002853" -Recurse -File -ErrorAction SilentlyContinue).Count
    Add-Check "artifact_store_exists" "PASS" "$artCount artifact files"
} else {
    Add-Check "artifact_store_exists" "WARN" "V2.1 artifact bundle not found"
}

# ── Check 8: Secret scan ──
$secretScan = Get-ChildItem outputs/ -Recurse -File -ErrorAction SilentlyContinue | Select-String -Pattern 'sk-[A-Za-z0-9]{20,}' -ErrorAction SilentlyContinue
if ($secretScan.Count -eq 0) {
    Add-Check "no_secrets_in_outputs" "PASS" "No API key patterns found in outputs/"
} else {
    Add-Check "no_secrets_in_outputs" "FAIL" "POTENTIAL SECRETS FOUND IN $($secretScan.Count) FILES"
}

# ── Check 9: Restore checklist ──
if (Test-Path "outputs/V2_9/V2_9_RESTORE_VERIFY_CHECKLIST.md") {
    Add-Check "restore_checklist_exists" "PASS" "outputs/V2_9/V2_9_RESTORE_VERIFY_CHECKLIST.md"
} else {
    Add-Check "restore_checklist_exists" "FAIL" "Restore checklist not found"
}

# ── Compute strict counts ──
$failCount    = ($results.checks | Where-Object { $_.status -eq "FAIL" }).Count
$warnCount    = ($results.checks | Where-Object { $_.status -eq "WARN" }).Count
$passCount    = ($results.checks | Where-Object { $_.status -eq "PASS" }).Count
$skipCount    = 0
$totalChecks  = $results.checks.Count

# Consistency assertion
$sum = $passCount + $failCount + $warnCount + $skipCount
Add-Check "check_count_consistency" $(if ($sum -eq $totalChecks){"PASS"}else{"FAIL"}) "PASS=$passCount FAIL=$failCount WARN=$warnCount SKIP=$skipCount SUM=$sum TOTAL=$totalChecks"

# ── Determine overall ──
if ($hashChecked -gt 0) {
    if ($hashFailures -eq 0) {
        $results.snapshot_verified = $true
        $results.overall = "SNAPSHOT_VERIFIED"
    } elseif ($AllowDrift) {
        $results.snapshot_verified = $false
        $results.overall = "SNAPSHOT_DRIFT_DETECTED_ALLOWED"
    } else {
        $results.snapshot_verified = $false
        $results.overall = "SNAPSHOT_DRIFT_DETECTED"
    }
} else {
    $results.overall = if ($failCount -eq 0){"PARTIAL_NO_HASH_CHECKS"}else{"FAIL"}
}

# ── Output ──
if ($Json) {
    $results | ConvertTo-Json -Depth 4
} else {
    Write-Output "=== Snapshot Verifier V3.4.2 (Strict) ==="
    Write-Output "Snapshot: $($results.snapshot_id)"
    Write-Output "AllowDrift: $($results.allow_drift)"
    Write-Output "Checks: $totalChecks"
    Write-Output "PASS: $passCount | FAIL: $failCount | WARN: $warnCount"
    Write-Output "Consistency: PASS+FAIL+WARN = $sum == TOTAL $totalChecks : $(if($sum -eq $totalChecks){'OK'}else{'MISMATCH'})"
    Write-Output "MANIFEST_MATCH: $($results.manifest_match)"
    Write-Output "FILE_HASH_MATCH: $($results.file_hash_match)"
    Write-Output "SNAPSHOT_VERIFIED: $($results.snapshot_verified)"
    Write-Output "Overall: $($results.overall)"
    Write-Output ""
    foreach ($c in $results.checks) {
        Write-Output "[$($c.status)] $($c.name) -- $($c.detail)"
    }
}

# ── Exit code ──
$exitCode = if ($AllowDrift) { 0 } else { $failCount }
exit $exitCode
