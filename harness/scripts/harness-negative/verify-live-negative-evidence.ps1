# verify-live-negative-evidence.ps1 — Phase 6C-H6
# Verifies that a live negative control has complete evidence
param([Parameter(Mandatory=$true)][string]$RunDir)
$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

$fm = Join-Path $RunDir "fault-manifest.json"
$tr = Join-Path $RunDir "reports\acceptance-transcript.json"
$ac = Join-Path $RunDir "reports\tenant-metering-acceptance-report.json"

# Check fault manifest
if (Test-Path $fm) {
    $manifest = Get-Content $fm -Raw | ConvertFrom-Json
    if ($manifest.negativeId) { [void]$passes.Add("Fault manifest: valid") } else { [void]$errors.Add("Fault manifest: invalid"); $exitCode=1 }
    $hashChanged = $false
if ($manifest.changedFiles -and $manifest.changedFiles.Count -gt 0) {
    $hashChanged = ($manifest.changedFiles[0].beforeSha256 -ne $manifest.changedFiles[0].afterSha256)
} elseif ($manifest.beforeHash -and $manifest.afterHash) {
    $hashChanged = ($manifest.beforeHash -ne $manifest.afterHash)
}
if ($hashChanged) {
        [void]$passes.Add("Fault manifest: hash changed")
    } else { [void]$errors.Add("Fault manifest: hash NOT changed"); $exitCode=1 }
} else { [void]$errors.Add("Fault manifest: MISSING"); $exitCode=1 }

# Check transcript
if (Test-Path $tr) {
    $transcript = Get-Content $tr -Raw | ConvertFrom-Json
    if ($transcript.transcript) { [void]$passes.Add("Transcript: exists ($($transcript.transcript.Count) scenarios)") } else { [void]$errors.Add("Transcript: empty"); $exitCode=1 }
    $failed = @($transcript.transcript | Where-Object { -not $_.passed })
    if ($failed.Count -gt 0) { [void]$passes.Add("Transcript: $($failed.Count) failed scenarios") } else { [void]$errors.Add("Transcript: NO failures (target-gate negative must fail)"); $exitCode=1 }
} else { [void]$errors.Add("Transcript: MISSING"); $exitCode=1 }

# Check acceptance JSON
if (Test-Path $ac) { [void]$passes.Add("Acceptance JSON: exists") } else { [void]$errors.Add("Acceptance JSON: MISSING"); $exitCode=1 }

# Check no pre-classified only
$dnr = Join-Path $RunDir "reports\domain-negative-result.json"
$hasTranscript = Test-Path $tr
if ((Test-Path $dnr) -and -not $hasTranscript) { [void]$errors.Add("PRE-CLASSIFIED ONLY: domain-negative-result.json without transcript"); $exitCode=1 }
if ($hasTranscript) { [void]$passes.Add("Live execution confirmed: transcript present") }

$cp = Join-Path $RunDir "reports\corrupted-path.txt"
if (Test-Path $cp) {
    $corrupt = Get-Content $cp -Raw
    if ($corrupt -match '^[a-z]+/[a-z]+') {
        [void]$errors.Add("Corrupted evidence path detected: $($corrupt.Trim())")
        $exitCode = 1
    }
}
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
Write-Output (@{verdict=$verdict; passCount=$passes.Count; failCount=$errors.Count; passes=@($passes); errors=@($errors); timestamp=(Get-Date).ToString("o")} | ConvertTo-Json -Depth 3)
exit $exitCode


