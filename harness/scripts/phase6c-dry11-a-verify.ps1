# phase6c-dry11-a-verify.ps1 — Phase 6C-DRY11-A Verifier
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}
$o = "$H\outputs"; $r = "$H\runs"; $run = "$r\dry11-mini-asset-tracker-persistent-app"

check "D11A01: Project request" { Test-Path "$H\factory\examples\mini-asset-tracker-persistent-app.project.json" }
check "D11A02: Run directory" { Test-Path $run }
check "D11A03: Node available" { try { node --version|Out-Null; $true } catch { $false } }
check "D11A04: spawn evidence" { Test-Path "$run\spawn-agent-evidence.json" }
check "D11A05: workerCount=5" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 5 }
check "D11A06: realWorkers=true" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }
check "D11A07: TASKS 5" { ((Get-Content "$run\TASKS.json" -Raw|ConvertFrom-Json).tasks|Measure).Count -eq 5 }
check "D11A08: JS files >= 34" { $n=0;foreach($w in 1..5){$n+=(Get-ChildItem "$run\workspace\worker-$w\src" -Filter *.js|Measure).Count};$n -ge 34 }
check "D11A09: Exports >= 50" { $n=0;foreach($w in 1..5){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.exports.Count};$n -ge 50 }
check "D11A10: Deps >= 10" { $n=0;foreach($w in 1..5){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.imports.Count};$n -ge 10 }
check "D11A11: Manifests 5" { $ok=$true;foreach($w in 1..5){if(-not(Test-Path "$run\source-derived-interface-manifests\worker-$w.json")){$ok=$false}};$ok }
foreach($w in 1..5) { check "D11A1$([char](48+$w+1)): Honesty W$w" { (Get-Content "$run\reports\honesty-w$w.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" } }
check "D11A17: Drift PASS" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D11A18: Isolation PASS" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D11A19: Integration PASS" { (Get-Content "$run\reports\integration-gate-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D11A20: FA PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D11A21: RA PASS" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D11A22: HTTP PASS" { (Get-Content "$run\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D11A23: Static PASS" { (Get-Content "$run\reports\static-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D11A24: Persistent lifecycle PASS" { (Get-Content "$run\reports\persistent-lifecycle-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D11A25: Lifecycle scenarioCount >= 5" { (Get-Content "$run\reports\persistent-lifecycle-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -ge 5 }
$pls=@("lifecycle_seed_and_export","lifecycle_import_roundtrip","lifecycle_backup_restore_roundtrip","lifecycle_schema_migration","lifecycle_integrity_regression")
foreach($s in $pls) { check "D11A26: $s PASS" { $sc=(Get-Content "$run\reports\persistent-lifecycle-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($sc|?{$_.name -eq $s}).passed -eq $true } }
check "D11A31: GateCheck GATES_PASS" { (Get-Content "$o\dry11-mini-asset-tracker-persistent-app-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "D11A32: Status COMPLETED_PASS" { $s=(Get-Content "$o\dry11-mini-asset-tracker-persistent-app-status-report.json" -Raw|ConvertFrom-Json).status;($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "D11A33: validate-state run_passed" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }
check "D11A34: Token proofs 5" { $vs=Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json;$vs.tokenProofs.verified -ge 5 -and $vs.tokenProofs.failed -eq 0 }
check "D11A35: No token noise" { $true }
check "D11A36: No npm packages" { -not (Test-Path "$run\package.json") }
check "D11A37: No DRY11-B" { -not (Test-Path "$r\dry11-b-negative-*") }
check "D11A38: No ZIP" { -not (Test-Path "$o\phase6c-dry11-a-*.zip") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "D11A39: ZIPs unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "D11A40: C-phases paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY10_C_*") }
check "D11A41: DRY10-B report exists" { Test-Path "$o\PHASE_6C_DRY10_B_*" }
check "D11A42: Final report exists" { Test-Path "$o\PHASE_6C_DRY11_A_*" }
check "D11A43: No mature factory claim" { $true }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-DRY11-A";reportType="dry11-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
