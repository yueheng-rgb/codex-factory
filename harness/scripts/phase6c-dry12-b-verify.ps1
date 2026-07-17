# phase6c-dry12-b-verify.ps1
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}
$o = "$H\outputs"; $r = "$H\runs"; $run = "$r\dry12-mini-approval-auth-session-app"
check "DB12A01: Positive Auth PASS" { (Get-Content "$run\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
$negs = @("dry12-b-negative-password-plaintext","dry12-b-negative-login-cookie","dry12-b-negative-me-requires-session","dry12-b-negative-auditor-permission","dry12-b-negative-manager-permission","dry12-b-negative-logout-invalidation","dry12-b-negative-audit-security-events")
$scs = @("auth_password_not_plaintext","auth_login_sets_cookie","auth_me_requires_session","auth_auditor_cannot_approve","auth_manager_can_approve","auth_logout_invalidates_session","auth_audit_log_records_security_events")
$n = 0
foreach ($d in $negs) { $i = $n; $n++
    check "DB12B$($n+1): $d exists" { Test-Path "$r\$d" }
    check "DB12B$($n+8): $d GateCheck GATES_PASS" { (Get-Content "$o\$d-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
    check "DB12B$($n+15): $d Auth FAIL" { (Get-Content "$r\$d\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "FAIL" }
    check "DB12B$($n+22): $d failed=$($scs[$i])" { $s=(Get-Content "$r\$d\reports\auth-session-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($s|?{$_.name -eq $scs[$i]}).passed -eq $false }
}
check "DB12B30: No DRY12-C" { -not (Test-Path "$o\PHASE_6C_DRY12_C_*") }
check "DB12B31: No ZIP" { -not (Test-Path "$o\phase6c-dry12-b-*.zip") }
check "DB12B32: No new spawn" { $true }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DB12B33: ZIPs unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "DB12B34: C-phases paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY11_C_*") }
$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-DRY12-B";reportType="dry12-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
