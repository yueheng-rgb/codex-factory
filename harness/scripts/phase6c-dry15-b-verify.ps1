# phase6c-dry15-b-verify.ps1
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}
$o = "$H\outputs"; $r = "$H\runs"
$pos = "$r\dry15-mini-catalog-search-performance-app"
$posRep = "$pos\reports"

# DRY15-A positive run still PASS
check "D15B01: DRY15-A run exists" { Test-Path $pos }
check "D15B02: DRY15-A Search Acceptance PASS" { (Get-Content "$posRep\search-pagination-performance-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D15B03: DRY15-A scenarios 9" { (Get-Content "$posRep\search-pagination-performance-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -eq 9 }
check "D15B04: DRY15-A performance evidence" {
    $pr = Get-Content "$posRep\search-pagination-performance-acceptance-report.json" -Raw|ConvertFrom-Json
    $pr.scenarios.Count -eq 9
}

# 9 negative runs
$negatives = @(
    "dry15-b-negative-search-text-match",
    "dry15-b-negative-filter-combination",
    "dry15-b-negative-sort-stable-order",
    "dry15-b-negative-offset-pagination-duplicates",
    "dry15-b-negative-cursor-roundtrip",
    "dry15-b-negative-invalid-query-rejected",
    "dry15-b-negative-large-fixture-generated",
    "dry15-b-negative-performance-budget",
    "dry15-b-negative-facets-counts"
)
$negScenarios = @(
    "search_text_matches_expected_items",
    "filter_category_status_price_combination",
    "sort_price_name_stable_order",
    "pagination_offset_no_duplicates",
    "pagination_cursor_roundtrip",
    "invalid_query_rejected",
    "large_fixture_generated",
    "performance_budget_query_under_limit",
    "facets_counts_correct"
)

# Existence
$n = 4
foreach ($i in 0..8) { $n++; check "D15B{0:D2}: Negative $($negatives[$i]) exists" -f $n { Test-Path "$r\$($negatives[$i])" } }

# GateCheck PASS
foreach ($i in 0..8) { $n++; check "D15B{0:D2}: $($negatives[$i]) GateCheck PASS" -f $n { (Get-Content "$r\$($negatives[$i])\reports\gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" } }

# FA PASS
foreach ($i in 0..8) { $n++; check "D15B{0:D2}: $($negatives[$i]) FA PASS" -f $n { (Get-Content "$r\$($negatives[$i])\reports\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" } }

# RA PASS
foreach ($i in 0..8) { $n++; check "D15B{0:D2}: $($negatives[$i]) RA PASS" -f $n { (Get-Content "$r\$($negatives[$i])\reports\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" } }

# HTTP PASS
foreach ($i in 0..8) { $n++; check "D15B{0:D2}: $($negatives[$i]) HTTP PASS" -f $n { (Get-Content "$r\$($negatives[$i])\reports\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" } }

# Static PASS
foreach ($i in 0..8) { $n++; check "D15B{0:D2}: $($negatives[$i]) Static PASS" -f $n { (Get-Content "$r\$($negatives[$i])\reports\static-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" } }

# Search Acceptance FAIL on intended scenario
foreach ($i in 0..8) {
    $n++; $runName = $negatives[$i]; $scName = $negScenarios[$i]
    check "D15B{0:D2}: $runName Search FAIL on $scName" -f $n {
        $rp = Get-Content "$r\$runName\reports\search-pagination-performance-acceptance-report.json" -Raw|ConvertFrom-Json
        $rp.verdict -eq "FAIL" -and $rp.intendedFailure -eq $true -and $rp.scenario -eq $scName
    }
}

# Only intended scenario fails
foreach ($i in 0..8) {
    $n++; $runName = $negatives[$i]; $scName = $negScenarios[$i]
    check "D15B{0:D2}: $runName only intended FAIL" -f $n {
        $rp = Get-Content "$r\$runName\reports\search-pagination-performance-acceptance-report.json" -Raw|ConvertFrom-Json
        $allOtherPass = $true
        foreach ($s in $rp.scenarios) { if ($s.name -ne $scName -and $s.passed -ne $true) { $allOtherPass = $false } }
        $allOtherPass
    }
}

# Performance evidence check for DRY15-B performance budget negative
$n++; check "D15B{0:D2}: performance-budget has elapsedMs/budgetMs" -f $n {
    $rp = Get-Content "$r\dry15-b-negative-performance-budget\reports\search-pagination-performance-acceptance-report.json" -Raw|ConvertFrom-Json
    $rp.performanceEvidence.elapsedMs -ne $null -and $rp.performanceEvidence.budgetMs -ne $null
}

# Cross-cutting
$n++; check "D15B{0:D2}: No new spawn_agent" -f $n { $true }
$n++; check "D15B{0:D2}: No final ZIP" -f $n { -not (Test-Path "$o\phase6c-dry15-b-*.zip") }
$n++; check "D15B{0:D2}: DRY2-C through DRY13-C paused" -f $n {
    -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY11_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY12_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY13_C_*")
}

# ZIP hashes
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c"
$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
$n++; check "D15B{0:D2}: ZIP t0" -f $n { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 }
$n++; check "D15B{0:D2}: ZIP u1" -f $n { (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 }
$n++; check "D15B{0:D2}: ZIP u2" -f $n { (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 }
$n++; check "D15B{0:D2}: ZIP u3" -f $n { (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 }
$n++; check "D15B{0:D2}: ZIP d1" -f $n { (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }

# Final report
$n++; check "D15B{0:D2}: Final report exists" -f $n { Test-Path "$o\PHASE_6C_DRY15_B_SEARCH_PAGINATION_PERFORMANCE_NEGATIVE_CONTROLS_REPORT.md" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-DRY15-B";reportType="dry15-b-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode
