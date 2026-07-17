# Capability Runtime Simulation
# Part of: FACTORY-R2.3-C-CAPABILITY-REGISTRY-RUNTIME
# Runs 10 test cases against the Capability Permission Gate.
# Usage: . .\runtime\capability-runtime-simulation.ps1

param(
    [string]$FactoryRoot = "C:\Codex_App_Factory"
)

$ErrorActionPreference = "Continue"

. (Join-Path $FactoryRoot "runtime\capability-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-permission-gate.ps1")
. (Join-Path $FactoryRoot "runtime\capability-decision-logger.ps1")
. (Join-Path $FactoryRoot "runtime\agent-loader.ps1")

$Results = @()
$PassCount = 0
$FailCount = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-C CAPABILITY RUNTIME SIMULATION" -ForegroundColor Cyan
Write-Host " Local-First: true" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Run-Test {
    param(
        [string]$Label,
        [string]$AgentId,
        [string]$CapabilityId,
        [string]$ProjectType,
        [hashtable]$Overrides,
        [string[]]$AcceptDecisions
    )
    $params = @{
        ProjectId = "PROJ-SIM-001"; PhaseId = "PHASE-IMPL-001"
        AgentId = $AgentId; CapabilityId = $CapabilityId
        ProjectType = $ProjectType; RequestedAction = "import"
        HasAuth = $false; HasWriteScope = $false; HasSandbox = $false
        HasHumanConfirmation = $false; IsLocalFirst = $true
    }
    if ($Overrides) {
        foreach ($k in $Overrides.Keys) { $params[$k] = $Overrides[$k] }
    }
    $r = Test-CapabilityPermission @params
    
    Write-CapabilityDecision -DecisionResult $r -ProjectId "PROJ-SIM-001" -PhaseId "PHASE-IMPL-001" -AgentId $AgentId | Out-Null
    
    $passed = ($r.Decision -in $AcceptDecisions)
    
    $script:Results += [PSCustomObject]@{
        TestLabel     = $Label
        AgentId       = $AgentId
        CapabilityId  = $CapabilityId
        Decision      = $r.Decision
        AcceptDecisions = ($AcceptDecisions -join '|')
        Passed        = $passed
        Reason        = $r.Reason
        GateChecks    = ($r.GateChecks -join "; ")
        CapInfo       = if ($r.CapabilityInfo) { "$($r.CapabilityInfo.name) ($($r.CapabilityInfo.type), $($r.CapabilityInfo.trustLevel), $($r.CapabilityInfo.recommendedAction))" } else { "NOT_FOUND" }
    }
    
    if ($passed) { $script:PassCount++ } else { $script:FailCount++ }
    $icon = if ($passed) { "[PASS]" } else { "[MISMATCH]" }
    $color = if ($passed) { "Green" } else { "Yellow" }
    Write-Host "$icon $Label" -ForegroundColor $color
    Write-Host "    Decision: $($r.Decision) | Accept: $($AcceptDecisions -join '|')" -ForegroundColor $(if($passed){'Green'}else{'Yellow'})
}

# ============================================
# TEST A: FE agent + UI template (with write scope) → ALLOW
# ============================================
Write-Host "--- Test A: Low-risk template ---" -ForegroundColor Yellow
Run-Test -Label "A: FE agent + shadcn-ui-blocks (write scope)" `
    -AgentId "IMPL-FE-001" -CapabilityId "CAP-TMPL-004" -ProjectType "fullstack-admin" `
    -Overrides @{HasWriteScope=$true} -AcceptDecisions @("ALLOW", "ALLOW_WITH_CONTROLS")

# ============================================
# TEST B: FE agent + Stitch MCP (monitor action) → MONITOR_ONLY
# ============================================
Write-Host "--- Test B: Stitch MCP (monitor-only) ---" -ForegroundColor Yellow
Run-Test -Label "B: FE agent + stitch-mcp (action=monitor)" `
    -AgentId "IMPL-FE-001" -CapabilityId "CAP-MCP-001" -ProjectType "fullstack-admin" `
    -AcceptDecisions @("MONITOR_ONLY")

# ============================================
# TEST C: Research agent + web search provider → MONITOR_ONLY (monitor action)
# ============================================
Write-Host "--- Test C: Search provider ---" -ForegroundColor Yellow
Run-Test -Label "C: Research agent + web-search-fallback (monitor)" `
    -AgentId "RSRC-001" -CapabilityId "CAP-SRCH-009" -ProjectType "fullstack-admin" `
    -AcceptDecisions @("MONITOR_ONLY", "ALLOW_WITH_CONTROLS")

# ============================================
# TEST D: Verifier + Playwright verifier → ALLOW
# ============================================
Write-Host "--- Test D: Verifier tool ---" -ForegroundColor Yellow
Run-Test -Label "D: Verifier + api-contract-verifier" `
    -AgentId "VER-001" -CapabilityId "CAP-VER-007" -ProjectType "fullstack-admin" `
    -AcceptDecisions @("ALLOW", "ALLOW_WITH_CONTROLS")

# ============================================
# TEST E: Implementer + Security Scanner (agent mismatch) → REJECT
# ============================================
Write-Host "--- Test E: Cross-role capability ---" -ForegroundColor Yellow
Run-Test -Label "E: FE agent + security-scanner-mcp (SEC-only)" `
    -AgentId "IMPL-FE-001" -CapabilityId "CAP-MCP-012" -ProjectType "fullstack-admin" `
    -AcceptDecisions @("REJECT")

# ============================================
# TEST F: Any agent + quarantine capability → REJECT
# ============================================
Write-Host "--- Test F: Quarantine capability ---" -ForegroundColor Yellow
Run-Test -Label "F: FE agent + cloud-provider-mcp (QUARANTINE)" `
    -AgentId "IMPL-FE-001" -CapabilityId "CAP-MCP-014" -ProjectType "fullstack-admin" `
    -AcceptDecisions @("REJECT")

# ============================================
# TEST G: Any agent + quarantine capability (reject proxy) → REJECT
# ============================================
Write-Host "--- Test G: Rejected capability proxy ---" -ForegroundColor Yellow
Run-Test -Label "G: FE agent + cloud-queue-service (QUARANTINE as reject proxy)" `
    -AgentId "IMPL-FE-001" -CapabilityId "CAP-CLD-004" -ProjectType "fullstack-admin" `
    -AcceptDecisions @("REJECT")

# ============================================
# TEST H: MCP needing network+secrets without auth → REJECT
# ============================================
Write-Host "--- Test H: Secrets requirement ---" -ForegroundColor Yellow
Run-Test -Label "H: Research agent + github-mcp (needs token, no auth)" `
    -AgentId "RSRC-001" -CapabilityId "CAP-MCP-005" -ProjectType "fullstack-admin" `
    -Overrides @{HasAuth=$false} -AcceptDecisions @("REJECT")

# ============================================
# TEST I: Cloud capability in local-first → REJECT or MONITOR_ONLY
# ============================================
Write-Host "--- Test I: Cloud in local-first ---" -ForegroundColor Yellow
Run-Test -Label "I: DB agent + supabase-managed-db (cloud, action=monitor)" `
    -AgentId "IMPL-DB-001" -CapabilityId "CAP-CLD-001" -ProjectType "fullstack-admin" `
    -Overrides @{IsLocalFirst=$true} -AcceptDecisions @("REJECT", "MONITOR_ONLY")

# ============================================
# TEST J: Unknown capabilityId → REJECT
# ============================================
Write-Host "--- Test J: Unknown capability ---" -ForegroundColor Yellow
Run-Test -Label "J: FE agent + CAP-GHOST-999 (unknown ID)" `
    -AgentId "IMPL-FE-001" -CapabilityId "CAP-GHOST-999" -ProjectType "fullstack-admin" `
    -AcceptDecisions @("REJECT")

# ============================================
# SUMMARY
# ============================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SIMULATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PASS (decision matches): $PassCount" -ForegroundColor Green
Write-Host "  MISMATCH (decision differs): $FailCount" -ForegroundColor Yellow
Write-Host "  TOTAL: $($PassCount + $FailCount)" -ForegroundColor Cyan

$allPassed = ($FailCount -eq 0)

$simResult = [PSCustomObject]@{
    simulationDate = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    factoryRoot    = $FactoryRoot
    totalTests     = $PassCount + $FailCount
    passCount      = $PassCount
    mismatchCount  = $FailCount
    allPassed      = $allPassed
    tests          = $Results
}

$outPath = Join-Path $FactoryRoot "runtime\tests\capability-simulation-result.json"
$simResult | ConvertTo-Json -Depth 4 | Out-File -FilePath $outPath -Encoding UTF8
Write-Host "Results saved: runtime\tests\capability-simulation-result.json" -ForegroundColor White

if ($allPassed) {
    Write-Host "`n>>> ALL 10 TESTS PASSED <<<" -ForegroundColor Green
} else {
    Write-Host "`n>>> $FailCount TEST(S) HAD DECISION MISMATCH (see gap notes) <<<" -ForegroundColor Yellow
}
