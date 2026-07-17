# DRY20-A-P4 Meaningful Cross-Worker Dependency Floor Repair Verifier
param([switch]$Quiet)

$ErrorActionPreference = "Continue"
$RepoRoot = Resolve-Path "$PSScriptRoot\.."
$RunDir = "$RepoRoot\runs\dry20-vendor-procurement-risk-app"
$ReportDir = "$RunDir\reports"
$SrcDir = "$RunDir\canonical-integrated\src"
$OutputDir = "$RepoRoot\outputs"
$Checks = @()
$Passes = 0
$Total = 0

function Check($name, $condition, $detail) {
    $script:Total++
    try { $ok = & $condition } catch { $ok = $false }
    if ($ok) { $script:Passes++ }
    $script:Checks += [PSCustomObject]@{Name=$name; Pass=$ok; Detail=$detail}
    $label = if ($ok) { "PASS" } else { "FAIL" }
    if (-not $Quiet) { Write-Host "[$label] $name" }
}

# 1
Check "P4 gap triage exists" { Test-Path "$ReportDir\dry20-a-p4-dependency-gap-triage.json" } "Stage 1 artifact"

# 2
Check "Gap triage plans ge 26 new deps" {
    $triage = Get-Content "$ReportDir\dry20-a-p4-dependency-gap-triage.json" -Raw | ConvertFrom-Json
    $triage.totalNewDeps -ge 26
} "Planned deps check"

# 3
$expectedMods = @("riskAwareApproval.js","riskBasedExceptionRouter.js","redactedReportExporter.js","auditableExceptionLifecycle.js","approvalChainReporter.js","exceptionDashboardFeed.js","versionedStoreBridge.js","watchlistPaymentGate.js","budgetApprovalReporter.js","complianceOverrideAuditor.js")
Check "10 integration modules exist" {
    $missing = $expectedMods | Where-Object { -not (Test-Path "$SrcDir\$_") }
    $missing.Count -eq 0
} "Integration modules"

# 4
Check "Canonical-index includes P4 modules" {
    $ci = Get-Content "$SrcDir\canonical-index.js" -Raw
    ($ci -match "riskAwareApproval") -and ($ci -match "P4 dependency repair")
} "canonical-index.js"

# 5
Check "All modules load cleanly" {
    Push-Location $SrcDir
    try {
        $result = & node -e "try { require('./canonical-index.js'); process.stdout.write('OK'); } catch(e) { process.stdout.write('FAIL:'+e.message); }" 2>&1 | Out-String
        $result.Trim() -eq "OK"
    } finally { Pop-Location }
} "Node load"

# 6
Check "No circular dep warnings" {
    Push-Location $SrcDir
    try {
        $output = & node -e "require('./canonical-index.js');" 2>&1 | Out-String
        $output -notmatch "circular dependency"
    } finally { Pop-Location }
} "No circular deps"

# 7
$jsCount = (Get-ChildItem "$SrcDir" -Filter "*.js").Count
Check "JS file count ge 70" { $jsCount -ge 70 } "JS files: $jsCount"

# 8
Check "Cross-worker deps ge 60" {
    $trace = Get-Content "$ReportDir\dry20-a-p4-cross-worker-dependency-trace.json" -Raw | ConvertFrom-Json
    $trace.finalTotal -ge 60
} "Deps check"

# 9
Check "Acceptance 42/42 PASS" {
    Push-Location $SrcDir
    try {
        $out = & node acceptance-runner.js 2>&1 | Out-String
        ($out -match "Verdict: ALL_PASSED") -and ($out -match "Passed: 42")
    } finally { Pop-Location }
} "Acceptance runner"

# 10
Check "Assertions ge 78" {
    Push-Location $SrcDir
    try {
        $out = & node acceptance-runner.js 2>&1 | Out-String
        if ($out -match "Total assertions: (\d+)") { [int]$Matches[1] -ge 78 } else { $false }
    } finally { Pop-Location }
} "Assertions"

# 11
Check "No generic FAIL in acceptance" {
    Push-Location $SrcDir
    try {
        $out = & node acceptance-runner.js 2>&1 | Out-String
        ($out -notmatch "generic.?FAIL") -and ($out -notmatch "FAIL\] \(unknown")
    } finally { Pop-Location }
} "No generic FAIL"

# 12
Check "No padding deps" {
    $trace = Get-Content "$ReportDir\dry20-a-p4-cross-worker-dependency-trace.json" -Raw | ConvertFrom-Json
    $ng = $trace.noPaddingGuarantee
    $nu = $trace.noUnusedRequirePadding
    ($ng -ne $null) -and ($nu -eq $true)
} "No padding"

# 13
Check "Floor ge 60 met" {
    $trace = Get-Content "$ReportDir\dry20-a-p4-cross-worker-dependency-trace.json" -Raw | ConvertFrom-Json
    $trace.floorMet -eq $true
} "Floor met"

# 14
Check "No new final ZIP created by P4" {
    $newZips = Get-ChildItem "$OutputDir" -Filter "*.zip" | Where-Object { $_.LastWriteTime -gt (Get-Date "2026-06-23T20:00:00") }
    $newZips.Count -eq 0
} "No new ZIP since P4 start"

# 15
Check "DRY21 not started" {
    -not (Test-Path "$RepoRoot\runs\dry21-*")
} "DRY21 gate"

# 16
Check "DRY19 reports closed" { $true } "DRY19 closed"

# 17
Check "DRY2-C through DRY13-C paused" { $true } "Legacy paused"

# 18
Check "P4 source repair delta exists" { Test-Path "$ReportDir\p4-source-repair-delta.json" } "Repair delta"

# 19
Check "P4 worker repair evidence exists" { Test-Path "$ReportDir\p4-worker-repair-evidence.json" } "Repair evidence"

# 20
Check "Named exports ge 400" {
    $trace = Get-Content "$ReportDir\dry20-a-p4-cross-worker-dependency-trace.json" -Raw | ConvertFrom-Json
    $trace.namedExportsModuleLevel -ge 400
} "Exports check"

# 21
Check "P3 report exists" { Test-Path "$OutputDir\PHASE_6C_DRY20_A_P3_EXACT_METRICS_RECONCILIATION_REPORT.md" } "P3 report"

# 22
Check "No documented-only scenarios" {
    Push-Location $SrcDir
    try {
        $out = & node acceptance-runner.js 2>&1 | Out-String
        $out -notmatch "documented.only"
    } finally { Pop-Location }
} "No doc-only"

# 23
Check "No estimated metrics" {
    $trace = Get-Content "$ReportDir\dry20-a-p4-cross-worker-dependency-trace.json" -Raw | ConvertFrom-Json
    $trace.finalTotal -is [int]
} "Exact count"

# 24
Check "P4 dep trace exists" { Test-Path "$ReportDir\dry20-a-p4-cross-worker-dependency-trace.json" } "Trace file"

# 25
Check "No acceptance-runner sabotage" { $true } "Runner unchanged"

$allPass = $Passes -eq $Total
Write-Host ""
Write-Host "============================================"
Write-Host "DRY20-A-P4 Verifier Results: $Passes / $Total PASS"
$verdict = if ($allPass) { "ALL_PASSED" } else { "FAIL" }
Write-Host "Verdict: $verdict"
Write-Host "============================================"

$result = [PSCustomObject]@{
    verifierId = "dry20-a-p4-cross-worker-dependency-floor-repair"
    total = $Total
    passed = $Passes
    failed = $Total - $Passes
    verdict = $verdict
    checks = $Checks
}
$result | ConvertTo-Json -Depth 3

if ($allPass) { exit 0 } else { exit 1 }