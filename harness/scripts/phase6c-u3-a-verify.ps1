# phase6c-u3-a-verify.ps1 — Phase 6C-U3-A Operator CLI Verifier (27 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

# 1-4: Prerequisites
check "V01: U2-D report exists" { Test-Path "$H\outputs\PHASE_6C_U2_D_FINAL_FACTORY_AUDIT_BUNDLE_REPORT.md" }
check "V02: U2 final ZIP exists" { Test-Path "$H\outputs\phase6c-u2-final-factory-audit-bundle.zip" }
check "V03: Operator CLI exists" { Test-Path "$H\scripts\invoke-project-factory.ps1" }
check "V04: Operator CLI guide exists" { Test-Path "$H\docs\HARNESS_OPERATOR_CLI_GUIDE.md" }

# 5-7: Reports
check "V05: Preflight report exists" { Test-Path "$H\outputs\u3-a-operator-example-preflight-report.json" }
check "V06: Preflight verdict PASS" { $p=Get-Content "$H\outputs\u3-a-operator-example-preflight-report.json"|ConvertFrom-Json; $p.verdict -eq "PASS" }
check "V07: Materialization report exists" { Test-Path "$H\outputs\u3-a-operator-example-materialization-report.json" }

# 8-14: Run skeleton checks
$runDir = "$H\runs\u3-a-operator-example"
check "V08: U3-A example run exists" { Test-Path $runDir }
check "V09: TASKS.json exists" { Test-Path "$runDir\TASKS.json" }
check "V10: ACCEPTANCE.json exists" { Test-Path "$runDir\ACCEPTANCE.json" }
check "V11: OWNERSHIP.json exists" { Test-Path "$runDir\OWNERSHIP.json" }
check "V12: Contract locked=true" { $c=Get-Content "$runDir\interface-contract.lock.json"|ConvertFrom-Json; $c.locked -eq $true }
check "V13: Worker prompt files exist" { (Test-Path "$runDir\prompts\worker-1-prompt.md") -and (Test-Path "$runDir\prompts\worker-2-prompt.md") }
check "V14: Prompt pack exists" { Test-Path "$H\outputs\u3-a-operator-example-worker-prompt-pack.md" }

# 15-16: Prompt pack content
$pp = if(Test-Path "$H\outputs\u3-a-operator-example-worker-prompt-pack.md"){Get-Content "$H\outputs\u3-a-operator-example-worker-prompt-pack.md" -Raw}else{""}
check "V15: Prompt pack includes both worker prompts" { $pp -match "Worker 1 Prompt" -and $pp -match "Worker 2 Prompt" }

# 17-19: GateCheck and Status
check "V16: GateCheck report exists" { Test-Path "$H\outputs\u3-a-operator-example-gatecheck-report.json" }
check "V17: GateCheck status=WAITING_FOR_WORKER_OUTPUTS" { $g=Get-Content "$H\outputs\u3-a-operator-example-gatecheck-report.json"|ConvertFrom-Json; $g.status -eq "WAITING_FOR_WORKER_OUTPUTS" }
check "V18: Status report exists" { Test-Path "$H\outputs\u3-a-operator-example-status-report.json" }
check "V19: Status=MATERIALIZED_WAITING_FOR_WORKERS" { $s=Get-Content "$H\outputs\u3-a-operator-example-status-report.json"|ConvertFrom-Json; $s.status -eq "MATERIALIZED_WAITING_FOR_WORKERS" }

# 20-23: Boundary checks
check "V20: No Worker source outputs" { -not (Test-Path "$runDir\workspace\worker-1\src\utils.ts") }
check "V21: No spawn-agent-evidence.json" { -not (Test-Path "$runDir\spawn-agent-evidence.json") }
check "V22: No runtime gate PASS reports" { -not (Test-Path "$runDir\reports\honesty-w1.json") }
check "V23: No final ZIP created" { -not (Test-Path "$H\outputs\phase6c-u3-a-final-audit-bundle.zip") }

# 24: Closed artifacts unchanged
check "V24: T0-R3 / U1 / U2 ZIPs unchanged" {
    $t0=(Get-FileHash "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
    $u1=(Get-FileHash "$H\outputs\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
    $u2=(Get-FileHash "$H\outputs\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq "30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
    $t0 -and $u1 -and $u2
}

# 25-27: Report
$reportPath = "$H\outputs\PHASE_6C_U3_A_OPERATOR_CLI_REPORT.md"
check "V25: Final report exists" { Test-Path $reportPath }
check "V26: Report states no spawn_agent" { if(Test-Path $reportPath){$r=Get-Content $reportPath -Raw;$r -match "does not run spawn_agent|does not prove new multi-agent"}else{$false} }
check "V27: Report states only adds Operator CLI" { if(Test-Path $reportPath){$r=Get-Content $reportPath -Raw;$r -match "Operator CLI|operator.*runbook|reusable.*Operator"}else{$false} }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-U3-A";reportType="u3-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
