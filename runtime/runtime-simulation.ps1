# Minimal Runtime Simulation
# Part of: FACTORY-R2.2-AGENT-RUNTIME-BINDING
# Runs 6 test cases: 1 PASS, 5 FAIL scenarios.
# Usage: powershell -File runtime\runtime-simulation.ps1

param(
    [string]$FactoryRoot = "C:\Codex_App_Factory"
)

# Dot-source runtime modules
. (Join-Path $FactoryRoot "runtime\agent-loader.ps1")
. (Join-Path $FactoryRoot "runtime\permission-gate.ps1")
. (Join-Path $FactoryRoot "runtime\execution-context.ps1")
. (Join-Path $FactoryRoot "runtime\handoff-validator.ps1")
. (Join-Path $FactoryRoot "runtime\contract-checker.ps1")

$TestProjectId = "PROJ-SIM-001"
$TestPhaseId = "PHASE-SIM-001"
$Results = @()
$PassCount = 0
$FailCount = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.2 RUNTIME SIMULATION" -ForegroundColor Cyan
Write-Host " Project: $TestProjectId" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ============================================
# TEST 1: Valid implementer handoff — should PASS
# ============================================
Write-Host "--- TEST 1: Valid Implementer Handoff ---" -ForegroundColor Yellow

$validHandoff = @{
    handoffId     = "HANDOFF-SIM-001"
    timestamp     = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    projectId     = $TestProjectId
    phaseId       = $TestPhaseId
    fromAgent     = "IMPL-FE-001"
    toAgent       = "INTG-001"
    handoffType   = "IMPLEMENTATION_COMPLETE"
    taskId        = "TASK-001"
    contractId    = "FC-PROJ-SIM-001-FE-001"
    status        = "PENDING"
    inputRefs     = @("projects/PROJ-SIM-001/docs/architecture/design.md")
    outputRefs    = @("projects/PROJ-SIM-001/src/app/page.tsx")
    filesChanged  = @(@{path="projects/PROJ-SIM-001/src/app/page.tsx"; action="created"; checksum="abc123"})
    commandsRun   = @("npm run build")
    verificationResults = @{verdict="PASS"; testsPassed=5; testsFailed=0; testsSkipped=0; negativeControlsPassed=3; negativeControlsFailed=0}
    caveats       = @("Dark mode not yet implemented")
    blockers      = @()
    nextRecommendedAction = "Integrate with backend implementation"
    requiresApproval = $false
}

$test1 = Submit-Handoff -Handoff $validHandoff -ProjectId $TestProjectId -AgentId "IMPL-FE-001" -ErrorAction SilentlyContinue
$test1Result = [PSCustomObject]@{
    TestNumber  = 1
    TestName    = "Valid Implementer Handoff"
    ExpectPass  = $true
    ActualPass  = $test1.Valid
    Result      = if ($test1.Valid) { "PASS" } else { "FAIL" }
    Reason      = $test1.Reason
}
$Results += $test1Result
if ($test1.Valid) { $PassCount++ } else { $FailCount++ }
Write-Host "Result: $($test1Result.Result) — $($test1.Reason)" -ForegroundColor $(if($test1.Valid){'Green'}else{'Red'})

# ============================================
# TEST 2: Anonymous handoff — should FAIL
# ============================================
Write-Host "--- TEST 2: Anonymous Handoff (should FAIL) ---" -ForegroundColor Yellow

$anonHandoff = @{
    handoffId     = "HANDOFF-SIM-002"
    timestamp     = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    projectId     = $TestProjectId
    phaseId       = $TestPhaseId
    fromAgent     = "anonymous"
    toAgent       = "INTG-001"
    handoffType   = "IMPLEMENTATION_COMPLETE"
    taskId        = "TASK-002"
    status        = "PENDING"
    filesChanged  = @()
    nextRecommendedAction = "Review"
}

$test2 = Submit-Handoff -Handoff $anonHandoff -ProjectId $TestProjectId -ErrorAction SilentlyContinue
$test2Result = [PSCustomObject]@{
    TestNumber  = 2
    TestName    = "Anonymous Handoff"
    ExpectPass  = $false
    ActualPass  = $test2.Valid
    Result      = if (-not $test2.Valid) { "PASS (correctly rejected)" } else { "FAIL (should have been rejected)" }
    Reason      = $test2.Reason
}
$Results += $test2Result
if (-not $test2.Valid) { $PassCount++ } else { $FailCount++ }
Write-Host "Result: $($test2Result.Result) — $($test2.Reason)" -ForegroundColor $(if(-not $test2.Valid){'Green'}else{'Red'})

# ============================================
# TEST 3: Out-of-scope write — should FAIL
# ============================================
Write-Host "--- TEST 3: Out-of-Scope Write Handoff (should FAIL) ---" -ForegroundColor Yellow

$scopeViolationHandoff = @{
    handoffId     = "HANDOFF-SIM-003"
    timestamp     = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    projectId     = $TestProjectId
    phaseId       = $TestPhaseId
    fromAgent     = "VER-001"
    toAgent       = "INTG-001"
    handoffType   = "VERIFICATION_REPORT"
    taskId        = "TASK-003"
    status        = "PENDING"
    filesChanged  = @(@{path="projects/PROJ-SIM-001/src/app/page.tsx"; action="modified"; checksum="def456"})
    nextRecommendedAction = "Review findings"
}

$test3 = Submit-Handoff -Handoff $scopeViolationHandoff -ProjectId $TestProjectId -AgentId "VER-001" -ErrorAction SilentlyContinue
$test3Result = [PSCustomObject]@{
    TestNumber  = 3
    TestName    = "Out-of-Scope Write (Verifier modifying source)"
    ExpectPass  = $false
    ActualPass  = $test3.Valid
    Result      = if (-not $test3.Valid) { "PASS (correctly rejected)" } else { "FAIL (should have been rejected)" }
    Reason      = $test3.Reason
}
$Results += $test3Result
if (-not $test3.Valid) { $PassCount++ } else { $FailCount++ }
Write-Host "Result: $($test3Result.Result) — $($test3.Reason)" -ForegroundColor $(if(-not $test3.Valid){'Green'}else{'Red'})

# ============================================
# TEST 4: Unregistered agent — should FAIL
# ============================================
Write-Host "--- TEST 4: Unregistered Agent Handoff (should FAIL) ---" -ForegroundColor Yellow

$unknownAgentHandoff = @{
    handoffId     = "HANDOFF-SIM-004"
    timestamp     = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    projectId     = $TestProjectId
    phaseId       = $TestPhaseId
    fromAgent     = "GHOST-999"
    toAgent       = "INTG-001"
    handoffType   = "IMPLEMENTATION_COMPLETE"
    taskId        = "TASK-004"
    status        = "PENDING"
    filesChanged  = @()
    nextRecommendedAction = "Unknown"
}

$test4 = Submit-Handoff -Handoff $unknownAgentHandoff -ProjectId $TestProjectId -ErrorAction SilentlyContinue
$test4Result = [PSCustomObject]@{
    TestNumber  = 4
    TestName    = "Unregistered Agent Handoff"
    ExpectPass  = $false
    ActualPass  = $test4.Valid
    Result      = if (-not $test4.Valid) { "PASS (correctly rejected)" } else { "FAIL (should have been rejected)" }
    Reason      = $test4.Reason
}
$Results += $test4Result
if (-not $test4.Valid) { $PassCount++ } else { $FailCount++ }
Write-Host "Result: $($test4Result.Result) — $($test4.Reason)" -ForegroundColor $(if(-not $test4.Valid){'Green'}else{'Red'})

# ============================================
# TEST 5: Unauthorized skill — should FAIL
# ============================================
Write-Host "--- TEST 5: Unauthorized Skill Usage (should FAIL) ---" -ForegroundColor Yellow

$test5 = Assert-Permission -AgentId "VER-001" -Action "write" -TargetPath "projects/PROJ-SIM-001/reports/verification/report.md" -Skill "imagegen" -ProjectId $TestProjectId -ExpectAllowed $false
$test5Result = [PSCustomObject]@{
    TestNumber  = 5
    TestName    = "Unauthorized Skill (Verifier using imagegen)"
    ExpectPass  = $false
    ActualPass  = $test5.Passed
    Result      = if ($test5.Passed) { "PASS (correctly rejected)" } else { "FAIL (should have been rejected)" }
    Reason      = $test5.Reason
}
$Results += $test5Result
if ($test5.Passed) { $PassCount++ } else { $FailCount++ }
Write-Host "Result: $($test5Result.Result) — $($test5.Reason)" -ForegroundColor $(if($test5.Passed){'Green'}else{'Red'})

# ============================================
# TEST 6: Missing projectId — should FAIL
# ============================================
Write-Host "--- TEST 6: Missing projectId Handoff (should FAIL) ---" -ForegroundColor Yellow

$noProjectHandoff = @{
    handoffId     = "HANDOFF-SIM-006"
    timestamp     = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    projectId     = ""
    phaseId       = $TestPhaseId
    fromAgent     = "IMPL-FE-001"
    toAgent       = "INTG-001"
    handoffType   = "IMPLEMENTATION_COMPLETE"
    taskId        = "TASK-006"
    status        = "PENDING"
    filesChanged  = @()
    nextRecommendedAction = "Review"
}

$test6 = Submit-Handoff -Handoff $noProjectHandoff -ProjectId "" -ErrorAction SilentlyContinue
$test6Result = [PSCustomObject]@{
    TestNumber  = 6
    TestName    = "Missing projectId Handoff"
    ExpectPass  = $false
    ActualPass  = $test6.Valid
    Result      = if (-not $test6.Valid) { "PASS (correctly rejected)" } else { "FAIL (should have been rejected)" }
    Reason      = $test6.Reason
}
$Results += $test6Result
if (-not $test6.Valid) { $PassCount++ } else { $FailCount++ }
Write-Host "Result: $($test6Result.Result) — $($test6.Reason)" -ForegroundColor $(if(-not $test6.Valid){'Green'}else{'Red'})

# ============================================
# BONUS: Generate execution contexts for all agents
# ============================================
Write-Host ""
Write-Host "--- BONUS: Generate Execution Contexts ---" -ForegroundColor Yellow
$contexts = New-AllAgentExecutionContexts -ProjectId $TestProjectId -PhaseId $TestPhaseId -OutputDir (Join-Path $FactoryRoot "runtime\contexts")
Write-Host "Generated $($contexts.Count) execution contexts in runtime/contexts/"

# ============================================
# BONUS: Contract schema check
# ============================================
Write-Host ""
Write-Host "--- BONUS: Contract Schema Check ---" -ForegroundColor Yellow
$contractResults = Test-AllContractSchemas
$contractResults | ForEach-Object {
    $status = if ($_.ValidJson) { "PASS" } else { "FAIL" }
    Write-Host "[$status] $($_.ContractType): $($_.Reason)"
}

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SIMULATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$Results | Format-Table TestNumber, TestName, Result -AutoSize | Out-String | Write-Host

Write-Host "EXPECTED PASS: 1 (Test 1)" -ForegroundColor Green
Write-Host "EXPECTED FAIL: 5 (Tests 2-6)" -ForegroundColor Yellow
Write-Host "ACTUAL PASS:   $PassCount" -ForegroundColor $(if($PassCount -eq 6){'Green'}else{'Red'})
Write-Host "ACTUAL FAIL:   $FailCount" -ForegroundColor $(if($FailCount -eq 0){'Green'}else{'Red'})

if ($PassCount -eq 6 -and $FailCount -eq 0) {
    Write-Host "`n>>> ALL 6 SIMULATION TESTS PASSED <<<" -ForegroundColor Green
} else {
    Write-Host "`n>>> $FailCount SIMULATION TEST(S) FAILED <<<" -ForegroundColor Red
}

# Save results
$simResult = @{
    simulationDate = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    projectId      = $TestProjectId
    totalTests     = $Results.Count
    expectedPass   = 1
    expectedFail   = 5
    actualPass     = $PassCount
    actualFail     = $FailCount
    allPassed      = ($FailCount -eq 0)
    tests          = $Results
}
$simResult | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $FactoryRoot "runtime\tests\simulation-result.json") -Encoding UTF8
Write-Host "`nResults saved to: runtime\tests\simulation-result.json"
