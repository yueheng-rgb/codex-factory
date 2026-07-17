# validate-cfp-fail-closed.ps1 — Phase 6C-H1
# Fail-closed CFP adapter. Missing evidence = FAIL_MISSING_EVIDENCE, never PASS.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

$requiredFiles = @{
    "RUN_STATE.jsonl" = "Run state event log"
    "ACCEPTANCE.json" = "Acceptance criteria"
}
$requiredDirs = @{
    "reports" = "Verifier reports"
    "canonical-integrated" = "Integrated source"
}

# Check required files
foreach ($rf in $requiredFiles.Keys) {
    $fp = Join-Path $RunDir $rf
    if (-not (Test-Path $fp)) {
        [void]$errors.Add("FAIL_MISSING_EVIDENCE: $rf ($($requiredFiles[$rf]))"); $exitCode = 1
    } else {
        [void]$passes.Add("Found: $rf")
    }
}

# Check required directories
foreach ($rd in $requiredDirs.Keys) {
    $dp = Join-Path $RunDir $rd
    if (-not (Test-Path $dp)) {
        [void]$errors.Add("FAIL_MISSING_EVIDENCE: $rd ($($requiredDirs[$rd]))"); $exitCode = 1
    } else {
        $hasContent = (Get-ChildItem $dp -Recurse -File).Count -gt 0
        if (-not $hasContent) {
            [void]$errors.Add("FAIL_EMPTY_EVIDENCE: $rd is empty"); $exitCode = 1
        } else {
            [void]$passes.Add("Found content: $rd")
        }
    }
}

# Check worker freeze manifests
$freezeDir = Join-Path $RunDir "worker-freeze-manifests"
if (-not (Test-Path $freezeDir)) {
    [void]$errors.Add("FAIL_MISSING_EVIDENCE: worker-freeze-manifests"); $exitCode = 1
} else {
    $fmCount = (Get-ChildItem $freezeDir -Filter "*.freeze.json").Count
    if ($fmCount -eq 0) {
        [void]$errors.Add("FAIL_EMPTY_EVIDENCE: no freeze manifests"); $exitCode = 1
    } else {
        [void]$passes.Add("Freeze manifests: $fmCount")
    }
}

# Check integration patch ledger
$ledgerPath = Join-Path $RunDir "integration-patches.jsonl"
if (-not (Test-Path $ledgerPath)) {
    [void]$errors.Add("FAIL_MISSING_EVIDENCE: integration-patches.jsonl"); $exitCode = 1
} else {
    [void]$passes.Add("Integration ledger present")
}

# Check verifier registry
$govDir = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..\..")) "governance\harness-core\verifier-registry.json"
if (-not (Test-Path $govDir)) {
    [void]$errors.Add("FAIL_MISSING_EVIDENCE: verifier-registry.json"); $exitCode = 1
} else {
    [void]$passes.Add("Verifier registry present")
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL_MISSING_EVIDENCE" }
@{ verdict=$verdict; timestamp=(Get-Date).ToString("o"); passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors } | ConvertTo-Json -Depth 4
exit $exitCode
