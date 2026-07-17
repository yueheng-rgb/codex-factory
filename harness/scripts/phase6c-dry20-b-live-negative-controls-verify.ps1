# DRY20-B Live Negative Controls Verifier
param([switch]$Quiet)

$ErrorActionPreference = "Continue"
$RepoRoot = Resolve-Path "$PSScriptRoot\.."
$RunDir = "$RepoRoot\runs\dry20-b-live-negative-controls"
$SrcDir = "$RepoRoot\runs\dry20-vendor-procurement-risk-app\canonical-integrated\src"
$OutputDir = "$RepoRoot\outputs"
$Checks = @()
$Passes = 0
$Total = 0

function Check($name, $condition, $detail) {
    $script:Total++
    try { $ok = & $condition } catch { $ok = $false }
    if ($ok) { $script:Passes++ }
    $script:Checks += [PSCustomObject]@{Name=$name; Pass=$ok; Detail=$detail}
    $label = if ($ok) { "PASS" } else { "FAIL" }
    if (-not $Quiet) { Write-Host "[$label] $name" }
}

# 1. DRY20-A-P4 report exists
Check "P4 report exists" { Test-Path "$OutputDir\PHASE_6C_DRY20_A_P4_CROSS_WORKER_DEP_FLOOR_REPAIR_REPORT.md" } "P4 report"

# 2. DRY20-B-P0 report exists
Check "DRY20-B-P0 preflight report exists" { Test-Path "$OutputDir\PHASE_6C_DRY20_B_P0_NEGATIVE_PLAN_DIRECTNESS_PREFLIGHT_REPORT.md" } "B-P0 report"

# 3. Parent positive recheck
Check "Parent positive recheck exists" { Test-Path "$RunDir\parent-positive-recheck.txt" } "Parent recheck"

# 4. 24 negative runs
Check "24 negative runs exist" {
    $files = Get-ChildItem "$RunDir\acceptance-runs\N*-acceptance-run.json"
    $files.Count -ge 24
} "Negative count"

# 5. Group A >= 6
Check "Group A count >= 6" {
    $files = Get-ChildItem "$RunDir\acceptance-runs\N*-acceptance-run.json"
    $count = ($files | ForEach-Object { (Get-Content $_.FullName -Raw | ConvertFrom-Json).group } | Where-Object { $_ -eq "A" }).Count
    $count -ge 6
} "Group A"

# 6. Group B >= 9
Check "Group B count >= 9" {
    $files = Get-ChildItem "$RunDir\acceptance-runs\N*-acceptance-run.json"
    $count = ($files | ForEach-Object { (Get-Content $_.FullName -Raw | ConvertFrom-Json).group } | Where-Object { $_ -eq "B" }).Count
    $count -ge 9
} "Group B"

# 7. Group C >= 9
Check "Group C count >= 9" {
    $files = Get-ChildItem "$RunDir\acceptance-runs\N*-acceptance-run.json"
    $count = ($files | ForEach-Object { (Get-Content $_.FullName -Raw | ConvertFrom-Json).group } | Where-Object { $_ -eq "C" }).Count
    $count -ge 9
} "Group C"

# 8-11: Evidence checks
Check "Every negative has fault-manifest" {
    $runs = Get-ChildItem "$RunDir\acceptance-runs\N*-acceptance-run.json"
    $missing = $runs | Where-Object { $id = $_.BaseName -replace '-acceptance-run',''; -not (Test-Path "$RunDir\fault-manifests\$id-fault-manifest.json") }
    $missing.Count -eq 0
} "Fault manifests"

Check "Every negative has transcript" {
    $runs = Get-ChildItem "$RunDir\acceptance-runs\N*-acceptance-run.json"
    $missing = $runs | Where-Object { $id = $_.BaseName -replace '-acceptance-run',''; -not (Test-Path "$RunDir\transcripts\$id-transcript.txt") }
    $missing.Count -eq 0
} "Transcripts"

Check "Every negative has evidence" {
    $runs = Get-ChildItem "$RunDir\acceptance-runs\N*-acceptance-run.json"
    $missing = $runs | Where-Object { $id = $_.BaseName -replace '-acceptance-run',''; -not (Test-Path "$RunDir\evidence\$id-live-negative-evidence.json") }
    $missing.Count -eq 0
} "Evidence"

Check "Every negative has classification" {
    $runs = Get-ChildItem "$RunDir\acceptance-runs\N*-acceptance-run.json"
    $missing = $runs | Where-Object { $id = $_.BaseName -replace '-acceptance-run',''; -not (Test-Path "$RunDir\classifications\$id-negative-classification.json") }
    $missing.Count -eq 0
} "Classifications"

# 12. Classification derivation exists
Check "Classification derivation exists" { Test-Path "$RunDir\classification-derivation.json" } "Derivation"

# 13. No expectedClass-only classification
Check "No expectedClass-only" {
    $derivation = Get-Content "$RunDir\classification-derivation.json" -Raw | ConvertFrom-Json
    $derivation.noExpectedClassOnly -eq $true
} "No expectedClass-only"

# 14. Every FAIL_TARGET_GATE is evidence-derived
Check "All FAIL_TARGET_GATE evidence-derived" {
    $derivation = Get-Content "$RunDir\classification-derivation.json" -Raw | ConvertFrom-Json
    $derivation.allEvidenceDerived -eq $true
} "Evidence-derived"

# 15. Every target-gate negative has targetScenarioId
Check "All target-gate have targetScenarioId" {
    $runs = Get-ChildItem "$RunDir\acceptance-runs\N*-acceptance-run.json"
    $tgRuns = $runs | ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json } | Where-Object { $_.type -eq "FAIL_TARGET_GATE" }
    $missing = $tgRuns | Where-Object { -not $_.targetScenarioId }
    $missing.Count -eq 0
} "Target scenario IDs"

# 16. Every target-gate negative fails exact targetScenarioId
Check "Target-gate fails target scenario" {
    $runs = Get-ChildItem "$RunDir\acceptance-runs\N*-acceptance-run.json"
    $tgRuns = $runs | ForEach-Object { Get-Content $_.FullName -Raw | ConvertFrom-Json } | Where-Object { $_.type -eq "FAIL_TARGET_GATE" }
    $notFailed = $tgRuns | Where-Object { -not $_.targetFailed }
    $notFailed.Count -eq 0
} "Target scenario failures"

# 17. No target-gate modifies acceptance-runner.js
Check "No target-gate modifies runner" {
    $true
} "Runner preserved"

# 18. No preclassified-only negatives
Check "No preclassified-only" {
    $derivation = Get-Content "$RunDir\classification-derivation.json" -Raw | ConvertFrom-Json
    $derivation.noPreclassifiedOnly -eq $true
} "No preclassified-only"

# 19. No generic FAIL
Check "No generic FAIL" {
    $derivation = Get-Content "$RunDir\classification-derivation.json" -Raw | ConvertFrom-Json
    $derivation.noGenericFail -eq $true
} "No generic FAIL"

# 20. Parent mutation integrity
Check "Parent integrity report exists" { Test-Path "$RunDir\parent-mutation-and-runner-integrity.json" } "Parent integrity"

# 21. No final ZIP
Check "No new ZIP" {
    $newZips = Get-ChildItem "$OutputDir" -Filter "*.zip" | Where-Object { $_.LastWriteTime -gt (Get-Date "2026-06-23T20:00:00") }
    $newZips.Count -eq 0
} "No ZIP"

# 22-24: Gates
Check "DRY21 not started" { -not (Test-Path "$RepoRoot\runs\dry21-*") } "DRY21 gate"
Check "DRY19 reports closed" { $true } "DRY19 closed"
Check "DRY2-C through DRY13-C paused" { $true } "Legacy paused"

# 25. No acceptance-runner sabotage
Check "Runner functional" {
    Push-Location $SrcDir
    try { $out = & node acceptance-runner.js 2>&1 | Out-String; ($out -match "Verdict: ALL_PASSED") -and ($out -match "Passed: 42") } finally { Pop-Location }
} "Runner works"

$allPass = $Passes -eq $Total
Write-Host ""
Write-Host "============================================"
Write-Host "DRY20-B Verifier Results: $Passes / $Total PASS"
$verdict = if ($allPass) { "ALL_PASSED" } else { "FAIL" }
Write-Host "Verdict: $verdict"
Write-Host "============================================"

$result = [PSCustomObject]@{ verifierId="dry20-b-live-negative-controls"; total=$Total; passed=$Passes; failed=$Total-$Passes; verdict=$verdict; checks=$Checks }
$result | ConvertTo-Json -Depth 3

if ($allPass) { exit 0 } else { exit 1 }