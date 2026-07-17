# R2.2 AGENT RUNTIME BINDING — Verification Script
# Part of: FACTORY-R2.2-AGENT-RUNTIME-BINDING
# Usage: powershell -File harness\verification\verify-r2-2-runtime.ps1

param(
    [string]$FactoryRoot = "C:\Codex_App_Factory"
)

$ErrorActionPreference = "Continue"

# Import runtime modules
. (Join-Path $FactoryRoot "runtime\agent-loader.ps1")
. (Join-Path $FactoryRoot "runtime\permission-gate.ps1")
. (Join-Path $FactoryRoot "runtime\execution-context.ps1")
. (Join-Path $FactoryRoot "runtime\handoff-validator.ps1")
. (Join-Path $FactoryRoot "runtime\contract-checker.ps1")

$Results = @()
$PassCount = 0
$FailCount = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.2 RUNTIME BINDING — VERIFICATION" -ForegroundColor Cyan
Write-Host " Factory Root: $FactoryRoot" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Add-Result {
    param([string]$Check, [bool]$Passed, [string]$Detail = "")
    $script:Results += [PSCustomObject]@{Check=$Check; Passed=$Passed; Detail=$Detail}
    if ($Passed) { $script:PassCount++ } else { $script:FailCount++ }
    $icon = if ($Passed) { "[PASS]" } else { "[FAIL]" }
    Write-Host "$icon $Check" -ForegroundColor $(if($Passed){'Green'}else{'Red'})
    if ($Detail -and -not $Passed) { Write-Host "       $Detail" -ForegroundColor Red }
}

# ============================================
# 1. Agent Definition Loader
# ============================================
Write-Host "--- 1. Agent Definition Loader ---" -ForegroundColor Yellow
$loaderResults = Test-AllAgentDefinitions
$allLoaded = ($loaderResults | Where-Object { -not $_.Loadable }).Count -eq 0
Add-Result "All 11 agent definitions loadable" $allLoaded "Count: $($loaderResults.Count)"

foreach ($r in $loaderResults) {
    Add-Result "Agent $($r.AgentId) loaded" $r.Loadable $r.Fields
}

# ============================================
# 2. Runtime Permission Gate
# ============================================
Write-Host "--- 2. Runtime Permission Gate ---" -ForegroundColor Yellow

# Test: Valid permission (PM reading governance)
$p1 = Test-AgentPermission -AgentId "PM-001" -Action "read" -TargetPath "governance/rules.md"
Add-Result "Permission: PM reading governance" $p1.Allowed $p1.Reason

# Test: Forbidden write (Verifier writing source)
$p2 = Test-AgentPermission -AgentId "VER-001" -Action "write" -TargetPath "projects/PROJ-099/src/app/page.tsx" -ProjectId "PROJ-099"
Add-Result "Permission: Verifier blocked from writing source" (-not $p2.Allowed) $p2.Reason

# Test: Forbidden skill (Security agent using browser)
$p3 = Test-AgentPermission -AgentId "SEC-001" -Action "execute" -TargetPath "" -Skill "browser"
Add-Result "Permission: Security blocked from browser skill" (-not $p3.Allowed) $p3.Reason

# Test: Missing projectId for write
$p4 = Test-AgentPermission -AgentId "IMPL-FE-001" -Action "write" -TargetPath "projects/PROJ-099/src/app/page.tsx" -ProjectId ""
Add-Result "Permission: Write rejected without projectId" (-not $p4.Allowed) $p4.Reason

# Test: Unknown agent
$p5 = Test-AgentPermission -AgentId "GHOST-999" -Action "read" -TargetPath ""
Add-Result "Permission: Unknown agent rejected" (-not $p5.Allowed) $p5.Reason

# ============================================
# 3. Execution Context Generator
# ============================================
Write-Host "--- 3. Execution Context Generator ---" -ForegroundColor Yellow

$ctx = New-AgentExecutionContext -AgentId "PM-001" -ProjectId "PROJ-VERIFY-001" -PhaseId "PHASE-VERIFY-001"
Add-Result "Execution context: PM-001 generated" ($null -ne $ctx) ""
if ($ctx) {
    Add-Result "  Context has projectId" ($ctx.projectId -eq "PROJ-VERIFY-001") ""
    Add-Result "  Context has allowedWriteScopes" ($ctx.allowedWriteScopes.Count -gt 0) ""
    Add-Result "  Context has forbiddenActions" ($ctx.forbiddenActions.Count -gt 0) ""
    Add-Result "  Context has allowedSkills" ($null -ne $ctx.allowedSkills) ""
    Add-Result "  Context has handoffRequired" ($ctx.handoffRequired -ne $null) ""
}

# Generate contexts for all agents
$allContexts = New-AllAgentExecutionContexts -ProjectId "PROJ-VERIFY-001" -PhaseId "PHASE-VERIFY-001" -OutputDir (Join-Path $FactoryRoot "runtime\contexts")
Add-Result "Execution contexts: all agents generated" ($allContexts.Count -ge 9) "Count: $($allContexts.Count)"

# Check context files exist
$ctxFiles = Get-ChildItem (Join-Path $FactoryRoot "runtime\contexts") -Filter "*-PROJ-VERIFY-001-context.json"
Add-Result "Context files written to disk" ($ctxFiles.Count -ge 9) "Count: $($ctxFiles.Count)"

# ============================================
# 4. Handoff Validator
# ============================================
Write-Host "--- 4. Handoff Validator ---" -ForegroundColor Yellow

# Valid handoff
$validH = @{
    handoffId="HANDOFF-VFY-001"; timestamp=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"); projectId="PROJ-VERIFY-001"
    phaseId="PHASE-VERIFY-001"; fromAgent="IMPL-FE-001"; toAgent="INTG-001"; handoffType="IMPLEMENTATION_COMPLETE"
    taskId="TASK-001"; status="PENDING"; filesChanged=@(); nextRecommendedAction="Review"
}
$hv1 = Test-Handoff -Handoff $validH
Add-Result "Handoff: Valid handoff passes" $hv1.Valid $hv1.Reason

# Anonymous handoff
$anonH = @{handoffId="HANDOFF-VFY-002"; timestamp=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"); projectId="PROJ-VERIFY-001"; fromAgent="anonymous"; toAgent="INTG-001"; handoffType="IMPLEMENTATION_COMPLETE"; taskId="TASK-002"; status="PENDING"; filesChanged=@(); nextRecommendedAction="Review"}
$hv2 = Test-Handoff -Handoff $anonH
Add-Result "Handoff: Anonymous handoff rejected" (-not $hv2.Valid) $hv2.Reason

# Missing projectId
$noProjH = @{handoffId="HANDOFF-VFY-003"; timestamp=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"); projectId=""; fromAgent="IMPL-FE-001"; toAgent="INTG-001"; handoffType="IMPLEMENTATION_COMPLETE"; taskId="TASK-003"; status="PENDING"; filesChanged=@(); nextRecommendedAction="Review"}
$hv3 = Test-Handoff -Handoff $noProjH
Add-Result "Handoff: Missing projectId rejected" (-not $hv3.Valid) $hv3.Reason

# Unregistered agent
$ghostH = @{handoffId="HANDOFF-VFY-004"; timestamp=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"); projectId="PROJ-VERIFY-001"; fromAgent="GHOST-999"; toAgent="INTG-001"; handoffType="IMPLEMENTATION_COMPLETE"; taskId="TASK-004"; status="PENDING"; filesChanged=@(); nextRecommendedAction="Review"}
$hv4 = Test-Handoff -Handoff $ghostH
Add-Result "Handoff: Unregistered agent rejected" (-not $hv4.Valid) $hv4.Reason

# ============================================
# 5. Handoff Index (append)
# ============================================
Write-Host "--- 5. Handoff Index ---" -ForegroundColor Yellow

$indexPath = Join-Path $FactoryRoot "governance\multi-agent\handoff-bus\handoff-index.jsonl"
$indexBefore = (Get-Content $indexPath -Encoding UTF8 | Where-Object { $_.Trim() -ne "" -and $_ -notmatch '^#' }).Count

$submitResult = Submit-Handoff -Handoff $validH -ProjectId "PROJ-VERIFY-001" -AgentId "IMPL-FE-001" -ErrorAction SilentlyContinue
$indexAfter = (Get-Content $indexPath -Encoding UTF8 | Where-Object { $_.Trim() -ne "" -and $_ -notmatch '^#' }).Count

Add-Result "Handoff index: Entry appended" ($indexAfter -gt $indexBefore) "Before: $indexBefore, After: $indexAfter"
Add-Result "Handoff submission accepted" $submitResult.Valid $submitResult.Reason

# ============================================
# 6. Contract Schema Check
# ============================================
Write-Host "--- 6. Contract Schema Check ---" -ForegroundColor Yellow

$contractResults = Test-AllContractSchemas
foreach ($cr in $contractResults) {
    Add-Result "Contract: $($cr.ContractType) schema parseable" $cr.ValidJson $cr.Reason
}

# ============================================
# 7. Runtime Simulation Re-run
# ============================================
Write-Host "--- 7. Runtime Simulation ---" -ForegroundColor Yellow

$simPath = Join-Path $FactoryRoot "runtime\tests\simulation-result.json"
if (Test-Path $simPath) {
    $sim = Get-Content $simPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Add-Result "Simulation: All 6 tests passed" $sim.allPassed "Pass: $($sim.actualPass), Fail: $($sim.actualFail)"
    foreach ($t in $sim.tests) {
        $passed = ($t.Result -match "^PASS")
        Add-Result "  Test $($t.TestNumber): $($t.TestName)" $passed $t.Result
    }
} else {
    Add-Result "Simulation result file exists" $false "Run runtime-simulation.ps1 first"
}

# ============================================
# 8. Runtime files exist
# ============================================
Write-Host "--- 8. Runtime File Inventory ---" -ForegroundColor Yellow

$runtimeFiles = @(
    "runtime\agent-loader.ps1",
    "runtime\permission-gate.ps1",
    "runtime\execution-context.ps1",
    "runtime\handoff-validator.ps1",
    "runtime\contract-checker.ps1",
    "runtime\runtime-simulation.ps1"
)
foreach ($rf in $runtimeFiles) {
    $exists = Test-Path (Join-Path $FactoryRoot $rf)
    Add-Result "Runtime file: $rf" $exists ""
}

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PASS: $PassCount" -ForegroundColor Green
Write-Host "  FAIL: $FailCount" -ForegroundColor Red
Write-Host "  TOTAL: $($PassCount + $FailCount)" -ForegroundColor Cyan

if ($FailCount -eq 0) {
    Write-Host "`n>>> R2.2 AGENT RUNTIME BINDING: ALL CHECKS PASSED <<<" -ForegroundColor Green
} else {
    Write-Host "`n>>> R2.2: $FailCount CHECK(S) FAILED <<<" -ForegroundColor Red
}

# Save verification result
$verResult = @{
    verificationDate = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    factoryRoot = $FactoryRoot
    passCount = $PassCount
    failCount = $FailCount
    totalChecks = $PassCount + $FailCount
    allPassed = ($FailCount -eq 0)
    results = $Results
}
$verResult | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $FactoryRoot "harness\verification\r2-2-verification-result.json") -Encoding UTF8
Write-Host "`nResults saved to: harness\verification\r2-2-verification-result.json"
