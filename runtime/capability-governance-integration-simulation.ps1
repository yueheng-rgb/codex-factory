# Capability Governance Integration Simulation
# Part of: FACTORY-R2.3-D-CAPABILITY-GOVERNANCE-INTEGRATION
# 8+ scenarios exercising the full governance pipeline.

param([string]$FactoryRoot = "C:\Codex_App_Factory")

$ErrorActionPreference = "Continue"

. (Join-Path $FactoryRoot "runtime\agent-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-permission-gate.ps1")
. (Join-Path $FactoryRoot "runtime\bootstrap-capability-plan.ps1")

$Results = @(); $PassCount = 0; $FailCount = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-D GOVERNANCE INTEGRATION SIMULATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Run-S {
    param([string]$L, [bool]$P, [string]$D)
    $script:Results += [PSCustomObject]@{ Scenario=$L; Passed=$P; Detail=$D }
    if ($P) { $script:PassCount++ } else { $script:FailCount++ }
    Write-Host "$(if($P){'[PASS]'}else{'[FAIL]'}) $L" -ForegroundColor $(if($P){'Green'}else{'Red'})
    if ($D) { Write-Host "    $D" -ForegroundColor White }
}

# === A: Local-first design, ARCH only (no CAP-SKILL-099 exposure) ===
Write-Host "--- A: ARCH-only design startup ---" -ForegroundColor Yellow
$pA = New-CapabilityPlan -ProjectId "PROJ-SIM-D-A" -PhaseId "PHASE-DESIGN" -ProjectType "fullstack-admin" `
    -ActiveAgents @("ARCH-001") -LocalFirst $true -NetworkAllowed $true -CloudAllowed $false `
    -SecretsAllowed $false -SandboxAvailable $false -HumanApprovalAvailable $false
Run-S -L "A: ARCH-only design, low-risk baseline" -P ($pA.summary.allowedCount -gt 0 -and $pA.summary.pendingHumanCount -eq 0) `
    -D "Allowed=$($pA.summary.allowedCount) Monitor=$($pA.summary.monitorOnlyCount) Rejected=$($pA.summary.rejectedCount)"

# === A2: Design WITH PM → CAP-SKILL-099 triggers pending_human (expected) ===
Write-Host "--- A2: PM-inclusive design startup ---" -ForegroundColor Yellow
$pA2 = New-CapabilityPlan -ProjectId "PROJ-SIM-D-A2" -PhaseId "PHASE-DESIGN" -ProjectType "fullstack-admin" `
    -ActiveAgents @("PM-001","ARCH-001") -LocalFirst $true -NetworkAllowed $true -CloudAllowed $false `
    -SecretsAllowed $false -SandboxAvailable $false -HumanApprovalAvailable $false
Run-S -L "A2: PM-inclusive design detects CAP-SKILL-099 pending_human" -P ($pA2.summary.pendingHumanCount -gt 0) `
    -D "PendingH=$($pA2.summary.pendingHumanCount)"

# === B: DB agent + high-risk postgres-mcp, no sandbox → pending_sandbox ===
Write-Host "--- B: High-risk MCP without sandbox ---" -ForegroundColor Yellow
$pB = New-CapabilityPlan -ProjectId "PROJ-SIM-D-B" -PhaseId "PHASE-IMPL-DB" -ProjectType "fullstack-admin" `
    -ActiveAgents @("IMPL-DB-001") -LocalFirst $true -NetworkAllowed $true -CloudAllowed $false `
    -SecretsAllowed $true -SandboxAvailable $false -HumanApprovalAvailable $false
Run-S -L "B: DB agent + high-risk MCP, no sandbox → pending_sandbox" -P ($pB.summary.pendingSandboxCount -gt 0) `
    -D "PendingS=$($pB.summary.pendingSandboxCount)"

# === C: Network-restricted blocks network MCPs ===
Write-Host "--- C: Network-restricted MCPs ---" -ForegroundColor Yellow
$pC = New-CapabilityPlan -ProjectId "PROJ-SIM-D-C" -PhaseId "PHASE-IMPL-FE" -ProjectType "fullstack-admin" `
    -ActiveAgents @("IMPL-FE-001") -LocalFirst $true -NetworkAllowed $false -CloudAllowed $false `
    -SecretsAllowed $true -SandboxAvailable $true -HumanApprovalAvailable $false
$mcpBlocked = ($pC.rejectedCapabilities | Where-Object { $_.type -eq "mcp_server" }).Count + ($pC.monitorOnlyCapabilities | Where-Object { $_.type -eq "mcp_server" }).Count
if ($mcpBlocked -isnot [int]) { $mcpBlocked = 0 }
Run-S -L "C: Network-restricted blocks/monitors MCPs" -P ($mcpBlocked -gt 0) `
    -D "MCPs blocked/monitored: $mcpBlocked"

# === D: Research intake + search providers → monitor_only present ===
Write-Host "--- D: Research + search providers ---" -ForegroundColor Yellow
$pD = New-CapabilityPlan -ProjectId "PROJ-SIM-D-D" -PhaseId "PHASE-RESEARCH" -ProjectType "fullstack-admin" `
    -ActiveAgents @("RSRC-001") -LocalFirst $true -NetworkAllowed $true -CloudAllowed $false `
    -SecretsAllowed $false -SandboxAvailable $false -HumanApprovalAvailable $false
Run-S -L "D: Research + search providers (monitor_only)" -P ($pD.summary.monitorOnlyCount -gt 0) `
    -D "Monitor=$($pD.summary.monitorOnlyCount) Rejected=$($pD.summary.rejectedCount)"

# === E: CAP-SKILL-099, no human confirmation → pending_human ===
Write-Host "--- E: Pending human UNconfirmed ---" -ForegroundColor Yellow
$pE = New-CapabilityPlan -ProjectId "PROJ-SIM-D-E" -PhaseId "PHASE-DESIGN" -ProjectType "fullstack-admin" `
    -ActiveAgents @("LIB-001") -LocalFirst $true -NetworkAllowed $true -CloudAllowed $false `
    -SecretsAllowed $false -SandboxAvailable $false -HumanApprovalAvailable $false
$hasCap099P = @($pE.pendingHumanCapabilities | Where-Object { $_.capabilityId -eq "CAP-SKILL-099" }).Count -gt 0
Run-S -L "E: CAP-SKILL-099 pending_human (no confirmation)" -P $hasCap099P `
    -D "Total pendingH=$($pE.summary.pendingHumanCount)"

# === F: CAP-SKILL-099, WITH human confirmation → allow ===
Write-Host "--- F: Pending human CONFIRMED ---" -ForegroundColor Yellow
$pF = New-CapabilityPlan -ProjectId "PROJ-SIM-D-F" -PhaseId "PHASE-DESIGN" -ProjectType "fullstack-admin" `
    -ActiveAgents @("LIB-001") -LocalFirst $true -NetworkAllowed $true -CloudAllowed $false `
    -SecretsAllowed $false -SandboxAvailable $false -HumanApprovalAvailable $true
$hasCap099A = @($pF.allowedCapabilities | Where-Object { $_.capabilityId -eq "CAP-SKILL-099" }).Count -gt 0
Run-S -L "F: CAP-SKILL-099 ALLOWED after confirmation" -P $hasCap099A `
    -D "Total allowed=$($pF.summary.allowedCount)"

# === G: Monitor-only capability NOT invocable ===
Write-Host "--- G: Monitor-only invocability ---" -ForegroundColor Yellow
$rG = Test-CapabilityPermission -AgentId "IMPL-FE-001" -CapabilityId "CAP-MCP-001" -ProjectId "PROJ-SIM-D-G" -ProjectType "fullstack-admin" -RequestedAction "execute"
Run-S -L "G: Monitor-only cap NOT invocable" -P ($rG.Decision -eq "MONITOR_ONLY") `
    -D "Decision: $($rG.Decision)"

# === H: Cloud service in local-first → rejected/monitored ===
Write-Host "--- H: Cloud in local-first ---" -ForegroundColor Yellow
$rH = Test-CapabilityPermission -AgentId "IMPL-BE-001" -CapabilityId "CAP-CLD-003" -ProjectId "PROJ-SIM-D-H" -ProjectType "fullstack-admin" -IsLocalFirst $true
Run-S -L "H: Cloud service blocked in local-first" -P ($rH.Decision -in @("REJECT","MONITOR_ONLY")) `
    -D "Decision: $($rH.Decision)"

# === SUMMARY ===
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " INTEGRATION SIMULATION: $PassCount/$($PassCount+$FailCount) PASSED" -ForegroundColor $(if($FailCount -eq 0){'Green'}else{'Yellow'})
Write-Host "========================================" -ForegroundColor Cyan

$simR = [PSCustomObject]@{ date=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"); passCount=$PassCount; failCount=$FailCount; allPassed=($FailCount -eq 0); scenarios=$Results }
$simR | ConvertTo-Json -Depth 4 | Out-File (Join-Path $FactoryRoot "runtime\tests\governance-integration-simulation-result.json") -Encoding UTF8
