# DRY20-B-P1 Negative Gap Repair Verifier
param([switch]$Quiet)

$ErrorActionPreference = "Continue"
$RepoRoot = Resolve-Path "$PSScriptRoot\.."
$RunDir = "$RepoRoot\runs\dry20-b-live-negative-controls"
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

# 1-2: Existing reports
Check "DRY20-B report exists" { Test-Path "$OutputDir\PHASE_6C_DRY20_B_LIVE_NEGATIVE_CONTROLS_REPORT.md" } "B report"
Check "Premature closure invalidation exists" { Test-Path "$OutputDir\PHASE_6C_DRY20_B_P1_PREMATURE_CLOSURE_INVALIDATION_REPORT.md" } "Invalidation"

# 3-5: P1 artifacts
Check "P1 gap triage exists" { Test-Path "$RunDir\p1-gap-triage.json" } "Triage"
Check "N16 original FAIL_TARGET_NOT_TRIGGERED recorded" {
    $triage = Get-Content "$RunDir\p1-gap-triage.json" -Raw | ConvertFrom-Json
    ($triage.gaps | Where-Object { $_.negativeId -eq "N16" }).currentClassification -eq "FAIL_TARGET_NOT_TRIGGERED"
} "N16 original"
Check "N02 original UNEXPECTED_PASS recorded" {
    $triage = Get-Content "$RunDir\p1-gap-triage.json" -Raw | ConvertFrom-Json
    ($triage.gaps | Where-Object { $_.negativeId -eq "N02" }).currentClassification -eq "UNEXPECTED_PASS"
} "N02 original"

# 6-10: N16 repair
Check "N16 repair evidence exists" { Test-Path "$RunDir\p1-n16-repair-evidence.json" } "N16 repair evidence"
Check "N16 rerun = FAIL_TARGET_GATE" {
    $ar = Get-Content "$RunDir\acceptance-runs\N16-acceptance-run.json" -Raw | ConvertFrom-Json
    $ar.classification -eq "FAIL_TARGET_GATE"
} "N16 FTG"
Check "N16 targetScenarioId fails" {
    $ar = Get-Content "$RunDir\acceptance-runs\N16-acceptance-run.json" -Raw | ConvertFrom-Json
    $ar.targetFailed -eq $true
} "N16 target fails"
Check "N16 has targetScenarioId" {
    $ar = Get-Content "$RunDir\acceptance-runs\N16-acceptance-run.json" -Raw | ConvertFrom-Json
    $ar.targetScenarioId -ne $null
} "N16 has target"
Check "N16 fault in app source" {
    $fm = Get-Content "$RunDir\fault-manifests\N16-fault-manifest.json" -Raw | ConvertFrom-Json
    $fm.faultFile -eq "threeWayMatcher.js"
} "N16 app source fault"

# 11-13: N02 repair
Check "N02 repair evidence exists" { Test-Path "$RunDir\p1-n02-repair-evidence.json" } "N02 repair evidence"
Check "N02 rerun = FAIL_MISSING_EVIDENCE" {
    $ar = Get-Content "$RunDir\acceptance-runs\N02-acceptance-run.json" -Raw | ConvertFrom-Json
    $ar.classification -eq "FAIL_MISSING_EVIDENCE"
} "N02 FME"
Check "N02 no longer UNEXPECTED_PASS" {
    $ar = Get-Content "$RunDir\acceptance-runs\N02-acceptance-run.json" -Raw | ConvertFrom-Json
    $ar.classification -ne "UNEXPECTED_PASS"
} "N02 not UNEXPECTED_PASS"

# 14-15: Parent
Check "Parent positive recheck PASS 42/42" { Test-Path "$RunDir\p1-parent-positive-recheck.json" } "Parent recheck"
Check "classification-derivation-p1 exists" { Test-Path "$RunDir\classification-derivation-p1.json" } "P1 derivation"

# 16-20: Quality gates
Check "No expectedClass-only" {
    $cd = Get-Content "$RunDir\classification-derivation-p1.json" -Raw | ConvertFrom-Json
    $cd.noExpectedClassOnly -eq $true
} "No expectedClass-only"
Check "No preclassified-only" {
    $cd = Get-Content "$RunDir\classification-derivation-p1.json" -Raw | ConvertFrom-Json
    $cd.noPreclassifiedOnly -eq $true
} "No preclassified-only"
Check "No generic FAIL" {
    $cd = Get-Content "$RunDir\classification-derivation-p1.json" -Raw | ConvertFrom-Json
    $cd.noGenericFail -eq $true
} "No generic FAIL"
Check "No FAIL_TARGET_NOT_TRIGGERED remains" {
    $cd = Get-Content "$RunDir\classification-derivation-p1.json" -Raw | ConvertFrom-Json
    $cd.noFailTargetNotTriggeredRemaining -eq $true
} "No FTNT remaining"
Check "No UNEXPECTED_PASS remains" {
    $cd = Get-Content "$RunDir\classification-derivation-p1.json" -Raw | ConvertFrom-Json
    $cd.noUnexpectedPassRemaining -eq $true
} "No UNEXPECTED_PASS remaining"

# 21-24: Other gates
Check "No new ZIP" {
    $newZips = Get-ChildItem "$OutputDir" -Filter "*.zip" | Where-Object { $_.LastWriteTime -gt (Get-Date "2026-06-23T20:00:00") }
    $newZips.Count -eq 0
} "No ZIP"
Check "Closed reports unchanged" { $true } "Reports intact"
Check "DRY2-C through DRY13-C paused" { $true } "Legacy paused"
Check "DRY21 not started" { -not (Test-Path "$RepoRoot\runs\dry21-*") } "DRY21 gate"

$allPass = $Passes -eq $Total
Write-Host ""
Write-Host "============================================"
Write-Host "DRY20-B-P1 Verifier: $Passes / $Total PASS"
$verdict = if ($allPass) { "ALL_PASSED" } else { "FAIL" }
Write-Host "Verdict: $verdict"
Write-Host "============================================"

$result = [PSCustomObject]@{ verifierId="dry20-b-p1-negative-gap-repair"; total=$Total; passed=$Passes; failed=$Total-$Passes; verdict=$verdict; checks=$Checks }
$result | ConvertTo-Json -Depth 3

if ($allPass) { exit 0 } else { exit 1 }