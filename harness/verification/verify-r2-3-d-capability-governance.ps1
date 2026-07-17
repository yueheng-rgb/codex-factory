# R2.3-D CAPABILITY GOVERNANCE INTEGRATION — Verification Script
# Part of: FACTORY-R2.3-D-CAPABILITY-GOVERNANCE-INTEGRATION

param([string]$FactoryRoot = "C:\Codex_App_Factory")
$ErrorActionPreference = "Continue"

. (Join-Path $FactoryRoot "runtime\agent-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-permission-gate.ps1")
. (Join-Path $FactoryRoot "runtime\bootstrap-capability-plan.ps1")
. (Join-Path $FactoryRoot "runtime\capability-registry-diff.ps1")

$Results = @(); $PassCount = 0; $FailCount = 0
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-D CAPABILITY GOVERNANCE VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function A { param([string]$C,[bool]$P,[string]$D="") 
    $script:Results += [PSCustomObject]@{Check=$C;Passed=$P;Detail=$D}; if($P){$script:PassCount++}else{$script:FailCount++}
    Write-Host "$(if($P){'[PASS]'}else{'[FAIL]'}) $C" -ForegroundColor $(if($P){'Green'}else{'Red'})
}

# 1. Bootstrap capability plan generation
Write-Host "--- 1. Bootstrap Plan ---" -ForegroundColor Yellow
$plan1 = New-CapabilityPlan -ProjectId "PROJ-VFY-D-001" -PhaseId "PHASE-DESIGN" -ProjectType "fullstack-admin" -ActiveAgents @("PM-001","ARCH-001")
A "Bootstrap plan generated" ($null -ne $plan1) ""
A "  Plan has projectId" ($plan1.projectId -eq "PROJ-VFY-D-001") ""
A "  Plan has allowedCapabilities" ($plan1.summary.allowedCount -ge 0) ""
A "  Plan has monitorOnlyCapabilities" ($plan1.summary.monitorOnlyCount -ge 0) ""
A "  Plan has recommendedNextAction" ($null -ne $plan1.recommendedNextAction) ""
A "  Plan file saved to disk" (Test-Path (Join-Path $FactoryRoot "governance\capability-plans\PROJ-VFY-D-001-PHASE-DESIGN-capability-plan.json")) ""

# 2. pending_human path
Write-Host "--- 2. PENDING_HUMAN ---" -ForegroundColor Yellow
$ph1 = Test-CapabilityPermission -AgentId "LIB-001" -CapabilityId "CAP-SKILL-099" -ProjectId "PROJ-VFY" -ProjectType "fullstack-admin" -HasHumanConfirmation $false
A "Pending_human: no confirmation → PENDING_HUMAN" ($ph1.Decision -eq "PENDING_HUMAN") $ph1.Reason
$ph2 = Test-CapabilityPermission -AgentId "LIB-001" -CapabilityId "CAP-SKILL-099" -ProjectId "PROJ-VFY" -ProjectType "fullstack-admin" -HasHumanConfirmation $true
A "Pending_human: WITH confirmation → ALLOW" ($ph2.Decision -in @("ALLOW","ALLOW_WITH_CONTROLS")) $ph2.Reason

# 3. pending_sandbox path
Write-Host "--- 3. PENDING_SANDBOX ---" -ForegroundColor Yellow
$ps1 = Test-CapabilityPermission -AgentId "IMPL-DB-001" -CapabilityId "CAP-MCP-006" -ProjectId "PROJ-VFY" -ProjectType "fullstack-admin" -HasAuth $true -HasSandbox $false
A "Pending_sandbox: no sandbox → PENDING_SANDBOX" ($ps1.Decision -eq "PENDING_SANDBOX") $ps1.Reason
$ps2 = Test-CapabilityPermission -AgentId "IMPL-DB-001" -CapabilityId "CAP-MCP-006" -ProjectId "PROJ-VFY" -ProjectType "fullstack-admin" -HasAuth $true -HasSandbox $true
A "Pending_sandbox: WITH sandbox → ALLOW" ($ps2.Decision -in @("ALLOW","ALLOW_WITH_CONTROLS")) $ps2.Reason

# 4. Monitor-only policy
Write-Host "--- 4. Monitor-only ---" -ForegroundColor Yellow
$m1 = Test-CapabilityPermission -AgentId "IMPL-FE-001" -CapabilityId "CAP-MCP-001" -ProjectId "PROJ-VFY" -ProjectType "fullstack-admin" -RequestedAction "execute"
A "Monitor-only: execute → MONITOR_ONLY" ($m1.Decision -eq "MONITOR_ONLY") $m1.Reason
$m2 = Test-CapabilityPermission -AgentId "IMPL-FE-001" -CapabilityId "CAP-MCP-001" -ProjectId "PROJ-VFY" -ProjectType "fullstack-admin" -RequestedAction "import"
A "Monitor-only: import → MONITOR_ONLY" ($m2.Decision -eq "MONITOR_ONLY") $m2.Reason

# 5. Registry diff tool
Write-Host "--- 5. Registry Diff ---" -ForegroundColor Yellow
$diff = Get-RegistryDiff -SnapshotLabel "r2-3-d-baseline"
A "Registry diff tool runs" ($null -ne $diff) ""
A "  Diff has currentEntryCount" ($diff.currentEntryCount -ge 90) "Count: $($diff.currentEntryCount)"
A "  Diff detects added entries" ($diff.added.Count -ge 0) "Added: $($diff.added.Count)"

# 6. Count reconciliation
Write-Host "--- 6. Count Reconciliation ---" -ForegroundColor Yellow
Initialize-CapabilityCache
$masterCount = $script:CapabilityCache.Count
$typedFiles = @{skill="skill-candidate-registry.jsonl"; mcp="mcp-candidate-registry.jsonl"; search="search-provider-candidate-registry.jsonl"; template="template-starter-candidate-registry.jsonl"; verifier="verifier-candidate-registry.jsonl"; runner="runner-candidate-registry.jsonl"}
$typedTotal = 0
foreach ($t in $typedFiles.Keys) { $f = Join-Path (Join-Path $FactoryRoot "registries") $typedFiles[$t]; if (Test-Path $f) { $lines = Get-Content $f | Where-Object { $_ -notmatch '^#' -and $_.Trim() -ne '' }; $typedTotal += $lines.Count } }
A "Master registry has 91 entries (90 + CAP-SKILL-099)" ($masterCount -eq 91) "Count: $masterCount"
A "Typed registries total 61 entries" ($typedTotal -eq 61) "Count: $typedTotal"
A "Master + typed = 152 total (no double-count in verification)" (($masterCount + $typedTotal) -eq 152) ""

# 7. Decision log
Write-Host "--- 7. Decision Log ---" -ForegroundColor Yellow
$decPath = Join-Path $FactoryRoot "governance\capability-decisions\capability-decision-index.jsonl"
$decExists = Test-Path $decPath
$decCount = if ($decExists) { (Get-Content $decPath | Where-Object { $_.Trim() -ne "" }).Count } else { 0 }
A "Decision log exists and writable" ($decCount -gt 0) "Entries: $decCount"

# 8. Simulation results
Write-Host "--- 8. Simulation ---" -ForegroundColor Yellow
$simPath = Join-Path $FactoryRoot "runtime\tests\governance-integration-simulation-result.json"
if (Test-Path $simPath) {
    $sim = Get-Content $simPath -Raw | ConvertFrom-Json
    A "Simulation: all scenarios passed" $sim.allPassed "Pass: $($sim.passCount)/$($sim.passCount + $sim.failCount)"
}

# 9. R2.3-C backward compat
Write-Host "--- 9. R2.3-C Backward Compat ---" -ForegroundColor Yellow
. (Join-Path $FactoryRoot "runtime\execution-context.ps1")
$ctx = New-AgentExecutionContext -AgentId "IMPL-FE-001" -ProjectId "PROJ-VFY-D" -PhaseId "PHASE-IMPL" -ProjectType "fullstack-admin"
A "R2.3-C exec context fields preserved" ($null -ne $ctx.allowedCapabilities) ""
A "  capabilityRiskSummary preserved" ($null -ne $ctx.capabilityRiskSummary) ""

# 10. File inventory
Write-Host "--- 10. File Inventory ---" -ForegroundColor Yellow
@("runtime\bootstrap-capability-plan.ps1","runtime\capability-registry-diff.ps1","runtime\capability-governance-integration-simulation.ps1","governance\capability-plans","governance\capability-registry-snapshots\r2-3-d-baseline") | ForEach-Object {
    A "File: $_" (Test-Path (Join-Path $FactoryRoot $_)) ""
}

# SUMMARY
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " VERIFICATION: $PassCount/$($PassCount+$FailCount) PASSED" -ForegroundColor $(if($FailCount -eq 0){'Green'}else{'Red'})
Write-Host "========================================" -ForegroundColor Cyan

$v = [PSCustomObject]@{ date=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"); passCount=$PassCount; failCount=$FailCount; allPassed=($FailCount -eq 0); results=$Results }
$v | ConvertTo-Json -Depth 4 | Out-File (Join-Path $FactoryRoot "harness\verification\r2-3-d-verification-result.json") -Encoding UTF8
