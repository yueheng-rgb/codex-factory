# phase6c-u2-b-verify.ps1 闂?Phase 6C-U2-B Verifier (42 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l, $sb) { $script:total++; try { if (& $sb) { [void]$script:P.Add($l); $script:ok++ } else { [void]$script:E.Add("$l-FAIL") } } catch { [void]$script:E.Add("$l-ERROR: $_") } }

$runDir = "$H\runs\u2-b-factory-real-run"

# 1-3: Prerequisites
check "V01: U2-A report exists" { Test-Path "$H\outputs\PHASE_6C_U2_A_REUSABLE_FACTORY_REPORT.md" }
check "V02: Project factory guide exists" { Test-Path "$H\docs\HARNESS_PROJECT_FACTORY_GUIDE.md" }
check "V03: Example project request exists" { Test-Path "$H\factory\examples\tiny-typescript-service.project.json" }

# 4-9: Run existence and factory provenance
check "V04: U2-B run exists" { Test-Path $runDir }
check "V05: Run was factory-generated" { (Test-Path "$runDir\TASKS.json") -and (Test-Path "$runDir\README.md") }
check "V06: TASKS.json exists" { Test-Path "$runDir\TASKS.json" }
check "V07: ACCEPTANCE.json exists" { Test-Path "$runDir\ACCEPTANCE.json" }
check "V08: OWNERSHIP.json non-empty" { $o=Get-Content "$runDir\OWNERSHIP.json"|ConvertFrom-Json; ($o.ownershipMap.PSObject.Properties|Measure).Count -gt 0 }
check "V09: Contract locked=true" { $c=Get-Content "$runDir\interface-contract.lock.json"|ConvertFrom-Json; $c.locked -eq $true }

# 10-14: Spawn evidence
check "V10: spawn-agent-evidence exists" { Test-Path "$runDir\spawn-agent-evidence.json" }
check "V11: realWorkersUsed=true" { $s=Get-Content "$runDir\spawn-agent-evidence.json"|ConvertFrom-Json; $s.realWorkersUsed -eq $true }
check "V12: workerCount=2" { $s=Get-Content "$runDir\spawn-agent-evidence.json"|ConvertFrom-Json; $s.workerCount -eq 2 }
check "V13: Worker 1 source output exists" { Test-Path "$runDir\workspace\worker-1\src\utils.ts" }
check "V14: Worker 2 source output exists" { Test-Path "$runDir\workspace\worker-2\src\service.ts" }

# 15-22: Manifests
check "V15: Worker 1 interface manifest exists" { Test-Path "$runDir\worker-interface-manifests\worker-1-interface-manifest.json" }
check "V16: Worker 2 interface manifest exists" { Test-Path "$runDir\worker-interface-manifests\worker-2-interface-manifest.json" }
check "V17: Source-derived W1 exists" { Test-Path "$runDir\source-derived-interface-manifests\worker-1.json" }
check "V18: Source-derived W2 exists" { Test-Path "$runDir\source-derived-interface-manifests\worker-2.json" }
check "V19: Honesty W1 PASS" { $h=Get-Content "$runDir\reports\manifest-honesty-report-worker-1.json"|ConvertFrom-Json; $h.verdict -eq "PASS" }
check "V20: Honesty W2 PASS" { $h=Get-Content "$runDir\reports\manifest-honesty-report-worker-2.json"|ConvertFrom-Json; $h.verdict -eq "PASS" }
check "V21: Interface drift PASS" { $d=Get-Content "$runDir\reports\interface-drift-report.json"|ConvertFrom-Json; $d.verdict -eq "PASS" }
check "V22: Drift count=0" { $d=Get-Content "$runDir\reports\interface-drift-report.json"|ConvertFrom-Json; $d.driftCount -eq 0 }

# 23-26: Isolation + integration
check "V23: Workspace isolation PASS" { $i=Get-Content "$runDir\reports\isolation-report.json"|ConvertFrom-Json; $i.verdict -eq "PASS" }
check "V24: Parallel overlap PASS" { $p=Get-Content "$runDir\reports\parallel-overlap-report.json"|ConvertFrom-Json; $p.verdict -eq "PASS" -and $p.overlapExists -eq $true -and $p.overlapSeconds -gt 0 }
check "V25: Canonical contains W1 output" { Test-Path "$runDir\canonical-integrated\src\utils.ts" }
check "V26: Canonical contains W2 output" { Test-Path "$runDir\canonical-integrated\src\service.ts" }
check "V27: Integration gate PASS" { $g=Get-Content "$runDir\reports\integration-gate-report.json"|ConvertFrom-Json; $g.verdict -eq "PASS" }

# 28-35: validate-state
$vsOut = if (Test-Path "$runDir\reports\validate-state-report.json") { Get-Content "$runDir\reports\validate-state-report.json" | ConvertFrom-Json } else { $null }
check "V28: validate-state report exists" { $vsOut -ne $null }
check "V29: validate-state verdict=run_passed" { $vsOut -and $vsOut.verdict -eq "run_passed" }
check "V30: No no_token_store" { if ($vsOut -and $vsOut.errors) { ($vsOut.errors | Out-String) -notmatch "no_token_store" } else { $true } }
check "V31: No PROOF_VERIFICATION_FAILED" { if ($vsOut -and $vsOut.errors) { ($vsOut.errors | Out-String) -notmatch "PROOF_VERIFICATION_FAILED" } else { $true } }
check "V32: Hash chain valid" { $vsOut -and ($vsOut.passes -match "Hash chain valid") }
check "V33: CONTROL_PLANE not tampered" { if ($vsOut -and $vsOut.errors) { ($vsOut.errors | Out-String) -notmatch "CONTROL_PLANE_TAMPERED|EXTERNAL_TRUST_ROOT" } else { $true } }

# 36-39: Boundaries
check "V34: No U2-C negative runs" { -not (Test-Path "$H\runs\u2-b-factory-real-run-negative") }
check "V35: No final ZIP created" { -not (Test-Path "$H\outputs\phase6c-u2-b-final-audit-bundle.zip") }
check "V36: T0-R3 ZIP unchanged" { $t="$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"; if(Test-Path $t){(Get-FileHash $t -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"}else{$false} }
check "V37: U1 final ZIP unchanged" { $u="$H\outputs\phase6c-u1-final-audit-bundle.zip"; if(Test-Path $u){(Get-FileHash $u -Algorithm SHA256).Hash.ToLower() -eq "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"}else{$false} }

# 40-42: Report
$reportPath = "$H\outputs\PHASE_6C_U2_B_FACTORY_REAL_RUN_REPORT.md"
check "V38: Final report exists" { Test-Path $reportPath }
check "V39: Report states factory-generated real run" { if(Test-Path $reportPath){$r=Get-Content $reportPath -Raw;$r -match "factory-generated|Factory.*real"}else{$false} }
check "V40: Report does not claim mature factory" { if(Test-Path $reportPath){$r=Get-Content $reportPath -Raw;$r -notmatch "mature.*multi"}else{$true} }

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$exitCode = if ($E.Count -gt 0) { 1 } else { 0 }
@{ phase="Phase 6C-U2-B"; reportType="u2-b-verifier"; verdict=$verdict; timestamp=(Get-Date).ToString("o"); totalChecks=$total; passCount=$ok; failCount=$E.Count; passes=$P; errors=$E } | ConvertTo-Json -Depth 3
exit $exitCode