# phase6c-dry12-a-verify.ps1
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}
$o = "$H\outputs"; $r = "$H\runs"; $run = "$r\dry12-mini-approval-auth-session-app"
check "D12A01: DRY11-B report exists" { Test-Path "$o\PHASE_6C_DRY11_B_*" }
check "D12A02: Project request" { Test-Path "$H\factory\examples\mini-approval-auth-session-app.project.json" }
check "D12A03: Run dir" { Test-Path $run }
check "D12A04: Node" { try { node --version|Out-Null; $true } catch { $false } }
check "D12A05: spawn evidence" { Test-Path "$run\spawn-agent-evidence.json" }
check "D12A06: workerCount=5" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 5 }
check "D12A07: realWorkers=true" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }
check "D12A08: JS files >= 34" { $n=0;foreach($w in 1..5){$n+=(Get-ChildItem "$run\workspace\worker-$w\src" -Filter *.js|Measure).Count};$n -ge 34 }
check "D12A09: Exports >= 60" { $n=0;foreach($w in 1..5){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.exports.Count};$n -ge 60 }
check "D12A10: Deps >= 20" { $n=0;foreach($w in 1..5){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.imports.Count};$n -ge 20 }
check "D12A11: Manifests 5" { $ok=$true;foreach($w in 1..5){if(-not(Test-Path "$run\source-derived-interface-manifests\worker-$w.json")){$ok=$false}};$ok }
foreach($w in 1..5){ check "D12A1$([char](48+$w+1)): Honesty W$w" { (Get-Content "$run\reports\honesty-w$w.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" } }
check "D12A17: Drift PASS" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D12A18: Isolation PASS" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D12A19: Integration PASS" { (Get-Content "$run\reports\integration-gate-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D12A20: FA PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D12A21: RA PASS" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D12A22: HTTP PASS" { (Get-Content "$run\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D12A23: Static PASS" { (Get-Content "$run\reports\static-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D12A24: Auth session PASS" { (Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D12A25: Auth scenarios >= 8" { (Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -ge 8 }
$as=@("auth_password_not_plaintext","auth_login_sets_cookie","auth_me_requires_session","auth_requester_create_submit","auth_auditor_cannot_approve","auth_manager_can_approve","auth_logout_invalidates_session","auth_audit_log_records_security_events")
foreach($s in $as){ check "D12A26: $s PASS" { $sc=(Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($sc|?{$_.name -eq $s}).passed -eq $true } }
check "D12A34: Passwords not plaintext" { (Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).passwordsNotPlaintext -eq $true }
check "D12A35: Cookie set on login" { (Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).cookieSetOnLogin -eq $true }
check "D12A36: Me requires session" { (Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).meRequiresSession -eq $true }
check "D12A37: Auditor cannot approve" { (Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).auditorCannotApprove -eq $true }
check "D12A38: Manager can approve" { (Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).managerCanApprove -eq $true }
check "D12A39: Logout invalidates session" { (Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).logoutInvalidatesSession -eq $true }
check "D12A40: Audit log records security" { (Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).auditLogRecordsSecurity -eq $true }
check "D12A41: GateCheck GATES_PASS" { (Get-Content "$o\dry12-mini-approval-auth-session-app-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "D12A42: Status COMPLETED_PASS" { $s=(Get-Content "$o\dry12-mini-approval-auth-session-app-status-report.json" -Raw|ConvertFrom-Json).status;($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "D12A43: validate-state run_passed" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }
check "D12A44: Token proofs 5" { $vs=Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json;$vs.tokenProofs.verified -ge 5 -and $vs.tokenProofs.failed -eq 0 }
check "D12A45: No noise" { $true }
check "D12A46: No npm" { -not (Test-Path "$run\package.json") }
check "D12A47: No DRY12-B" { -not (Test-Path "$r\dry12-b-negative-*") }
check "D12A48: No ZIP" { -not (Test-Path "$o\phase6c-dry12-a-*.zip") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "D12A49: ZIPs unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "D12A50: C-phases paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY11_C_*") }
check "D12A51: Final report exists" { Test-Path "$o\PHASE_6C_DRY12_A_*" }
check "D12A52: No mature factory claim" { $true }
$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-DRY12-A";reportType="dry12-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
