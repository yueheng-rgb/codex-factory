# compare-worker-manifest-to-source.ps1 鈥?Phase 6C-U0-C
# Compares Worker-submitted interface manifest against source-derived manifest.
# Detects dishonesty: Worker claims export A but source code actually exports B.
param(
    [Parameter(Mandatory=$true)][string]$WorkerManifestPath,
    [Parameter(Mandatory=$true)][string]$SourceManifestPath,
    [Parameter(Mandatory=$true)][string]$OutputReportPath,
    [string]$Phase = "Phase 6C-U0-C"
)


# Normalize file paths for comparison (strip SourceRoot prefix, normalize slashes)
function Normalize-FilePath($path, $sourceRoot) {
    if (-not $path) { return $path }
    $normalized = $path.Replace('\', '/').Replace('//', '/')
    if ($sourceRoot) {
        $srNorm = $sourceRoot.Replace('\', '/').Replace('//', '/').TrimEnd('/') + '/'
        if ($normalized.StartsWith($srNorm, [StringComparison]::OrdinalIgnoreCase)) {
            $normalized = $normalized.Substring($srNorm.Length)
        }
    }
    return $normalized.TrimStart('/')
}$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$mismatches = [System.Collections.ArrayList]::new()
$exitCode = 0

# Load manifests
if (-not (Test-Path $WorkerManifestPath)) {
    [void]$errors.Add("WORKER_MANIFEST_NOT_FOUND: $WorkerManifestPath")
    $result = @{ verdict="FAIL"; errors=$errors; passes=$passes; timestamp=(Get-Date).ToString("o") }
    [System.IO.File]::WriteAllText($OutputReportPath, ($result | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
    exit 1
}
if (-not (Test-Path $SourceManifestPath)) {
    [void]$errors.Add("SOURCE_MANIFEST_NOT_FOUND: $SourceManifestPath")
    $result = @{ verdict="FAIL"; errors=$errors; passes=$passes; timestamp=(Get-Date).ToString("o") }
    [System.IO.File]::WriteAllText($OutputReportPath, ($result | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
    exit 1
}

try { $workerManifest = Get-Content $WorkerManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json }
catch { [void]$errors.Add("WORKER_MANIFEST_INVALID_JSON"); exit 1 }

try { $sourceManifest = Get-Content $SourceManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json }
catch { [void]$errors.Add("SOURCE_MANIFEST_INVALID_JSON"); exit 1 }

[void]$passes.Add("Both manifests loaded: worker=$($workerManifest.workerId) source=$($sourceManifest.workerId)")

# --- Check exports ---
# Every export in worker manifest must exist in source manifest
foreach ($we in $workerManifest.exports) {
    $found = $false
    foreach ($se in $sourceManifest.exports) {
        $seFileNorm = Normalize-FilePath $se.file $sourceManifest.sourceRoot; $weFileNorm = Normalize-FilePath $we.file $null; if ($se.name -eq $we.name -and $seFileNorm -eq $weFileNorm) {
            $found = $true
            break
        }
    }
    if ($found) {
        [void]$passes.Add("Export verified: $($we.name) in $($we.file)")
    } else {
        $msg = "EXPORT_MISMATCH: worker=$($workerManifest.workerId) claims export name='$($we.name)' file='$($we.file)' but NOT found in source code"
        [void]$mismatches.Add(@{type="export_mismatch"; workerClaimed=$we.name; workerClaimedFile=$we.file; sourceExports=@($sourceManifest.exports | ForEach-Object { "$($_.name)@$($_.file)" }); detail=$msg })
        [void]$errors.Add($msg)
        $exitCode = 1
    }
}

# Every export in source manifest should be in worker manifest (completeness check)
# BUT: skip exports where the worker imports the same name (dependency, not ownership)
$workerImportNames = @($workerManifest.imports | ForEach-Object { $_.name })
foreach ($se in $sourceManifest.exports) {
    $found = $false
    foreach ($we in $workerManifest.exports) {
        $seFileNorm2 = Normalize-FilePath $se.file $sourceManifest.sourceRoot; $weFileNorm2 = Normalize-FilePath $we.file $null; if ($we.name -eq $se.name -and $weFileNorm2 -eq $seFileNorm2) {
            $found = $true
            break
        }
    }
    if (-not $found -and $workerImportNames -notcontains $se.name) {       $msg = "EXPORT_UNREPORTED: worker=$($workerManifest.workerId) source exports name='$($se.name)' file='$($se.file)' but NOT declared in worker manifest"
        [void]$mismatches.Add(@{type="export_unreported"; sourceExport=$se.name; sourceFile=$se.file; detail=$msg})
        [void]$errors.Add($msg)
        $exitCode = 1
    }
}

# --- Check imports (match by name only — file differs between worker/submitted and source/extracted) ---
foreach ($wi in $workerManifest.imports) {
    $found = $false
    foreach ($si in $sourceManifest.imports) {
        if ($si.name -eq $wi.name) {
            $found = $true
            break
        }
    }
    if ($found) {
        [void]$passes.Add("Import verified: $($wi.name) in $($wi.file)")
    } else {
        $msg = "IMPORT_MISMATCH: worker=$($workerManifest.workerId) claims import name='$($wi.name)' file='$($wi.file)' but NOT found in source code"
        [void]$mismatches.Add(@{type="import_mismatch"; workerClaimed=$wi.name; workerClaimedFile=$wi.file; sourceImports=@($sourceManifest.imports | ForEach-Object { "$($_.name)@$($_.file)" }); detail=$msg })
        [void]$errors.Add($msg)
        $exitCode = 1
    }
}

foreach ($si in $sourceManifest.imports) {
    $found = $false
    foreach ($wi in $workerManifest.imports) {
        if ($wi.name -eq $si.name) {
            $found = $true
            break
        }
    }
    if (-not $found) {
        $msg = "IMPORT_UNREPORTED: worker=$($workerManifest.workerId) source imports name='$($si.name)' file='$($si.file)' but NOT declared in worker manifest"
        [void]$mismatches.Add(@{type="import_unreported"; sourceImport=$si.name; sourceFile=$si.file; detail=$msg})
        [void]$errors.Add($msg)
        $exitCode = 1
    }
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$report = @{
    phase = $Phase
    reportType = "manifest-honesty-report"
    verdict = $verdict
    workerId = $workerManifest.workerId
    taskId = $workerManifest.taskId
    workerManifestPath = $WorkerManifestPath
    sourceManifestPath = $SourceManifestPath
    mismatchCount = $mismatches.Count
    mismatches = @($mismatches)
    errors = @($errors)
    passes = @($passes)
    timestamp = (Get-Date).ToString("o")
}

$outputDir = Split-Path $OutputReportPath -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}
[System.IO.File]::WriteAllText($OutputReportPath, ($report | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
Write-Output ($report | ConvertTo-Json -Depth 4)
exit $exitCode