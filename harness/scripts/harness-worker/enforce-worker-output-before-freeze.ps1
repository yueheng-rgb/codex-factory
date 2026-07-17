# enforce-worker-output-before-freeze.ps1 - Phase 6C-H8
# Blocks freeze/integration until worker output passes contract conformance.
param(
    [Parameter(Mandatory=$true)][string]$WorkerContractPath,
    [Parameter(Mandatory=$true)][string]$WorkerWorkspacePath,
    [Parameter(Mandatory=$true)][string]$RunStatePath,
    [switch]$DryRun
)
$ErrorActionPreference = "Continue"
$verifier = "$PSScriptRoot\verify-worker-output-contract.ps1"
$ts = (Get-Date).ToString("o")

$raw = & powershell -NoProfile -File $verifier -WorkerContractPath $WorkerContractPath -WorkerWorkspacePath $WorkerWorkspacePath 2>$null | Out-String
$result = try { $raw | ConvertFrom-Json } catch { $null }
if (-not $result) {
    $event = @{timestamp=$ts; event="worker_output_rejected"; workerContract=$WorkerContractPath; workerWorkspace=$WorkerWorkspacePath; reason="Verification failed"; details="Analyzer/verifier returned null"}
    Add-Content -Path $RunStatePath -Value ($event | ConvertTo-Json -Compress)
    Write-Output (@{verdict="REJECTED"; freezeAllowed=$false; reason="Verification FAIL"; timestamp=$ts} | ConvertTo-Json)
    exit 1
}

if ($result.verdict -eq "PASS") {
    $event = @{timestamp=$ts; event="worker_output_verified"; workerContract=$WorkerContractPath; workerWorkspace=$WorkerWorkspacePath; classification=$result.classification}
    Add-Content -Path $RunStatePath -Value ($event | ConvertTo-Json -Compress)
    Write-Output (@{verdict="VERIFIED"; freezeAllowed=$true; workerId=(Get-Content $WorkerContractPath -Raw | ConvertFrom-Json).workerId; timestamp=$ts} | ConvertTo-Json)
    exit 0
} else {
    $event = @{timestamp=$ts; event="worker_output_rejected"; workerContract=$WorkerContractPath; workerWorkspace=$WorkerWorkspacePath; reason="Contract conformance FAIL"; failedChecks=$result.failedChecks; classification=$result.classification}
    Add-Content -Path $RunStatePath -Value ($event | ConvertTo-Json -Compress)
    Write-Output (@{verdict="REJECTED"; freezeAllowed=$false; reason="Contract conformance FAIL"; failedChecks=$result.failedChecks; classification=$result.classification; timestamp=$ts} | ConvertTo-Json)
    exit 1
}
