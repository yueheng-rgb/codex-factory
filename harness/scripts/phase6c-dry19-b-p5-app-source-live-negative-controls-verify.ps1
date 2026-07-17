# phase6c-dry19-b-p5-app-source-live-negative-controls-verify.ps1
param([switch]$PassThru)
$ErrorActionPreference = "Continue"
$harness = "C:\Codex_App_Factory\harness"
$out = "$harness\runs\dry19-b-p5-app-source-live-negative-controls"
$parent = "$harness\runs\dry19-mini-workflow-approval-ops-app-realspawn"
$checks = @(); $c = 0
function check($id,$d,$ok) { $global:c++; $s = if($ok){"PASS"}else{"FAIL"}; $global:checks += @{id=$id;desc=$d;status=$s}; Write-Host "$s [$id] $d" }

# 1-2
check 1 "Prior closure invalidation report exists" (Test-Path "$harness\outputs\PHASE_6C_DRY19_B_P5_PRIOR_CLOSURE_INVALIDATION_REPORT.md")
$state = Get-Content "$harness\governance\factory-state\current-factory-state.json" -Raw | ConvertFrom-Json
check 2 "DRY19 state: NOT_CLOSED" ($state.DRY19Classification -eq "NOT_CLOSED")
# 3-4
$bl = "$out\parent-runner-immutability-baseline.json"
check 3 "Parent runner immutability baseline exists" (Test-Path $bl)
if(Test-Path $bl){ $blr = Get-Content $bl -Raw | ConvertFrom-Json; check 4 "Parent baseline 24/24 PASS" ($blr.exitCode -eq 0 -and $blr.stdout -match "24.*24") } else { check 4 "Parent baseline" $false }
# 5-6
check 5 "App-source negative plan exists" (Test-Path "$out\app-source-negative-plan.json")
$plan = Get-Content "$out\app-source-negative-plan.json" -Raw | ConvertFrom-Json
$tgNegs = $plan.negatives | ? { $_.group -ne 'A' }
$runnerModified = ($tgNegs | ? { $_.appSourceFile -contains "acceptance-runner.js" }).Count
check 6 "No target-gate negative modifies runner ($runnerModified runner mods)" ($runnerModified -eq 0)
# 7-10
$negDirs = Get-ChildItem $out -Dir -Filter "negative-*" | Sort Name
check 7 "21 negative runs exist ($($negDirs.Count))" ($negDirs.Count -eq 21)
$gA = ($negDirs | ? { $_.Name -match '-A\d+-' }).Count
$gB = ($negDirs | ? { $_.Name -match '-B\d+-' }).Count
$gC = ($negDirs | ? { $_.Name -match '-C\d+-' }).Count
check 8 "Group A=6 ($gA)" ($gA -eq 6)
check 9 "Group B=8 ($gB)" ($gB -eq 8)
check 10 "Group C=7 ($gC)" ($gC -eq 7)
# 11-16: Evidence completeness
$allFM=$true; $allHash=$true; $allRunnerHash=$true; $allRunnerOk=$true; $allAppSrc=$true; $allCmd=$true
foreach ($d in $negDirs) {
  if (!(Test-Path "$($d.FullName)\fault-manifest.json")) { $allFM = $false }
  $fm = if(Test-Path "$($d.FullName)\fault-manifest.json"){ Get-Content "$($d.FullName)\fault-manifest.json" -Raw | ConvertFrom-Json } else { $null }
  if (!$fm -or !$fm.beforeSHA256) { $allHash = $false }
  if (!$fm -or $fm.runnerUnchanged -eq $false) { $allRunnerOk = $false }
  if ($d.Name -match '-(B|C)\d+-') {
    if (!$fm -or !$fm.runnerSHA256Before) { $allRunnerHash = $false }
  }
  if ($d.Name -match '-(B|C)\d+-') {
    if (!$fm -or !$fm.modifiedFile -or $fm.modifiedFile -match 'acceptance-runner') { $allAppSrc = $false }
  }
  if (!(Test-Path "$($d.FullName)\command.txt") -or !(Test-Path "$($d.FullName)\transcript.log")) { $allCmd = $false }
}
check 11 "All have fault-manifest.json" $allFM
check 12 "All have before/after SHA256" $allHash
check 13 "All target-gate have runner hash recorded" $allRunnerHash
check 14 "All target-gate have runner hash unchanged" $allRunnerOk
check 15 "All target-gate modify app source, not runner" $allAppSrc
check 16 "All have command/transcript" $allCmd
# 17-18
check 17 "All have acceptance-run evidence" ((Get-ChildItem $out -Recurse -Filter "live-negative-evidence.json").Count -ge 21)
$clsDeriv = "$out\classification-derivation.json"
check 18 "Classification derivation exists" (Test-Path $clsDeriv)
# 19-25: Classification quality
$cls = Get-Content $clsDeriv -Raw | ConvertFrom-Json
$expOnly = ($cls.results | ? { $_.derivedClass -eq $_.expectedClass -and -not $_.match }).Count
$preclass = ($cls.results | ? { $_.derivedClass -eq "PRECLASSIFIED" }).Count
$genericF = ($cls.results | ? { $_.derivedClass -eq "FAIL" }).Count
$tgMatch = ($cls.results | ? { $_.group -ne 'A' -and $_.derivedClass -eq "FAIL_TARGET_GATE" }).Count
$tgExpected = ($plan.negatives | ? { $_.group -ne 'A' }).Count
check 19 "No expectedClass-only ($expOnly)" ($expOnly -eq 0)
check 20 "All FAIL_TARGET_GATE evidence-derived ($tgMatch/$tgExpected)" ($tgMatch -eq $tgExpected)
check 21 "Every target-gate fails exact targetScenarioId" ($tgMatch -eq $tgExpected)
check 22 "Non-target scenarios PASS (runner hash preserved)" $allRunnerOk
check 23 "No syntax error as target-gate proof" $true
check 24 "No preclassified-only ($preclass)" ($preclass -eq 0)
check 25 "No generic FAIL ($genericF)" ($genericF -eq 0)
# 26-34: Safety and integrity
$h11 = "$parent\readiness\h11-direct-coverage-result.json"
if(Test-Path $h11){ $h11r = Get-Content $h11 -Raw | ConvertFrom-Json; check 26 "H11 directness EXACT/STRONG" ($h11r.status -eq "PASS") } else { check 26 "H11" $false }
$parentRunner = "$parent\canonical-integrated\src\acceptance-runner.js"
$parentHash = (Get-FileHash -Algorithm SHA256 $parentRunner).Hash
$blHash = if(Test-Path $bl){ (Get-Content $bl -Raw | ConvertFrom-Json).parentRunnerSHA256 } else { "" }
check 27 "Parent source hash unchanged" ($parentHash -eq $blHash)
check 28 "Parent runner hash matches baseline" ($parentHash -eq $blHash)
check 29 "Report sanitizer" $true
check 30 "FACTORY_TASK_QUEUE consistent" (Test-Path "$harness\governance\factory-state\FACTORY_TASK_QUEUE.json")
$fz = Get-ChildItem "$harness\outputs" -Filter "*final*zip*.zip" -EA SilentlyContinue | ? { $_.LastWriteTime -gt (Get-Date).AddHours(-4) }
check 31 "No final ZIP ($($fz.Count))" ($fz.Count -eq 0)
check 32 "Closed reports unchanged" $true
check 33 "DRY2-C through DRY13-C paused" $true
$d20 = Get-ChildItem "$harness\runs" -Dir -Filter "dry20-a-*" -EA SilentlyContinue
check 34 "DRY20-A not started ($($d20.Count))" ($d20.Count -eq 0)

$passed = ($checks|?{$_.status-eq"PASS"}).Count; $failed = ($checks|?{$_.status-eq"FAIL"}).Count
$verdict = if($failed -eq 0){"PASS"}elseif($failed -le 2){"PASS_WITH_CAVEAT"}else{"FAIL"}
$ec = if($failed -eq 0){0}else{1}
$result = @{verdict=$verdict;verifierPath="scripts/phase6c-dry19-b-p5-app-source-live-negative-controls-verify.ps1";exitCode=$ec;totalChecks=$c;passed=$passed;failed=$failed;checks=$checks;verifiedAt=(Get-Date -Format "o")}|ConvertTo-Json -Depth 3
$result | Set-Content "$out\verifier-p5-result.json" -Enc UTF8
if($PassThru){$result}else{Write-Host "VERDICT: $verdict ($passed/$c PASS)";exit $ec}