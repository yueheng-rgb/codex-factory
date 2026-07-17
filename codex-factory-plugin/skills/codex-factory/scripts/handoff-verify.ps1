#!/usr/bin/env pwsh
# Phase 6C Session Rotation Handoff Verifier
# Phase: H13-D

$ErrorActionPreference = "Stop"
$Base = $PSScriptRoot | Split-Path -Parent
$Script:Checks = [System.Collections.ArrayList]::new()
$Passed = 0
$Failed = 0

function Check {
    param($id, $desc, [scriptblock]$test)
    $r = & $test
    $status = if ($r) { "PASS" } else { "FAIL" }
    [void]$Script:Checks.Add([PSCustomObject]@{ id=$id; desc=$desc; status=$status })
    if ($r) { $Script:Passed++ } else { $Script:Failed++ }
    Write-Output "  [$status] $desc"
}

Write-Output "=== Phase 6C Session Rotation Handoff Verifier ==="
Write-Output "Phase: H13-D"
Write-Output "Timestamp: $(Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz')"
Write-Output ""

Write-Output "--- Section 1: Main Factory State Sync ---"
Check 1 "current-factory-state.json exists" { Test-Path "$Base\governance\factory-state\current-factory-state.json" }
$state = Get-Content "$Base\governance\factory-state\current-factory-state.json" -Raw | ConvertFrom-Json
Check 2 "currentTrustedPhase is DRY20 (not stale)" { $state.currentTrustedPhase -eq "DRY20" }
Check 3 "DRY20 status is POSITIVE_NEGATIVE_CLOSED" { $state.dry20Status -eq "POSITIVE_NEGATIVE_CLOSED" }
Check 4 "H13-C status is PASS" { $state.h13cStatus -eq "PASS" }
Check 5 "DRY19-B status is CLOSED" { $state.DRY19BStatus -eq "CLOSED" }
Check 6 "H12 status is PASS" { $state.h12Status -eq "PASS" }
Check 7 "H10 status is PASS" { $state.h10Status -eq "PASS" }
Check 8 "H11 status is PASS" { $state.h11Status -eq "PASS" }
Check 9 "DRY20 cross-worker deps >=60" { $state.dry20CrossWorkerDeps -ge 60 }
Check 10 "DRY20 gap repairs N16+N02" { $state.dry20GapRepairs -contains "N16" -and $state.dry20GapRepairs -contains "N02" }
Check 11 "finalZipExists is false" { $state.finalZipExists -eq $false }
Check 12 "repairedDuringPhase is H13-D" { $state.repairedDuringPhase -eq "H13-D" }
Check 13 "previousTrustedPhase was DRY19-A-P5" { $state.stateRepairMetadata.previousTrustedPhase -eq "DRY19-A-P5" }
Check 14 "closedPhases includes DRY19-B" { $state.closedPhases -contains "DRY19-B" }
Check 15 "closedPhases includes H13-C" { $state.closedPhases -contains "H13-C" }
Check 16 "closedPhases includes DRY20-B-P1" { $state.closedPhases -contains "DRY20-B-P1" }
Check 17 "pausedPhases DRY2-C..DRY13-C (12)" {
    $p = $state.pausedPhases; $p -contains "DRY2-C" -and $p -contains "DRY13-C" -and $p.Count -eq 12 }
Check 18 "allowedNextPhase is DRY21 or H14" { $state.allowedNextPhase -eq "DRY21 or H14" }

Write-Output ""
Write-Output "--- Section 2: Handoff Artifacts ---"
Check 19 "HANDOFF_REPORT.md exists" { Test-Path "$Base\outputs\PHASE_6C_SESSION_ROTATION_HANDOFF_REPORT.md" }
Check 20 "session-rotation-handoff.json exists" { Test-Path "$Base\governance\factory-state\session-rotation-handoff.json" }
$handoff = Get-Content "$Base\governance\factory-state\session-rotation-handoff.json" -Raw | ConvertFrom-Json
Check 21 "handoff sourceEvidencePaths >=8" { $handoff.sourceEvidencePaths.Count -ge 8 }
Check 22 "handoff sourceEvidenceSha256 >=8" { $handoff.sourceEvidenceSha256.PSObject.Properties.Name.Count -ge 8 }
Check 23 "handoff repairedFromExistingEvidence: true" { $handoff.repairedFromExistingEvidence -eq $true }
Check 24 "handoff originalHandoffMissingAtMainPath: true" { $handoff.originalHandoffMissingAtMainPath -eq $true }
Check 25 "handoff generatedDuringPhase is H13-D" { $handoff.generatedDuringPhase -eq "H13-D" }
Check 26 "handoff dry20 classification POSITIVE_NEGATIVE_CLOSED" { $handoff.dry20FinalClassification -eq "POSITIVE_NEGATIVE_CLOSED" }
Check 27 "handoff verifier script exists" { Test-Path "$Base\scripts\phase6c-session-rotation-handoff-verify.ps1" }

Write-Output ""
Write-Output "--- Section 3: Agent Registry / Progress ---"
Check 28 "AGENT_REGISTRY.json exists" { Test-Path "$Base\governance\factory-state\AGENT_REGISTRY.json" }
$registry = Get-Content "$Base\governance\factory-state\AGENT_REGISTRY.json" -Raw | ConvertFrom-Json
Check 29 "AGENT_REGISTRY reconstructedFromEvidence: true" { $registry._reconstructedFromEvidence -eq $true }
Check 30 "AGENT_REGISTRY >=5 agents" { $registry.agents.Count -ge 5 }
Check 31 "AGENT_REGISTRY has h13-c-builder-1" { (@($registry.agents).Where({$_.agentId -eq "h13-c-builder-1"})).Count -eq 1 }
Check 32 "AGENT_REGISTRY has dry20-integrator-1" { (@($registry.agents).Where({$_.agentId -eq "dry20-integrator-1"})).Count -eq 1 }
Check 33 "AGENT_PROGRESS.jsonl exists" { Test-Path "$Base\governance\factory-state\AGENT_PROGRESS.jsonl" }
$lines = Get-Content "$Base\governance\factory-state\AGENT_PROGRESS.jsonl"
$valid = 0; $invalid = 0
foreach ($l in $lines) { if ([string]::IsNullOrWhiteSpace($l)) { continue }; try { $null = $l | ConvertFrom-Json; $valid++ } catch { $invalid++ } }
Check 34 "AGENT_PROGRESS >=20 events" { $lines.Count -ge 20 }
Check 35 "AGENT_PROGRESS all valid JSON" { $invalid -eq 0 -and $valid -gt 0 }
Check 36 "AGENT_PROGRESS events marked reconstructed" { ($lines | ForEach-Object { if ($_ -match '"reconstructedFromEvidence":true') { 1 } } | Measure-Object).Count -ge 10 }

Write-Output ""
Write-Output "--- Section 4: No DRY21/H14 Artifacts ---"
Check 37 "No DRY21 outputs" { -not (Get-ChildItem "$Base\outputs" -Filter "*DRY21*" -ErrorAction SilentlyContinue) }
Check 38 "No DRY21 governance" { -not (Get-ChildItem "$Base\governance\factory-state" -Filter "*dry21*" -ErrorAction SilentlyContinue) }
Check 39 "No DRY21 harness runs" { -not (Get-ChildItem "$Base\harness\runs" -Filter "*dry21*" -Directory -ErrorAction SilentlyContinue) }
Check 40 "No H14 outputs" { -not (Get-ChildItem "$Base\outputs" -Filter "*H14*" -ErrorAction SilentlyContinue) }
Check 41 "No H14 harness runs" { -not (Get-ChildItem "$Base\harness\runs" -Filter "*h14*" -Directory -ErrorAction SilentlyContinue) }
Check 42 "No final delivery ZIP at root" { -not (Get-ChildItem "$Base" -Filter "*-final-*.zip" -ErrorAction SilentlyContinue) }
Check 43 "Audit ZIP not final delivery ZIP" { $handoff.auditEvidenceBundlePath -like "harness/outputs/handoff-audit-evidence-bundle.zip" -and $state.finalZipExists -eq $false }

Write-Output ""
Write-Output "--- Section 5: Integrity ---"
Check 44 "No manual PASS-only" { $handoff.PSObject.Properties.Name -notcontains "manualPassOnly" }
Check 45 "No expectedClass-only" { $handoff.PSObject.Properties.Name -notcontains "expectedClassOnly" }
Check 46 "No generic FAIL in registry" { -not ($registry.agents.verdict -contains "FAIL") }
Check 47 "handoff note denies pretending original" { $handoff.note -like "*does NOT pretend*" -or $handoff.note -like "*not pretend*" }

Write-Output ""
Write-Output "--- Section 6: factoryctl ---"
$fcOnPath = $false
try { cmd /c "where factoryctl" 2>&1 | Out-Null; $fcOnPath = ($LASTEXITCODE -eq 0) } catch { $fcOnPath = $false }
Check 48 "factoryctl PATH caveated in state" { ($state.openCaveats -join " ") -like "*factoryctl*" }

Write-Output ""
Write-Output "=============================================="
$total = $Script:Checks.Count
$verdict = if ($Script:Failed -eq 0) { "PASS" } else { "FAIL" }
Write-Output "VERDICT: $verdict"
Write-Output "Checks: $($Script:Passed)/$total PASS, $($Script:Failed) FAIL"
Write-Output "=============================================="

$result = [PSCustomObject]@{
    verdict = $verdict
    verifierPath = "scripts/phase6c-session-rotation-handoff-verify.ps1"
    exitCode = if ($Script:Failed -eq 0) { 0 } else { 1 }
    totalChecks = $total
    passed = $Script:Passed
    failed = $Script:Failed
    checks = $Script:Checks
    verifiedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    factoryctlOnPath = $fcOnPath
}
$result | ConvertTo-Json -Depth 4 | Set-Content "$Base\governance\factory-state\verifier-h13-d-result.json" -Encoding UTF8
Write-Output "Result: governance/factory-state/verifier-h13-d-result.json"
exit $result.exitCode
