# derive-source-metrics.ps1 — Phase 6C-H4
param([Parameter(Mandatory=$true)]$RunDir)
$ErrorActionPreference = "Continue"
$canonicalDir = Join-Path $RunDir "canonical-integrated"
$srcDir = Join-Path $canonicalDir "src"
$reportsDir = Join-Path $RunDir "reports"

$metrics = @{
    jsFileCount = 0
    namedExportCount = 0
    crossWorkerDependencyCount = 0
    scenarioCount = 0
    workerCount = 0
    taskCount = 0
    externalPackageCount = 0
    derivedAt = (Get-Date).ToString("o")
}

if (Test-Path $srcDir) {
    $jsFiles = @(Get-ChildItem $srcDir -Filter "*.js")
    $metrics.jsFileCount = $jsFiles.Count
    
    $totalExports = 0
    $allRequires = @{}
    foreach ($f in $jsFiles) {
        $content = Get-Content $f.FullName -Raw
        # Count module.exports = { ... } patterns
        $m = [regex]::Match($content, 'module\.exports\s*=\s*\{')
        if ($m.Success) { $totalExports += 1 }
        # Count exports.XXX = patterns
        $directMatches = [regex]::Matches($content, 'exports\.(\w+)\s*=')
        $totalExports += $directMatches.Count
        # Count require('./...') patterns using a simple match
        $reqPattern = 'require\(.{1,2}(\./[^)]+).{1,2}\)'
        $reqMatches = [regex]::Matches($content, $reqPattern)
        foreach ($rm in $reqMatches) {
            $reqText = $rm.Groups[1].Value
            if ($reqText -match '^\./') { $allRequires[$reqText] = $f.Name }
        }
    }
    $metrics.namedExportCount = $totalExports
    $metrics.crossWorkerDependencyCount = $allRequires.Count
}

# Count scenarios from acceptance JSON
if (Test-Path $reportsDir) {
    $accFiles = @(Get-ChildItem $reportsDir -Filter "*acceptance*.json")
    foreach ($af in $accFiles) {
        try {
            $acc = Get-Content $af.FullName -Raw | ConvertFrom-Json
            if ($acc.scenarioCount) { $metrics.scenarioCount += $acc.scenarioCount }
            elseif ($acc.scenarios) { $metrics.scenarioCount += @($acc.scenarios).Count }
        } catch {}
    }
}

# Count workers from freeze manifests
$freezeDir = Join-Path $RunDir "worker-freeze-manifests"
if (Test-Path $freezeDir) { $metrics.workerCount = @(Get-ChildItem $freezeDir -Filter "*.freeze.json").Count }

# Task count from contract
$contractPath = Join-Path $RunDir "run-contract.json"
if (Test-Path $contractPath) {
    try {
        $ct = Get-Content $contractPath -Raw | ConvertFrom-Json
        if ($ct.requiredTasks) { $metrics.taskCount = $ct.requiredTasks }
    } catch {}
}

# External packages: check for package.json
$pkgPath = Join-Path $canonicalDir "package.json"
if (Test-Path $pkgPath) {
    try {
        $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
        if ($pkg.dependencies) { $metrics.externalPackageCount = ($pkg.dependencies.PSObject.Properties | Measure-Object).Count }
    } catch {}
}

Write-Output ($metrics | ConvertTo-Json)
