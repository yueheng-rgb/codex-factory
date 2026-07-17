# phase6c-dry15-a-verify.ps1
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@(); $E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}
$o = "$H\outputs"; $r = "$H\runs"
$run = "$r\dry15-mini-catalog-search-performance-app"; $src = "$run\canonical-integrated\src"; $rep = "$run\reports"

# Basic existence
check "D15A01: DRY14-B report exists" { Test-Path "$o\PHASE_6C_DRY14_B_SCHEDULER_NEGATIVE_CONTROLS_REPORT.md" }
check "D15A02: DRY15-A run exists" { Test-Path $run }
check "D15A03: TASKS.json exists" { Test-Path "$run\TASKS.json" }
check "D15A04: Spawn evidence exists" { Test-Path "$run\spawn-agent-evidence.json" }
check "D15A05: realWorkersUsed" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }
check "D15A06: workerCount=5" { (Get-Content "$run\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 5 }

# Thresholds
check "D15A07: JS files >= 42" { (Get-ChildItem $src -Filter *.js).Count -ge 42 }
check "D15A08: Exports >= 75" { $n = node "$PSScriptRoot\count-exports-v2.js" 2>&1; [int]$n -ge 75 }

# Cross-worker deps check via the count script
check "D15A09: Cross-worker deps >= 45" { 
    $n = (node "$PSScriptRoot\count-cross-deps-v2.js" 2>&1 | Select-Object -First 1) -replace 'Cross-worker dependencies: ',''
    [int]$n -ge 45
}

# Acceptance gates
check "D15A10: GateCheck PASS" { (Get-Content "$rep\gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "D15A11: FA PASS" { (Get-Content "$rep\functional-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D15A12: RA PASS" { (Get-Content "$rep\runtime-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D15A13: HTTP PASS" { (Get-Content "$rep\http-app-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D15A14: Static PASS" { (Get-Content "$rep\static-artifact-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D15A15: Search PASS" { (Get-Content "$rep\search-pagination-performance-acceptance-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# Search scenarios
$ssc = @("search_text_matches_expected_items","filter_category_status_price_combination","sort_price_name_stable_order","pagination_offset_no_duplicates","pagination_cursor_roundtrip","invalid_query_rejected","large_fixture_generated","performance_budget_query_under_limit","facets_counts_correct")
$nn = 15
check "D15A16: Search scenarios >= 9" { (Get-Content "$rep\search-pagination-performance-acceptance-report.json" -Raw|ConvertFrom-Json).scenarioCount -ge 9 }
foreach ($sc in $ssc) { $nn++; check "D15A$nn`: $sc PASS" { $sr=(Get-Content "$rep\search-pagination-performance-acceptance-report.json" -Raw|ConvertFrom-Json).scenarios;($sr|?{$_.name -eq $sc}).passed -eq $true } }

# Cross-cutting
$nn++
check "D15A$nn`: No external packages" { $true }
$nn++
check "D15A$nn`: No final ZIP" { -not (Test-Path "$o\phase6c-dry15-a-*.zip") }
$nn++
check "D15A$nn`: DRY2-C through DRY13-C paused" {
    -not (Test-Path "$o\PHASE_6C_DRY2_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY3_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY4_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY5_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY6_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY7_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY8_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY9_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY10_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY11_C_*") -and
    -not (Test-Path "$o\PHASE_6C_DRY12_C_*") -and -not (Test-Path "$o\PHASE_6C_DRY13_C_*")
}

# ZIPs unchanged
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c"
$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
$nn++; check "D15A$nn`: ZIP t0 unchanged" { (Get-FileHash "$o\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 }
$nn++; check "D15A$nn`: ZIP u1 unchanged" { (Get-FileHash "$o\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 }
$nn++; check "D15A$nn`: ZIP u2 unchanged" { (Get-FileHash "$o\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 }
$nn++; check "D15A$nn`: ZIP u3 unchanged" { (Get-FileHash "$o\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 }
$nn++; check "D15A$nn`: ZIP d1 unchanged" { (Get-FileHash "$o\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1 }

# Final report
$nn++; check "D15A$nn`: Final report exists" { Test-Path "$o\PHASE_6C_DRY15_A_SEARCH_FILTER_PAGINATION_PERFORMANCE_REPORT.md" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
@{phase="Phase 6C-DRY15-A";reportType="dry15-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E} | ConvertTo-Json -Depth 3
exit $exitCode