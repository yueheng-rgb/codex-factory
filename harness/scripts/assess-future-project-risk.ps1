# assess-future-project-risk.ps1 — Phase 6C-T0-R1
# Assesses risk that future projects will pass engineering but fail audit closure.
# Returns risk level and blocked conditions.
param(
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$ScriptsDir = $PSScriptRoot
$HarnessRoot = Resolve-Path (Join-Path $ScriptsDir "..")

$risks = [System.Collections.ArrayList]::new()
$blockedConditions = [System.Collections.ArrayList]::new()
$requiredPreRun = [System.Collections.ArrayList]::new()
$requiredPostRun = [System.Collections.ArrayList]::new()
$totalRiskScore = 0

# --- Risk 1: Evidence omission ---
$existsDocs = Test-Path (Join-Path $HarnessRoot "docs\HARNESS_EVIDENCE_FLOW.md")
$existsSchemas = Test-Path (Join-Path $HarnessRoot "schemas\AUDIT_BUNDLE_SCHEMA.json")
if ($existsDocs -and $existsSchemas) {
    [void]$risks.Add(@{id="R1"; name="Evidence Omission"; level="LOW"; detail="Evidence flow documented, schema frozen. Risk: Agent generates PASS claim without saving evidence files."; mitigation="Schema validator checks required files; final-zip-self-consistency checks ZIP integrity." })
    $totalRiskScore += 1
} else {
    [void]$risks.Add(@{id="R1"; name="Evidence Omission"; level="HIGH"; detail="Evidence flow or schema missing. Agents may pass engineering without audit evidence."; mitigation="Complete T0 schema freeze first." })
    $totalRiskScore += 10
}

# --- Risk 2: Report/Evidence contradiction ---
$existsGate = Test-Path (Join-Path $HarnessRoot "scripts\validate-evidence-gates.ps1")
if ($existsGate) {
    [void]$risks.Add(@{id="R2"; name="Report/Evidence Contradiction"; level="LOW"; detail="CFP-001 gate exists. Risk: Agent writes PASS in report but evidence says FAIL."; mitigation="validate-evidence-gates.ps1 detects CFP-001; schema validator checks report consistency." })
    $totalRiskScore += 1
} else {
    [void]$risks.Add(@{id="R2"; name="Report/Evidence Contradiction"; level="HIGH"; detail="CFP-001 gate missing."; mitigation="Implement validate-evidence-gates.ps1." })
    $totalRiskScore += 10
}

# --- Risk 3: Missing mailbox/handoff evidence ---
$mailboxSchema = Test-Path (Join-Path $HarnessRoot "schemas\MAILBOX_SCHEMA.json")
if ($mailboxSchema) {
    [void]$risks.Add(@{id="R3"; name="Missing Mailbox Evidence"; level="MEDIUM"; detail="Mailbox schema exists but mailbox is advisory (not hard gate). Agents may use spawn_agent/resume_agent without preserving handoff artifacts."; mitigation="Require mailbox evidence for phases that claim multi-agent handoff." })
    $totalRiskScore += 3
} else {
    [void]$risks.Add(@{id="R3"; name="Missing Mailbox Evidence"; level="HIGH"; detail="Mailbox schema missing."; mitigation="Create mailbox schema." })
    $totalRiskScore += 7
}

# --- Risk 4: Context compression ---
[void]$risks.Add(@{id="R4"; name="Context Compression Data Loss"; level="MEDIUM"; detail="Codex may compress/truncate long conversations. Agents may lose task context, settings, or handoff details."; mitigation="Contract-first planning (read SPEC.md, write PLAN.md). Handoff files in independent workspace files." })
$totalRiskScore += 5

# --- Risk 5: Bundle path outside harness outputs ---
[void]$risks.Add(@{id="R5"; name="Bundle Path Drift"; level="LOW"; detail="Agent may write final ZIP outside harness/outputs/."; mitigation="Schema validator and final-zip-self-consistency check absolute path. Report must state ZIP path." })
$totalRiskScore += 2

# --- Risk 6: Long-run stability ---
[void]$risks.Add(@{id="R6"; name="Long-Run Stability"; level="MEDIUM"; detail="Phases 6C-A through S2 were short runs (< 30 min). Overnight or multi-hour runs untested. Agent timeouts, token expiry, context exhaustion likely."; mitigation="Phase 6C-S2 proves continuation. Heartbeat and timeout sweep exist. But overnight not proven." })
$totalRiskScore += 5

# --- Risk 7: Approval interruptions ---
[void]$risks.Add(@{id="R7"; name="Approval Interruptions"; level="MEDIUM"; detail="Codex requires user approval for escalated operations. Long runs may stall on approval prompts."; mitigation="Prefix rules for approved command prefixes. But new commands may still require approval." })
$totalRiskScore += 4

# --- Risk 8: External worker pool ---
[void]$risks.Add(@{id="R8"; name="External Worker Pool"; level="HIGH"; detail="codex exec worker pool not implemented. All current multi-agent is via spawn_agent within same session."; mitigation="Phase 6C-F explored token auth for external workers but not production ready." })
$totalRiskScore += 8

# --- Risk 9: Large project integration ---
[void]$risks.Add(@{id="R9"; name="Large Project Integration Complexity"; level="MEDIUM"; detail="Current test fixture is bookmark-manager (~30 files). Large projects with 100+ files may have complex merge conflicts."; mitigation="Git worktree spike shows feasibility. But large-scale merge not tested." })
$totalRiskScore += 5

# --- Risk 10: Codex capability drift ---
[void]$risks.Add(@{id="R10"; name="Codex Capability Drift"; level="LOW"; detail="Codex CLI, spawn_agent, resume_agent behavior may change across versions. Harness assumptions may break."; mitigation="Schema-frozen requirements. Phase validators are versioned. Re-validate after Codex updates." })
$totalRiskScore += 2

# --- Blocked conditions ---
[void]$blockedConditions.Add("No AUDIT_BUNDLE_SCHEMA.json — cannot validate bundle completeness")
[void]$blockedConditions.Add("No validate-state.ps1 run_passed — cannot close phase")
[void]$blockedConditions.Add("No validate-sha256sums.ps1 PASS — ZIP integrity unverified")
[void]$blockedConditions.Add("No external sidecar meta — ZIP digest unverifiable")
[void]$blockedConditions.Add("CFP-001 through CFP-012 not all passing — evidence/report contradiction possible")

# --- Required pre-run artifacts ---
[void]$requiredPreRun.Add("TASKS.json with baseCanonicalHash")
[void]$requiredPreRun.Add("ACCEPTANCE.json with acceptance items")
[void]$requiredPreRun.Add("CONTROL_PLANE_LOCK.json frozen before Worker start")
[void]$requiredPreRun.Add("RUN_PLAN.json or TASK_DAG.json")
[void]$requiredPreRun.Add("Authorization trust root established")

# --- Required post-run evidence ---
[void]$requiredPostRun.Add("RUN_STATE.jsonl with valid hash chain")
[void]$requiredPostRun.Add("validate-state stdout/stderr/exitCode")
[void]$requiredPostRun.Add("All command logs: npm ci, typecheck, test:unit, build")
[void]$requiredPostRun.Add("Authorization proofs for task_claimed, task_verified")
[void]$requiredPostRun.Add("SHA256SUMS.txt with relative paths, 0 mismatches")
[void]$requiredPostRun.Add("External sidecar meta matching ZIP digest")

# --- Calculate risk level ---
$riskLevel = if ($totalRiskScore -le 20) { "LOW" } elseif ($totalRiskScore -le 40) { "MEDIUM" } else { "HIGH" }

$result = @{
    phase = "6C-T0-R1"
    timestamp = (Get-Date).ToString("o")
    riskScore = $totalRiskScore
    riskLevel = $riskLevel
    risks = $risks
    blockedConditions = $blockedConditions
    requiredPreRunArtifacts = $requiredPreRun
    requiredPostRunEvidence = $requiredPostRun
    honestAnswer = "Yes, future projects may still have problems. The expected failure modes are now explicit and machine-checkable. The biggest remaining risks are long-run stability, external worker pool, approval interruptions, and large-project context drift."
}

if ($Json) {
    Write-Output ($result | ConvertTo-Json -Depth 4)
} else {
    Write-Output "=== Future Project Risk Assessment ==="
    Write-Output "Risk Level: $riskLevel (score: $totalRiskScore)"
    Write-Output ""
    Write-Output "Honest answer: $($result.honestAnswer)"
    Write-Output ""
    foreach ($r in $risks) { Write-Output "  $($r.level): $($r.name) — $($r.detail)" }
}

exit 0
