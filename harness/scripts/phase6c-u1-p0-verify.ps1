# phase6c-u1-p0-verify.ps1 -- U1-P0 Plan Lightweight Verifier
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0

function check($label, $scriptBlock) {
    $script:total++
    try { if (& $scriptBlock) { [void]$script:P.Add($label); $script:ok++ } else { [void]$script:E.Add("$label-FAIL") } }
    catch { [void]$script:E.Add("$label-ERROR: $_") }
}

# 1. Report exists
check "VFY-01: U1-P0 plan exists" { Test-Path "$H\outputs\PHASE_6C_U1_P0_EXECUTION_PLAN.md" }

# 2. Report non-empty
check "VFY-02: U1-P0 plan non-empty" { (Get-Item "$H\outputs\PHASE_6C_U1_P0_EXECUTION_PLAN.md").Length -gt 1000 }

# 3. Report contains required sections
$report = try { Get-Content "$H\outputs\PHASE_6C_U1_P0_EXECUTION_PLAN.md" -Raw } catch { "" }
check "VFY-03: Contains Readiness Summary" { $report -match "Readiness Summary" }
check "VFY-04: Contains Goal Definition" { $report -match "Goal Definition" }
check "VFY-05: Contains Worker Topology" { $report -match "Worker Topology" }
check "VFY-06: Contains Gate Chain" { $report -match "Gate Chain" }
check "VFY-07: Contains Negative Controls" { $report -match "Negative Controls" }
check "VFY-08: Contains Execution Phases" { $report -match "Execution Phases" }
check "VFY-09: Contains Risk Register" { $report -match "Risk Register" }
check "VFY-10: Contains Go/No-Go Checklist" { $report -match "Go.*No-Go" }

# 4. Recommends proceed or no-go
check "VFY-11: Recommends next step" { $report -match "Proceed to Phase|Do not proceed" }

# 5. No U1 run directory created
check "VFY-12: No U1 run directory" { -not (Test-Path "$H\runs\u1-r1") -and -not (Test-Path "$H\runs\phase6c-u1") }

# 6. No spawn evidence created
check "VFY-13: No spawn evidence" { -not (Test-Path "$H\runs\u1-r1\spawn-agent-evidence.json") -and -not (Test-Path "$H\runs\phase6c-u1") }

# 7. T0-R3 artifact unchanged
check "VFY-14: T0-R3 ZIP unchanged" {
    $zip = "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"
    if (Test-Path $zip) { (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d" }
    else { $false }
}

# 8. Report contains "Do Not Claim" section
check "VFY-15: Do Not Claim present" { $report -match "Do Not Claim" }

# 9. Report states design-only
check "VFY-16: Design-only statement" { $report -match "does not prove new multi-agent|does not run spawn_agent" }

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$exitCode = if ($E.Count -gt 0) { 1 } else { 0 }

@{
    phase="Phase 6C-U1-P0"; reportType="u1-p0-verifier"; verdict=$verdict
    timestamp=(Get-Date).ToString("o"); totalChecks=$total; passCount=$ok; failCount=$E.Count
    passes=$P; errors=$E
} | ConvertTo-Json -Depth 3

exit $exitCode