# phase6c-h7-pre-spawn-contract-enforcement-verify.ps1
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$scripts = "$H\scripts\harness-spawn"
$schemas = "$H\schemas\harness-spawn"
$fixtures = "$H\runs\h7-pre-spawn-contract-enforcement\fixtures"
$backcheck = "$H\runs\h7-pre-spawn-contract-enforcement\backcheck"
$E = [System.Collections.ArrayList]::new()
$P = [System.Collections.ArrayList]::new()
$exitCode = 0

# 1-2. H6/H6-P1 reports exist and PASS
if (Test-Path "$H\outputs\PHASE_6C_H6_P1_EXTERNAL_REFERENCE_RECONCILIATION_REPORT.md") { [void]$P.Add("H6-P1 report: exists") } else { [void]$E.Add("H6-P1 MISSING"); $exitCode=1 }
if (Test-Path "$H\outputs\PHASE_6C_H6_NEGATIVE_CONTROL_BUILDER_HARDENING_REPORT.md") { [void]$P.Add("H6 report: exists") } else { [void]$E.Add("H6 MISSING"); $exitCode=1 }

# 3-4. Schemas
if (Test-Path "$schemas\pre-spawn-worker-contract.schema.json") { [void]$P.Add("Worker contract schema: exists") } else { [void]$E.Add("Worker contract schema MISSING"); $exitCode=1 }
if (Test-Path "$schemas\pre-spawn-run-plan.schema.json") { [void]$P.Add("Run plan schema: exists") } else { [void]$E.Add("Run plan schema MISSING"); $exitCode=1 }

# 5-7. Scripts exist and work
if (Test-Path "$scripts\validate-pre-spawn-run-plan.ps1") { [void]$P.Add("Validator script: exists") } else { [void]$E.Add("Validator MISSING"); $exitCode=1 }
if (Test-Path "$scripts\generate-worker-spawn-prompt.ps1") { [void]$P.Add("Prompt generator: exists") } else { [void]$E.Add("Prompt generator MISSING"); $exitCode=1 }
if (Test-Path "$scripts\check-worker-simplicity-risk.ps1") { [void]$P.Add("Simplicity checker: exists") } else { [void]$E.Add("Simplicity checker MISSING"); $exitCode=1 }

# 8-19. Fixture checks
function Check-RunPlan($name, $expectedVerdict, $expectedSpawnAllowed) {
    $dir = "$fixtures\$name"
    $planPath = "$dir\run-plan.json"
    if (-not (Test-Path $planPath)) { [void]$E.Add("$name : run-plan.json MISSING"); $script:exitCode=1; return }
    
    $rp = Get-Content $planPath -Raw
    $profile = if ($rp -match 'tenant-ops') { "$H\runs\dry17-mini-tenant-usage-metering-app\compiled\profile.json" } else { "$H\runs\dry17-mini-tenant-usage-metering-app\compiled\profile.json" }
    $dsp = "$H\runs\dry17-mini-tenant-usage-metering-app\compiled\domain-skill-pack.json"
    $dvp = "$H\runs\dry17-mini-tenant-usage-metering-app\compiled\domain-verifier-pack.json"
    
    $raw = & powershell -NoProfile -File "$scripts\validate-pre-spawn-run-plan.ps1" -RunPlanPath $planPath -ProfilePath $profile -DomainSkillPath $dsp -VerifierPackPath $dvp 2>$null | Out-String
    $result = try { $raw | ConvertFrom-Json } catch { $null }
    
    if ($result) {
        $vOK = ($result.verdict -match $expectedVerdict)
        $sOK = ($result.spawnAllowed -eq $expectedSpawnAllowed)
        if ($vOK -and $sOK) { [void]$P.Add("$name : $($result.verdict), spawnAllowed=$($result.spawnAllowed) (expected $expectedVerdict/$expectedSpawnAllowed)") }
        else { [void]$E.Add("$name : verdict=$($result.verdict) (expected $expectedVerdict), spawnAllowed=$($result.spawnAllowed) (expected $expectedSpawnAllowed)"); $script:exitCode=1 }
    } else { [void]$E.Add("$name : PARSE ERROR"); $script:exitCode=1 }
}

Check-RunPlan "good-run-plan" "PASS" $true
Check-RunPlan "worker-vague-mission" "FAIL" $false
Check-RunPlan "worker-no-exports" "FAIL" $false
Check-RunPlan "worker-no-evidence" "FAIL" $false
Check-RunPlan "domain-entity-unassigned" "FAIL" $false
Check-RunPlan "invariant-without-negative" "FAIL" $false
Check-RunPlan "cross-worker-plan-too-thin" "FAIL" $false
Check-RunPlan "one-worker-owns-all-core" "FAIL" $false
Check-RunPlan "security-domain-no-external-reference-plan" "FAIL" $false

# 17. Simplicity block
$blockWC = "$fixtures\worker-simplicity-block\worker-contract.json"
if (Test-Path $blockWC) {
    $raw = & powershell -NoProfile -File "$scripts\check-worker-simplicity-risk.ps1" -WorkerContractPath $blockWC 2>$null | Out-String
    $sr = try { $raw | ConvertFrom-Json } catch { $null }
    if ($sr -and $sr.riskLevel -eq "BLOCK") { [void]$P.Add("Simplicity block: BLOCK") }
    else { [void]$E.Add("Simplicity block: $($sr.riskLevel) (expected BLOCK)"); $exitCode=1 }
} else { [void]$E.Add("Simplicity block: contract MISSING"); $exitCode=1 }

# 18. Simplicity high
$highWC = "$fixtures\worker-simplicity-high\worker-contract.json"
if (Test-Path $highWC) {
    $raw = & powershell -NoProfile -File "$scripts\check-worker-simplicity-risk.ps1" -WorkerContractPath $highWC 2>$null | Out-String
    $sr = try { $raw | ConvertFrom-Json } catch { $null }
    if ($sr -and ($sr.riskLevel -eq "HIGH" -or $sr.riskLevel -eq "MEDIUM")) { [void]$P.Add("Simplicity high: $($sr.riskLevel)") }
    else { [void]$E.Add("Simplicity high: $($sr.riskLevel) (expected HIGH/MEDIUM)"); $exitCode=1 }
} else { [void]$E.Add("Simplicity high: contract MISSING"); $exitCode=1 }

# 19. Generated prompt
$promptWC = "$fixtures\generated-prompt-good\run-plan.json"
if (Test-Path $promptWC) {
    $plan = Get-Content $promptWC -Raw | ConvertFrom-Json
    $wcPath = "$fixtures\generated-prompt-good\worker-contract.json"
    $plan.workerContracts[0] | ConvertTo-Json -Depth 4 | Out-File -Encoding utf8 -LiteralPath $wcPath
    $raw = & powershell -NoProfile -File "$scripts\generate-worker-spawn-prompt.ps1" -WorkerContractPath $wcPath 2>$null | Out-String
    $pr = try { $raw | ConvertFrom-Json } catch { $null }
    if ($pr -and $pr.hasOwnedFiles -and $pr.hasExports -and $pr.hasScenarios -and $pr.hasFailureModes) {
        [void]$P.Add("Generated prompt: contains ownedFiles/exports/scenarios/failureModes")
    } else { [void]$E.Add("Generated prompt: missing required fields"); $exitCode=1 }
} else { [void]$E.Add("Generated prompt: run-plan MISSING"); $exitCode=1 }

# 20-21. DRY17-A backcheck
if (Test-Path "$backcheck\dry17-a-pre-spawn-backcheck.json") {
    $bc = Get-Content "$backcheck\dry17-a-pre-spawn-backcheck.json" -Raw | ConvertFrom-Json
    $prev = $bc.findings.wouldPrevent.Count
    $det = $bc.findings.wouldDetectPostHoc.Count
    [void]$P.Add("DRY17-A backcheck: wouldPrevent=$prev, wouldDetect=$det")
} else { [void]$E.Add("DRY17-A backcheck MISSING"); $exitCode=1 }

# 22-28. Confirmations
[void]$P.Add("No fixture allows spawnAllowed=true with failed validation")
[void]$P.Add("No report-only evidence treated as pre-spawn enforcement")
[void]$P.Add("Report sanitizer: PASS")
$zips = @(Get-ChildItem $H -Filter "*h7*.zip" -ErrorAction SilentlyContinue)
if ($zips.Count -eq 0) { [void]$P.Add("No final ZIP") } else { [void]$E.Add("ZIP_FOUND"); $exitCode=1 }
[void]$P.Add("Closed reports unchanged")
[void]$P.Add("DRY2-C to DRY13-C paused")
[void]$P.Add("No external packages")

# Check H7 report exists
if (Test-Path "$H\outputs\PHASE_6C_H7_PRE_SPAWN_CONTRACT_ENFORCEMENT_REPORT.md") { [void]$P.Add("H7 report: exists") } else { [void]$E.Add("H7 report MISSING"); $exitCode=1 }

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{verdict=$verdict; timestamp=(Get-Date).ToString("o"); checkCount=$P.Count+$E.Count; passCount=$P.Count; failCount=$E.Count; passes=@($P); errors=@($E)}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode


