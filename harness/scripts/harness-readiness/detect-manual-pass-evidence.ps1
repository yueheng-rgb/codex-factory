# detect-manual-pass-evidence.ps1 — Phase 6C-H9-P2 Part E
# Detects suspicious manually written PASS evidence.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$findings = @()
$ts = (Get-Date).ToString("o")
$manualPassRiskDetected = $false

# Scan all JSON files in the run directory
$jsonFiles = @(Get-ChildItem $RunDir -Recurse -Filter "*.json" -File -ErrorAction SilentlyContinue)

foreach ($jf in $jsonFiles) {
    try {
        $content = Get-Content $jf.FullName -Raw
        $obj = $content | ConvertFrom-Json
    } catch { continue }

    $relPath = $jf.FullName.Replace($RunDir, "").TrimStart("\","/")
    $signals = @()
    
    # Signal 1: Has PASS verdict/status but no command
    $isPass = ($obj.verdict -eq "PASS" -or $obj.status -eq "PASS" -or $obj.readinessVerdict -eq "PASS")
    $hasCommand = ($obj.command -or $obj.runnerCommand -or $obj.scriptPath -or $obj.validatorScript)
    if ($isPass -and -not $hasCommand) {
        $signals += "NO_COMMAND: PASS verdict with no command/script path"
    }
    
    # Signal 2: PASS evidence with no transcript
    $hasTranscript = ($obj.transcript -or $obj.transcriptPath -or $obj.transcriptFile)
    if ($isPass -and -not $hasTranscript -and $relPath -match "readiness|pre-spawn|validation|acceptance") {
        $signals += "NO_TRANSCRIPT: PASS in $relPath with no transcript"
    }
    
    # Signal 3: Pre-spawn validation with no validator script output
    if ($relPath -match "pre-spawn" -and $obj.verdict -eq "PASS" -and -not $obj.validatorOutput) {
        $signals += "NO_VALIDATOR_OUTPUT: Pre-spawn PASS with no validator script output"
    }
    
    # Signal 4: Readiness result with no verify-dry18-readiness trace
    if ($relPath -match "readiness" -and $obj.readinessVerdict -eq "PASS" -and -not $obj.verifierScript -and -not $obj.verifiedBy) {
        $signals += "NO_READINESS_VERIFIER: Readiness PASS with no verify-dry18-readiness trace"
    }
    
    # Signal 5: Audit PASS with no audit-run transcript
    if ($relPath -match "audit" -and $obj.verdict -eq "PASS" -and -not $obj.auditScript) {
        $signals += "NO_AUDIT_TRANSCRIPT: Audit PASS with no audit-run trace"
    }
    
    # Signal 6: Acceptance PASS with no runner info
    if ($relPath -match "acceptance" -and ($obj.verdict -eq "PASS" -or $obj.status -eq "PASS")) {
        $hasRunner = ($obj.runner -or $obj.runnerCommand -or $obj.runnerScript)
        $hasExitCode = ($obj.exitCode -ne $null -or ($obj.runner -and $obj.runner.exitCode -ne $null))
        if (-not $hasRunner) { $signals += "NO_RUNNER: Acceptance PASS with no runner info" }
        if (-not $hasExitCode) { $signals += "NO_EXIT_CODE: Acceptance PASS with no exit code" }
    }
    
    # Signal 7: Complexity PASS with no derived metrics
    if ($relPath -match "complexity" -and $obj.verdict -eq "PASS" -and -not $obj.derivedMetrics) {
        $signals += "NO_DERIVED_METRICS: Complexity PASS with no derived metrics"
    }
    
    # Signal 8: JSON file with only verdict/status + timestamp (extremely minimal)
    $keyCount = ($obj.PSObject.Properties | Measure-Object).Count
    if ($isPass -and $keyCount -le 5 -and $relPath -match "validation|verdict|result") {
        $signals += "MINIMAL_JSON: Only $keyCount keys ($relPath)"
    }
    
    # Signal 9: Hardcoded PASS patterns in JSON
    $rawContent = Get-Content $jf.FullName -Raw
    if ($rawContent -match '"verdict"\s*:\s*"PASS"' -and $keyCount -le 8 -and -not $hasCommand) {
        $signals += "HARDCODED_PASS_PATTERN: PASS verdict in minimal JSON with no execution evidence"
    }
    
    if ($signals.Count -gt 0) {
        $findings += @{
            file = $relPath
            signals = $signals
            keyCount = $keyCount
            hasCommand = $hasCommand
            hasTranscript = $hasTranscript
        }
        $manualPassRiskDetected = $true
    }
}

$classification = if ($manualPassRiskDetected) { "FAIL_MISSING_EVIDENCE" } else { "PASS" }
$verdict = if ($manualPassRiskDetected) { "FAIL" } else { "PASS" }

$result = @{
    verdict = $verdict
    classification = $classification
    manualPassRiskDetected = $manualPassRiskDetected
    findings = $findings
    findingCount = $findings.Count
    filesScanned = $jsonFiles.Count
    checkedAt = $ts
}
Write-Output ($result | ConvertTo-Json -Depth 4)
exit $(if ($manualPassRiskDetected) { 1 } else { 0 })
