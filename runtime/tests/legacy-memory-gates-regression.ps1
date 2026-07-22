# Regression suite for deprecated legacy memory compatibility wrappers.
# Codex Factory V5 Context Space admission remains authoritative.
# Run with Windows PowerShell 5.1:
#   powershell.exe -NoProfile -ExecutionPolicy Bypass -File runtime/tests/legacy-memory-gates-regression.ps1

$ErrorActionPreference = "Stop"

$runtimeRoot = Split-Path $PSScriptRoot -Parent
$memoryGatePath = Join-Path $runtimeRoot "memory-admission-gate.ps1"
$compressionVerifierPath = Join-Path $runtimeRoot "compression-summary-verifier.ps1"
$staleDetectorPath = Join-Path $runtimeRoot "stale-context-detector.ps1"
$resumeGatePath = Join-Path $runtimeRoot "resume-gate.ps1"

$script:passed = 0
$script:failed = 0
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("codex-factory-legacy-memory-gates-{0}" -f [guid]::NewGuid().ToString("N"))

function Assert-True {
    param([bool]$Condition, [string]$Message)
    if ($Condition) {
        $script:passed++
        Write-Output "PASS: $Message"
    }
    else {
        $script:failed++
        Write-Output "FAIL: $Message"
    }
}

function Write-Utf8Json {
    param([string]$Path, $Value)
    $json = $Value | ConvertTo-Json -Depth 12
    [System.IO.File]::WriteAllText($Path, $json, (New-Object System.Text.UTF8Encoding($false)))
}

function Write-Utf8Text {
    param([string]$Path, [string]$Value)
    [System.IO.File]::WriteAllText($Path, $Value, (New-Object System.Text.UTF8Encoding($false)))
}

function Invoke-JsonScript {
    param([string]$Path, [hashtable]$Parameters)
    $output = @(& $Path @Parameters)
    $json = $output -join [Environment]::NewLine
    try {
        return $json | ConvertFrom-Json
    }
    catch {
        throw "Script '$Path' did not return valid JSON. Output: $json"
    }
}

function New-ValidSummary {
    param($State)
    return [PSCustomObject]@{
        project_id = $State.project_id
        phase = $State.phase
        frozen_pipelines = @($State.frozen_pipelines | ForEach-Object {
            [PSCustomObject]@{ pipeline = $_.pipeline; status = $_.status }
        })
        deprecated_directions = @($State.deprecated_directions | ForEach-Object {
            [PSCustomObject]@{ direction = $_.direction; status = $_.status }
        })
        engine_status = @($State.engine_status | ForEach-Object {
            [PSCustomObject]@{ engine_id = $_.engine_id; status = $_.status }
        })
        regression = [PSCustomObject]@{
            passing = $State.regression_baseline.passing
            total_tests = $State.regression_baseline.total_tests
        }
    }
}

try {
    $null = New-Item -ItemType Directory -Path $tempRoot -Force
    $statePath = Join-Path $tempRoot "trusted-state.json"
    $missingStatePath = Join-Path $tempRoot "missing-state.json"
    $malformedStatePath = Join-Path $tempRoot "malformed-state.json"
    $evidencePath = Join-Path $tempRoot "evidence.txt"
    $emptySummaryPath = Join-Path $tempRoot "empty-summary.json"
    $validSummaryPath = Join-Path $tempRoot "valid-summary.json"

    $state = [PSCustomObject]@{
        project_id = "memory-gate-regression"
        phase = "implementation"
        last_verified = [datetimeoffset]::Now.ToString("o")
        frozen_pipelines = @(
            [PSCustomObject]@{ pipeline = "search"; status = "FROZEN" },
            [PSCustomObject]@{ pipeline = "multi-agent"; status = "ACTIVE" }
        )
        deprecated_directions = @(
            [PSCustomObject]@{ direction = "Independent Search Agent"; status = "FORBIDDEN" }
        )
        engine_status = @(
            [PSCustomObject]@{ engine_id = "semgrep"; status = "AVAILABLE" }
        )
        regression_baseline = [PSCustomObject]@{ passing = 12; total_tests = 12 }
        stale_references = @(
            [PSCustomObject]@{ reference = "obsolete architecture"; current_status = "RETIRED" }
        )
    }
    Write-Utf8Json -Path $statePath -Value $state
    Write-Utf8Text -Path $malformedStatePath -Value '{broken'
    Write-Utf8Text -Path $evidencePath -Value "real evidence artifact"
    Write-Utf8Text -Path $emptySummaryPath -Value '{}'

    $validSummary = New-ValidSummary -State $state
    Write-Utf8Json -Path $validSummaryPath -Value $validSummary

    # Compression summaries must be complete and bound to a valid trusted state.
    $missingStateCompression = Invoke-JsonScript -Path $compressionVerifierPath -Parameters @{
        SummaryJson = ($validSummary | ConvertTo-Json -Depth 12); StatePath = $missingStatePath
    }
    Assert-True (-not [bool]$missingStateCompression.verified) "compression verifier fails closed when trusted state is missing"

    $malformedStateCompression = Invoke-JsonScript -Path $compressionVerifierPath -Parameters @{
        SummaryJson = ($validSummary | ConvertTo-Json -Depth 12); StatePath = $malformedStatePath
    }
    Assert-True (-not [bool]$malformedStateCompression.verified) "compression verifier fails closed when trusted state is malformed"

    $emptyCompression = Invoke-JsonScript -Path $compressionVerifierPath -Parameters @{ SummaryJson = '{}'; StatePath = $statePath }
    Assert-True (-not [bool]$emptyCompression.verified) "empty compression summary cannot vacuously verify"

    $partialCompression = Invoke-JsonScript -Path $compressionVerifierPath -Parameters @{
        SummaryJson = (@{ project_id = $state.project_id; phase = $state.phase } | ConvertTo-Json); StatePath = $statePath
    }
    Assert-True (-not [bool]$partialCompression.verified) "partial compression summary cannot vacuously verify"
    Assert-True ($null -eq $partialCompression.error) "missing optional PSCustomObject properties do not crash compression verification"

    $validCompression = Invoke-JsonScript -Path $compressionVerifierPath -Parameters @{
        SummaryJson = ($validSummary | ConvertTo-Json -Depth 12); StatePath = $statePath
    }
    Assert-True ([bool]$validCompression.verified) "complete compression summary matching trusted state verifies"

    $mismatchedSummary = New-ValidSummary -State $state
    $mismatchedSummary.regression.passing = 11
    $mismatchedCompression = Invoke-JsonScript -Path $compressionVerifierPath -Parameters @{
        SummaryJson = ($mismatchedSummary | ConvertTo-Json -Depth 12); StatePath = $statePath
    }
    Assert-True (-not [bool]$mismatchedCompression.verified) "mismatched regression count blocks compression verification"

    # Memory admission requires a physical evidence file, optional digest match,
    # phase binding, and independent compression verification.
    $evidenceHash = (Get-FileHash -LiteralPath $evidencePath -Algorithm SHA256).Hash
    $validClaim = [PSCustomObject]@{
        source = "report"
        phase = $state.phase
        evidence_path = $evidencePath
        evidence_sha256 = $evidenceHash
        verification_status = "VERIFIED"
        content_summary = "Current implementation result"
        claim_text = "Evidence-bound result"
    }
    $validAdmission = Invoke-JsonScript -Path $memoryGatePath -Parameters @{
        ClaimJson = ($validClaim | ConvertTo-Json -Depth 8); StatePath = $statePath
    }
    Assert-True ([bool]$validAdmission.admitted) "evidence-bound current-phase report is admitted by compatibility gate"

    $missingEvidenceClaim = $validClaim | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $missingEvidenceClaim.evidence_path = Join-Path $tempRoot "does-not-exist.txt"
    $missingEvidenceAdmission = Invoke-JsonScript -Path $memoryGatePath -Parameters @{
        ClaimJson = ($missingEvidenceClaim | ConvertTo-Json -Depth 8); StatePath = $statePath
    }
    Assert-True (-not [bool]$missingEvidenceAdmission.admitted) "nonexistent evidence path is rejected"

    $directoryEvidenceClaim = $validClaim | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $directoryEvidenceClaim.evidence_path = $tempRoot
    $directoryAdmission = Invoke-JsonScript -Path $memoryGatePath -Parameters @{
        ClaimJson = ($directoryEvidenceClaim | ConvertTo-Json -Depth 8); StatePath = $statePath
    }
    Assert-True (-not [bool]$directoryAdmission.admitted) "directory cannot masquerade as evidence file"

    $wrongHashClaim = $validClaim | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $wrongHashClaim.evidence_sha256 = "0" * 64
    $wrongHashAdmission = Invoke-JsonScript -Path $memoryGatePath -Parameters @{
        ClaimJson = ($wrongHashClaim | ConvertTo-Json -Depth 8); StatePath = $statePath
    }
    Assert-True (-not [bool]$wrongHashAdmission.admitted) "evidence SHA-256 mismatch is rejected"

    $wrongPhaseClaim = $validClaim | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $wrongPhaseClaim.phase = "obsolete-phase"
    $wrongPhaseAdmission = Invoke-JsonScript -Path $memoryGatePath -Parameters @{
        ClaimJson = ($wrongPhaseClaim | ConvertTo-Json -Depth 8); StatePath = $statePath
    }
    Assert-True (-not [bool]$wrongPhaseAdmission.admitted) "claim phase mismatch is rejected"

    $staleStatusClaim = $validClaim | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $staleStatusClaim.verification_status = "STALE"
    $staleStatusAdmission = Invoke-JsonScript -Path $memoryGatePath -Parameters @{
        ClaimJson = ($staleStatusClaim | ConvertTo-Json -Depth 8); StatePath = $statePath
    }
    Assert-True (-not [bool]$staleStatusAdmission.admitted) "stale caller status cannot enter trusted memory"

    $staleTextClaim = $validClaim | ConvertTo-Json -Depth 8 | ConvertFrom-Json
    $staleTextClaim.claim_text = "Continue with obsolete architecture"
    $staleTextAdmission = Invoke-JsonScript -Path $memoryGatePath -Parameters @{
        ClaimJson = ($staleTextClaim | ConvertTo-Json -Depth 8); StatePath = $statePath
    }
    Assert-True (-not [bool]$staleTextAdmission.admitted) "trusted-state stale reference blocks memory admission"

    $missingStateAdmission = Invoke-JsonScript -Path $memoryGatePath -Parameters @{
        ClaimJson = ($validClaim | ConvertTo-Json -Depth 8); StatePath = $missingStatePath
    }
    Assert-True (-not [bool]$missingStateAdmission.admitted) "memory admission fails closed without trusted state"

    $fakeVerifiedCompressionClaim = [PSCustomObject]@{
        source = "compression_summary"
        phase = $state.phase
        evidence_path = $emptySummaryPath
        verification_status = "VERIFIED"
        content_summary = "Caller says this is verified"
    }
    $fakeVerifiedAdmission = Invoke-JsonScript -Path $memoryGatePath -Parameters @{
        ClaimJson = ($fakeVerifiedCompressionClaim | ConvertTo-Json -Depth 8); StatePath = $statePath
    }
    Assert-True (-not [bool]$fakeVerifiedAdmission.admitted) "caller-supplied VERIFIED cannot bypass compression verifier"

    $validCompressionClaim = [PSCustomObject]@{
        source = "compression_summary"
        phase = $state.phase
        evidence_path = $validSummaryPath
        evidence_sha256 = (Get-FileHash -LiteralPath $validSummaryPath -Algorithm SHA256).Hash
        verification_status = "VERIFIED"
        content_summary = "Complete trusted-state compression"
    }
    $validCompressionAdmission = Invoke-JsonScript -Path $memoryGatePath -Parameters @{
        ClaimJson = ($validCompressionClaim | ConvertTo-Json -Depth 8); StatePath = $statePath
    }
    Assert-True ([bool]$validCompressionAdmission.admitted) "independently verified compression artifact is admitted"

    # Stale context detection must fail closed and compare both regression values.
    $missingStateDetection = Invoke-JsonScript -Path $staleDetectorPath -Parameters @{
        ContextText = "12/12 PASS"; StatePath = $missingStatePath
    }
    Assert-True (-not [bool]$missingStateDetection.context_trustworthy) "stale detector fails closed without trusted state"

    $malformedStateDetection = Invoke-JsonScript -Path $staleDetectorPath -Parameters @{
        ContextText = "12/12 PASS"; StatePath = $malformedStatePath
    }
    Assert-True (-not [bool]$malformedStateDetection.context_trustworthy) "stale detector fails closed on malformed trusted state"

    $freshDetection = Invoke-JsonScript -Path $staleDetectorPath -Parameters @{
        ContextText = "phase: implementation`n12/12 PASS"; StatePath = $statePath
    }
    Assert-True ([bool]$freshDetection.context_trustworthy) "current phase and full regression count are trustworthy"

    $stalePassingDetection = Invoke-JsonScript -Path $staleDetectorPath -Parameters @{
        ContextText = "11/12 PASS"; StatePath = $statePath
    }
    Assert-True (-not [bool]$stalePassingDetection.context_trustworthy) "stale passing count is detected"

    $staleTotalDetection = Invoke-JsonScript -Path $staleDetectorPath -Parameters @{
        ContextText = "12/13 PASS"; StatePath = $statePath
    }
    Assert-True (-not [bool]$staleTotalDetection.context_trustworthy) "stale total count is detected"

    $deprecatedDetection = Invoke-JsonScript -Path $staleDetectorPath -Parameters @{
        ContextText = "Use Independent Search Agent"; StatePath = $statePath
    }
    Assert-True (-not [bool]$deprecatedDetection.context_trustworthy) "deprecated direction is detected literally"

    $staleReferenceDetection = Invoke-JsonScript -Path $staleDetectorPath -Parameters @{
        ContextText = "Resume obsolete architecture"; StatePath = $statePath
    }
    Assert-True (-not [bool]$staleReferenceDetection.context_trustworthy) "state-provided stale reference is detected"

    # Resume decisions must include phase and all stale checks in the decision.
    $missingStateResume = Invoke-JsonScript -Path $resumeGatePath -Parameters @{
        ResumeContextJson = (@{ phase = $state.phase } | ConvertTo-Json); StatePath = $missingStatePath
    }
    Assert-True (-not [bool]$missingStateResume.allowed) "resume gate returns valid blocked JSON when trusted state is missing"

    $emptyResume = Invoke-JsonScript -Path $resumeGatePath -Parameters @{ ResumeContextJson = '{}'; StatePath = $statePath }
    Assert-True (-not [bool]$emptyResume.allowed) "resume without phase binding is blocked"
    Assert-True ($null -eq $emptyResume.error) "missing resume properties do not cause PSCustomObject property errors"

    $wrongPhaseResume = Invoke-JsonScript -Path $resumeGatePath -Parameters @{
        ResumeContextJson = (@{ phase = "obsolete-phase" } | ConvertTo-Json); StatePath = $statePath
    }
    Assert-True (-not [bool]$wrongPhaseResume.allowed) "phase mismatch participates in resume decision"

    $staleBenchmarkResume = Invoke-JsonScript -Path $resumeGatePath -Parameters @{
        ResumeContextJson = (@{ phase = $state.phase; previous_benchmark = 11; previous_benchmark_total = 12 } | ConvertTo-Json); StatePath = $statePath
    }
    Assert-True (-not [bool]$staleBenchmarkResume.allowed) "stale structured benchmark blocks resume"

    $staleTextResume = Invoke-JsonScript -Path $resumeGatePath -Parameters @{
        ResumeContextJson = (@{ phase = $state.phase; summary_text = "obsolete architecture" } | ConvertTo-Json); StatePath = $statePath
    }
    Assert-True (-not [bool]$staleTextResume.allowed) "stale free-text claim blocks resume"

    $staleStatusResume = Invoke-JsonScript -Path $resumeGatePath -Parameters @{
        ResumeContextJson = (@{ phase = $state.phase; verification_status = "STALE" } | ConvertTo-Json); StatePath = $statePath
    }
    Assert-True (-not [bool]$staleStatusResume.allowed) "stale resume status blocks resume"

    $freshResume = Invoke-JsonScript -Path $resumeGatePath -Parameters @{
        ResumeContextJson = (@{
            phase = $state.phase
            previous_benchmark = 12
            previous_benchmark_total = 12
            summary_text = "Current implementation`n12/12 PASS"
        } | ConvertTo-Json); StatePath = $statePath
    }
    Assert-True ([bool]$freshResume.allowed) "current phase and current evidence allow legacy resume"

    Write-Output "RESULT: $script:passed passed, $script:failed failed"
    if ($script:failed -gt 0) { exit 1 }
}
finally {
    if ([System.IO.Directory]::Exists($tempRoot) -and [System.IO.Path]::GetFileName($tempRoot).StartsWith("codex-factory-legacy-memory-gates-")) {
        [System.IO.Directory]::Delete($tempRoot, $true)
    }
}
