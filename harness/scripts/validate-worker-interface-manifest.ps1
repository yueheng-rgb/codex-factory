# validate-worker-interface-manifest.ps1 — Phase 6C-U0-A
# Validates a single worker interface manifest file against WORKER_INTERFACE_MANIFEST_SCHEMA.json.
# READ-ONLY: never modifies the manifest.
param(
    [Parameter(Mandatory=$true)][string]$ManifestPath,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

if (-not (Test-Path $ManifestPath)) {
    [void]$errors.Add("MANIFEST_NOT_FOUND: $ManifestPath")
    $result = @{ verdict="FAIL"; errors=$errors; passes=$passes; checkedManifestPath=$ManifestPath; timestamp=(Get-Date).ToString("o") }
    if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: Manifest not found" }
    exit 1
}

[void]$passes.Add("Manifest file exists: $ManifestPath")

try {
    $manifest = Get-Content $ManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    [void]$errors.Add("MANIFEST_INVALID_JSON: $_")
    exit 1
}

[void]$passes.Add("Manifest is valid JSON")

# Required fields
$requiredFields = @("phase","workerId","taskId","exports","imports")
foreach ($f in $requiredFields) {
    if ($null -ne $manifest.$f) {
        [void]$passes.Add("Field present: $f")
    } else {
        [void]$errors.Add("MISSING_FIELD: $f")
        $exitCode = 1
    }
}

# Exports must be array
if ($manifest.exports -isnot [array]) {
    [void]$errors.Add("EXPORTS_NOT_ARRAY")
    $exitCode = 1
} else {
    [void]$passes.Add("Exports count: $($manifest.exports.Count)")
    $exportReq = @("interfaceId","name","file")
    foreach ($exp in $manifest.exports) {
        foreach ($f in $exportReq) {
            if ($null -eq $exp.$f) {
                [void]$errors.Add("EXPORT_MISSING_FIELD: worker=$($manifest.workerId) missing=$f")
                $exitCode = 1
            }
        }
    }
}

# Imports must be array
if ($manifest.imports -isnot [array]) {
    [void]$errors.Add("IMPORTS_NOT_ARRAY")
    $exitCode = 1
} else {
    [void]$passes.Add("Imports count: $($manifest.imports.Count)")
    $importReq = @("interfaceId","name","file")
    foreach ($imp in $manifest.imports) {
        foreach ($f in $importReq) {
            if ($null -eq $imp.$f) {
                [void]$errors.Add("IMPORT_MISSING_FIELD: worker=$($manifest.workerId) missing=$f")
                $exitCode = 1
            }
        }
    }
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    phase = "Phase 6C-U0-A"
    tool = "validate-worker-interface-manifest"
    verdict = $verdict
    checkedManifestPath = $ManifestPath
    workerId = $manifest.workerId
    taskId = $manifest.taskId
    exportCount = $manifest.exports.Count
    importCount = $manifest.imports.Count
    errorCount = $errors.Count
    errors = $errors
    passes = $passes
    timestamp = (Get-Date).ToString("o")
}
if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "Verdict: $verdict" }
exit $exitCode