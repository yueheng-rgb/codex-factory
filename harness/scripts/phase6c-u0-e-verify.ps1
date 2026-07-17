# phase6c-u0-e-verify.ps1 -- Phase 6C-U0-E Umbrella Verifier
param([switch]$JsonOnly)
$ErrorActionPreference="Continue"
$H=(Resolve-Path (Join-Path $PSScriptRoot ".."))
$E=[System.Collections.ArrayList]::new(); $P=[System.Collections.ArrayList]::new(); $X=0
Write-Output "=== Phase 6C-U0-E Umbrella Verifier ==="

$pos="$H\runs\phase6c-u0-e-real-parallel"; $neg="$H\runs\phase6c-u0-e-negative-isolation"

# 1
if(Test-Path "$H\outputs\PHASE_6C_U0_D_FINAL_REPORT.md"){[void]$P.Add("U0-D report exists")}else{[void]$E.Add("NO_U0D_REPORT");$X=1}
# 2-4
if(Test-Path $pos){[void]$P.Add("Positive run exists")}else{[void]$E.Add("NO_POS");$X=1}
$sev=Get-Content "$pos\spawn-agent-evidence.json" -Raw|ConvertFrom-Json
if($sev.realWorkersUsed){[void]$P.Add("realWorkersUsed=true")}else{[void]$E.Add("NOT_REAL");$X=1}
if($sev.workerCount -eq 2){[void]$P.Add("workerCount=2")}else{[void]$E.Add("BAD_COUNT");$X=1}
# 5-7
$ovr="$pos\reports\parallel-overlap-report.json"
if(Test-Path $ovr){$o=Get-Content $ovr -Raw|ConvertFrom-Json;if($o.verdict -eq "PASS"){[void]$P.Add("Overlap PASS")}else{[void]$E.Add("OVR_FAIL");$X=1};if($o.overlap.exists){[void]$P.Add("overlap=true")}else{[void]$E.Add("NO_OVL");$X=1};if($o.overlap.overlapSeconds -gt 0){[void]$P.Add("overlapSecs=$($o.overlap.overlapSeconds)")}else{[void]$E.Add("OVL_ZERO");$X=1}}
else{[void]$E.Add("NO_OVR");$X=1}
# 8-13
$isr="$pos\reports/workspace-isolation-report.json"
if(Test-Path $isr){$is=Get-Content $isr -Raw|ConvertFrom-Json;if($is.verdict -eq "PASS"){[void]$P.Add("Isolation PASS")}else{[void]$E.Add("ISO_FAIL");$X=1};if(-not $is.ownershipViolation){[void]$P.Add("No ownership violation")}else{[void]$E.Add("OWN_VIOL");$X=1}}
else{[void]$E.Add("NO_ISO");$X=1}
$own=Get-Content "$pos\OWNERSHIP.json" -Raw|ConvertFrom-Json
if($own.entries.Count -gt 0){[void]$P.Add("OWNERSHIP non-empty")}else{[void]$E.Add("OWN_EMPTY");$X=1}
# 14-17
if((Test-Path "$pos\source-derived-interface-manifests\worker-1.json") -and (Test-Path "$pos\source-derived-interface-manifests\worker-2.json")){[void]$P.Add("SD manifests exist")}
$h1=Get-Content "$pos\reports\manifest-honesty-report-worker-1.json" -Raw|ConvertFrom-Json
$h2=Get-Content "$pos\reports\manifest-honesty-report-worker-2.json" -Raw|ConvertFrom-Json
if($h1.verdict -eq "PASS" -and $h2.verdict -eq "PASS"){[void]$P.Add("Honesty PASS")}else{[void]$E.Add("HON_FAIL");$X=1}
$dr=Get-Content "$pos\reports\interface-drift-report.json" -Raw|ConvertFrom-Json
if($dr.verdict -eq "PASS" -and $dr.driftCount -eq 0){[void]$P.Add("Drift PASS")}else{[void]$E.Add("DR_FAIL");$X=1}
$ig=Get-Content "$pos\reports\integration-gate-report.json" -Raw|ConvertFrom-Json
if($ig.verdict -eq "PASS"){[void]$P.Add("Integration PASS")}else{[void]$E.Add("IG_FAIL");$X=1}
# 18-20
$pvs=&(Join-Path $H "scripts\validate-state.ps1") -RunDir $pos 2>&1|Out-String
if($pvs -match '"verdict":\s*"run_passed"'){[void]$P.Add("VS pos: run_passed")}else{[void]$E.Add("VS_POS_FAIL");$X=1}
if($pvs -notmatch "no_token_store"){[void]$P.Add("Pos: no no_token_store")}else{[void]$E.Add("POS_TS");$X=1}
if($pvs -notmatch "PROOF_VERIFICATION_FAILED"){[void]$P.Add("Pos: no proof fail")}else{[void]$E.Add("POS_PF");$X=1}
# 21-26
if(Test-Path $neg){[void]$P.Add("Neg exists")}else{[void]$E.Add("NO_NEG");$X=1}
$nis=Get-Content "$neg\reports/workspace-isolation-report.json" -Raw|ConvertFrom-Json
if($nis.verdict -eq "FAIL"){[void]$P.Add("Neg iso FAIL")}else{[void]$E.Add("NEG_ISO_NOT_FAIL");$X=1}
$nvs=&(Join-Path $H "scripts\validate-state.ps1") -RunDir $neg 2>&1|Out-String
if($nvs -match '"verdict":\s*"run_failed"'){[void]$P.Add("Neg VS: run_failed")}else{[void]$E.Add("NEG_VS_NOT_FAIL");$X=1}
if($nvs -match "OWNERSHIP_VIOLATION" -or $nvs -match "WORKSPACE_ISOLATION_FAIL"){[void]$P.Add("Neg: isolation violation")}else{[void]$E.Add("NEG_NO_ISO_REASON");$X=1}
if($nvs -notmatch "no_token_store"){[void]$P.Add("Neg: no no_token_store")}else{[void]$E.Add("NEG_TS");$X=1}
if($nvs -notmatch "PROOF_VERIFICATION_FAILED"){[void]$P.Add("Neg: no proof fail")}else{[void]$E.Add("NEG_PF");$X=1}
# 27-32
$t0="$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"
if(Test-Path $t0){if((Get-FileHash $t0 -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"){[void]$P.Add("T0-R3 unchanged")}else{[void]$E.Add("T0_MOD");$X=1}}
if(Test-Path "$H\runs\phase6c-u0-d-real"){[void]$P.Add("U0-D run present")}else{[void]$E.Add("NO_U0D_RUN");$X=1}
$fr="$H\outputs\PHASE_6C_U0_E_FINAL_REPORT.md"
if(Test-Path $fr){[void]$P.Add("Final report exists")}else{[void]$E.Add("NO_FR");$X=1}

$V=if($X -eq 0){"PASS"}else{"FAIL"}
$R=@{phase="Phase 6C-U0-E";tool="phase6c-u0-e-verify";verdict=$V;errorCount=$E.Count;passCount=$P.Count;errors=$E;passes=$P;timestamp=(Get-Date).ToString("o")}
if($JsonOnly){Write-Output ($R|ConvertTo-Json -Depth 4)}
else{Write-Output "`n=== U0-E VERDICT: $V ===";Write-Output "Errors: $($E.Count) | Passes: $($P.Count)";foreach($p in $P){Write-Output "  [PASS] $p"};foreach($e in $E){Write-Output "  [FAIL] $e"}}
exit $X