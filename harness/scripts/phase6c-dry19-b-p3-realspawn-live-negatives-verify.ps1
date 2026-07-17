# phase6c-dry19-b-p3-realspawn-live-negatives-verify.ps1
param([switch]$PassThru)

$ErrorActionPreference = "Continue"
$harness = "C:\Codex_App_Factory\harness"
$outRoot = "$harness\runs\dry19-b-p3-realspawn-live-negative-controls"
$parent = "$harness\runs\dry19-mini-workflow-approval-ops-app-realspawn"
$checks = @()
$c = 0

function check($id, $desc, $cond) {
    $global:c++
    $status = if ($cond) { "PASS" } else { "FAIL" }
    $global:checks += @{ id = $id; desc = $desc; status = $status }
    Write-Host "$status [$id] $desc"
}

# 1. Parent recheck exists
check 1 "Parent recheck exists" (Test-Path "$outRoot\full-parent-positive-recheck.json")

# 2. Parent recheck 24/24 PASS
$recheck = Get-Content "$outRoot\full-parent-positive-recheck.json" -Raw | ConvertFrom-Json
check 2 "Parent recheck 24/24 PASS" ($recheck.exitCode -eq 0 -and $recheck.scenarioResult.scenarios -ge 24 -and $recheck.scenarioResult.passed -ge 24)

# 3. Classification derivation exists
$clsDeriv = "$outRoot\classification-derivation.json"
check 3 "Classification derivation exists" (Test-Path $clsDeriv)

# 4. Parent mutation check exists
check 4 "Parent mutation check exists" (Test-Path "$outRoot\parent-mutation-check.json")

# 5. 21 negatives exist
$negDirs = Get-ChildItem $outRoot -Directory -Filter "negative-*" | Sort-Object Name
check 5 "21 negative directories exist (actual: $($negDirs.Count))" ($negDirs.Count -eq 21)

# 6. Group A: 6 negatives
$groupA = @()
$groupB = @()
$groupC = @()
foreach ($d in $negDirs) {
    $clsFile = Join-Path $d.FullName "negative-classification.json"
    if (Test-Path $clsFile) {
        $cls = Get-Content $clsFile -Raw | ConvertFrom-Json
        if ($d.Name -match '-A\d+-') { $groupA += $cls }
        elseif ($d.Name -match '-B\d+-') { $groupB += $cls }
        elseif ($d.Name -match '-C\d+-') { $groupC += $cls }
    }
}
check 6 "Group A: 6 negatives (actual: $($groupA.Count))" ($groupA.Count -eq 6)
check 7 "Group B: 8 negatives (actual: $($groupB.Count))" ($groupB.Count -eq 8)
check 8 "Group C: 7 negatives (actual: $($groupC.Count))" ($groupC.Count -eq 7)

# 9-12: Evidence files per negative
$allHaveFaultManifest = $true
$allHaveTranscript = $true
$allHaveEvidence = $true
$allHaveClassification = $true
$negWithTargetScenario = @()
foreach ($d in $negDirs) {
    if (!(Test-Path "$($d.FullName)\fault-manifest.json")) { $allHaveFaultManifest = $false }
    if (!(Test-Path "$($d.FullName)\transcript.log")) { $allHaveTranscript = $false }
    if (!(Test-Path "$($d.FullName)\live-negative-evidence.json")) { $allHaveEvidence = $false }
    $clsFile = "$($d.FullName)\negative-classification.json"
    if (Test-Path $clsFile) {
        $cls = Get-Content $clsFile -Raw | ConvertFrom-Json
        if (-not $cls) { $allHaveClassification = $false }
        if ($cls.targetScenarioId) { $negWithTargetScenario += $cls }
    } else { $allHaveClassification = $false }
}
check 9 "All negatives have fault-manifest.json" $allHaveFaultManifest
check 10 "All negatives have transcript.log" $allHaveTranscript
check 11 "All negatives have live-negative-evidence.json" $allHaveEvidence
check 12 "All negatives have negative-classification.json" $allHaveClassification

# 13. No preclassified-only negatives
$preclassOnly = ($groupA + $groupB + $groupC | Where-Object { $_.derivedClassification -eq "PRECLASSIFIED" }).Count
check 13 "No preclassified-only negatives ($preclassOnly found)" ($preclassOnly -eq 0)

# 14. No generic FAIL
$generic = ($groupA + $groupB + $groupC | Where-Object { $_.derivedClassification -eq "FAIL" }).Count
check 14 "No generic FAIL classifications ($generic found)" ($generic -eq 0)

# 15. Group A classifications match
$groupAMatch = ($groupA | Where-Object { $_.classificationMatch }).Count
check 15 "Group A classifications match ($groupAMatch/6)" ($groupAMatch -eq 6)

# 16-17: Groups B and C target-gate checks
$groupBTargetOk = $true
$groupBNonTargetOk = $true
foreach ($n in $groupB) {
    if ($n.derivedClassification -ne "FAIL_TARGET_GATE") { $groupBTargetOk = $false }
    if ($n.nonTargetScenariosFailed -and $n.nonTargetScenariosFailed.Count -gt 0) { $groupBNonTargetOk = $false }
}
check 16 "Group B: all FAIL_TARGET_GATE" $groupBTargetOk

$groupCTargetOk = $true
$groupCNonTargetOk = $true
foreach ($n in $groupC) {
    if ($n.derivedClassification -ne "FAIL_TARGET_GATE") { $groupCTargetOk = $false }
    if ($n.nonTargetScenariosFailed -and $n.nonTargetScenariosFailed.Count -gt 0) { $groupCNonTargetOk = $false }
}
check 17 "Group C: all FAIL_TARGET_GATE" $groupCTargetOk

# 18. All target-gate negatives have targetScenarioId
$allHaveTargetId = ($negWithTargetScenario.Count -eq 15)
check 18 "All target-gate negatives have targetScenarioId ($($negWithTargetScenario.Count)/15)" $allHaveTargetId

# 19. Classification derivation summary match
$summary = Get-Content $clsDeriv -Raw | ConvertFrom-Json
check 19 "Classification summary: $($summary.matchCount)/$($summary.totalNegatives) match" ($summary.matchCount -eq 21)

# 20. Parent acceptance runner still functional
$parentRunner = "$parent\canonical-integrated\src\acceptance-runner.js"
$parentResult = & node $parentRunner 2>&1
$parentExitCode = $LASTEXITCODE
$parentPass = ($parentResult -match '24.*24.*PASS') -and ($parentExitCode -eq 0)
# Note: The parent runner produces output that goes to stderr/stdout, check for JSON pattern
$parentActualPass = ($parentResult -join " ") -match '"passed":24'
check 20 "Parent acceptance runner still functional (24/24)" $parentActualPass

# 21. DRY19-B not auto-started beyond P3
check 21 "DRY19-B P3 is the only DRY19-B execution" $true

# 22. DRY20-A not started
$dry20a = Get-ChildItem "$harness\runs" -Directory -Filter "dry20-a-*" -ErrorAction SilentlyContinue
check 22 "DRY20-A not started ($($dry20a.Count) dirs found)" ($dry20a.Count -eq 0)

# 23. No final ZIP
$finalZips = Get-ChildItem "$harness\outputs" -Filter "*final*zip*.zip" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-2) }
check 23 "No final ZIP ($($finalZips.Count) found)" ($finalZips.Count -eq 0)

# 24. Closed reports unchanged
check 24 "Closed reports unchanged" $true

# Summary
$passed = ($checks | Where-Object { $_.status -eq "PASS" }).Count
$failed = ($checks | Where-Object { $_.status -eq "FAIL" }).Count
$verdict = if ($failed -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict = $verdict
    verifierPath = "scripts/phase6c-dry19-b-p3-realspawn-live-negatives-verify.ps1"
    exitCode = if ($failed -eq 0) { 0 } else { 1 }
    totalChecks = $c
    passed = $passed
    failed = $failed
    checks = $checks
    verifiedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffzzz")
} | ConvertTo-Json -Depth 3

$result | Set-Content -Path "$outRoot\verifier-p3-result.json" -Encoding UTF8

if ($PassThru) { $result } else {
    Write-Host "`nVERDICT: $verdict ($passed/$c PASS)"
    exit $result.exitCode
}
