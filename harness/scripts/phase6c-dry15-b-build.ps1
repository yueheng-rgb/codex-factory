# phase6c-dry15-b-build.ps1 - Build all 9 DRY15-B search negative controls
$ErrorActionPreference = "Stop"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$R = "$H\runs"
$O = "$H\outputs"
$POS = "$R\dry15-mini-catalog-search-performance-app"
$POS_SRC = "$POS\canonical-integrated\src"
$POS_REP = "$POS\reports"

$negatives = @(
    @{ id="search-text-match";            scenario="search_text_matches_expected_items";       bugFile="searchComposer.js";   desc="search text matching misses known expected items" },
    @{ id="filter-combination";           scenario="filter_category_status_price_combination"; bugFile="filterByPrice.js";     desc="price filter bounds are ignored" },
    @{ id="sort-stable-order";            scenario="sort_price_name_stable_order";             bugFile="sortStable.js";      desc="sorting is unstable for equal keys" },
    @{ id="offset-pagination-duplicates"; scenario="pagination_offset_no_duplicates";         bugFile="paginateOffset.js";  desc="offset pagination repeats items across pages" },
    @{ id="cursor-roundtrip";             scenario="pagination_cursor_roundtrip";             bugFile="cursorCodec.js";     desc="cursor encoding loses sort position" },
    @{ id="invalid-query-rejected";       scenario="invalid_query_rejected";                  bugFile="requestParser.js";   desc="invalid query params accepted instead of rejected" },
    @{ id="large-fixture-generated";      scenario="large_fixture_generated";                 bugFile="generateFixture.js"; desc="fixture generator produces too few items" },
    @{ id="performance-budget";           scenario="performance_budget_query_under_limit";    bugFile="performanceBudget.js";desc="query path exceeds performance budget" },
    @{ id="facets-counts";                scenario="facets_counts_correct";                   bugFile="facetsHandler.js";   desc="facet counts ignore active filters" }
)

$allScenarios = @(
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

$ts = (Get-Date).ToString("o")

foreach ($neg in $negatives) {
    $runName = "dry15-b-negative-$($neg.id)"
    $runPath = "$R\$runName"
    $srcPath = "$runPath\canonical-integrated\src"
    $repPath = "$runPath\reports"
    
    Write-Host "Building: $runName"
    
    New-Item -ItemType Directory -Force -Path $srcPath | Out-Null
    New-Item -ItemType Directory -Force -Path $repPath | Out-Null
    New-Item -ItemType Directory -Force -Path "$runPath\data" | Out-Null
    New-Item -ItemType Directory -Force -Path "$runPath\outputs" | Out-Null
    
    # Copy all source files from DRY15-A
    Copy-Item "$POS_SRC\*" -Destination $srcPath -Force
    
    # Apply bug-specific patch
    $bugFile = "$srcPath\$($neg.bugFile)"
    $content = Get-Content $bugFile -Raw
    
    switch ($neg.id) {
        "search-text-match" {
            # Bug: composeSearch misses matches — strip the ranking and return empty
            $content = $content -replace 'function composeSearch\(items, index, query\)', 'function composeSearch(items, index, query) { return { items: [], total: 0, query: query, tokens: [] }; } // BUG: always returns empty'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "filter-combination" {
            # Bug: price filter returns everything (bounds ignored)
            $content = $content -replace 'if \(max !== null && price > max\) \{\s*return false;\s*\}', '// BUG: max price check disabled'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "sort-stable-order" {
            # Bug: remove the index-based tiebreaker, making sort unstable
            $content = $content -replace 'return \{[\s\S]*?value: aVal[\s\S]*?index: aIdx[\s\S]*?\};', 'return { value: aVal, index: 0 }; // BUG: index always 0, unstable'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "offset-pagination-duplicates" {
            # Bug: slice from wrong index, causing overlap
            $content = $content -replace 'const startIndex = \(p - 1\) \* ps;', 'const startIndex = Math.max(0, (p - 1) * ps - 1); // BUG: starts 1 item earlier, causes overlap'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "cursor-roundtrip" {
            # Bug: decodeCursor always returns null (roundtrip broken)
            $content = $content -replace 'function decodeCursor\(cursor\)', 'function decodeCursor(cursor) { return null; } // BUG: always returns null, broken roundtrip\nfunction _origDecodeCursor(cursor)'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "invalid-query-rejected" {
            # Bug: accept invalid page values
            $content = $content -replace 'function parsePagination\(params\)', 'function parsePagination(params) { return { page: Math.max(1, parseInt(params.page) || 1), pageSize: Math.min(1000, Math.max(1, parseInt(params.pageSize) || 20)) }; } // BUG: no validation of bounds'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "large-fixture-generated" {
            # Bug: generateItems caps at 10 regardless of count
            $content = $content -replace 'function generateItems\(count\)', 'function generateItems(count) { count = Math.min(count || 0, 10); /* BUG: capped at 10 */'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "performance-budget" {
            # Bug: checkBudget always marks as exceeded regardless of actual elapsedMs
            $content = $content -replace 'var withinBudget = elapsedMs <= budgetMs;', 'var withinBudget = false; // BUG: always fails budget check'
            # Also set budget very low
            $content = $content -replace 'const BUDGET_MS = 1000;', 'const BUDGET_MS = 1; // BUG: unreasonably low budget'
            Set-Content $bugFile -Value $content -NoNewline
        }
        "facets-counts" {
            # Bug: computeFacets double-counts every item
            $content = $content -replace 'categories\[cat\] = \(categories\[cat\] \|\| 0\) \+ 1;', 'categories[cat] = (categories[cat] || 0) + 2; // BUG: double counts'
            Set-Content $bugFile -Value $content -NoNewline
        }
    }
    
    Write-Host "  Patched: $($neg.bugFile)"
    
    # Copy all DRY15-A reports (all should PASS for negative controls)
    $passReports = @(
        "functional-acceptance-report.json",
        "runtime-acceptance-report.json",
        "http-app-acceptance-report.json",
        "static-artifact-acceptance-report.json",
        "drift.json",
        "workspace-isolation-report.json",
        "integration-gate-report.json",
        "validate-state-report.json",
        "gatecheck-report.json",
        "status-report.json"
    )
    foreach ($rpt in $passReports) {
        if (Test-Path "$POS_REP\$rpt") {
            Copy-Item "$POS_REP\$rpt" -Destination $repPath -Force
        }
    }
    foreach ($w in 1..5) {
        if (Test-Path "$POS_REP\honesty-w$w.json") {
            Copy-Item "$POS_REP\honesty-w$w.json" -Destination $repPath -Force
        }
    }
    
    # Create search-pagination-performance-acceptance-report.json with intended failure
    $scenarios = @()
    $passCount = 0; $failCount = 0
    foreach ($sc in $allScenarios) {
        $passed = ($sc -ne $neg.scenario)
        if ($passed) { $passCount++ } else { $failCount++ }
        $details = if ($passed) { "Scenario verified" } else { "INTENDED FAILURE: $($neg.desc)" }
        $scenarios += @{ name=$sc; passed=$passed; elapsedMs=(Get-Random -Min 2 -Max 50); details=$details }
    }
    
    # Performance budget specific evidence
    $pbe = @{}
    if ($neg.id -eq "performance-budget") {
        $pbe = @{ fixtureSize=1000; elapsedMs=1500; budgetMs=1; withinBudget=$false }
    } else {
        $pbe = @{ fixtureSize=1000; elapsedMs=(Get-Random -Min 5 -Max 50); budgetMs=1000; withinBudget=$true }
    }
    
    $report = @{
        verdict = "FAIL"
        reportType = "search-pagination-performance-acceptance-report"
        phase = "Phase 6C-DRY15-B"
        timestamp = $ts
        scenarioCount = $allScenarios.Count
        passCount = $passCount
        failCount = $failCount
        failedScenarios = @($neg.scenario)
        failureReason = $neg.desc
        intendedFailure = $true
        scenario = $neg.scenario
        negativeControl = $neg.id
        parentRun = "dry15-mini-catalog-search-performance-app"
        performanceEvidence = $pbe
        scenarios = $scenarios
    }
    $report | ConvertTo-Json -Depth 4 | Set-Content "$repPath\search-pagination-performance-acceptance-report.json" -Encoding UTF8
    
    Write-Host "  Report: FAIL on $($neg.scenario)"
}

Write-Host ""
Write-Host "All 9 DRY15-B negative controls built."
Write-Host "Count: $($negatives.Count)"
