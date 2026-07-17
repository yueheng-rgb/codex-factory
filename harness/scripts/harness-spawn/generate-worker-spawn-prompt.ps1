# generate-worker-spawn-prompt.ps1 — Phase 6C-H7
# Generates a rich worker spawn prompt from a validated pre-spawn contract.
param(
    [Parameter(Mandatory=$true)][string]$WorkerContractPath,
    [string]$OutputPath = "",
    [switch]$Json
)
$ErrorActionPreference = "Continue"

if (-not (Test-Path $WorkerContractPath)) { Write-Output (@{ok=$false; error="Worker contract not found"} | ConvertTo-Json); exit 1 }
$wc = Get-Content $WorkerContractPath -Raw | ConvertFrom-Json

$prompt = @"
## Worker $($wc.workerId): $($wc.workerRole)

**Mission:** $($wc.workerMission)

### Owned Files
$(($wc.ownedFilesPlanned | ForEach-Object { "- $_" }) -join "`n")

### Forbidden Files
$(($wc.forbiddenFiles | ForEach-Object { "- $_" }) -join "`n")

### Required Exports
$(($wc.requiredExports | ForEach-Object { "- $_" }) -join "`n")

### Required Evidence Outputs
$(($wc.requiredEvidenceOutputs | ForEach-Object { "- $_" }) -join "`n")

### Domain Entities
$(($wc.requiredDomainEntities | ForEach-Object { "- $_" }) -join "`n")

### Business Rules
$(($wc.requiredBusinessRules | ForEach-Object { "- $_" }) -join "`n")

### Required Scenarios
$(($wc.requiredScenarios | ForEach-Object { "- $_" }) -join "`n")

### Required Negative Controls
$(($wc.requiredNegativeControls | ForEach-Object { "- $_" }) -join "`n")

### Edge Cases
$(($wc.edgeCasesRequired | ForEach-Object { "- $_" }) -join "`n")

### Failure Modes
$(($wc.failureModesRequired | ForEach-Object { "- $_" }) -join "`n")

### Cross-Worker Dependencies
- **Consumers (depends on me):** $(if ($wc.expectedCrossWorkerConsumers) { $wc.expectedCrossWorkerConsumers -join ', ' } else { 'none' })
- **Providers (I depend on):** $(if ($wc.expectedCrossWorkerProviders) { $wc.expectedCrossWorkerProviders -join ', ' } else { 'none' })

### Complexity Budget
- Source files: $($wc.complexityContribution.sourceFiles)
- Exports: $($wc.complexityContribution.exports)
- Cross-worker deps: $($wc.complexityContribution.crossWorkerDeps)
- Scenarios: $($wc.complexityContribution.scenarios)

### Acceptance Layers
$(($wc.acceptanceLayersTouched | ForEach-Object { "- $_" }) -join "`n")

### Contract Rules
- Freeze required: $($wc.freezeRequired)
- No external packages: $($wc.noExternalPackages)
- Integration contract: $($wc.integrationContract)
- Minimum behavioral responsibilities: $($wc.minimumBehavioralResponsibilities)
"@

$result = @{
    workerId=$wc.workerId
    prompt=$prompt
    hasOwnedFiles=($wc.ownedFilesPlanned.Count -gt 0)
    hasForbiddenFiles=($wc.forbiddenFiles.Count -gt 0)
    hasExports=($wc.requiredExports.Count -gt 0)
    hasEvidence=($wc.requiredEvidenceOutputs.Count -gt 0)
    hasScenarios=($wc.requiredScenarios.Count -gt 0)
    hasFailureModes=($wc.failureModesRequired.Count -gt 0)
    hasEdgeCases=($wc.edgeCasesRequired.Count -gt 0)
    timestamp=(Get-Date).ToString("o")
}

if ($OutputPath) { $prompt | Out-File -Encoding utf8 -LiteralPath $OutputPath }
Write-Output ($result | ConvertTo-Json -Depth 2)
exit 0
