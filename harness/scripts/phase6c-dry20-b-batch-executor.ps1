# DRY20-B Live Negative Controls Batch Executor
param([switch]$DryRun)

$ErrorActionPreference = "Continue"
$RepoRoot = Resolve-Path "$PSScriptRoot\.."
$SrcDir = "$RepoRoot\runs\dry20-vendor-procurement-risk-app\canonical-integrated\src"
$RunDir = "$RepoRoot\runs\dry20-b-live-negative-controls"
$AccRunner = "$SrcDir\acceptance-runner.js"
$ManifestDir = "$RunDir\fault-manifests"
$AcceptDir = "$RunDir\acceptance-runs"
$TranscriptDir = "$RunDir\transcripts"
$EvidenceDir = "$RunDir\evidence"
$ClassDir = "$RunDir\classifications"

@($ManifestDir, $AcceptDir, $TranscriptDir, $EvidenceDir, $ClassDir) | ForEach-Object { New-Item -ItemType Directory -Path $_ -Force | Out-Null }

$runnerHash = (Get-FileHash $AccRunner -Algorithm SHA256).Hash
$parentHash = @{ acceptanceRunnerSHA256 = $runnerHash; recordedAt = (Get-Date -Format "o"); parentPhase = "DRY20-A-P4"; parentStatus = "PASS" } | ConvertTo-Json
Set-Content "$RunDir\parent-baseline.json" -Value $parentHash -NoNewline
Write-Host "Parent baseline: runner SHA256 = $runnerHash"

Write-Host "=== PARENT POSITIVE RECHECK ==="
Push-Location $SrcDir
$parentOut = & node acceptance-runner.js 2>&1 | Out-String
Pop-Location
$parentPass = ($parentOut -match "Verdict: ALL_PASSED") -and ($parentOut -match "Passed: 42")
Write-Host "Parent recheck: $(if($parentPass){"PASS"}else{"FAIL"})"
$parentOut | Set-Content "$RunDir\parent-positive-recheck.txt" -NoNewline
if (-not $parentPass) { Write-Host "FATAL: Parent positive recheck failed"; exit 1 }

$negatives = @(
  # GROUP A
  @{id="N01";group="A";name="missing-acceptance-runner";type="CONTROL_NEGATIVE";faultFile="acceptance-runner.js";faultType="file_missing";expectedClass="FAIL_CONTROL_NEGATIVE";desc="Acceptance runner removed"},
  @{id="N02";group="A";name="corrupt-scenario-manifest";type="CONTROL_NEGATIVE";faultFile="scenario-manifest.json";faultType="corrupt_json";expectedClass="FAIL_CONTROL_NEGATIVE";desc="Scenario manifest corrupted"},
  @{id="N03";group="A";name="missing-canonical-index";type="CONTROL_NEGATIVE";faultFile="canonical-index.js";faultType="file_missing";expectedClass="FAIL_CONTROL_NEGATIVE";desc="Canonical index removed"},
  @{id="N04";group="A";name="syntax-error-worker-module";type="CONTROL_NEGATIVE";faultFile="vendorModel.js";faultType="syntax_error";expectedClass="FAIL_CONTROL_NEGATIVE";desc="Syntax error in vendor model"},
  @{id="N05";group="A";name="corrupt-acceptance-runner";type="CONTROL_NEGATIVE";faultFile="acceptance-runner.js";faultType="truncated";expectedClass="FAIL_CONTROL_NEGATIVE";desc="Acceptance runner truncated"},
  @{id="N06";group="A";name="missing-required-export";type="CONTROL_NEGATIVE";faultFile="vendorModel.js";faultType="remove_export";expectedClass="FAIL_CONTROL_NEGATIVE";desc="Exports removed from vendor model"}
)

