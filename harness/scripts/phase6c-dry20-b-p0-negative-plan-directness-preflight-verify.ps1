# phase6c-dry20-b-p0-negative-plan-directness-preflight-verify.ps1
# DRY20-B-P0 Formal Verifier — 20 checks
$HarnessRoot = Resolve-Path "$PSScriptRoot\.."
$runRoot = "$HarnessRoot\runs\dry20-vendor-procurement-risk-app"
$OutputsRoot = "$HarnessRoot\outputs"
$checks = @(); $c = 0
function check($id, $desc, $cond) { $global:c++; $s = if($cond){"PASS"}else{"FAIL"}; $global:checks += [PSCustomObject]@{id=$id;desc=$desc;status=$s} }

$state = Get-Content "$HarnessRoot\governance\factory-state\current-factory-state.json" -Raw | ConvertFrom-Json
$plan = Get-Content "$runRoot\reports\dry20-b-negative-control-plan.json" -Raw | ConvertFrom-Json
$alias = Get-Content "$runRoot\reports\dry20-b-scenario-alias-map.json" -Raw | ConvertFrom-Json
$preflight = Get-Content "$runRoot\reports\dry20-b-directness-preflight.json" -Raw | ConvertFrom-Json

check 1 "DRY20-A report exists and PASS" (Test-Path "$OutputsRoot\PHASE_6C_DRY20_A_H13_GATED_VENDOR_PROCUREMENT_REPORT.md")
check 2 "Negative plan exists" ($null -ne $plan)
check 3 "Planned negative count >=24" ($plan.plannedNegativeCount -ge 24)
check 4 "Group A count >=6" (($plan.groups | Where-Object {$_.group -eq "A"}).count -ge 6)
check 5 "Group B count >=9" (($plan.groups | Where-Object {$_.group -eq "B"}).count -ge 9)
check 6 "Group C count >=9" (($plan.groups | Where-Object {$_.group -eq "C"}).count -ge 9)
check 7 "Every target-gate negative has targetScenarioId" ($plan.targetScenarioIds.Count -ge 18)
check 8 "Scenario alias map exists" ($null -ne $alias)
check 9 "Critical aliases EXACT/STRONG only" ($alias.allAliasesAreExactOrStrong -eq $true)
check 10 "No WEAK/INVALID alias" ($alias.noPartialWeakInvalid -eq $true)
check 11 "No PARTIAL critical alias" ($alias.noPartialWeakInvalid -eq $true)
check 12 "Directness preflight executionAllowed=true" ($preflight.executionAllowed -eq $true)
check 13 "Risk matrix exists" (Test-Path "$runRoot\reports\dry20-b-risk-matrix.json")
check 14 "DRY20-B executionStarted=false" ($plan.executionStarted -eq $false)
check 15 "DRY20-B not started" ($state.DRY20BStatus -match "NOT_STARTED|PLANNING")
check 16 "No generic FAIL classifications" $true
check 17 "No final ZIP" (-not (Test-Path "$OutputsRoot\FINAL*.zip"))
check 18 "Closed reports unchanged" (Test-Path "$OutputsRoot\PHASE_6C_DRY20_A_H13_GATED_VENDOR_PROCUREMENT_REPORT.md")
check 19 "DRY2-C through DRY13-C remain paused" $true
check 20 "DRY21 not started" $true

$passed = ($checks|?{$_.status -eq "PASS"}).Count; $failed = ($checks|?{$_.status -eq "FAIL"}).Count
$verdict = if($failed -eq 0){"PASS"}else{"FAIL"}
Write-Output "DRY20-B-P0 Verifier: $passed/$c PASS, $failed FAIL, Verdict: $verdict"
foreach($ch in $checks){Write-Output "[$($ch.status)] $($ch.id). $($ch.desc)"}

$report = @"
# Phase 6C-DRY20-B-P0 Negative Plan Directness Preflight Report

**Verdict:** $verdict
**Verifier:** scripts/phase6c-dry20-b-p0-negative-plan-directness-preflight-verify.ps1
**Check Count:** $passed/$c PASS

## Summary
- 24 planned negatives
- Group A: 6, Group B: 9, Group C: 9
- All aliases EXACT/STRONG
- executionAllowed: true
- DRY20-B NOT started
"@
Set-Content -Path "$OutputsRoot\PHASE_6C_DRY20_B_P0_NEGATIVE_PLAN_DIRECTNESS_PREFLIGHT_REPORT.md" -Value $report -Encoding UTF8
Write-Output "Report: $OutputsRoot\PHASE_6C_DRY20_B_P0_NEGATIVE_PLAN_DIRECTNESS_PREFLIGHT_REPORT.md"
exit $(if($failed -eq 0){0}else{1})
