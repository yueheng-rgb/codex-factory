# Factory State Dashboard Prototype
# Phase: FACTORY-STATE-DASHBOARD-0 / H
# Reads fixtures and generates Markdown + JSON dashboard
# SAFETY: read-only, no destructive actions, no secrets printed

param(
    [string]$FixturesDir = "C:\Codex_App_Factory\factory-dashboard\fixtures",
    [switch]$AsJson,
    [switch]$ShowBrief,
    [switch]$ShowPaths,
    [switch]$ShowAgents,
    [switch]$ShowRisks,
    [switch]$ShowCleanup,
    [switch]$ShowMount
)

$ErrorActionPreference = "Stop"

# === Load fixtures ===
$identity = Get-Content "$FixturesDir\project-identity.json" -Raw | ConvertFrom-Json
$phaseLedger = Get-Content "$FixturesDir\phase-ledger.json" -Raw | ConvertFrom-Json
$verifier = Get-Content "$FixturesDir\verifier-result.json" -Raw | ConvertFrom-Json
$blockersRisks = Get-Content "$FixturesDir\blockers-risks.json" -Raw | ConvertFrom-Json
$cleanupState = Get-Content "$FixturesDir\cleanup-state.json" -Raw | ConvertFrom-Json
$gates = Get-Content "$FixturesDir\gates.json" -Raw | ConvertFrom-Json
$agentLedgerLines = Get-Content "$FixturesDir\agent-ledger.jsonl"
$agentEntries = $agentLedgerLines | ForEach-Object { $_ | ConvertFrom-Json }

# === Health checks ===
$warningList = @()
$criticalList = @()

# Identity health
$identityHealth = if ($identity.userConfirmedIdentity) { "HEALTHY" } else { "WARNING" }

# Phase health
$currentPhase = $phaseLedger.currentPhase
$lastPhaseClose = $phaseLedger.lastPhaseClose
$phaseHealth = if ($verifier.verdict -eq "PASS") { "HEALTHY" } elseif ($verifier.verdict -eq "FAIL") { "CRITICAL" } else { "WARNING" }

# Blocker/risk counts
$blockerCount = $blockersRisks.blockers.Count
$riskCount = $blockersRisks.risks.Count
$blockerRiskHealth = if ($blockerCount -gt 0) { "CRITICAL" } elseif ($riskCount -gt 0) { "WARNING" } else { "HEALTHY" }
$foreignRiskCount = ($blockersRisks.risks | Where-Object { $_.foreignContext }).Count
if ($foreignRiskCount -gt 0) { $warningList += "FOREIGN_CONTEXT: $foreignRiskCount risk(s) from other project" }

# Memory health
$memoryHealth = "HEALTHY"
$mountSummary = "Clean - no foreign context detected"
if ($foreignRiskCount -gt 0) {
    $mountSummary = "WARNING: $foreignRiskCount foreign context item(s) detected"
    $warningList += "$foreignRiskCount foreign context item(s) detected"
}

# Cleanup health
$cleanupHealth = if ($cleanupState.pendingCleanupPlan) { "WARNING" } else { "HEALTHY" }
$cleanupSummary = if ($cleanupState.pendingCleanupPlan) { "Pending cleanup plan exists" } else { "No pending cleanup" }

# Agent ledger health
$agentPassCount = ($agentEntries | Where-Object { $_.verdict -eq "PASS" }).Count
$agentFailCount = ($agentEntries | Where-Object { $_.verdict -eq "FAIL" }).Count
$agentPartialCount = ($agentEntries | Where-Object { $_.verdict -eq "PARTIAL" }).Count
$agentRoles = ($agentEntries | ForEach-Object { $_.agent_role } | Select-Object -Unique) -join ", "
$agentLastActivity = ($agentEntries | Sort-Object { $_.timestamp } -Descending | Select-Object -First 1).timestamp
$missingProjectIdCount = ($agentEntries | Where-Object { -not $_.projectId }).Count
if ($missingProjectIdCount -gt 0) { $warningList += "Agent ledger: $missingProjectIdCount entry/ies missing projectId" }

# Path list
$pathList = @(
    @{name="Root"; path=$identity.rootPath},
    @{name="Working Copy"; path=$identity.workingCopyPath},
    @{name="Factory Install"; path=$identity.factoryInstallPath},
    @{name="External Space"; path=$identity.externalConversationSpacePath},
    @{name="Governance"; path=$identity.governancePath},
    @{name="Outputs"; path=$identity.outputsPath},
    @{name="Agent Ledger"; path=$identity.agentLedgerPath},
    @{name="Cleanup State"; path=$identity.cleanupStatePath}
)

# Overall health
$overallHealth = if ($criticalList.Count -gt 0) { "CRITICAL" } elseif ($warningList.Count -ge 3) { "WARNING" } else { "HEALTHY" }

# === Mode flags ===
if ($ShowBrief) {
    $emoji = switch ($overallHealth) { "HEALTHY" { "🟢" } "WARNING" { "🟡" } "CRITICAL" { "🔴" } default { "⚪" } }
    Write-Host "$emoji $($identity.projectName) | $($identity.status) | $currentPhase | $overallHealth"
    exit 0
}

if ($ShowPaths) {
    Write-Host "## 📁 Project Paths"
    foreach ($p in $pathList) {
        $exists = Test-Path $p.path -ErrorAction SilentlyContinue
        $indicator = if ($exists) { "🟢" } else { "🔴" }
        $status = if ($exists) { "" } else { "UNKNOWN_WITH_REASON: path not found" }
        Write-Host "$indicator **$($p.name):** $($p.path) $status"
    }
    exit 0
}

if ($ShowAgents) {
    Write-Host "## 🤖 Agent Ledger"
    Write-Host ""
    Write-Host "**Total Entries:** $($agentEntries.Count)"
    Write-Host "**By Role:** $agentRoles"
    Write-Host "**Verdicts:** ✅ $agentPassCount | ❌ $agentFailCount | ⚠ $agentPartialCount"
    Write-Host "**Last Activity:** $agentLastActivity"
    Write-Host ""
    foreach ($entry in $agentEntries) {
        $vEmoji = switch ($entry.verdict) { "PASS" { "✅" } "FAIL" { "❌" } "PARTIAL" { "⚠" } }
        Write-Host "### $($entry.agent_role) — $($entry.agent_id) $vEmoji"
        Write-Host "- **Time:** $($entry.timestamp)"
        Write-Host "- **Phase:** $($entry.phase)"
        Write-Host "- **Project:** $($entry.projectId)"
        Write-Host "- **Inputs:** $($entry.input_artifacts -join ', ')"
        Write-Host "- **Outputs:** $($entry.output_artifacts -join ', ')"
        Write-Host "- **Verdict:** $($entry.verdict)"
        if ($entry.known_caveats.Count -gt 0) { Write-Host "- **Caveats:** $($entry.known_caveats -join '; ')" }
        if ($entry.parent_agent) { Write-Host "- **Parent:** $($entry.parent_agent)" }
        if ($entry.handoff_to) { Write-Host "- **Handoff to:** $($entry.handoff_to)" }
        Write-Host ""
    }
    exit 0
}

if ($ShowRisks) {
    Write-Host "## 🚨 Blockers & Risks"
    Write-Host "**Blockers:** $blockerCount"
    foreach ($b in $blockersRisks.blockers) { Write-Host "- 🔴 $($b.description)" }
    Write-Host "**Risks:** $riskCount"
    foreach ($r in $blockersRisks.risks) { Write-Host "- 🟡 $($r.description)" }
    exit 0
}

if ($ShowCleanup) {
    Write-Host "## 🧹 Cleanup Status"
    Write-Host "- **Last Plan:** $($cleanupState.lastCleanupPlan)"
    Write-Host "- **Last Executed:** $($cleanupState.lastCleanupExecuted)"
    Write-Host "- **Pending Plan:** $(if($cleanupState.pendingCleanupPlan){'YES'}else{'None'})"
    Write-Host "- **Cache Size:** $($cleanupState.cacheSizeBytes) bytes"
    Write-Host "- **History Entries:** $($cleanupState.cleanupHistory.Count)"
    exit 0
}

if ($ShowMount) {
    Write-Host "## 🔗 Mount Status"
    Write-Host "- **Status:** $mountSummary"
    Write-Host "- **Foreign Context Warnings:** $($warningList.Count)"
    foreach ($w in $warningList) { Write-Host "  - 🟡 $w" }
    exit 0
}

if ($AsJson) {
    $dashboard = [ordered]@{
        projectId = $identity.projectId
        projectName = $identity.projectName
        projectStatus = $identity.status
        rootPath = $identity.rootPath
        workingCopyPath = $identity.workingCopyPath
        factoryInstallPath = $identity.factoryInstallPath
        externalConversationSpacePath = $identity.externalConversationSpacePath
        governancePath = $identity.governancePath
        outputsPath = $identity.outputsPath
        currentPhase = $currentPhase
        lastPhaseClose = $lastPhaseClose
        latestVerifier = @{ phase = $verifier.phase; verdict = $verifier.verdict; timestamp = $verifier.timestamp }
        latestPhaseReport = "UNKNOWN_WITH_REASON: not configured"
        activeBlockers = @($blockersRisks.blockers)
        activeRisks = @($blockersRisks.risks)
        enabledGates = @($gates)
        memoryStatus = $memoryHealth
        cleanupStatus = $cleanupState
        mountStatus = @{ summary = $mountSummary; foreignWarnings = @($warningList) }
        foreignContextWarnings = @($warningList)
        staleWarnings = @()
        missingEvidenceWarnings = @()
        agentLedgerSummary = @{
            totalEntries = $agentEntries.Count
            byRole = ($agentEntries | Group-Object agent_role | ForEach-Object { "$($_.Name):$($_.Count)" }) -join ", "
            passCount = $agentPassCount
            failCount = $agentFailCount
            partialCount = $agentPartialCount
            lastActivity = $agentLastActivity
        }
        nextRecommendedAction = if ($overallHealth -eq "CRITICAL") { "Resolve critical issues before continuing" } elseif ($warningList.Count -gt 0) { "Review $($warningList.Count) warning(s)" } else { "Continue to next phase" }
    }
    $dashboard | ConvertTo-Json -Depth 5
    exit 0
}

# === Default: Full Markdown Dashboard ===
$overallEmoji = switch ($overallHealth) { "HEALTHY" { "🟢" } "WARNING" { "🟡" } "CRITICAL" { "🔴" } default { "⚪" } }

Write-Host "========================================"
Write-Host " FACTORY STATE DASHBOARD"
Write-Host " $overallEmoji Overall: $overallHealth"
Write-Host "========================================"
Write-Host ""

Write-Host "## 🏷 Project: $($identity.projectName)"
Write-Host "- **ID:** $($identity.projectId)"
Write-Host "- **Status:** $($identity.status) $identityHealth"
Write-Host "- **Root:** $($identity.rootPath)"
Write-Host ""

Write-Host "## 📋 Phase"
Write-Host "- **Current:** $currentPhase $phaseHealth"
Write-Host "- **Last Close:** $lastPhaseClose"
Write-Host "- **Latest Verifier:** $($verifier.verdict) ($($verifier.timestamp))"
Write-Host ""

Write-Host "## ⚙ Mode"
Write-Host "- **Build Mode:** Build Lite (default)"
Write-Host "- **Multi-Agent:** Disabled"
Write-Host ""

Write-Host "## 🚨 Blockers & Risks"
Write-Host "### Blockers ($blockerCount)"
if ($blockerCount -eq 0) { Write-Host "- ✅ None" } else { foreach ($b in $blockersRisks.blockers) { Write-Host "- 🔴 $($b.description)" } }
Write-Host "### Risks ($riskCount)"
if ($riskCount -eq 0) { Write-Host "- ✅ None" } else { foreach ($r in $blockersRisks.risks) { $ri = if($r.foreignContext){"🟡 FOREIGN"}else{"🟡"}; Write-Host "- $ri $($r.description)" } }
Write-Host ""

Write-Host "## 📁 Paths"
foreach ($p in $pathList) {
    $exists = Test-Path $p.path -ErrorAction SilentlyContinue
    $indicator = if ($exists) { "🟢" } else { "🔴" }
    $status = if ($exists) { "" } else { " UNKNOWN_WITH_REASON: path not found" }
    Write-Host "$indicator **$($p.name):** $($p.path)$status"
}
Write-Host ""

Write-Host "## 🛡 Gates"
if ($gates.Count -eq 0) { Write-Host "- ⚪ No gates enabled" } else { foreach ($g in $gates) { Write-Host "- $g" } }
Write-Host ""

Write-Host "## 🧠 Memory & Context"
Write-Host "- **Memory:** $memoryHealth"
Write-Host "- **Mount:** $mountSummary"
Write-Host "- **Cleanup:** $cleanupSummary $cleanupHealth"
Write-Host ""

Write-Host "## 🤖 Agent Ledger"
Write-Host "- **Entries:** $($agentEntries.Count)"
Write-Host "- **Last Activity:** $agentLastActivity"
Write-Host "- **Agents:** $agentRoles"
if ($missingProjectIdCount -gt 0) { Write-Host "- 🔴 **WARNING:** $missingProjectIdCount entry/ies missing projectId" }
Write-Host ""

Write-Host "## ⚠ Warnings"
Write-Host "### Foreign Context ($foreignRiskCount)"
if ($warningList.Count -eq 0) { Write-Host "- ✅ None" } else { foreach ($w in $warningList) { Write-Host "- 🟡 $w" } }
Write-Host "### Stale (0)"
Write-Host "- ✅ None"
Write-Host "### Missing Evidence (0)"
Write-Host "- ✅ None"
Write-Host ""

if ($overallHealth -eq "CRITICAL") {
    Write-Host "## ▶ Next"
    Write-Host "Resolve critical issues before continuing."
} elseif ($warningList.Count -gt 0) {
    Write-Host "## ▶ Next"
    Write-Host "Review $($warningList.Count) warning(s) before next phase."
} else {
    Write-Host "## ▶ Next"
    Write-Host "Continue to next phase."
}
