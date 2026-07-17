# new-project-run.ps1 — Phase 6C-U2-A
# One-click wrapper: validate + materialize.
param(
    [Parameter(Mandatory=$true)][string]$ProjectRequest,
    [Parameter(Mandatory=$true)][string]$RunId
)
$ErrorActionPreference = "Stop"
$H = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

Write-Host "=== Phase 6C-U2-A: New Project Run ==="
Write-Host "Project: $ProjectRequest"
Write-Host "Run ID: $RunId"
Write-Host ""

# Step 1: Validate
Write-Host "[1/2] Validating project request..."
$valResult = & "$H\scripts\validate-project-request.ps1" -ProjectRequest $ProjectRequest 2>&1 | ConvertFrom-Json
if ($valResult.verdict -ne "PASS") {
    Write-Host "VALIDATION FAILED:"
    $valResult.errors | ForEach-Object { Write-Host "  $_" }
    exit 1
}
Write-Host "  Validation: PASS ($($valResult.passCount)/$($valResult.totalChecks) checks)"

# Step 2: Materialize
Write-Host "[2/2] Materializing run skeleton..."
$matResult = & "$H\scripts\materialize-project-run.ps1" -ProjectRequest $ProjectRequest -RunId $RunId 2>&1 | ConvertFrom-Json
Write-Host "  Run skeleton: $($matResult.runDir)"
Write-Host "  Tasks: $($matResult.tasksCount)"
Write-Host "  Contract interfaces: $($matResult.contractInterfaceCount)"
Write-Host "  Cross-worker deps: $($matResult.crossWorkerDependencyCount)"
Write-Host "  Contract locked: $($matResult.contractLocked)"

Write-Host ""
Write-Host "=== Phase 6C-U2-A: Complete ==="
Write-Host "Run skeleton ready at: $($matResult.runDir)"
Write-Host "Next: Use Orchestrator + spawn_agent Workers with prompts in prompts/"
exit 0
