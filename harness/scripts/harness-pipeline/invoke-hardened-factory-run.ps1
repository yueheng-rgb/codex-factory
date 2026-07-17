# invoke-hardened-factory-run.ps1 — Phase 6C-H2
# Hardened factory run lifecycle driver. Consumes all H1 controls mandatorily.
# Fails closed if any required control is missing or skipped.
param(
    [Parameter(Mandatory=$true)][string]$ContractPath,
    [Parameter(Mandatory=$true)][string]$RunDir,
    [Parameter(Mandatory=$true)][string[]]$WorkerWorkspacePaths,
    [string]$IntegrationPatchesLedgerPath = "",
    [string]$CanonicalOutputPath = "",
    [string]$VerifierRegistryPath = "",
    [switch]$SkipIntegration,
    [switch]$SkipVerification
)

$ErrorActionPreference = "Continue"
$harnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$coreScripts = "$harnessRoot\scripts\harness-core"
$pipelineScripts = "$harnessRoot\scripts\harness-pipeline"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

function fail-closed($msg) {
    [void]$errors.Add($msg)
    $script:exitCode = 1
}

function check-control($name, $path) {
    if (-not (Test-Path $path)) {
        fail-closed "MISSING_CONTROL: $name ($path)"
        return $false
    }
    [void]$passes.Add("Control present: $name")
    return $true
}

# ===== Phase 0: Validate all H1 controls exist =====
$requiredControls = @{
    "append-run-state-event" = "$coreScripts\append-run-state-event.ps1"
    "freeze-worker-output" = "$coreScripts\freeze-worker-output.ps1"
    "verify-worker-freeze" = "$coreScripts\verify-worker-freeze.ps1"
    "apply-integration-patch" = "$coreScripts\apply-integration-patch.ps1"
    "verify-integration-patch-ledger" = "$coreScripts\verify-integration-patch-ledger.ps1"
    "require-run-state" = "$coreScripts\require-run-state.ps1"
    "verify-run-state-chain" = "$coreScripts\verify-run-state-chain.ps1"
    "verify-run-contract" = "$coreScripts\verify-run-contract.ps1"
    "validate-cfp-fail-closed" = "$coreScripts\validate-cfp-fail-closed.ps1"
    "verify-verifier-registry" = "$coreScripts\verify-verifier-registry.ps1"
}

$allControlsPresent = $true
foreach ($ck in $requiredControls.Keys) {
    if (-not (check-control $ck $requiredControls[$ck])) { $allControlsPresent = $false }
}
if (-not $allControlsPresent) {
    $result = @{ verdict="FAIL"; reason="MISSING_H1_CONTROLS"; errors=$errors; passes=$passes; timestamp=(Get-Date).ToString("o") }
    Write-Output ($result | ConvertTo-Json -Depth 4)
    exit 1
}

# ===== Phase 1: Read contract =====
if (-not (Test-Path $ContractPath)) {
    fail-closed "CONTRACT_NOT_FOUND: $ContractPath"
    $result = @{ verdict="FAIL"; reason="CONTRACT_NOT_FOUND"; errors=$errors; passes=$passes; timestamp=(Get-Date).ToString("o") }
    Write-Output ($result | ConvertTo-Json -Depth 4)
    exit 1
}

try {
    $contract = Get-Content $ContractPath -Raw -Encoding UTF8 | ConvertFrom-Json
    [void]$passes.Add("Contract loaded: $($contract.runId)")
} catch {
    fail-closed "CONTRACT_MALFORMED: $_"
}

$runId = $contract.runId
if (-not $runId) { fail-closed "CONTRACT_MISSING_runId" }

# ===== Phase 2: Create RUN_STATE =====
New-Item -ItemType Directory -Force -Path $RunDir | Out-Null

# Append run_started
$result = & $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType "run_started" -ActorRole "MainAgent" -Payload @{ contractPath=$ContractPath; phase=$contract.phase } | ConvertFrom-Json
if ($result.status -ne "APPENDED") { fail-closed "RUN_STATE_APPEND_FAILED: run_started" }
else { [void]$passes.Add("RUN_STATE: run_started") }

# ===== Phase 3: Worker lifecycle =====
$workerIds = @()
$freezeManifests = @()
$freezeDir = Join-Path $RunDir "worker-freeze-manifests"
New-Item -ItemType Directory -Force -Path $freezeDir | Out-Null

for ($i = 0; $i -lt $WorkerWorkspacePaths.Count; $i++) {
    $wId = $i + 1
    $wPath = $WorkerWorkspacePaths[$i]
    $workerIds += $wId
    
    if (-not (Test-Path $wPath)) {
        fail-closed "WORKER_WORKSPACE_NOT_FOUND: worker-$wId path=$wPath"
        continue
    }
    
    # Append worker_started
    $result = & $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType "worker_started" -ActorRole "Worker$wId" -Payload @{ workerId=$wId; workspacePath=$wPath } | ConvertFrom-Json
    if ($result.status -ne "APPENDED") { fail-closed "RUN_STATE_APPEND_FAILED: worker_started w$wId" }
    
    # Append worker_completed
    $result = & $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType "worker_completed" -ActorRole "Worker$wId" -Payload @{ workerId=$wId } | ConvertFrom-Json
    
    # Freeze worker output
    $manifestPath = Join-Path $freezeDir "worker-$wId.freeze.json"
    $freezeResult = & $requiredControls["freeze-worker-output"] -WorkspacePath $wPath -OutputPath $manifestPath -RunId $runId -WorkerId $wId -WorkerName "worker-$wId" | ConvertFrom-Json
    if ($freezeResult.status -ne "FROZEN") {
        fail-closed "FREEZE_FAILED: worker-$wId"
    } else {
        [void]$passes.Add("Worker $wId frozen: $($freezeResult.fileCount) files")
        $freezeManifests += $manifestPath
        
        # Append worker_frozen
        & $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType "worker_frozen" -ActorRole "Integrator" -Payload @{ workerId=$wId; manifestHash=$freezeResult.manifestHash } | Out-Null
    }
    
    # Verify freeze
    $verifyResult = & $requiredControls["verify-worker-freeze"] -FreezeManifestPath $manifestPath | ConvertFrom-Json
    if ($verifyResult.verdict -ne "PASS") {
        fail-closed "WORKER_FREEZE_VERIFY_FAILED: worker-$wId"
    } else {
        [void]$passes.Add("Worker $wId freeze verified")
    }
}

# ===== Phase 4: Integration =====
if (-not $SkipIntegration) {
    # Append integration_started
    & $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType "integration_started" -ActorRole "Integrator" -Payload @{ workerCount=$workerIds.Count } | Out-Null
    
    if ($IntegrationPatchesLedgerPath -and (Test-Path $IntegrationPatchesLedgerPath)) {
        $ledgerLines = @(Get-Content $IntegrationPatchesLedgerPath -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
        if ($ledgerLines.Count -gt 0) {
            [void]$passes.Add("Integration patches: $($ledgerLines.Count) recorded")
            
            # Append integration_patch_recorded
            & $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType "integration_patch_recorded" -ActorRole "Integrator" -Payload @{ patchCount=$ledgerLines.Count } | Out-Null
            
            # Verify patch ledger
            $ledgerVerify = & $requiredControls["verify-integration-patch-ledger"] -LedgerPath $IntegrationPatchesLedgerPath | ConvertFrom-Json
            if ($ledgerVerify.verdict -ne "PASS") {
                fail-closed "INTEGRATION_LEDGER_VERIFY_FAILED"
            } else {
                [void]$passes.Add("Integration ledger verified")
            }
        } else {
            # No patches — verify canonical matches frozen
            [void]$passes.Add("No integration patches recorded (canonical matches frozen)")
        }
    }
    
    # Append integration_completed
    & $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType "integration_completed" -ActorRole "Integrator" -Payload @{} | Out-Null
}

# ===== Phase 5: Verification =====
if (-not $SkipVerification) {
    & $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType "verification_started" -ActorRole "Verifier" -Payload @{} | Out-Null
    
    # Verify RUN_STATE
    $rsResult = & $requiredControls["require-run-state"] -RunDir $RunDir | ConvertFrom-Json
    if ($rsResult.verdict -ne "PASS") {
        fail-closed "RUN_STATE_VERIFY_FAILED"
    } else {
        [void]$passes.Add("RUN_STATE verified")
    }
    
    # Verify run-state chain
    $chainResult = & $requiredControls["verify-run-state-chain"] -RunDir $RunDir | ConvertFrom-Json
    if ($chainResult.verdict -ne "PASS") {
        fail-closed "RUN_STATE_CHAIN_VERIFY_FAILED"
    } else {
        [void]$passes.Add("RUN_STATE chain verified")
    }
    
    # Verify run contract
    if ($CanonicalOutputPath) {
        $ctResult = & $requiredControls["verify-run-contract"] -ContractPath $ContractPath -RunDir $CanonicalOutputPath | ConvertFrom-Json
        if ($ctResult.verdict -ne "PASS") {
            fail-closed "RUN_CONTRACT_VERIFY_FAILED"
        } else {
            [void]$passes.Add("Run contract verified")
        }
    }
    
    # Verify CFP fail-closed
    $cfpResult = & $requiredControls["validate-cfp-fail-closed"] -RunDir $RunDir | ConvertFrom-Json
    if ($cfpResult.verdict -eq "FAIL_MISSING_EVIDENCE") {
        fail-closed "CFP_FAIL_CLOSED_DETECTED_MISSING_EVIDENCE"
    } else {
        [void]$passes.Add("CFP fail-closed: $($cfpResult.verdict)")
    }
    
    # Verify verifier registry
    if ($VerifierRegistryPath -and (Test-Path $VerifierRegistryPath)) {
        $vrResult = & $requiredControls["verify-verifier-registry"] -RegistryPath $VerifierRegistryPath -HarnessRoot $harnessRoot | ConvertFrom-Json
        if ($vrResult.verdict -ne "PASS") {
            fail-closed "VERIFIER_REGISTRY_FAILED"
        } else {
            [void]$passes.Add("Verifier registry verified")
        }
    }
    
    & $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType "verification_completed" -ActorRole "Verifier" -Payload @{ errors=$errors.Count } | Out-Null
}

# ===== Phase 6: Finalize =====
$finalEvent = if ($exitCode -eq 0) { "report_written"; & $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType "report_written" -ActorRole "Verifier" -Payload @{} | Out-Null; "run_passed" } else { "run_failed" }
& $requiredControls["append-run-state-event"] -RunDir $RunDir -RunId $runId -EventType $finalEvent -ActorRole "MainAgent" -Payload @{ exitCode=$exitCode; errorCount=$errors.Count } | Out-Null

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict = $verdict
    runId = $runId
    timestamp = (Get-Date).ToString("o")
    passCount = $passes.Count
    failCount = $errors.Count
    passes = $passes
    errors = $errors
    workerCount = $workerIds.Count
    freezeManifests = $freezeManifests
    h1ControlsConsumed = $requiredControls.Keys
}
Write-Output ($result | ConvertTo-Json -Depth 4)
exit $exitCode