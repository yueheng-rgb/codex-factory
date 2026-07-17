# phase6c-u3-b-verify.ps1 — Phase 6C-U3-B Operator Real Run Verifier (38 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$runDir = "$H\runs\u3-b-operator-real-run"
$out = "$H\outputs"
$rid = "u3-b-operator-real-run"

# 1-3: Prereqs
check "V01: U3-A report exists" { Test-Path "$H\outputs\PHASE_6C_U3_A_OPERATOR_CLI_REPORT.md" }
check "V02: Operator CLI exists" { Test-Path "$H\scripts\invoke-project-factory.ps1" }
check "V03: U3-B run exists" { Test-Path $runDir }

# 4-6: Operator reports
check "V04: Preflight report PASS" { $p=Get-Content "$out\$rid-preflight-report.json"|ConvertFrom-Json; $p.verdict -eq "PASS" }
check "V05: Materialization report PASS" { $m=Get-Content "$out\$rid-materialization-report.json"|ConvertFrom-Json; $m.verdict -eq "PASS" }
check "V06: Prompt pack exists" { Test-Path "$out\$rid-worker-prompt-pack.md" }

# 7-10: Spawn evidence
check "V07: spawn-agent-evidence exists" { Test-Path "$runDir\spawn-agent-evidence.json" }
$se = if(Test-Path "$runDir\spawn-agent-evidence.json"){Get-Content "$runDir\spawn-agent-evidence.json"|ConvertFrom-Json}else{$null}
check "V08: operatorDriven=true" { $se -and $se.operatorDriven -eq $true }
check "V09: realWorkersUsed=true" { $se -and $se.realWorkersUsed -eq $true }
check "V10: workerCount=2" { $se -and $se.workerCount -eq 2 }

# 11-14: Worker outputs
check "V11: Worker 1 source exists" { Test-Path "$runDir\workspace\worker-1\src\utils.ts" }
check "V12: Worker 2 source exists" { Test-Path "$runDir\workspace\worker-2\src\service.ts" }
check "V13: Worker 1 manifest exists" { Test-Path "$runDir\worker-interface-manifests\worker-1-interface-manifest.json" }
check "V14: Worker 2 manifest exists" { Test-Path "$runDir\worker-interface-manifests\worker-2-interface-manifest.json" }

# 15-18: GateCheck + Status
check "V15: GateCheck report exists" { Test-Path "$out\$rid-gatecheck-report.json" }
$gc = if(Test-Path "$out\$rid-gatecheck-report.json"){Get-Content "$out\$rid-gatecheck-report.json"|ConvertFrom-Json}else{$null}
check "V16: GateCheck status GATES_PASS" { $gc -and ($gc.status -eq "GATES_PASS" -or $gc.allGatesPass -eq $true) }
check "V17: Status report exists" { Test-Path "$out\$rid-status-report.json" }
$st = if(Test-Path "$out\$rid-status-report.json"){Get-Content "$out\$rid-status-report.json"|ConvertFrom-Json}else{$null}
check "V18: Status GATES_PASS" { $st -and ($st.status -eq "GATES_PASS" -or $st.status -eq "COMPLETED_PASS") }

# 19-26: Gates
check "V19: Source-derived W1 exists" { Test-Path "$runDir\source-derived-interface-manifests\worker-1.json" }
check "V20: Source-derived W2 exists" { Test-Path "$runDir\source-derived-interface-manifests\worker-2.json" }
$h1 = Get-Content "$runDir\reports\manifest-honesty-report-worker-1.json"|ConvertFrom-Json
$h2 = Get-Content "$runDir\reports\manifest-honesty-report-worker-2.json"|ConvertFrom-Json
check "V21: Honesty W1 PASS" { $h1.verdict -eq "PASS" }
check "V22: Honesty W2 PASS" { $h2.verdict -eq "PASS" }
$dr = Get-Content "$runDir\reports\interface-drift-report.json"|ConvertFrom-Json
check "V23: Drift PASS" { $dr.verdict -eq "PASS" }
check "V24: Isolation PASS" { (Get-Content "$runDir\reports\workspace-isolation-report.json"|ConvertFrom-Json).verdict -eq "PASS" }
check "V25: Overlap PASS" { (Get-Content "$runDir\reports\parallel-overlap-report.json"|ConvertFrom-Json).verdict -eq "PASS" }
check "V26: Integration PASS" { (Get-Content "$runDir\reports\integration-gate-report.json"|ConvertFrom-Json).verdict -eq "PASS" }

# 27-32: validate-state
$vs = Get-Content "$runDir\reports\validate-state-report.json"|ConvertFrom-Json
check "V27: validate-state report exists" { $vs -ne $null }
check "V28: validate-state verdict=run_passed" { $vs.verdict -eq "run_passed" }
check "V29: No no_token_store" { ($vs.errors|Out-String) -notmatch "no_token_store" }
check "V30: No PROOF_VERIFICATION_FAILED" { ($vs.errors|Out-String) -notmatch "PROOF_VERIFICATION_FAILED" }
check "V31: Hash chain valid" { ($vs.passes|Out-String) -match "Hash chain valid" }
check "V32: No tamper" { ($vs.errors|Out-String) -notmatch "CONTROL_PLANE|EXTERNAL_TRUST" }

# 33-38: Boundaries
check "V33: No U3-C negatives" { -not (Test-Path "$H\runs\u3-c-negative") }
check "V34: No final ZIP" { -not (Test-Path "$H\outputs\phase6c-u3-b-final-audit-bundle.zip") }
check "V35: T0-R3/U1/U2 unchanged" {
    $t0=(Get-FileHash "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
    $u1=(Get-FileHash "$H\outputs\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
    $u2=(Get-FileHash "$H\outputs\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq "30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
    $t0 -and $u1 -and $u2
}
$rp = "$H\outputs\PHASE_6C_U3_B_OPERATOR_REAL_RUN_REPORT.md"
check "V36: Final report exists" { Test-Path $rp }
check "V37: Report states one operator-driven run" { if(Test-Path $rp){$r=Get-Content $rp -Raw;$r -match "operator-driven|Operator.*real.*run"}else{$false} }
check "V38: Report does not claim production capabilities" { if(Test-Path $rp){$r=Get-Content $rp -Raw;$r -notmatch "production.*grade.*multi"}else{$true} }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-U3-B";reportType="u3-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
