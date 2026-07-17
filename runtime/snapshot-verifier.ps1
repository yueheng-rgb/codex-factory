# Snapshot Verifier for Codex Factory V2.9
# Immutable Release Snapshot & Reproducibility Package
# Usage: powershell -File runtime/snapshot-verifier.ps1

param(
    [string]$ManifestPath = "outputs/V2_9/V2_9_IMMUTABLE_SNAPSHOT_MANIFEST.json",
    [string]$BundleIndexPath = "outputs/V2_9/V2_9_BUNDLE_INDEX.json",
    [string]$ClaimSnapshotPath = "outputs/V2_9/V2_9_CLAIM_SNAPSHOT.json",
    [switch]$Json,
    [switch]$Quick
)

$results = @{
    snapshot_id = "CODEX-FACTORY-V2-20260717"
    verified_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    checks = @()
    overall = "PENDING"
}

function Add-Check {
    param($name, $status, $detail)
    $results.checks += @{ name=$name; status=$status; detail=$detail }
}

# Check 1: Manifest exists
if (Test-Path $ManifestPath) {
    Add-Check "manifest_exists" "PASS" $ManifestPath
    try {
        $manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
        Add-Check "manifest_valid_json" "PASS" "Parsed successfully"
        
        # Verify a sample hash
        $sample = ($manifest.categories.governance_core | Where-Object { $_.path -eq "AGENTS.md" })
        if ($sample) {
            $actualHash = (Get-FileHash "AGENTS.md" -Algorithm SHA256).Hash
            if ($sample.sha256 -eq $actualHash) {
                Add-Check "manifest_hash_sample_AGENTS.md" "PASS" "SHA256 matches"
            } else {
                Add-Check "manifest_hash_sample_AGENTS.md" "FAIL" "SHA256 MISMATCH: expected $($sample.sha256), got $actualHash"
            }
        }
    } catch {
        Add-Check "manifest_valid_json" "FAIL" "Parse error: $_"
    }
} else {
    Add-Check "manifest_exists" "FAIL" "Manifest not found: $ManifestPath"
}

# Check 2: Bundle index exists
if (Test-Path $BundleIndexPath) {
    Add-Check "bundle_index_exists" "PASS" $BundleIndexPath
    try {
        $bundles = (Get-Content $BundleIndexPath -Raw | ConvertFrom-Json).bundles
        Add-Check "bundle_count" "PASS" "$($bundles.Count) bundles (expected 8)"
        if ($bundles.Count -ne 8) { Add-Check "bundle_count_warning" "PARTIAL" "Expected 8 bundles, found $($bundles.Count)" }
    } catch {
        Add-Check "bundle_index_valid_json" "FAIL" "Parse error: $_"
    }
} else {
    Add-Check "bundle_index_exists" "FAIL" "Bundle index not found: $BundleIndexPath"
}

# Check 3: Claim snapshot exists
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

# Check 4: V2.0 reports exist (report-verified)
$v20Count = (Get-ChildItem "outputs/V2_0_*" -ErrorAction SilentlyContinue).Count
if ($v20Count -ge 10) {
    Add-Check "v2_0_reports_exist" "PASS" "$v20Count files"
} else {
    Add-Check "v2_0_reports_exist" "PARTIAL" "Only $v20Count V2.0 files found (expected >= 10)"
}

# Check 5: Review receipts exist
$revCount = (Get-ChildItem "reviews/*REV*.json" -ErrorAction SilentlyContinue).Count
if ($revCount -ge 7) {
    Add-Check "review_receipts_exist" "PASS" "$revCount receipts"
} else {
    Add-Check "review_receipts_exist" "PARTIAL" "$revCount receipts (expected >= 7)"
}

# Check 6: Artifact store exists
if (Test-Path "artifacts/RUN-V2_1-20260712-002853") {
    $artCount = (Get-ChildItem "artifacts/RUN-V2_1-20260712-002853" -Recurse -File -ErrorAction SilentlyContinue).Count
    Add-Check "artifact_store_exists" "PASS" "$artCount artifact files"
} else {
    Add-Check "artifact_store_exists" "PARTIAL" "V2.1 artifact bundle not found"
}

# Check 7: Deprecated locks
$lockContent = Get-Content "outputs/V2_0_DEPRECATED_DIRECTIONS_FINAL_LOCK.md" -Raw -ErrorAction SilentlyContinue
if ($lockContent -match "Independent Search Agent|Dual Search Channel|Firecrawl|Implementer direct search") {
    Add-Check "deprecated_locks_intact" "PASS" "Deprecated directions referenced in lock file"
} else {
    Add-Check "deprecated_locks_intact" "PARTIAL" "Lock file content verification incomplete"
}

# Check 8: No secret leak check (basic)
$secretScan = Get-ChildItem outputs/ -Recurse -File | Select-String -Pattern 'sk-[A-Za-z0-9]{20,}' -ErrorAction SilentlyContinue
if ($secretScan.Count -eq 0) {
    Add-Check "no_secrets_in_outputs" "PASS" "No API key patterns found in outputs/"
} else {
    Add-Check "no_secrets_in_outputs" "FAIL" "POTENTIAL SECRETS FOUND IN $($secretScan.Count) FILES"
}

# Check 9: Restore checklist exists
if (Test-Path "outputs/V2_9/V2_9_RESTORE_VERIFY_CHECKLIST.md") {
    Add-Check "restore_checklist_exists" "PASS" "outputs/V2_9/V2_9_RESTORE_VERIFY_CHECKLIST.md"
} else {
    Add-Check "restore_checklist_exists" "FAIL" "Restore checklist not found"
}

# Determine overall
$failCount = ($results.checks | Where-Object { $_.status -eq "FAIL" }).Count
$partialCount = ($results.checks | Where-Object { $_.status -eq "PARTIAL" }).Count
$passCount = ($results.checks | Where-Object { $_.status -eq "PASS" }).Count

if ($failCount -eq 0 -and $partialCount -eq 0) { $results.overall = "PASS" }
elseif ($failCount -eq 0) { $results.overall = "PARTIAL_WITH_REASON" }
else { $results.overall = "FAIL" }

if ($Json) {
    $results | ConvertTo-Json -Depth 3
} else {
    Write-Output "=== Snapshot Verifier ==="
    Write-Output "Snapshot: CODEX-FACTORY-V2-20260717"
    Write-Output "Checks: $($results.checks.Count)"
    Write-Output "PASS: $passCount | PARTIAL: $partialCount | FAIL: $failCount"
    Write-Output "Overall: $($results.overall)"
    Write-Output ""
    foreach ($c in $results.checks) {
        Write-Output "[$($c.status)] $($c.name) — $($c.detail)"
    }
}

