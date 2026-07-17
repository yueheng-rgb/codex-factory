# Starter Type Consistency Check v1.0.0
# Part of: FACTORY-R2.12
# Verifies typecheck + build + tests for all runnable starters and testbeds.
# Supplementary checks for pagination/field/enum consistency.

param(
    [switch]$Json
)

$targets = @(
    @{path="C:\Codex_App_Factory\runnable-starters\node-api-postgres"; name="node-api-postgres"; cat="STARTER"},
    @{path="C:\Codex_App_Factory\runnable-starters\vite-threejs-interactive"; name="vite-threejs-interactive"; cat="STARTER"},
    @{path="C:\Codex_App_Factory\runnable-starters\next-fullstack-admin"; name="next-fullstack-admin"; cat="STARTER"},
    @{path="C:\Codex_App_Factory\runnable-starters\next-saas-ai-tool"; name="next-saas-ai-tool"; cat="STARTER"},
    @{path="C:\Codex_App_Factory\runnable-starters\vite-react-content-site"; name="vite-react-content-site"; cat="STARTER"},
    @{path="C:\Codex_App_Factory\testbeds\products-api"; name="products-api"; cat="TESTBED"}
)

$results = @()
$allPass = $true

foreach ($t in $targets) {
    if (-not (Test-Path $t.path)) {
        $results += [PSCustomObject]@{name=$t.name; cat=$t.cat; typecheck="NOT_FOUND"; build="NOT_FOUND"; tests="NOT_FOUND"; pagination="SKIP"; fieldNames="SKIP"; passed=$false; issues=@("Path not found")}
        $allPass = $false
        continue
    }

    Write-Host "===== $($t.cat) : $($t.name) =====" -ForegroundColor Cyan
    $check = [PSCustomObject]@{name=$t.name; cat=$t.cat; typecheck="NOT_RUN"; build="NOT_RUN"; tests="NOT_RUN"; pagination="NOT_CHECKED"; fieldNames="NOT_CHECKED"; passed=$true; issues=@()}

    Push-Location $t.path
    try {
        # 1. Typecheck
        Write-Host "  typecheck..." -NoNewline
        npx tsc --noEmit 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $check.typecheck = "PASS"; Write-Host " PASS" -F Green }
        else { $check.typecheck = "FAIL"; $check.passed = $false; $allPass = $false; Write-Host " FAIL" -F Red }

        # 2. Build
        Write-Host "  build..." -NoNewline
        if (Test-Path "next.config.js") {
            npx next build 2>&1 | Out-Null
        } elseif ((Test-Path "vite.config.ts") -or (Test-Path "vite.config.js")) {
            npx vite build 2>&1 | Out-Null
        } else {
            npx tsc 2>&1 | Out-Null
        }
        if ($LASTEXITCODE -eq 0) { $check.build = "PASS"; Write-Host " PASS" -F Green }
        else { $check.build = "FAIL"; $check.passed = $false; $allPass = $false; Write-Host " FAIL" -F Red }

        # 3. Tests
        if ((Test-Path "vitest.config.ts") -or (Test-Path "vitest.config.js")) {
            Write-Host "  tests..." -NoNewline
            $testOut = npx vitest run 2>&1 | Out-String
            if ($LASTEXITCODE -eq 0) { $check.tests = "PASS"; Write-Host " PASS" -F Green }
            else { $check.tests = "FAIL"; $check.passed = $false; $allPass = $false; Write-Host " FAIL" -F Red }
        } else { $check.tests = "NO_TESTS"; Write-Host "  tests... NO_TESTS" -F Yellow }

        # 4. Pagination — check source files only (skip node_modules, dist, .next)
        $srcFiles = Get-ChildItem -Recurse -Include *.ts,*.tsx -File | Where-Object { $_.FullName -notmatch '\\\\(node_modules|dist|\\.next)\\\\' }
        $hasPageSize = ($srcFiles | ForEach-Object { if ((Get-Content $_.FullName -Raw) -match '\bpageSize\b') { $_ } }).Count
        $hasLimit = ($srcFiles | ForEach-Object { if ((Get-Content $_.FullName -Raw) -match '\blimit\b') { $_ } }).Count
        if ($hasPageSize -gt 0 -and $hasLimit -gt 0) {
            $check.pagination = "WARN"
            $check.issues += "[pagination] Both pageSize and limit found in source"
        } else { $check.pagination = "PASS" }

        # 5. Field names — check createdBy/createdByName consistency
        $hasCreatedBy = ($srcFiles | ForEach-Object { if ((Get-Content $_.FullName -Raw) -match '\bcreatedBy\b') { $_ } }).Count
        $hasCreatedByName = ($srcFiles | ForEach-Object { if ((Get-Content $_.FullName -Raw) -match '\bcreatedByName\b') { $_ } }).Count
        if ($hasCreatedBy -gt 0 -and $hasCreatedByName -eq 0) {
            $check.fieldNames = "WARN"
            $check.issues += "[field] createdBy found without createdByName"
        } else { $check.fieldNames = "PASS" }

    } finally {
        Pop-Location
    }
    $results += $check
}

# Summary
Write-Host "`n===== CONSISTENCY SUMMARY =====" -F Cyan
$passN = ($results | Where-Object { $_.passed }).Count
$failN = ($results | Where-Object { -not $_.passed }).Count
Write-Host "Total: $($results.Count) | PASS: $passN | FAIL: $failN"
foreach ($r in $results) {
    $icon = if ($r.passed) { "[PASS]" } else { "[FAIL]" }
    Write-Host "  $icon $($r.cat) $($r.name) — TC:$($r.typecheck) B:$($r.build) T:$($r.tests) P:$($r.pagination) F:$($r.fieldNames)"
    foreach ($i in $r.issues) { Write-Host "    $i" -F Yellow }
}

if ($Json) { $results | ConvertTo-Json -Depth 3 }
exit $(if ($allPass) { 0 } else { 1 })
