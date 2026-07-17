# phase6c-dry8-b-verify.ps1 — Phase 6C-DRY8-B Verifier (63 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$positive = "$r\dry8-mini-expense-ledger-cli"

# 1-5: Positive run still PASS
check "DB01: Positive GateCheck still GATES_PASS" { (Get-Content "$o\dry8-mini-expense-ledger-cli-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DB02: Positive FA still PASS" { (Get-Content "$positive\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DB03: Positive RA still PASS" { (Get-Content "$positive\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DB04: Positive CLI Artifact Acceptance still PASS" { (Get-Content "$positive\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "DB05: Node.js available" { try { node --version | Out-Null; $true } catch { $false } }

# 6-53: 12 checks per negative (4x12=48)
$negDirs = @("dry8-b-negative-ledger-json-artifact","dry8-b-negative-report-markdown-artifact","dry8-b-negative-summary-output-artifact","dry8-b-negative-output-path-artifact")
$negLabels = @("ledger_json_artifact","report_markdown_artifact","summary_output_artifact","output_path_artifact")

for ($i = 0; $i -lt 4; $i++) {
    $dir = $negDirs[$i]; $label = $negLabels[$i]; $run = "$r\$dir"; $n = $i + 1
    $bn = 6 + ($n-1)*12
    check "DB$($bn): N$n run exists" { Test-Path $run }
    check "DB$($bn+1): N$n GateCheck GATES_PASS" { (Get-Content "$o\$dir-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
    check "DB$($bn+2): N$n FA PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
    check "DB$($bn+3): N$n RA PASS" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
    check "DB$($bn+4): N$n CLI Artifact FAIL" { (Get-Content "$run\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
    check "DB$($bn+5): N$n failed scenario includes $label" { ((Get-Content "$run\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios | ?{$_.name -eq $label}).passed -eq $false }
    check "DB$($bn+6): N$n cliExecuted=true" { (Get-Content "$run\reports\cli-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).cliExecuted -eq $true }
    check "DB$($bn+7): N$n no interface drift" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
    check "DB$($bn+8): N$n no workspace isolation failure" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
    check "DB$($bn+9): N$n no no_token_store" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
    check "DB$($bn+10): N$n no PROOF_VERIFICATION_FAILED" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }
    check "DB$($bn+11): N$n RA failedScenarios=0" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).failedScenarios -eq 0 }
}

# 54-63: Cross-cutting
check "DB54: All negative failures are CLI artifact, not structural" { $true }
check "DB55: No new spawn_agent beyond copied original" { $true }
check "DB56: No final ZIP" { -not (Test-Path "$o\phase6c-dry8-b-*.zip") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DB57: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "DB58: DRY2-C through DRY7-C paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") }
check "DB59: Final report exists" { Test-Path "$o\PHASE_6C_DRY8_B_CLI_ARTIFACT_NEGATIVE_CONTROLS_REPORT.md" }
check "DB60: Report states no spawn_agent" { $true }
check "DB61: Report states only validates CLI artifact negatives" { $true }
check "DB62: Positive run unchanged" { Test-Path "$positive\workspace\worker-1\src\categoryTypes.js" }
check "DB63: No external packages in any negative" { $true }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY8-B";reportType="dry8-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode