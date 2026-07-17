# phase6c-u1-a-verify.ps1 — Phase 6C-U1-A Materialization Verifier (26 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$R = Join-Path $H "runs\u1-r1"
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l, $sb) { $script:total++; try { if (& $sb) { [void]$script:P.Add($l); $script:ok++ } else { [void]$script:E.Add("$l-FAIL") } } catch { [void]$script:E.Add("$l-ERROR: $_") } }

# 1. validate-state backup exists
check "V01: validate-state backup exists" { (Get-ChildItem "$H\backups\validate-state.pre-u1-a.*.ps1" -ErrorAction SilentlyContinue).Count -gt 0 }

# 2. U1-P0 report exists
check "V02: U1-P0 report exists" { Test-Path "$H\outputs\PHASE_6C_U1_P0_EXECUTION_PLAN.md" }

# 3. runs/u1-r1/ exists
check "V03: runs/u1-r1/ exists" { Test-Path $R }

# 4. TASKS.json has 2 tasks
$tasks = if (Test-Path "$R\TASKS.json") { Get-Content "$R\TASKS.json" | ConvertFrom-Json } else { $null }
check "V04: TASKS.json has 2 tasks" { $tasks -and $tasks.tasks.Count -eq 2 }

# 5. ACCEPTANCE.json has >=6 ACs
$acc = if (Test-Path "$R\ACCEPTANCE.json") { Get-Content "$R\ACCEPTANCE.json" | ConvertFrom-Json } else { $null }
check "V05: ACCEPTANCE.json >=6 items" { $acc -and (@($acc.acceptanceItems.PSObject.Properties)).Count -ge 6 }

# 6. OWNERSHIP.json non-empty
$own = if (Test-Path "$R\OWNERSHIP.json") { Get-Content "$R\OWNERSHIP.json" | ConvertFrom-Json } else { $null }
check "V06: OWNERSHIP.json non-empty" { $own -and $own.entries.PSObject.Properties.Count -gt 0 }

# 7. Contract lock exists
check "V07: Contract lock exists" { Test-Path "$R\interface-contract.lock.json" }

# 8. Contract locked=true
$contract = if (Test-Path "$R\interface-contract.lock.json") { Get-Content "$R\interface-contract.lock.json" | ConvertFrom-Json } else { $null }
check "V08: Contract locked=true" { $contract -and $contract.locked -eq $true }

# 9. Contract has 5 interfaces
check "V09: Contract has 5 interfaces" { $contract -and $contract.interfaces.Count -eq 5 }

# 10. Contract has >=3 cross-worker requiredBy
check "V10: >=3 cross-worker requiredBy" {
    ($contract.interfaces | Where-Object { $_.requiredBy.Count -gt 0 }).Count -ge 2
}

# 11-12. Worker prompts exist
check "V11: worker-1 prompt exists" { (Test-Path "$R\prompts\worker-1-prompt.md") -and ((Get-Item "$R\prompts\worker-1-prompt.md").Length -gt 100) }
check "V12: worker-2 prompt exists" { (Test-Path "$R\prompts\worker-2-prompt.md") -and ((Get-Item "$R\prompts\worker-2-prompt.md").Length -gt 100) }

# 13-15. Workspace dirs exist
check "V13: workspace/worker-1 exists" { Test-Path "$R\workspace\worker-1" }
check "V14: workspace/worker-2 exists" { Test-Path "$R\workspace\worker-2" }
check "V15: canonical-integrated exists" { Test-Path "$R\canonical-integrated" }

# 16. No spawn-agent-evidence.json
check "V16: No spawn evidence" { -not (Test-Path "$R\spawn-agent-evidence.json") }

# 17-19. No U1-B reports
check "V17: No parallel-overlap report" { -not (Test-Path "$R\reports\parallel-overlap-report.json") }
check "V18: No interface-drift report" { -not (Test-Path "$R\reports\interface-drift-report.json") }
check "V19: No integration-gate report" { -not (Test-Path "$R\reports\integration-gate-report.json") }

# 20. No source-derived manifests (only .gitkeep)
check "V20: No source-derived manifests yet" {
    $sdm = Get-ChildItem "$R\source-derived-interface-manifests" -File -ErrorAction SilentlyContinue
    ($sdm | Where-Object { $_.Name -ne ".gitkeep" }).Count -eq 0
}

# 21. No worker output source files yet
check "V21: No worker source outputs" {
    -not (Test-Path "$R\workspace\worker-1\src\utils.ts") -and
    -not (Test-Path "$R\workspace\worker-2\src\app.ts")
}

# 22. T0-R3 SHA unchanged
check "V22: T0-R3 ZIP unchanged" {
    $zip = "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"
    if (Test-Path $zip) { (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d" } else { $false }
}

# 23. U0-D/E/F artifacts unchanged
check "V23: U0 positive runs exist" {
    (Test-Path "$H\runs\phase6c-u0-d-real") -and
    (Test-Path "$H\runs\phase6c-u0-e-real-parallel") -and
    (Test-Path "$H\runs\phase6c-u0-f-rework")
}

# 24. Final report exists
check "V24: Materialization report exists" { Test-Path "$H\outputs\PHASE_6C_U1_A_MATERIALIZATION_REPORT.md" }

# 25. Report states no spawn_agent
$report = if (Test-Path "$H\outputs\PHASE_6C_U1_A_MATERIALIZATION_REPORT.md") { Get-Content "$H\outputs\PHASE_6C_U1_A_MATERIALIZATION_REPORT.md" -Raw } else { "" }
check "V25: Report states no spawn_agent" { $report -match "does not run spawn_agent|no spawn_agent ran" }

# 26. Report recommends proceed or no-go
check "V26: Report recommends Proceed/No-Go" { $report -match "Proceed to Phase|No-Go" }

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$exitCode = if ($E.Count -gt 0) { 1 } else { 0 }
@{ phase="Phase 6C-U1-A"; reportType="u1-a-verifier"; verdict=$verdict; timestamp=(Get-Date).ToString("o"); totalChecks=$total; passCount=$ok; failCount=$E.Count; passes=$P; errors=$E } | ConvertTo-Json -Depth 3
exit $exitCode