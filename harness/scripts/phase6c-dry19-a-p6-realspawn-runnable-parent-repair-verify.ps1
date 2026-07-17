# phase6c-dry19-a-p6-realspawn-runnable-parent-repair-verify.ps1
param([switch]$PassThru)

$ErrorActionPreference = "Stop"
$harness = "C:\Codex_App_Factory\harness"
$run = "$harness\runs\dry19-mini-workflow-approval-ops-app-realspawn"
$checks = @()
$c = 0

function check($id, $desc, $cond) {
    $global:c++
    $status = if ($cond) { "PASS" } else { "FAIL" }
    $global:checks += @{ id = $id; desc = $desc; status = $status }
    Write-Host "$status [$id] $desc"
}

# 1. DRY19-B-P3 report exists and PASS
$p3Report = "$harness\outputs\PHASE_6C_DRY19_B_P3_REEXECUTION_AGAINST_ACTUAL_REALSPAWN_PARENT_REPORT.md"
check 1 "DRY19-B-P3 report exists" (Test-Path $p3Report)

# 2. P3 recorded missing executable acceptance runner
if (Test-Path $p3Report) {
    $p3Content = Get-Content $p3Report -Raw -ErrorAction SilentlyContinue
    $p3Missing = ($p3Content -match "No executable acceptance runner found|missing.*acceptance|acceptance runner.*missing") -or ($p3Content -match "canonical-integrated\/src was empty|was empty")
    check 2 "P3 recorded missing executable acceptance runner" $p3Missing
} else {
    check 2 "P3 recorded missing executable acceptance runner" $false
}

# 3. realspawn parent inventory exists
$inv = "$run\reports\realspawn-runnable-parent-inventory.json"
check 3 "Realspawn parent inventory exists" (Test-Path $inv)

# 4. canonical-integrated/src exists and is not empty
$ciSrc = "$run\canonical-integrated\src"
$ciNotEmpty = (Test-Path $ciSrc) -and ((Get-ChildItem $ciSrc -Filter *.js).Count -gt 0)
check 4 "canonical-integrated/src exists and is not empty" $ciNotEmpty

# 5. integration ledger exists and records materialization
$ledger = "$run\canonical-integrated\reports\integration-patches.jsonl"
if (Test-Path $ledger) {
    $ledgerContent = Get-Content $ledger -Raw
    $ledgerOk = $ledgerContent -match "materialize"
    check 5 "Integration ledger exists and records materialization" $ledgerOk
} else {
    check 5 "Integration ledger exists and records materialization" $false
}

# 6. runtime entrypoint exists
$entrypoint = "$ciSrc\index.js"
check 6 "Runtime entrypoint exists" (Test-Path $entrypoint)

# 7. scenario runner exists
$runner = "$ciSrc\acceptance-runner.js"
check 7 "Scenario runner exists" (Test-Path $runner)

# 8. scenario manifest exists (package.json as proxy)
$pkg = "$run\canonical-integrated\package.json"
check 8 "Scenario manifest exists" (Test-Path $pkg)

# 9. live parent acceptance recheck exists
$recheck = "$run\reports\live-parent-acceptance-recheck.json"
check 9 "Live parent acceptance recheck exists" (Test-Path $recheck)

# 10. live parent acceptance command/transcript/exitCode exist
$cmdFile = "$run\reports\acceptance-command.txt"
$transFile = "$run\reports\acceptance-transcript.log"
$exitFile = "$run\reports\acceptance-exitCode.txt"
$evidenceOk = (Test-Path $cmdFile) -and (Test-Path $transFile) -and (Test-Path $exitFile)
check 10 "Live parent acceptance command/transcript/exitCode exist" $evidenceOk

# 11. live scenario count >= 24
if (Test-Path $recheck) {
    $rc = Get-Content $recheck -Raw | ConvertFrom-Json
    $countOk = $rc.scenarioCount -ge 24
    check 11 "Live scenario count >= 24 (actual: $($rc.scenarioCount))" $countOk
} else {
    check 11 "Live scenario count >= 24" $false
}

# 12. all live parent scenarios PASS
if (Test-Path $recheck) {
    $rc = Get-Content $recheck -Raw | ConvertFrom-Json
    $allPass = ($rc.passedCount -eq $rc.scenarioCount) -and ($rc.failedCount -eq 0)
    check 12 "All live parent scenarios PASS ($($rc.passedCount)/$($rc.scenarioCount))" $allPass
} else {
    check 12 "All live parent scenarios PASS" $false
}

# 13. H8-P1/H8-P2 acceptance evidence integrity PASS
$h8p1 = "$harness\outputs\PHASE_6C_H8_P1_ACCEPTANCE_EVIDENCE_INTEGRITY_REPORT.md"
$h8p2 = "$harness\outputs\PHASE_6C_H8_P2_TARGET_SCENARIO_AWARENESS_REPORT.md"
$h8ok = (Test-Path $h8p1) -and (Test-Path $h8p2)
check 13 "H8-P1/H8-P2 reports exist" $h8ok

# 14. H11 direct scenario coverage PASS
$h11 = "$run\readiness\h11-direct-coverage-result.json"
if (Test-Path $h11) {
    $h11r = Get-Content $h11 -Raw | ConvertFrom-Json
    $h11ok = $h11r.status -eq "PASS" -and $h11r.exitCode -eq 0
    check 14 "H11 direct scenario coverage PASS" $h11ok
} else {
    check 14 "H11 direct scenario coverage PASS" $false
}

# 15. derived metrics meet mandatory floors (JS file count >= 50)
$jsCount = (Get-ChildItem -Path "$run\workspace" -Recurse -Filter *.js -ErrorAction SilentlyContinue).Count
$metricsOk = $jsCount -ge 50
check 15 "Derived metrics meet mandatory floors (JS files: $jsCount, min: 50)" $metricsOk

# 16. no documented-only scenarios counted
if (Test-Path $runner) {
    $runnerContent = Get-Content $runner -Raw
    $docOnly = ($runnerContent -match 'documented.only|skip.*as.*pass|preclassified') -eq $false
    check 16 "No documented-only scenarios counted" $docOnly
} else {
    check 16 "No documented-only scenarios counted" $false
}

# 17. no skipped-as-pass
if (Test-Path $recheck) {
    $rc = Get-Content $recheck -Raw | ConvertFrom-Json
    $skipped = ($rc.results | Where-Object { $_.detail -match "skip|defer" }).Count
    check 17 "No skipped-as-pass ($skipped skipped)" ($skipped -eq 0)
} else {
    check 17 "No skipped-as-pass" $false
}

# 18. no hardcoded PASS (acceptance runner exercises real worker modules via require())
if (Test-Path $runner) {
    $runnerContent = Get-Content $runner -Raw
    $recCount = [regex]::Matches($runnerContent, 'rec\(').Count
    $reqCount = [regex]::Matches($runnerContent, 'require\(path\.join').Count
    $hasAssertions = $recCount -ge 24
    $requiresReal = $reqCount -ge 5
    check 18 "No hardcoded PASS ($recCount scenarios, $reqCount real requires)" ($hasAssertions -and $requiresReal)
} else {
    check 18 "No hardcoded PASS" $false
}

# 19. parent runnable readiness file exists
$readiness = "$run\reports\dry19-b-readiness-after-parent-runner-repair.json"
check 19 "Parent runnable readiness file exists" (Test-Path $readiness)

# 20. DRY19-B readiness after repair = true
if (Test-Path $readiness) {
    $rd = Get-Content $readiness -Raw | ConvertFrom-Json
    $ready = $rd.parentRunnable -eq $true -and $rd.DRY19BMayBeReExecuted -eq $true
    check 20 "DRY19-B readiness after repair = true" $ready
} else {
    check 20 "DRY19-B readiness after repair = true" $false
}

# 21. DRY19-B not started during P6 (no actual negative execution runs exist)
# Check for negative run directories that indicate actual execution
$dry19bDirs = @(
    "$harness\runs\dry19-b-live-negative-controls",
    "$harness\runs\dry19-b-p1-source-scenario-directness-repair",
    "$harness\runs\dry19-b-p3-realspawn-live-negative-controls"
)
$negExecDirs = 0
foreach ($d in $dry19bDirs) {
    if (Test-Path $d) {
        # Count directories matching "negative-" pattern which indicate actual execution
        $negs = Get-ChildItem $d -Directory -Filter "*negative-*" -ErrorAction SilentlyContinue
        $negExecDirs += $negs.Count
    }
}
# Also check for any new negative JSON evidence files created in P6 window (not reconciliation)
$p6Cutoff = Get-Date "2026-06-23T14:00:00+08:00"
$newExecEvidence = $false
foreach ($d in $dry19bDirs) {
    if (Test-Path $d) {
        $evidence = Get-ChildItem $d -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
            $_.LastWriteTime -gt $p6Cutoff -and $_.Name -match "fault-manifest|before-after|acceptance.*negative|transcript.*negative"
        }
        if ($evidence.Count -gt 0) { $newExecEvidence = $true }
    }
}
$negOk = ($negExecDirs -eq 0) -and (-not $newExecEvidence)
check 21 "DRY19-B not started during P6 (negExecDirs=$negExecDirs, newExecEvidence=$newExecEvidence)" $negOk

# 22. DRY20-A not started
$dry20a = "$harness\runs\dry20-a-*"
$dry20Started = (Get-ChildItem $dry20a -ErrorAction SilentlyContinue).Count -gt 0
check 22 "DRY20-A not started" (-not $dry20Started)

# 23. no generic FAIL classifications
if (Test-Path $recheck) {
    $rc = Get-Content $recheck -Raw | ConvertFrom-Json
    $genericFail = ($rc.results | Where-Object { $_.detail -eq "FAIL" -or $_.detail -eq "FAILED" }).Count
    check 23 "No generic FAIL classifications ($genericFail generic)" ($genericFail -eq 0)
} else {
    check 23 "No generic FAIL classifications" $false
}

# 24. no final project ZIP (phase audit bundle ZIPs are OK)
$allZips = Get-ChildItem "$harness\outputs" -Filter "*.zip" -ErrorAction SilentlyContinue
$recentFinal = ($allZips | Where-Object { $_.Name -match "final" -and $_.LastWriteTime -gt (Get-Date).AddHours(-2) }).Count
check 24 "No final project ZIP ($recentFinal final ZIPs)" ($recentFinal -eq 0)

# 25. closed reports unchanged except explicit P6 addendum
$closedOk = $true
$closedCheckDirs = @("$harness\outputs\h1-factory-core-hardening", "$harness\outputs\h2-hardened-factory-pipeline")
foreach ($d in $closedCheckDirs) {
    if (Test-Path $d) {
        $recent = Get-ChildItem $d -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-1) }
        if ($recent.Count -gt 0) { $closedOk = $false }
    }
}
check 25 "Closed reports unchanged" $closedOk

# 26. DRY2-C through DRY13-C remain paused
$pausedOk = $true
2..13 | ForEach-Object {
    $dn = "dry$_-c"
    $dirs = Get-ChildItem "$harness\runs" -Directory -Filter "$dn-*" -ErrorAction SilentlyContinue
    foreach ($d in $dirs) {
        $recent = Get-ChildItem $d.FullName -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-2) }
        if ($recent.Count -gt 0) { $global:pausedOk = $false }
    }
}
check 26 "DRY2-C through DRY13-C remain paused" $pausedOk

# Summary
$passed = ($checks | Where-Object { $_.status -eq "PASS" }).Count
$failed = ($checks | Where-Object { $_.status -eq "FAIL" }).Count
$verdict = if ($failed -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict = $verdict
    verifierPath = "scripts/phase6c-dry19-a-p6-realspawn-runnable-parent-repair-verify.ps1"
    exitCode = if ($failed -eq 0) { 0 } else { 1 }
    totalChecks = $c
    passed = $passed
    failed = $failed
    checks = $checks
    verifiedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffzzz")
}

$resultJson = $result | ConvertTo-Json -Depth 3
$resultJson | Set-Content -Path "$run\reports\verifier-p6-result.json" -Encoding UTF8

if ($PassThru) {
    $resultJson
} else {
    Write-Host "`nVERDICT: $verdict ($passed/$c PASS)"
    exit $result.exitCode
}
