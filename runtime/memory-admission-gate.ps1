# Deprecated compatibility wrapper. Codex Factory V5 Context Space and its
# admission pipeline are authoritative. This gate fail-closes for legacy
# trusted-project-state callers and does not promote data into V5 memory.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ClaimJson,
    [string]$StatePath = "C:\Codex_App_Factory\outputs\trusted-project-state.json"
)

$ErrorActionPreference = "Stop"

$DEPRECATED_PATTERNS = @(
    "Independent Search Agent", "Dual Search Channel", "Search Agent as Future Default",
    "Implementer direct search", "chat URL extraction", "mock/dry_run",
    "Firecrawl as canonical search", "multi-agent default mode"
)

function Test-ObjectProperty {
    param($InputObject, [string]$Name)
    return ($null -ne $InputObject -and $null -ne $InputObject.PSObject.Properties[$Name])
}

function Get-ObjectPropertyValue {
    param($InputObject, [string]$Name, $Default = $null)
    if (Test-ObjectProperty -InputObject $InputObject -Name $Name) {
        return $InputObject.PSObject.Properties[$Name].Value
    }
    return $Default
}

function Read-TrustedStateStrict {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Trusted state file not found: $Path"
    }
    $raw = [System.IO.File]::ReadAllText((Resolve-Path -LiteralPath $Path).Path)
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Trusted state file is empty: $Path"
    }
    try { $trustedState = $raw | ConvertFrom-Json }
    catch { throw "Trusted state is malformed JSON: $($_.Exception.Message)" }

    foreach ($requiredName in @("project_id", "phase", "last_verified", "deprecated_directions", "stale_references")) {
        if (-not (Test-ObjectProperty -InputObject $trustedState -Name $requiredName)) {
            throw "Trusted state is missing required property '$requiredName'"
        }
    }
    foreach ($requiredTextName in @("project_id", "phase", "last_verified")) {
        if ([string]::IsNullOrWhiteSpace([string](Get-ObjectPropertyValue -InputObject $trustedState -Name $requiredTextName -Default ""))) {
            throw "Trusted state property '$requiredTextName' is empty"
        }
    }
    try { $null = [datetimeoffset]::Parse([string](Get-ObjectPropertyValue -InputObject $trustedState -Name "last_verified")) }
    catch { throw "Trusted state last_verified is not a valid timestamp" }
    return $trustedState
}

function Add-Check {
    param($Result, [string]$Name, [string]$Status, [string]$Detail)
    $Result.checks += [PSCustomObject]@{ check = $Name; result = "$Status`: $Detail" }
}

function Test-ContainsLiteral {
    param([string]$Text, [string]$Needle)
    if ([string]::IsNullOrWhiteSpace($Text) -or [string]::IsNullOrWhiteSpace($Needle)) { return $false }
    return ($Text.IndexOf($Needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
}

function Resolve-EvidenceFile {
    param([string]$EvidencePath)
    if ([string]::IsNullOrWhiteSpace($EvidencePath)) { return $null }
    try {
        if ([System.IO.Path]::IsPathRooted($EvidencePath)) {
            $candidate = [System.IO.Path]::GetFullPath($EvidencePath)
        }
        else {
            $candidate = [System.IO.Path]::GetFullPath((Join-Path ([Environment]::CurrentDirectory) $EvidencePath))
        }
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) { return $null }
        $item = Get-Item -LiteralPath $candidate -Force
        if ($item.PSIsContainer) { return $null }
        return $item.FullName
    }
    catch {
        return $null
    }
}

$result = [PSCustomObject]@{
    claim_id = "CLAIM-$(Get-Date -Format 'yyyyMMddHHmmss')"
    admitted = $false
    checks = @()
    failure_count = 0
    error = $null
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    compatibility_mode = "DEPRECATED_V5_CONTEXT_ADMISSION_AUTHORITATIVE"
}

try {
    try { $claim = $ClaimJson | ConvertFrom-Json }
    catch { throw "Claim is malformed JSON: $($_.Exception.Message)" }
    if ($null -eq $claim -or $claim -is [System.Array] -or $claim.PSObject.Properties.Count -eq 0) {
        throw "Claim must be a non-empty JSON object"
    }

    $state = $null
    try {
        $state = Read-TrustedStateStrict -Path $StatePath
        Add-Check -Result $result -Name "trusted_state" -Status "PASS" -Detail "Trusted state is present and well formed"
    }
    catch {
        Add-Check -Result $result -Name "trusted_state" -Status "FAIL" -Detail $_.Exception.Message
    }

    $source = [string](Get-ObjectPropertyValue -InputObject $claim -Name "source" -Default "")
    $validSources = @("runtime_result", "report", "handoff", "benchmark", "engine_output", "compression_summary")
    if ($source -in $validSources) {
        Add-Check -Result $result -Name "source_validity" -Status "PASS" -Detail "Recognized legacy source"
    }
    else {
        Add-Check -Result $result -Name "source_validity" -Status "FAIL" -Detail "Untrusted source"
    }

    $verificationStatus = [string](Get-ObjectPropertyValue -InputObject $claim -Name "verification_status" -Default "")
    if ($verificationStatus -eq "VERIFIED") {
        Add-Check -Result $result -Name "verification_status" -Status "PASS" -Detail "Claim requests verified admission; evidence is checked independently"
    }
    else {
        Add-Check -Result $result -Name "verification_status" -Status "FAIL" -Detail "Only VERIFIED legacy claims are eligible for admission"
    }

    if ($null -eq $state) {
        Add-Check -Result $result -Name "phase_binding" -Status "FAIL" -Detail "Cannot bind phase without trusted state"
    }
    else {
        $claimPhase = [string](Get-ObjectPropertyValue -InputObject $claim -Name "phase" -Default "")
        $trustedPhase = [string](Get-ObjectPropertyValue -InputObject $state -Name "phase" -Default "")
        if ([string]::IsNullOrWhiteSpace($claimPhase)) {
            Add-Check -Result $result -Name "phase_binding" -Status "FAIL" -Detail "Claim phase is required"
        }
        elseif ($claimPhase -ne $trustedPhase) {
            Add-Check -Result $result -Name "phase_binding" -Status "FAIL" -Detail "Claim phase '$claimPhase' differs from trusted phase '$trustedPhase'"
        }
        else {
            Add-Check -Result $result -Name "phase_binding" -Status "PASS" -Detail "Claim is bound to trusted phase"
        }
    }

    $evidencePathText = [string](Get-ObjectPropertyValue -InputObject $claim -Name "evidence_path" -Default "")
    $resolvedEvidencePath = Resolve-EvidenceFile -EvidencePath $evidencePathText
    if ($null -eq $resolvedEvidencePath) {
        Add-Check -Result $result -Name "evidence_binding" -Status "FAIL" -Detail "evidence_path must resolve to an existing file"
    }
    else {
        Add-Check -Result $result -Name "evidence_binding" -Status "PASS" -Detail "Evidence file exists"
    }

    $expectedHash = [string](Get-ObjectPropertyValue -InputObject $claim -Name "evidence_sha256" -Default "")
    if (-not [string]::IsNullOrWhiteSpace($expectedHash)) {
        if ($null -eq $resolvedEvidencePath) {
            Add-Check -Result $result -Name "evidence_sha256" -Status "FAIL" -Detail "Cannot hash missing evidence file"
        }
        elseif ($expectedHash -notmatch '^[a-fA-F0-9]{64}$') {
            Add-Check -Result $result -Name "evidence_sha256" -Status "FAIL" -Detail "evidence_sha256 must be 64 hexadecimal characters"
        }
        else {
            $actualHash = (Get-FileHash -LiteralPath $resolvedEvidencePath -Algorithm SHA256).Hash
            if ($actualHash -ieq $expectedHash) {
                Add-Check -Result $result -Name "evidence_sha256" -Status "PASS" -Detail "Evidence digest matches"
            }
            else {
                Add-Check -Result $result -Name "evidence_sha256" -Status "FAIL" -Detail "Evidence digest mismatch"
            }
        }
    }

    $summary = [string](Get-ObjectPropertyValue -InputObject $claim -Name "content_summary" -Default "")
    $claimText = [string](Get-ObjectPropertyValue -InputObject $claim -Name "claim_text" -Default "")
    $combinedText = "$summary`n$claimText"

    $deprecatedHit = $null
    foreach ($pattern in $DEPRECATED_PATTERNS) {
        if (Test-ContainsLiteral -Text $combinedText -Needle $pattern) { $deprecatedHit = $pattern; break }
    }
    if ($null -eq $deprecatedHit -and $null -ne $state) {
        foreach ($direction in @(Get-ObjectPropertyValue -InputObject $state -Name "deprecated_directions" -Default @())) {
            $directionText = [string](Get-ObjectPropertyValue -InputObject $direction -Name "direction" -Default "")
            if (Test-ContainsLiteral -Text $combinedText -Needle $directionText) { $deprecatedHit = $directionText; break }
        }
    }
    if ($null -ne $deprecatedHit) {
        Add-Check -Result $result -Name "deprecated_direction_scan" -Status "FAIL" -Detail "References deprecated direction: $deprecatedHit"
    }
    else {
        Add-Check -Result $result -Name "deprecated_direction_scan" -Status "PASS" -Detail "No deprecated direction found"
    }

    if ($null -eq $state) {
        Add-Check -Result $result -Name "stale_reference_scan" -Status "FAIL" -Detail "Cannot scan stale references without trusted state"
    }
    else {
        $staleHit = $null
        foreach ($reference in @(Get-ObjectPropertyValue -InputObject $state -Name "stale_references" -Default @())) {
            $referenceText = [string](Get-ObjectPropertyValue -InputObject $reference -Name "reference" -Default "")
            if (Test-ContainsLiteral -Text $combinedText -Needle $referenceText) { $staleHit = $referenceText; break }
        }
        if ($null -ne $staleHit) {
            Add-Check -Result $result -Name "stale_reference_scan" -Status "FAIL" -Detail "References stale data: $staleHit"
        }
        else {
            Add-Check -Result $result -Name "stale_reference_scan" -Status "PASS" -Detail "No stale reference found"
        }
    }

    if ($source -eq "compression_summary") {
        if ($null -eq $resolvedEvidencePath) {
            Add-Check -Result $result -Name "compression_verification" -Status "FAIL" -Detail "Compression evidence file is unavailable"
        }
        else {
            try {
                $verifierPath = Join-Path $PSScriptRoot "compression-summary-verifier.ps1"
                $summaryArtifactJson = [System.IO.File]::ReadAllText($resolvedEvidencePath)
                $verifierOutput = & $verifierPath -SummaryJson $summaryArtifactJson -StatePath $StatePath
                $verification = (@($verifierOutput) -join [Environment]::NewLine) | ConvertFrom-Json
                $independentlyVerified = [bool](Get-ObjectPropertyValue -InputObject $verification -Name "verified" -Default $false)
                if ($independentlyVerified) {
                    Add-Check -Result $result -Name "compression_verification" -Status "PASS" -Detail "Compression artifact independently matches trusted state"
                }
                else {
                    Add-Check -Result $result -Name "compression_verification" -Status "FAIL" -Detail "Compression artifact did not independently verify"
                }
            }
            catch {
                Add-Check -Result $result -Name "compression_verification" -Status "FAIL" -Detail "Compression verifier error: $($_.Exception.Message)"
            }
        }
    }

    $failures = @($result.checks | Where-Object { [string]$_.result -like "FAIL:*" }).Count
    $result.admitted = ($failures -eq 0)
    $result.failure_count = $failures
    $result | ConvertTo-Json -Depth 6
}
catch {
    $result.admitted = $false
    $result.failure_count = 1
    $result.error = "Parse error: $($_.Exception.Message)"
    $result | ConvertTo-Json -Depth 6
}
