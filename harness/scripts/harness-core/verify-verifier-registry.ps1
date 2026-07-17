# verify-verifier-registry.ps1 — Phase 6C-H1
# Verifies all registered verifier scripts against their registered hashes.
param(
    [Parameter(Mandatory=$true)][string]$RegistryPath,
    [string]$HarnessRoot = ""
)
$ErrorActionPreference = "Continue"
if (-not $HarnessRoot) { $HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..") }
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

if (-not (Test-Path $RegistryPath)) {
    $result = @{ verdict="FAIL"; reason="REGISTRY_NOT_FOUND"; timestamp=(Get-Date).ToString("o"); errors=@("Registry file not found: $RegistryPath"); passes=@() }
    Write-Output ($result | ConvertTo-Json -Depth 4)
    exit 1
}
[void]$passes.Add("Registry found: $RegistryPath")

try { $registry = Get-Content $RegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json }
catch { [void]$errors.Add("REGISTRY_MALFORMED: $_"); $exitCode = 1 }

if ($registry.registry.Count -eq 0) {
    [void]$errors.Add("REGISTRY_EMPTY"); $exitCode = 1
} else {
    [void]$passes.Add("Registry entries: $($registry.registry.Count)")
    foreach ($entry in $registry.registry) {
        $fullPath = Join-Path $HarnessRoot $entry.scriptPath
        if (-not (Test-Path $fullPath)) {
            [void]$errors.Add("SCRIPT_MISSING: $($entry.scriptPath)"); $exitCode = 1; continue
        }
        $currentHash = (Get-FileHash $fullPath -Algorithm SHA256).Hash
        if ($currentHash -ne $entry.sha256) {
            [void]$errors.Add("HASH_MISMATCH: $($entry.scriptPath) registered=$($entry.sha256) current=$currentHash"); $exitCode = 1
        } else {
            [void]$passes.Add("Hash match: $($entry.scriptPath)")
        }
    }
}

# Verify hash chain
$prevHash = "GENESIS"
for ($i = 0; $i -lt $registry.registry.Count; $i++) {
    $e = $registry.registry[$i]
    if ($e.previousHash -ne $prevHash) {
        [void]$errors.Add("CHAIN_BREAK at entry $i"); $exitCode = 1
    }
    $prevHash = $e.registryEntryHash
}
if ($registry.registry.Count -gt 0) { [void]$passes.Add("Hash chain valid") }

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{ verdict=$verdict; timestamp=(Get-Date).ToString("o"); totalEntries=$registry.registry.Count; passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors }
Write-Output ($result | ConvertTo-Json -Depth 4)
exit $exitCode
