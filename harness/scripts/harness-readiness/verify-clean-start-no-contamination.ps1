# verify-clean-start-no-contamination.ps1 — Phase 6C-H9-P3 Part E
# Anti-contamination check: ensures clean run has no copied evidence from quarantined run.
param(
    [Parameter(Mandatory=$true)][string]$CleanRunDir,
    [Parameter(Mandatory=$true)][string]$QuarantinedRunDir,
    [switch]$PreStart,  # Run in pre-start mode (clean should be empty scaffold)
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$errors = @()
$passes = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")

# 1. Paths differ
$cleanNorm = (Resolve-Path $CleanRunDir).Path.TrimEnd('\')
$quarNorm = (Resolve-Path $QuarantinedRunDir).Path.TrimEnd('\')
if ($cleanNorm -eq $quarNorm) { $errors += "Paths are identical"; $exitCode = 1 }
else { $passes += "Paths differ" }

# 2. Clean run has no files copied from quarantined run (hash comparison)
$quarFiles = @(Get-ChildItem $QuarantinedRunDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(js|json|md|jsonl)$' })
$cleanFiles = @(Get-ChildItem $CleanRunDir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\.(js|json|md|jsonl)$' })

$copiedHashes = @()
foreach ($cf in $cleanFiles) {
    $cHash = (Get-FileHash $cf.FullName -Algorithm SHA256).Hash
    foreach ($qf in $quarFiles) {
        $qHash = (Get-FileHash $qf.FullName -Algorithm SHA256).Hash
        if ($cHash -eq $qHash) {
            $copiedHashes += "$($cf.Name) matches $($qf.Name)"
        }
    }
}
if ($copiedHashes.Count -gt 0) {
    $errors += "COPIED_FILES: $($copiedHashes.Count) hash matches between clean and quarantined"
    $exitCode = 1
} else { $passes += "No hash-matched copies from quarantined run" }

# 3. Clean run doesn't reuse quarantined readiness PASS JSON
$quarReadiness = "$QuarantinedRunDir\readiness"
$cleanReadiness = "$CleanRunDir\readiness"
if ((Test-Path $quarReadiness) -and (Test-Path $cleanReadiness)) {
    $quarRJ = Get-ChildItem $quarReadiness -Filter "*.json" -ErrorAction SilentlyContinue
    $cleanRJ = Get-ChildItem $cleanReadiness -Filter "*.json" -ErrorAction SilentlyContinue
    foreach ($qrj in $quarRJ) {
        foreach ($crj in $cleanRJ) {
            if ($qrj.Name -eq $crj.Name) {
                $errors += "REUSED_READINESS: $($qrj.Name) exists in both"
                $exitCode = 1
            }
        }
    }
    if ($exitCode -eq 0) { $passes += "No reused readiness evidence" }
} else { $passes += "Readiness comparison: N/A" }

# 4. Clean run doesn't reuse quarantined canonical-integrated
$quarCanon = "$QuarantinedRunDir\canonical-integrated"
$cleanCanon = "$CleanRunDir\canonical-integrated"
if ((Test-Path $quarCanon) -and (Test-Path $cleanCanon)) {
    $errors += "REUSED_INTEGRATED: canonical-integrated exists in both"
    $exitCode = 1
} elseif (Test-Path $cleanCanon) {
    # Check if files in clean canonical match quarantined hashes
    $passes += "Canonical comparison: clean has own integrated (pre-start should be empty)"
} else { $passes += "No reused canonical-integrated" }

# 5. Clean run doesn't reuse quarantined reports
$quarReports = "$QuarantinedRunDir\reports"
$cleanReports = "$CleanRunDir\reports"
if ((Test-Path $quarReports) -and (Test-Path $cleanReports)) {
    $qrFiles = @(Get-ChildItem $quarReports -Filter "*.json" -ErrorAction SilentlyContinue)
    $crFiles = @(Get-ChildItem $cleanReports -Filter "*.json" -ErrorAction SilentlyContinue)
    if ($crFiles.Count -gt 0) {
        foreach ($crf in $crFiles) {
            foreach ($qrf in $qrFiles) {
                if ($crf.Name -eq $qrf.Name) { $errors += "REUSED_REPORT: $($crf.Name)"; $exitCode = 1 }
            }
        }
    }
    if ($exitCode -eq 0) { $passes += "No reused report evidence" }
}

# 6. Pre-start mode: clean run should have minimal content
if ($PreStart) {
    # Only clean-start-marker.json expected; no contracts, no workers, no canonical
    $workerDirs = @(Get-ChildItem $CleanRunDir -Directory -Filter "*worker*" -ErrorAction SilentlyContinue)
    if ($workerDirs.Count -gt 0) { $errors += "PRE_START: Worker directories exist"; $exitCode = 1 }
    else { $passes += "Pre-start: no workers" }
    
    $passEvidence = @(Get-ChildItem $CleanRunDir -Recurse -Filter "*.json" -File -ErrorAction SilentlyContinue | Where-Object {
        try { $o = Get-Content $_.FullName -Raw | ConvertFrom-Json; $o.verdict -eq "PASS" } catch { $false }
    })
    if ($passEvidence.Count -gt 1) { $errors += "PRE_START: PASS evidence exists beyond marker"; $exitCode = 1 }
    else { $passes += "Pre-start: no PASS evidence beyond marker" }
}

# 7. Clean run lacks RUN_STATE (expected in pre-start)
$stateFile = Join-Path $CleanRunDir "RUN_STATE.jsonl"
if (Test-Path $stateFile) { $passes += "RUN_STATE present (post-start mode)" }
else { $passes += "No RUN_STATE (pre-start, expected)" }

$classification = if ($exitCode -eq 0) { "PASS" } else {
    $errStr = $errors -join " "
    if ($errStr -match "COPIED|REUSED|identical") { "FAIL_CONTRACT_DRIFT" }
    elseif ($errStr -match "PRE_START") { "FAIL_CONTRACT_DRIFT" }
    else { "FAIL_HARNESS_NOISE" }
}
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict = $verdict
    classification = $classification
    cleanRunDir = $CleanRunDir
    quarantinedRunDir = $QuarantinedRunDir
    preStartMode = $PreStart.IsPresent
    errors = $errors
    passes = $passes
    hashMatches = $copiedHashes
    checkedAt = $ts
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
