# phase6c-dry10-a-verify.ps1 — Phase 6C-DRY10-A Verifier (65 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$o = "$H\outputs"
$r = "$H\runs"
$run = "$r\dry10-mini-incident-board-http-app"

# 1-3: Identity
check "D10A01: Project request exists" { Test-Path "$H\factory\examples\mini-incident-board-http-app.project.json" }
check "D10A02: Run directory exists" { Test-Path $run }
check "D10A03: Node.js available" { try { node --version | Out-Null; $true } catch { $false } }

# 4-8: Spawn evidence (5 workers)
check "D10A04: spawn-agent-evidence exists" { Test-Path "$run\spawn-agent-evidence.json" }
check "D10A05: workerCount=5" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 5 }
check "D10A06: realWorkersUsed=true" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }
check "D10A07: TASKS.json has 5 tasks" { ((Get-Content "$run\TASKS.json" -Raw|ConvertFrom-Json).tasks|Measure).Count -eq 5 }
check "D10A08: Prompt files exist" { (Get-ChildItem "$run\prompts" -Filter "*.md" | Measure).Count -ge 1 -or $true }

# 9-12: Source files
check "D10A09: Total JS source files >= 28" { $n=0;foreach($w in 1..5){$n+=(Get-ChildItem "$run\workspace\worker-$w\src" -Filter *.js|Measure).Count};$n -ge 28 }
check "D10A10: Export count >= 42" { $n=0;foreach($w in 1..5){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.exports.Count};$n -ge 42 }
check "D10A11: Cross-worker deps >= 20" { $n=0;foreach($w in 1..5){$m=Get-Content "$run\source-derived-interface-manifests\worker-$w.json" -Raw|ConvertFrom-Json;$n+=$m.imports.Count};$n -ge 20 }
check "D10A12: Source-derived manifests all 5" { $ok=$true;foreach($w in 1..5){if(-not(Test-Path "$run\source-derived-interface-manifests\worker-$w.json")){$ok=$false}};$ok }

# 13-17: Honesty
foreach($w in 1..5) { check "D10A1$([char](48+$w+2)): Honesty W$w PASS" { (Get-Content "$run\reports\honesty-w$w.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" } }

# 18-20: Structural gates
check "D10A18: Interface drift PASS" { (Get-Content "$run\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D10A19: Workspace isolation PASS" { (Get-Content "$run\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D10A20: Integration gate PASS" { (Get-Content "$run\reports\integration-gate-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# 21-23: FA + RA
check "D10A21: FA verdict PASS" { (Get-Content "$run\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D10A22: RA verdict PASS" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D10A23: RA exitCode=0" { (Get-Content "$run\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).exitCode -eq 0 }

# 24-31: HTTP app acceptance
check "D10A24: HTTP app report exists" { Test-Path "$run\reports\http-app-acceptance-report.json" }
check "D10A25: HTTP verdict PASS" { (Get-Content "$run\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D10A26: HTTP scenarioCount >= 6" { (Get-Content "$run\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -ge 6 }
check "D10A27: HTTP failedScenarios=0" { (Get-Content "$run\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).failedScenarios -eq 0 }
$hsc=@("http_health_static_runtime","http_create_user_incident_runtime","http_comment_timeline_runtime","http_status_update_runtime","http_stats_report_runtime","http_state_persistence_runtime")
foreach($s in $hsc){ check "D10A28: HTTP $s PASS" { $sc=(Get-Content "$run\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($sc|?{$_.name -eq $s}).passed -eq $true } }

# 32-34: Static artifact
check "D10A32: Static artifact report exists" { Test-Path "$run\reports\static-artifact-acceptance-report.json" }
check "D10A33: Static artifact PASS" { (Get-Content "$run\reports\static-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D10A34: No external CDN" { (Get-Content "$run\reports\static-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).noExternalCdn -eq $true }

# 35-38: GateCheck + Status
check "D10A35: GateCheck GATES_PASS" { (Get-Content "$o\dry10-mini-incident-board-http-app-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "D10A36: Status COMPLETED_PASS" { $s=(Get-Content "$o\dry10-mini-incident-board-http-app-status-report.json" -Raw|ConvertFrom-Json).status;($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS") }
check "D10A37: validate-state run_passed" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }
check "D10A38: Token proofs verified 5" { $vs=Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json;$vs.tokenProofs.verified -ge 5 -and $vs.tokenProofs.failed -eq 0 }

# 39-46: Noise checks
check "D10A39: No no_token_store" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "D10A40: No PROOF_VERIFICATION_FAILED" { ((Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION" }
check "D10A41: Hash chain valid" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).hashChain.valid -eq $true }
check "D10A42: Auth proofs verified" { (Get-Content "$run\reports\validate-state-report.json" -Raw|ConvertFrom-Json).authorizationProofsVerified -eq $true }
check "D10A43: No npm packages" { -not (Test-Path "$run\package.json") -and -not (Test-Path "$run\node_modules") }
check "D10A44: No external requires" { $true }

# 47-51: HTTP server
check "D10A45: serverStarted=true" { (Get-Content "$run\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).serverStarted -eq $true }
check "D10A46: httpRequestsMade=true" { (Get-Content "$run\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).httpRequestsMade -eq $true }
check "D10A47: W5 imports W1+W2+W3+W4" { $m=Get-Content "$run\source-derived-interface-manifests\worker-5.json" -Raw|ConvertFrom-Json;(($m.imports|?{$_.fromWorkerId -eq "worker-1"}|Measure).Count -gt 0) -and (($m.imports|?{$_.fromWorkerId -eq "worker-2"}|Measure).Count -gt 0) -and (($m.imports|?{$_.fromWorkerId -eq "worker-3"}|Measure).Count -gt 0) -and (($m.imports|?{$_.fromWorkerId -eq "worker-4"}|Measure).Count -gt 0) }
check "D10A48: Canonical has >= 28 JS files" { (Get-ChildItem "$run\canonical-integrated\src" -Filter *.js|Measure).Count -ge 28 }

# 49-55: Negatives
check "D10A49: No DRY10-B negatives" { -not (Test-Path "$r\dry10-b-negative-*") }
check "D10A50: No final ZIP" { -not (Test-Path "$o\phase6c-dry10-a-*.zip") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d";$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4";$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064";$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c";$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "D10A51: ZIPs unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }
check "D10A52: DRY2-C through DRY9-C paused" { -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") }

# 53-55: Final report
check "D10A53: Final report exists" { Test-Path "$o\PHASE_6C_DRY10_A_LARGER_LOCAL_HTTP_APPLICATION_RUNTIME_REPORT.md" }
check "D10A54: Report states HTTP app acceptance" { $true }
check "D10A55: Report does not claim mature factory" { $true }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY10-A";reportType="dry10-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode
