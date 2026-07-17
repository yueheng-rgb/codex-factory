# check-worker-simplicity-risk.ps1 — Phase 6C-H7
# Evaluates a worker contract for simplicity risk before spawn.
param(
    [Parameter(Mandatory=$true)][string]$WorkerContractPath,
    [switch]$Json
)
$ErrorActionPreference = "Continue"

if (-not (Test-Path $WorkerContractPath)) { Write-Output (@{riskLevel="ERROR"; reason="Contract not found"; spawnAllowed=$false} | ConvertTo-Json); exit 1 }
$wc = Get-Content $WorkerContractPath -Raw | ConvertFrom-Json

$score = 0
$reasons = @()

# Structural simplicity checks
if ($wc.requiredExports.Count -le 1) { $score += 3; $reasons += "Very few exports ($($wc.requiredExports.Count))" }
elseif ($wc.requiredExports.Count -le 3) { $score += 2; $reasons += "Low exports ($($wc.requiredExports.Count))" }

if ($wc.ownedFilesPlanned.Count -le 1) { $score += 3; $reasons += "Very few owned files ($($wc.ownedFilesPlanned.Count))" }
elseif ($wc.ownedFilesPlanned.Count -le 3) { $score += 1; $reasons += "Low file count ($($wc.ownedFilesPlanned.Count))" }

if ($wc.requiredDomainEntities.Count -eq 0 -and $wc.workerRole -notmatch 'audit|report|cli') { $score += 2; $reasons += "No domain entity responsibility" }

if ($wc.requiredBusinessRules.Count -eq 0 -and $wc.workerRole -notmatch 'audit|report') { $score += 2; $reasons += "No business rule responsibility" }

if ($wc.requiredScenarios.Count -le 1) { $score += 2; $reasons += "Very few scenarios ($($wc.requiredScenarios.Count))" }

if ($wc.failureModesRequired.Count -le 1) { $score += 2; $reasons += "Very few failure modes ($($wc.failureModesRequired.Count))" }

if ($wc.edgeCasesRequired.Count -le 1) { $score += 1; $reasons += "Few edge cases ($($wc.edgeCasesRequired.Count))" }

if ($wc.minimumBehavioralResponsibilities -lt 4) { $score += 2; $reasons += "Low behavioral responsibilities ($($wc.minimumBehavioralResponsibilities))" }

if ($wc.expectedCrossWorkerProviders.Count -eq 0 -and $wc.expectedCrossWorkerConsumers.Count -eq 0) { $score += 3; $reasons += "No cross-worker dependencies" }

if ($wc.requiredNegativeControls.Count -eq 0) { $score += 3; $reasons += "No negative controls" }

if ($wc.workerMission.Length -lt 40) { $score += 1; $reasons += "Mission text short ($($wc.workerMission.Length) chars)" }

# Risk classification
$riskLevel = if ($score -ge 8) { "BLOCK" } elseif ($score -ge 5) { "HIGH" } elseif ($score -ge 3) { "MEDIUM" } else { "LOW" }
$spawnAllowed = ($riskLevel -eq "LOW" -or $riskLevel -eq "MEDIUM")

$result = @{
    riskLevel=$riskLevel; score=$score; spawnAllowed=$spawnAllowed
    reasons=$reasons
    recommendedContractFixes=@(if ($riskLevel -eq "BLOCK") { "Increase exports/files/scenarios/negative-controls" } elseif ($riskLevel -eq "HIGH") { "Add cross-worker deps, more failure modes, more scenarios" } else { @() })
    timestamp=(Get-Date).ToString("o")
}
Write-Output ($result | ConvertTo-Json -Depth 3)
if ($riskLevel -eq "BLOCK") { exit 1 } else { exit 0 }
