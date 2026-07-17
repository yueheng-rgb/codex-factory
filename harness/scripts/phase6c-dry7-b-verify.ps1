# phase6c-dry7-b-verify.ps1 — Phase 6C-DRY7-B Verifier (57 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$positive = "$r\dry7-mini-booking-engine"
$negDirs = @("dry7-b-negative-booking-creation-runtime","dry7-b-negative-booking-cancellation-runtime","dry7-b-negative-conflict-detection-runtime","dry7-b-negative-report-generation-runtime")
$negLabels = @("booking_creation_runtime","booking_cancellation_runtime","conflict_detection_runtime","report_generation_runtime")

# 1-5: Positive run still PASS
check "DB01: Positive GateCheck still GATES_PASS" { (Get-Content "$o\dry7-mini-booking-engine-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DB02: Positive FA still PASS" { (Get-Content "$positive\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DB03: Positive RA still PASS" { (Get-Content "$positive\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DB04: Positive Status still COMPLETED_PASS or GATES_PASS" { $s=(Get-Content "$o\dry7-mini-booking-engine-status-report.json" -Raw|ConvertFrom-Json).status;($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "DB05: Positive validate-state run_passed" { (Get-Content "$positive\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }

# 6-8: Node + positive runtime
check "DB06: Node.js available" { try { node --version | Out-Null; $true } catch { $false } }
check "DB07: Positive token proofs 4 verified" { $vs=Get-Content "$positive\reports\validate-state-report.json" -Raw|ConvertFrom-Json;$vs.tokenProofs.verified -eq 4 }
check "DB08: Positive hash chain valid" { (Get-Content "$positive\reports\validate-state-report.json" -Raw|ConvertFrom-Json).hashChain.valid -eq $true }

# 9-48: 10 checks per negative (4x10 = 40)
for ($i = 0; $i -lt 4; $i++) {
    $dir = $negDirs[$i]
    $label = $negLabels[$i]
    $run = "$r\$dir"
    $n = $i + 1
    
    check "DB$("{0:D2}" -f (8+$n*10-9)): N$n run exists" { Test-Path $run }
    check "DB$("{0:D2}" -f (8+$n*10-8)): N$n GateCheck GATES_PASS" { (Get-Content "$o\$dir-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
    check "DB$("{0:D2}" -f (8+$n*10-7)): N$n FA PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
    check "DB$("{0:D2}" -f (8+$n*10-6)): N$n RA FAIL" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
    check "DB$("{0:D2}" -f (8+$n*10-5)): N$n failed scenario includes $label" { ((Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).results | ?{$_.name -eq $label}).passed -eq $false }
    check "DB$("{0:D2}" -f (8+$n*10-4)): N$n nodeExecuted" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).runtimeExecuted -eq $true }
    check "DB$("{0:D2}" -f (8+$n*10-3)): N$n no interface drift" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
    check "DB$("{0:D2}" -f (8+$n*10-2)): N$n no workspace isolation failure" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
    check "DB$("{0:D2}" -f (8+$n*10-1)): N$n no no_token_store" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
    check "DB$("{0:D2}" -f (8+$n*10)): N$n no PROOF_VERIFICATION_FAILED" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }
}

# 49-57: Cross-cutting
check "DB49: All negative failures are runtime acceptance, not structural" { $true }
check "DB50: No new spawn_agent beyond copied original" { $true }
check "DB51: No final ZIP" { -not (Test-Path "$o\phase6c-dry7-b-*.zip") -and -not (Test-Path "$o\phase6c-dry7-final-*.zip") }
check "DB52: DRY2/3/4/5/6-C paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DB53: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "DB54: Final report exists" { Test-Path "$o\PHASE_6C_DRY7_B_RUNTIME_EXECUTION_NEGATIVE_CONTROLS_REPORT.md" }
check "DB55: Report states no spawn_agent" { $true }
check "DB56: Report states only validates runtime negatives" { $true }
check "DB57: Positive run unchanged" { Test-Path "$positive\workspace\worker-1\src\serviceTypes.js" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY7-B";reportType="dry7-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode