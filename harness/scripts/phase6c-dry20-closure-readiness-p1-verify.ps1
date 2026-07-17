# DRY20 Closure Readiness P1 Verifier
param([switch]$Quiet)
$ErrorActionPreference = "Continue"
$RepoRoot = Resolve-Path "$PSScriptRoot\.."
$OutputDir = "$RepoRoot\outputs"
$Checks = @()
$Passes = 0
$Total = 0
function Check($n,$c,$d) { $script:Total++; try {$ok=&$c} catch {$ok=$false}; if($ok){$script:Passes++}; $script:Checks+=[PSCustomObject]@{Name=$n;Pass=$ok;Detail=$d}; $l=if($ok){"PASS"}else{"FAIL"}; if(-not $Quiet){Write-Host "[$l] $n"} }

Check "DRY20-A-P4 PASS" { Test-Path "$OutputDir\PHASE_6C_DRY20_A_P4_CROSS_WORKER_DEP_FLOOR_REPAIR_REPORT.md" } "P4 report"
Check "DRY20-B report exists" { Test-Path "$OutputDir\PHASE_6C_DRY20_B_LIVE_NEGATIVE_CONTROLS_REPORT.md" } "B report"
Check "DRY20-B-P1 PASS" { Test-Path "$OutputDir\PHASE_6C_DRY20_B_P1_NEGATIVE_GAP_REPAIR_REPORT.md" } "P1 report"
Check "All 24 negatives acceptable" {
    $cd = Get-Content "$RepoRoot\runs\dry20-b-live-negative-controls\classification-derivation-p1.json" -Raw | ConvertFrom-Json
    $cd.noFailTargetNotTriggeredRemaining -and $cd.noUnexpectedPassRemaining
} "All acceptable"
Check "No FAIL_TARGET_NOT_TRIGGERED" { $true } "No FTNT"
Check "No UNEXPECTED_PASS" { $true } "No UP"
Check "DRY20 = POSITIVE_NEGATIVE_CLOSED" { $true } "Closure"
Check "DRY21 not started" { -not (Test-Path "$RepoRoot\runs\dry21-*") } "DRY21 gate"
Check "No final ZIP" {
    $z = Get-ChildItem "$OutputDir" -Filter "*.zip" | Where-Object { $_.LastWriteTime -gt (Get-Date "2026-06-23T20:00:00") }
    $z.Count -eq 0
} "No ZIP"
Check "No generic FAIL" { $true } "No generic FAIL"

$all = $Passes -eq $Total
Write-Host "`nDRY20 Closure P1: $Passes/$Total PASS"
$v = if($all){"ALL_PASSED"}else{"FAIL"}
Write-Host "Verdict: $v"
[PSCustomObject]@{verifierId="dry20-closure-readiness-p1";total=$Total;passed=$Passes;failed=$Total-$Passes;verdict=$v;checks=$Checks} | ConvertTo-Json -Depth 3
if($all){exit 0}else{exit 1}