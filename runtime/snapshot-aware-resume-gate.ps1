# Codex Factory V3.0 — Snapshot-Aware Resume Gate
# Preflight: verify v2.9 snapshot before allowing execution

param(
    [string]$ClaimedTask = "",
    [string]$ClaimedDirection = "",
    [switch]$Json
)

$gate = @{
    gate_id = "SNAPSHOT-RESUME-GATE-V3_0"
    checked_at = (Get-Date -Format "o")
    checks = @()
    overall = "PENDING"
}

# Check 1: Snapshot verifier
$snapOk = $false
if (Test-Path "runtime/snapshot-verifier.ps1") {
    $snapResult = powershell -File runtime/snapshot-verifier.ps1 2>&1 | Out-String
    $snapOk = $snapResult -match "Overall: PASS"
    $gate.checks += @{ check="snapshot_verifier"; status=if($snapOk){"PASS"}else{"FAIL"}; detail="Snapshot integrity check" }
}

# Check 2: Deprecated direction detection
$deprecatedPatterns = @(
    "Independent Search Agent","Dual Search Channel","Implementer direct search",
    "chat URL extraction as canonical","mock/dry_run.*live","Firecrawl.*canonical search",
    "compression summary.*trusted memory","fake sanitizer","fake human review"
)
$deprecatedHit = $false
foreach ($p in $deprecatedPatterns) {
    if ($ClaimedTask -match $p -or $ClaimedDirection -match $p) {
        $gate.checks += @{ check="deprecated_direction"; status="BLOCKED"; detail="Deprecated pattern detected: $p" }
        $deprecatedHit = $true
        break
    }
}
if (-not $deprecatedHit) {
    $gate.checks += @{ check="deprecated_direction"; status="PASS"; detail="No deprecated patterns detected" }
}

# Check 3: Snapshot conflict detection
if ($ClaimedTask -match "Firecrawl.*search|compression.*summary.*override|snapshot.*outdated") {
    $gate.checks += @{ check="snapshot_conflict"; status="BLOCKED"; detail="Task claims conflict with immutable snapshot" }
} else {
    $gate.checks += @{ check="snapshot_conflict"; status="PASS"; detail="No snapshot conflict detected" }
}

# Check 4: Evidence requirement
if ($ClaimedTask -match "PASS|verified|confirmed" -and $ClaimedTask -notmatch "artifact") {
    $gate.checks += @{ check="evidence_required"; status="NEEDS_RECONCILIATION"; detail="Claim without artifact reference" }
} else {
    $gate.checks += @{ check="evidence_required"; status="PASS"; detail="No unreferenced claims detected" }
}

$blocked = ($gate.checks | Where-Object { $_.status -eq "BLOCKED" }).Count
$gate.overall = if ($blocked -gt 0) { "BLOCKED" } elseif (-not $snapOk) { "FAIL" } else { "PASS" }

if ($Json) { $gate | ConvertTo-Json -Depth 3 }
else { Write-Output "Resume Gate: $($gate.overall) | Snapshot: $(if($snapOk){'OK'}else{'FAIL'}) | Deprecated: $(if($deprecatedHit){'BLOCKED'}else{'OK'})" }
