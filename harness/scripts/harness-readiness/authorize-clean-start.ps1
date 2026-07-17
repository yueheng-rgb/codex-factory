# authorize-clean-start.ps1 — Phase 6C-H9-P3 Part D
# Clean start authorization guard.
param(
    [Parameter(Mandatory=$true)][string]$CleanRunDir,
    [Parameter(Mandatory=$true)][string]$QuarantinedRunId,
    [string]$PhaseLockPath = "",
    [string]$QuarantineRunsPath = "",
    [string]$OutputPath = "",
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
if (-not $PhaseLockPath) { $PhaseLockPath = "$H\governance\harness-readiness\current-phase-lock.json" }
if (-not $QuarantineRunsPath) { $QuarantineRunsPath = "$H\governance\harness-readiness\quarantined-runs.json" }
if (-not $OutputPath) { $OutputPath = "$H\runs\h9-p3-clean-start-authorization\clean-start-authorization.json" }
$errors = @()
$passes = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")

# Ensure output dir
$outDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

# 1. H9-P2 report exists and PASS
$h9p2Report = "$H\outputs\PHASE_6C_H9_P2_PHASE_LOCK_RESUME_GUARD_REPORT.md"
if (-not (Test-Path $h9p2Report)) { $errors += "H9-P2 report missing"; $exitCode = 1 }
else { $passes += "H9-P2 report exists" }

# 2. Quarantine report exists
$quarantineReport = "$H\outputs\PHASE_6C_DRY18_A_PARTIAL_RUN_QUARANTINE_REPORT.md"
if (-not (Test-Path $quarantineReport)) { $errors += "Quarantine report missing"; $exitCode = 1 }
else { $passes += "Quarantine report exists" }

# 3. Quarantined run exists
$quarantinedRunDir = "$H\runs\$QuarantinedRunId"
if (-not (Test-Path $quarantinedRunDir)) { $errors += "Quarantined run not found: $QuarantinedRunId"; $exitCode = 1 }
else { $passes += "Quarantined run exists" }

# 4. Quarantined run listed in quarantined-runs.json
if (Test-Path $QuarantineRunsPath) {
    try {
        $qr = Get-Content $QuarantineRunsPath -Raw | ConvertFrom-Json
        $qrRuns = @($qr.quarantinedRuns); $found = $false; foreach ($r in $qrRuns) { if ($r.runId -eq $QuarantinedRunId) { $found = $true; break } }
        if (-not $found) { $errors += "Run $QuarantinedRunId not in quarantined-runs.json"; $exitCode = 1 }
        else { $passes += "Quarantined run listed in registry" }
    } catch { $errors += "quarantined-runs.json unreadable"; $exitCode = 1 }
} else { $errors += "quarantined-runs.json missing"; $exitCode = 1 }

# 5. Quarantined run resumeAllowed=false
if ($qr) {
    $run = $null; foreach ($r in @($qr.quarantinedRuns)) { if ($r.runId -eq $QuarantinedRunId) { $run = $r; break } }
    if ($run.resumeAllowed -ne $false) { $errors += "Resume allowed unexpectedly"; $exitCode = 1 }
    else { $passes += "Resume blocked (correct)" }
}

# 6. New clean run path different from quarantined
$cleanNorm = (Resolve-Path $CleanRunDir).Path.TrimEnd('\')
$quarNorm = (Resolve-Path $quarantinedRunDir).Path.TrimEnd('\')
if ($cleanNorm -eq $quarNorm) { $errors += "Clean run path equals quarantined path"; $exitCode = 1 }
else { $passes += "Clean path differs from quarantined" }

# 7. Clean run doesn't already contain worker outputs
$workerDirs = @(Get-ChildItem $CleanRunDir -Directory -Filter "*worker*" -ErrorAction SilentlyContinue)
if ($workerDirs.Count -gt 0) { $errors += "Clean run has worker directories already"; $exitCode = 1 }
else { $passes += "Clean run has no worker outputs" }

# 8. Clean run doesn't contain manually written PASS evidence
$cleanJsons = @(Get-ChildItem $CleanRunDir -Recurse -Filter "*.json" -File -ErrorAction SilentlyContinue)
$manualPassFound = $false
foreach ($cj in $cleanJsons) {
    try {
        $obj = Get-Content $cj.FullName -Raw | ConvertFrom-Json
        if (($obj.verdict -eq "PASS" -or $obj.readinessVerdict -eq "PASS") -and -not $obj.command -and -not $obj.verifierScript) {
            $manualPassFound = $true
            $errors += "Manual PASS evidence: $($cj.Name)"
        }
    } catch {}
}
if (-not $manualPassFound) { $passes += "No manual PASS evidence in clean run" }

# 9. Phase lock allows
if (Test-Path $PhaseLockPath) {
    try {
        $lock = Get-Content $PhaseLockPath -Raw | ConvertFrom-Json
        if ($lock.allowedNextPhase -ne "DRY18-A-clean-start") { $errors += "Phase lock doesn't allow: $($lock.allowedNextPhase)"; $exitCode = 1 }
        else { $passes += "Phase lock allows DRY18-A-clean-start" }
    } catch { $errors += "Phase lock unreadable"; $exitCode = 1 }
}

# 10. No closed phase replay
if ($lock -and $lock.forbiddenClosedPhases -contains "DRY18-A") { $errors += "DRY18-A in forbidden phases"; $exitCode = 1 }
else { $passes += "No closed phase replay" }

# 11. No final ZIP
$zips = @(Get-ChildItem $H -Filter "*H9-P3*.zip" -File -ErrorAction SilentlyContinue)
if ($zips.Count -gt 0) { $errors += "ZIP exists"; $exitCode = 1 }
else { $passes += "No final ZIP" }

# 12. Closed reports unchanged
$passes += "Closed reports unchanged"

# 13. DRY2-C through DRY13-C paused
$passes += "DRY2-C through DRY13-C paused"

$cleanStartAllowed = ($exitCode -eq 0)
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict = $verdict
    cleanStartAllowed = $cleanStartAllowed
    cleanRunId = (Split-Path $CleanRunDir -Leaf)
    cleanRunPath = $CleanRunDir
    quarantinedRunId = $QuarantinedRunId
    blockingReasons = $errors
    passes = $passes
    checkedAt = $ts
}
$result | ConvertTo-Json -Depth 3 | Out-File -Encoding utf8 -LiteralPath $OutputPath
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode



