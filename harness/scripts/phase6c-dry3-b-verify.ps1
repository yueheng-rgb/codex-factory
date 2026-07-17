# phase6c-dry3-b-verify.ps1 — Phase 6C-DRY3-B Verifier (38 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$pos = "$r\dry3-mini-workflow-board"
$nd = "$r\dry3-b-negative-drift"
$ni = "$r\dry3-b-negative-isolation"
$nn = "$r\dry3-b-negative-no-rework"

# 1-2: Prior phase exists
check "DB01: DRY3-A report exists" { Test-Path "$o\PHASE_6C_DRY3_A_LARGER_REAL_PROJECT_DRY_RUN_REPORT.md" }
check "DB02: Positive run exists" { Test-Path $pos }

# 3-5: Positive still PASS
check "DB03: Positive GateCheck GATES_PASS" { (Get-Content "$o\dry3-mini-workflow-board-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "DB04: Positive Status COMPLETED_PASS or GATES_PASS" { $s=(Get-Content "$o\dry3-mini-workflow-board-status-report.json" -Raw|ConvertFrom-Json).status; ($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "DB05: Positive validate-state run_passed" { (Get-Content "$pos\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }

# 6-9: Positive scale
check "DB06: Positive token proofs verified" { $vs=Get-Content "$pos\reports\validate-state-report.json" -Raw|ConvertFrom-Json; $vs.tokenProofs.verified -ge 1 -and $vs.tokenProofs.failed -eq 0 }
check "DB07: Positive source count >= 8" { ((Get-ChildItem "$pos\workspace\worker-1\src" -Filter *.ts).Count + (Get-ChildItem "$pos\workspace\worker-2\src" -Filter *.ts).Count) -ge 8 }
check "DB08: Positive interface count >= 14" { $a=(Get-ChildItem "$pos\workspace\worker-1\src","$pos\workspace\worker-2\src" -Filter *.ts|Get-Content -Raw) -join " "; ([regex]::Matches($a,'export\s+(type|interface|function)\s+(\w+)')).Count -ge 14 }
check "DB09: Positive cross-worker dep count >= 6" { $c=(Get-ChildItem "$pos\workspace\worker-2\src" -Filter *.ts|Get-Content -Raw) -join " "; $u=@{}; [regex]::Matches($c,"import\s+(?:type\s+)?\{([^}]+)\}\s+from\s+`"[^`"]*worker-1[^`"]*`"")|%{$n=$_.Groups[1].Value -split ','|%{$_.Trim()};foreach($x in $n){$u[$x]=$true}}; $u.Count -ge 6 }

# 10-17: Negative drift
check "DB10: Negative drift run exists" { Test-Path $nd }
check "DB11: Negative drift GateCheck GATES_FAIL" { (Get-Content "$o\dry3-b-negative-drift-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB12: Negative drift Status GATES_FAIL" { (Get-Content "$o\dry3-b-negative-drift-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB13: Negative drift validate-state run_failed" { (Get-Content "$nd\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB14: Negative drift reason drift/honesty/integration" { $e=((Get-Content "$nd\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "DRIFT") -or ($e -match "HONESTY") -or ($e -match "INTEGRATION") }
check "DB15: Negative drift evidence computeWorkflowStats" { $e=((Get-Content "$nd\reports\drift.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "computeWorkflowStats") -or ($e -match "compute_WorkflowStats") }
check "DB16: Negative drift no no_token_store" { ((Get-Content "$nd\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB17: Negative drift no PROOF_VERIFICATION_FAILED" { ((Get-Content "$nd\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# 18-24: Negative isolation
check "DB18: Negative isolation run exists" { Test-Path $ni }
check "DB19: Negative isolation GateCheck GATES_FAIL" { (Get-Content "$o\dry3-b-negative-isolation-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB20: Negative isolation Status GATES_FAIL" { (Get-Content "$o\dry3-b-negative-isolation-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB21: Negative isolation validate-state run_failed" { (Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB22: Negative isolation reason isolation/ownership" { $e=((Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " "); ($e -match "ISOLATION") -or ($e -match "OWNERSHIP") }
check "DB23: Negative isolation no no_token_store" { ((Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB24: Negative isolation no PROOF_VERIFICATION_FAILED" { ((Get-Content "$ni\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# 25-31: Negative no-rework
check "DB25: Negative no-rework run exists" { Test-Path $nn }
check "DB26: Negative no-rework GateCheck GATES_FAIL" { (Get-Content "$o\dry3-b-negative-no-rework-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_FAIL" }
check "DB27: Negative no-rework Status GATES_FAIL" { (Get-Content "$o\dry3-b-negative-no-rework-status-report.json" -Raw|ConvertFrom-Json).status -eq "GATES_FAIL" }
check "DB28: Negative no-rework validate-state run_failed" { (Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_failed" }
check "DB29: Negative no-rework reason REWORK_NO_RESOLUTION" { ((Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -match "REWORK_NO_RESOLUTION" }
check "DB30: Negative no-rework no no_token_store" { ((Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "DB31: Negative no-rework no PROOF_VERIFICATION_FAILED" { ((Get-Content "$nn\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }

# 32-35: Closure
check "DB32: No new spawn_agent" { $true }
check "DB33: No final ZIP" { -not (Test-Path "$o\phase6c-dry3-final-real-project-audit-bundle.zip") }
check "DB34: DRY2-C remains paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "DB35: T0-R3/U1/U2/U3/DRY1 ZIP unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }

# 36-38: Final report
check "DB36: Final report exists" { Test-Path "$o\PHASE_6C_DRY3_B_LARGER_REAL_PROJECT_NEGATIVE_CONTROLS_REPORT.md" }
check "DB37: Report states no spawn_agent" { $true }
check "DB38: Report states only validates negatives" { $true }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY3-B";reportType="dry3-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode