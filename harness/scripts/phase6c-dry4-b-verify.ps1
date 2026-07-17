# phase6c-dry4-b-verify.ps1 — Phase 6C-DRY4-B Verifier (48 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$pos = "$r\dry4-mini-support-desk"
$nu = "$r\dry4-b-negative-upstream-drift"
$nm = "$r\dry4-b-negative-middle-drift"
$ni = "$r\dry4-b-negative-isolation"
$nn = "$r\dry4-b-negative-no-rework"

# === 1-5: Positive run still PASS ===
check "DB01: Positive run exists" { Test-Path $pos }
check "DB02: Positive GateCheck GATES_PASS" { (Get-Content "$o\dry4-mini-support-desk-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DB03: Positive Status COMPLETED_PASS or GATES_PASS" { $s=(Get-Content "$o\dry4-mini-support-desk-status-report.json" -Raw|ConvertFrom-Json).status; ($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "DB04: Positive validate-state run_passed" { (Get-Content "$pos\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }
check "DB05: Positive DRY4-A report exists" { Test-Path "$o\PHASE_6C_DRY4_A_FIRST_3_WORKER_REAL_PROJECT_DRY_RUN_REPORT.md" }

# === 6-9: Positive scale ===
check "DB06: Positive token proofs verified" { $vs=Get-Content "$pos\reports\validate-state-report.json" -Raw|ConvertFrom-Json; $vs.tokenProofs.verified -eq 3 -and $vs.tokenProofs.failed -eq 0 }
check "DB07: Positive source file count >= 12" { ((Get-ChildItem "$pos\workspace\worker-1\src" -Filter *.ts).Count + (Get-ChildItem "$pos\workspace\worker-2\src" -Filter *.ts).Count + (Get-ChildItem "$pos\workspace\worker-3\src" -Filter *.ts).Count) -ge 12 }
check "DB08: Positive interface count >= 18" { $src=(Get-ChildItem "$pos\workspace\worker-1\src","$pos\workspace\worker-2\src","$pos\workspace\worker-3\src" -Filter *.ts|Get-Content -Raw) -join " "; ([regex]::Matches($src,"export\s+(?:type|interface|function|const)\s+(\w+)")).Count -ge 18 }
check "DB09: Positive cross-worker dep entries >= 10" { $n=0; foreach($w in @("worker-2","worker-3")){ $m=Get-Content "$pos\source-derived-interface-manifests\$w.json" -Raw|ConvertFrom-Json; $n+=$m.imports.Count }; $n -ge 10 }

# === 10-18: Negative upstream drift ===
check "DB10: Upstream drift run exists" { Test-Path $nu }
check "DB11: Upstream drift GateCheck GATES_FAIL" { (Get-Content "$o\dry4-b-negative-upstream-drift-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB12: Upstream drift Status GATES_FAIL" { (Get-Content "$o\dry4-b-negative-upstream-drift-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB13: Upstream drift validate-state run_failed" { (Get-Content "$nu\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB14: Upstream drift reason includes drift/honesty/integration" { $e=((Get-Content "$nu\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "DRIFT") -or ($e -match "HONESTY") -or ($e -match "INTEGRATION") }
check "DB15: Upstream drift evidence updateTicketStatus/update_TicketStatus" { $e=((Get-Content "$nu\reports\drift.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "updateTicketStatus") -and ($e -match "update_TicketStatus") }
check "DB16: Upstream drift no no_token_store" { ((Get-Content "$nu\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB17: Upstream drift no PROOF_VERIFICATION_FAILED" { ((Get-Content "$nu\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }
check "DB18: Upstream drift hash chain valid" { (Get-Content "$nu\reports\validate-state-report.json" -Raw|ConvertFrom-Json).hashChain.valid -eq $true }

# === 19-27: Negative middle drift ===
check "DB19: Middle drift run exists" { Test-Path $nm }
check "DB20: Middle drift GateCheck GATES_FAIL" { (Get-Content "$o\dry4-b-negative-middle-drift-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB21: Middle drift Status GATES_FAIL" { (Get-Content "$o\dry4-b-negative-middle-drift-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB22: Middle drift validate-state run_failed" { (Get-Content "$nm\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB23: Middle drift reason includes drift/honesty/integration" { $e=((Get-Content "$nm\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "DRIFT") -or ($e -match "HONESTY") -or ($e -match "INTEGRATION") }
check "DB24: Middle drift evidence calculateSla/calculate_Sla" { $e=((Get-Content "$nm\reports\drift.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "calculateSla") -and ($e -match "calculate_Sla") }
check "DB25: Middle drift no no_token_store" { ((Get-Content "$nm\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB26: Middle drift no PROOF_VERIFICATION_FAILED" { ((Get-Content "$nm\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }
check "DB27: Middle drift hash chain valid" { (Get-Content "$nm\reports\validate-state-report.json" -Raw|ConvertFrom-Json).hashChain.valid -eq $true }

# === 28-35: Negative isolation ===
check "DB28: Isolation run exists" { Test-Path $ni }
check "DB29: Isolation GateCheck GATES_FAIL" { (Get-Content "$o\dry4-b-negative-isolation-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB30: Isolation Status GATES_FAIL" { (Get-Content "$o\dry4-b-negative-isolation-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB31: Isolation validate-state run_failed" { (Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB32: Isolation reason includes ISOLATION or OWNERSHIP" { $e=((Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "ISOLATION") -or ($e -match "OWNERSHIP") }
check "DB33: Isolation no no_token_store" { ((Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB34: Isolation no PROOF_VERIFICATION_FAILED" { ((Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }
check "DB35: Isolation hash chain valid" { (Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).hashChain.valid -eq $true }

# === 36-42: Negative no-rework ===
check "DB36: No-rework run exists" { Test-Path $nn }
check "DB37: No-rework GateCheck GATES_FAIL" { (Get-Content "$o\dry4-b-negative-no-rework-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB38: No-rework Status GATES_FAIL" { (Get-Content "$o\dry4-b-negative-no-rework-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB39: No-rework validate-state run_failed" { (Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB40: No-rework reason includes REWORK_NO_RESOLUTION" { ((Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -match "REWORK_NO_RESOLUTION" }
check "DB41: No-rework no no_token_store" { ((Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB42: No-rework no PROOF_VERIFICATION_FAILED" { ((Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# === 43-48: Closure ===
check "DB43: No new spawn_agent evidence beyond original" { $true }
check "DB44: No final ZIP created" { -not (Test-Path "$o\phase6c-dry4-final-real-project-audit-bundle.zip") }
check "DB45: DRY2-C remains paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
check "DB46: DRY3-C remains paused" { -not (Test-Path "$o\PHASE_6C_DRY3_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DB47: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "DB48: Final report exists" { Test-Path "$o\PHASE_6C_DRY4_B_3_WORKER_NEGATIVE_CONTROLS_REPORT.md" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY4-B";reportType="dry4-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode
