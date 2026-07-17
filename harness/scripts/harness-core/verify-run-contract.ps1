# verify-run-contract.ps1 — Phase 6C-H1
param(
    [Parameter(Mandatory=$true)][string]$ContractPath,
    [Parameter(Mandatory=$true)][string]$RunDir
)
$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

if (-not (Test-Path $ContractPath)) {
    [void]$errors.Add("CONTRACT_NOT_FOUND"); $exitCode = 1
} else {
    try { $contract = Get-Content $ContractPath -Raw -Encoding UTF8 | ConvertFrom-Json }
    catch { [void]$errors.Add("CONTRACT_MALFORMED"); $exitCode = 1 }
    
    if ($contract) {
        # Check JS files
        $src = Join-Path $RunDir "canonical-integrated\src"
        $jsCount = if (Test-Path $src) { (Get-ChildItem $src -Filter *.js).Count } else { 0 }
        if ($jsCount -lt $contract.minimumJsFiles) {
            [void]$errors.Add("THRESHOLD_DRIFT: jsFiles=$jsCount contract=$($contract.minimumJsFiles)"); $exitCode = 1
        } else { [void]$passes.Add("JS files: $jsCount >= $($contract.minimumJsFiles)") }
        
        # Check required artifacts
        foreach ($art in $contract.requiredArtifacts) {
            $ap = Join-Path $RunDir $art
            if (-not (Test-Path $ap)) {
                [void]$errors.Add("MISSING_ARTIFACT: $art"); $exitCode = 1
            } else { [void]$passes.Add("Artifact: $art") }
        }
        
        # Check verifier hash lock
        if ($contract.requireVerifierHashLock) {
            $reg = Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..\..")) "governance\harness-core\verifier-registry.json"
            if (-not (Test-Path $reg)) { [void]$errors.Add("VERIFIER_REGISTRY_MISSING"); $exitCode = 1 }
            else { [void]$passes.Add("Verifier registry exists") }
        }
        
        # Check worker freeze
        if ($contract.requireWorkerFreeze) {
            $freezeDir = Join-Path $RunDir "worker-freeze-manifests"
            if (-not (Test-Path $freezeDir) -or (Get-ChildItem $freezeDir -Filter "*.freeze.json").Count -eq 0) {
                [void]$errors.Add("WORKER_FREEZE_MISSING"); $exitCode = 1
            } else { [void]$passes.Add("Worker freeze present") }
        }
        
        # Check integration ledger
        if ($contract.requireIntegrationLedger) {
            $ledger = Join-Path $RunDir "integration-patches.jsonl"
            if (-not (Test-Path $ledger)) { [void]$errors.Add("LEDGER_MISSING"); $exitCode = 1 }
            else { [void]$passes.Add("Integration ledger present") }
        }
        
        # Check RUN_STATE
        if ($contract.requireRunState) {
            $state = Join-Path $RunDir "RUN_STATE.jsonl"
            if (-not (Test-Path $state)) { [void]$errors.Add("RUN_STATE_MISSING"); $exitCode = 1 }
            else { [void]$passes.Add("RUN_STATE present") }
        }
    }
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
@{ verdict=$verdict; timestamp=(Get-Date).ToString("o"); passCount=$passes.Count; failCount=$errors.Count; passes=$passes; errors=$errors } | ConvertTo-Json -Depth 4
exit $exitCode
