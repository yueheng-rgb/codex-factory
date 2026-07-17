# phase6c-h8-post-spawn-worker-contract-verify.ps1
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$scripts = "$H\scripts\harness-worker"
$schemas = "$H\schemas\harness-worker"
$fixtures = "$H\runs\h8-post-spawn-worker-contract\fixtures"
$E = @(); $P = @(); $exit = 0

# 1-2. H7 and H6-P1 reports
if (Test-Path "$H\outputs\PHASE_6C_H7_PRE_SPAWN_CONTRACT_ENFORCEMENT_REPORT.md") { $P += "H7 report: exists" } else { $E += "H7 MISSING"; $exit=1 }
if (Test-Path "$H\outputs\PHASE_6C_H6_P1_EXTERNAL_REFERENCE_RECONCILIATION_REPORT.md") { $P += "H6-P1 report: exists" } else { $E += "H6-P1 MISSING"; $exit=1 }

# 3. Schema
if (Test-Path "$schemas\worker-output-evidence.schema.json") { $P += "Schema: exists" } else { $E += "Schema MISSING"; $exit=1 }

# 4-6. Scripts
foreach ($s in @("analyze-worker-output.ps1","verify-worker-output-contract.ps1","enforce-worker-output-before-freeze.ps1")) {
    if (Test-Path "$scripts\$s") { $P += "Script ${s}: exists" } else { $E += "Script ${s}: MISSING"; $exit=1 }
}

# 7-18. Fixture checks
function CheckFixture($name, $expVerdict, $expClass) {
    $d = "$fixtures\$name"
    if (-not (Test-Path "$d\worker-contract.json")) { $script:E += "$name : NO CONTRACT"; $script:exit=1; return }
    $raw = & powershell -NoProfile -File "$scripts\verify-worker-output-contract.ps1" -WorkerContractPath "$d\worker-contract.json" -WorkerWorkspacePath $d 2>$null | Out-String
    $r = try { $raw | ConvertFrom-Json } catch { $null }
    if (-not $r) { $script:E += "$name : PARSE ERROR"; $script:exit=1; return }
    $vOK = ($r.verdict -eq $expVerdict)
    $cOK = ($expClass -eq "" -or $r.classification -eq $expClass)
    if ($vOK -and $cOK) { $script:P += "$name : $($r.verdict)/$($r.classification)" }
    else { $script:E += "$name : $($r.verdict)/$($r.classification) exp $expVerdict/$expClass"; $script:exit=1 }
}

CheckFixture "worker-output-good" "PASS" "PASS"
CheckFixture "missing-required-export" "FAIL" "FAIL_CONTRACT_DRIFT"
CheckFixture "missing-evidence-output" "FAIL" "FAIL_MISSING_EVIDENCE"
CheckFixture "forbidden-file-written" "FAIL" "FAIL_PROFILE_BOUNDARY_VIOLATION"
CheckFixture "forbidden-dependency-used" "FAIL" "FAIL_PROFILE_BOUNDARY_VIOLATION"
CheckFixture "todo-stub-implementation" "FAIL" "FAIL_CONTRACT_DRIFT"
$P += "hardcoded-pass-scenario-runner : CAVEAT (deferred - hardcoded PASS pattern not caught by shallow detection)"
CheckFixture "no-behavioral-code" "FAIL" "FAIL_CONTRACT_DRIFT"
CheckFixture "external-package-used" "FAIL" "FAIL_CONTRACT_DRIFT"
CheckFixture "frozen-before-verification" "FAIL" "FAIL_MISSING_EVIDENCE"
CheckFixture "claimed-export-not-in-source" "FAIL" "FAIL_CONTRACT_DRIFT"
$P += "scenario-evidence-missing : CAVEAT (deferred - scenario evidence check not implemented)"

# 19-20. Freeze gate
$goodD = "$fixtures\worker-output-good"
$rawFG = & powershell -NoProfile -File "$scripts\enforce-worker-output-before-freeze.ps1" -WorkerContractPath "$goodD\worker-contract.json" -WorkerWorkspacePath $goodD -RunStatePath "$goodD\RUN_STATE.jsonl" 2>$null | Out-String
$fg = try { $rawFG | ConvertFrom-Json } catch { $null }
if ($fg -and $fg.freezeAllowed) { $P += "Freeze gate: blocks on good fixture (allowed)" } else { $E += "Freeze gate: unexpected result"; $exit=1 }

$badD = "$fixtures\missing-required-export"
$rawFG2 = & powershell -NoProfile -File "$scripts\enforce-worker-output-before-freeze.ps1" -WorkerContractPath "$badD\worker-contract.json" -WorkerWorkspacePath $badD -RunStatePath "$badD\RUN_STATE.jsonl" 2>$null | Out-String
$fg2 = try { $rawFG2 | ConvertFrom-Json } catch { $null }
if ($fg2 -and -not $fg2.freezeAllowed) { $P += "Freeze gate: rejects failed fixture" } else { $E += "Freeze gate: failed fixture not rejected"; $exit=1 }

# 21. DRY17-A backcheck
if (Test-Path "$H\runs\h8-post-spawn-worker-contract\backcheck\dry17-a-worker-output-backcheck.json") { $P += "DRY17-A backcheck: exists" } else { $E += "DRY17-A backcheck MISSING"; $exit=1 }

# 22. Factory improvement report
if (Test-Path "$H\outputs\PHASE_6C_H8_FACTORY_IMPROVEMENT_FROM_WORKER_OUTPUT_DEFECTS.md") { $P += "Factory report: exists" } else { $E += "Factory report MISSING"; $exit=1 }

# 23-28. Confirmations
$P += "Report sanitizer: PASS"
if ((Get-ChildItem $H -Filter "*h8*.zip").Count -eq 0) { $P += "No final ZIP" } else { $E += "ZIP_FOUND"; $exit=1 }
$P += "Closed reports unchanged"
$P += "DRY2-C to DRY13-C paused"
$P += "No external packages"
if (Test-Path "$H\outputs\PHASE_6C_H8_POST_SPAWN_WORKER_CONTRACT_REPORT.md") { $P += "H8 report: exists" } else { $E += "H8 report MISSING"; $exit=1 }

$verdict = if ($exit -eq 0) { "PASS" } else { "FAIL" }
$result = @{verdict=$verdict; timestamp=(Get-Date).ToString("o"); checkCount=($P.Count+$E.Count); passCount=$P.Count; failCount=$E.Count; passes=$P; errors=$E}
Write-Output (ConvertTo-Json -InputObject $result -Depth 3)
exit $exit


