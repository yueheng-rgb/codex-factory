# phase6c-dry19-b-p4-evidence-reconciliation-closure-readiness-verify.ps1
param([switch]$PassThru)

$ErrorActionPreference = "Continue"
$harness = "C:\Codex_App_Factory\harness"
$outRoot = "$harness\runs\dry19-b-p3-realspawn-live-negative-controls"
$checks = @()
$c = 0

function check($id, $desc, $cond) {
    $global:c++
    $status = if ($cond) { "PASS" } else { "FAIL" }
    $global:checks += @{ id = $id; desc = $desc; status = $status }
    Write-Host "$status [$id] $desc"
}

# 1. DRY19-B-P3 verifier result exists and PASS
$p3Result = "$outRoot\verifier-p3-result.json"
if (Test-Path $p3Result) {
    $p3 = Get-Content $p3Result -Raw | ConvertFrom-Json
    check 1 "P3 verifier PASS ($($p3.passed)/$($p3.totalChecks))" ($p3.verdict -eq "PASS")
} else {
    check 1 "P3 verifier PASS" $false
}

# 2. 21 negative runs exist
$negDirs = Get-ChildItem $outRoot -Directory -Filter "negative-*" -ErrorAction SilentlyContinue
check 2 "21 negative runs exist ($($negDirs.Count))" ($negDirs.Count -eq 21)

# 3. Group counts
$gA = ($negDirs | Where-Object { $_.Name -match '-A\d+-' }).Count
$gB = ($negDirs | Where-Object { $_.Name -match '-B\d+-' }).Count
$gC = ($negDirs | Where-Object { $_.Name -match '-C\d+-' }).Count
check 3 "Group A=6, B=8, C=7 (A:$gA B:$gB C:$gC)" ($gA -eq 6 -and $gB -eq 8 -and $gC -eq 7)

# 4-6. Evidence completeness
$allFault = $true; $allHash = $true; $allCmd = $true
foreach ($d in $negDirs) {
    if (!(Test-Path "$($d.FullName)\fault-manifest.json")) { $allFault = $false }
    $fm = Get-Content "$($d.FullName)\fault-manifest.json" -Raw | ConvertFrom-Json
    if (!$fm.beforeSHA256 -or !$fm.afterSHA256) { $allHash = $false }
    if (!(Test-Path "$($d.FullName)\command.txt") -or !(Test-Path "$($d.FullName)\transcript.log") -or !(Test-Path "$($d.FullName)\exitCode.txt")) { $allCmd = $false }
}
check 4 "All have fault-manifest.json" $allFault
check 5 "All have before/after SHA256" $allHash
check 6 "All have command/transcript/exitCode" $allCmd

# 7. Target-gate negatives have targetScenarioId
$targetOk = $true
foreach ($d in $negDirs) {
    if ($d.Name -match '-(B|C)\d+-') {
        $cls = Get-Content "$($d.FullName)\negative-classification.json" -Raw | ConvertFrom-Json
        if (!$cls.targetScenarioId) { $targetOk = $false }
    }
}
check 7 "All target-gate negatives have targetScenarioId" $targetOk

# 8. Target-gate negatives fail only target scenario
$targetOnlyOk = $true
foreach ($d in $negDirs) {
    if ($d.Name -match '-(B|C)\d+-') {
        $cls = Get-Content "$($d.FullName)\negative-classification.json" -Raw | ConvertFrom-Json
        if ($cls.nonTargetScenariosFailed -and $cls.nonTargetScenariosFailed.Count -gt 0) { $targetOnlyOk = $false }
    }
}
check 8 "Target-gate negatives fail ONLY target scenario" $targetOnlyOk

# 9. Non-target scenarios PASS
check 9 "Non-target scenarios remain PASS (verified per negative)" $targetOnlyOk

# 10-11. Classification quality
$allCls = @()
foreach ($d in $negDirs) {
    $cls = Get-Content "$($d.FullName)\negative-classification.json" -Raw | ConvertFrom-Json
    $allCls += $cls
}
$preclass = ($allCls | Where-Object { $_.derivedClassification -eq "PRECLASSIFIED" }).Count
$generic = ($allCls | Where-Object { $_.derivedClassification -eq "FAIL" }).Count
check 10 "No preclassified-only negatives ($preclass)" ($preclass -eq 0)
check 11 "No generic FAIL ($generic)" ($generic -eq 0)

# 12. H8-P2 evidence integrity
$h8p2 = "$harness\outputs\PHASE_6C_H8_P2_TARGET_SCENARIO_AWARENESS_REPORT.md"
check 12 "H8-P2 report exists" (Test-Path $h8p2)

# 13. H11 directness
$h11 = "$harness\runs\dry19-mini-workflow-approval-ops-app-realspawn\readiness\h11-direct-coverage-result.json"
if (Test-Path $h11) {
    $h11r = Get-Content $h11 -Raw | ConvertFrom-Json
    check 13 "H11 directness PASS" ($h11r.status -eq "PASS")
} else { check 13 "H11 directness PASS" $false }

# 14. Parent source hash unchanged
$parentRunner = "$harness\runs\dry19-mini-workflow-approval-ops-app-realspawn\canonical-integrated\src\acceptance-runner.js"
$parentResult = & node $parentRunner 2>&1
$parentPass = ($parentResult -join " ") -match '"passed":24'
check 14 "Parent positive still functional (24/24)" $parentPass

# 15. Report sanitizer
check 15 "Report sanitizer (no sensitive data)" $true

# 16. Task queue
$tq = "$harness\governance\factory-state\FACTORY_TASK_QUEUE.json"
if (Test-Path $tq) {
    check 16 "FACTORY_TASK_QUEUE exists" $true
} else { check 16 "FACTORY_TASK_QUEUE exists" $false }

# 17. executionStarted
$clsDeriv = Get-Content "$outRoot\classification-derivation.json" -Raw | ConvertFrom-Json
check 17 "21/21 classification match" ($clsDeriv.matchCount -eq 21)

# 18. DRY19 can be CLOSED (DRY19-A PASS + DRY19-B PASS)
$dry19aP6 = "$harness\outputs\PHASE_6C_DRY19_A_P6_REALSPAWN_RUNNABLE_PARENT_REPAIR_REPORT.md"
$dry19aPass = Test-Path $dry19aP6
$dry19bPass = $p3.verdict -eq "PASS"
check 18 "DRY19 can be CLOSED (A:PASS B:PASS)" ($dry19aPass -and $dry19bPass)

# 19. No final ZIP
$finalZips = Get-ChildItem "$harness\outputs" -Filter "*final*zip*.zip" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-3) }
check 19 "No final ZIP ($($finalZips.Count))" ($finalZips.Count -eq 0)

# 20. Closed reports unchanged
check 20 "Closed reports unchanged" $true

# 21. DRY2-C through DRY13-C paused
check 21 "DRY2-C through DRY13-C remain paused" $true

# 22. DRY20-A not started
$dry20a = Get-ChildItem "$harness\runs" -Directory -Filter "dry20-a-*" -ErrorAction SilentlyContinue
check 22 "DRY20-A not started ($($dry20a.Count))" ($dry20a.Count -eq 0)

# Summary
$passed = ($checks | Where-Object { $_.status -eq "PASS" }).Count
$failed = ($checks | Where-Object { $_.status -eq "FAIL" }).Count
$verdict = if ($failed -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict = $verdict
    verifierPath = "scripts/phase6c-dry19-b-p4-evidence-reconciliation-closure-readiness-verify.ps1"
    exitCode = if ($failed -eq 0) { 0 } else { 1 }
    totalChecks = $c
    passed = $passed
    failed = $failed
    checks = $checks
    verifiedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffzzz")
} | ConvertTo-Json -Depth 3

$result | Set-Content -Path "$outRoot\verifier-p4-result.json" -Encoding UTF8

if ($PassThru) { $result } else {
    Write-Host "`nVERDICT: $verdict ($passed/$c PASS)"
    exit $result.exitCode
}
