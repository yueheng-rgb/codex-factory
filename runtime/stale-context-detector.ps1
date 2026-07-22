# Deprecated compatibility wrapper. Codex Factory V5 Context Space packet
# validation is authoritative. This detector fail-closes legacy free-text
# context checks so an unavailable trusted state is never reported as safe.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$ContextText,
    [string]$StatePath = "C:\Codex_App_Factory\outputs\trusted-project-state.json"
)

$ErrorActionPreference = "Stop"

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
    if ([string]::IsNullOrWhiteSpace($raw)) { throw "Trusted state file is empty: $Path" }
    try { $trustedState = $raw | ConvertFrom-Json }
    catch { throw "Trusted state is malformed JSON: $($_.Exception.Message)" }

    foreach ($requiredName in @("project_id", "phase", "last_verified", "deprecated_directions", "stale_references", "regression_baseline")) {
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

    $baseline = Get-ObjectPropertyValue -InputObject $trustedState -Name "regression_baseline"
    foreach ($metricName in @("passing", "total_tests")) {
        if (-not (Test-ObjectProperty -InputObject $baseline -Name $metricName)) {
            throw "Trusted state regression_baseline is missing '$metricName'"
        }
    }
    return $trustedState
}

function Test-ContainsLiteral {
    param([string]$Text, [string]$Needle)
    if ([string]::IsNullOrWhiteSpace($Text) -or [string]::IsNullOrWhiteSpace($Needle)) { return $false }
    return ($Text.IndexOf($Needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0)
}

function New-StaleHit {
    param([string]$Type, [string]$Reference, [string]$Status, [string]$Severity)
    return [PSCustomObject]@{ type = $Type; reference = $Reference; status = $Status; severity = $Severity }
}

$result = [PSCustomObject]@{
    detection_id = "STALE-$(Get-Date -Format 'yyyyMMddHHmmss')"
    stale_hits = @()
    hit_count = 0
    context_trustworthy = $false
    error = $null
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    compatibility_mode = "DEPRECATED_V5_CONTEXT_ADMISSION_AUTHORITATIVE"
}

try {
    try {
        $state = Read-TrustedStateStrict -Path $StatePath
    }
    catch {
        $result.stale_hits += New-StaleHit -Type "TRUSTED_STATE_INVALID" -Reference $_.Exception.Message -Status "BLOCKED" -Severity "CRITICAL"
        $result.hit_count = $result.stale_hits.Count
        $result.error = $_.Exception.Message
        $result | ConvertTo-Json -Depth 6
        return
    }

    foreach ($deprecatedDirection in @(Get-ObjectPropertyValue -InputObject $state -Name "deprecated_directions" -Default @())) {
        $direction = [string](Get-ObjectPropertyValue -InputObject $deprecatedDirection -Name "direction" -Default "")
        if (Test-ContainsLiteral -Text $ContextText -Needle $direction) {
            $status = [string](Get-ObjectPropertyValue -InputObject $deprecatedDirection -Name "status" -Default "FORBIDDEN")
            $result.stale_hits += New-StaleHit -Type "DEPRECATED_DIRECTION" -Reference $direction -Status $status -Severity "CRITICAL"
        }
    }

    foreach ($staleReference in @(Get-ObjectPropertyValue -InputObject $state -Name "stale_references" -Default @())) {
        $reference = [string](Get-ObjectPropertyValue -InputObject $staleReference -Name "reference" -Default "")
        if (Test-ContainsLiteral -Text $ContextText -Needle $reference) {
            $currentStatus = [string](Get-ObjectPropertyValue -InputObject $staleReference -Name "current_status" -Default "STALE")
            $result.stale_hits += New-StaleHit -Type "STALE_REFERENCE" -Reference $reference -Status $currentStatus -Severity "HIGH"
        }
    }

    if ($ContextText -match "(?i)old\s+benchmark|stale\s+benchmark|previous\s+benchmark") {
        $result.stale_hits += New-StaleHit -Type "STALE_BENCHMARK" -Reference "Old benchmark reference" -Status "STALE" -Severity "HIGH"
    }

    $trustedBaseline = Get-ObjectPropertyValue -InputObject $state -Name "regression_baseline"
    $trustedPassing = [int](Get-ObjectPropertyValue -InputObject $trustedBaseline -Name "passing")
    $trustedTotal = [int](Get-ObjectPropertyValue -InputObject $trustedBaseline -Name "total_tests")
    $regressionMatches = [regex]::Matches($ContextText, '(?i)(\d+)\s*/\s*(\d+)\s*(?:tests?\s*)?PASS')
    foreach ($regressionMatch in $regressionMatches) {
        $claimedPassing = [int]$regressionMatch.Groups[1].Value
        $claimedTotal = [int]$regressionMatch.Groups[2].Value
        if ($claimedPassing -ne $trustedPassing -or $claimedTotal -ne $trustedTotal) {
            $result.stale_hits += New-StaleHit -Type "STALE_METRIC" -Reference "Regression: claimed=$claimedPassing/$claimedTotal, current=$trustedPassing/$trustedTotal" -Status "STALE" -Severity "HIGH"
        }
    }

    $trustedPhase = [string](Get-ObjectPropertyValue -InputObject $state -Name "phase" -Default "")
    $phaseMatches = [regex]::Matches($ContextText, '(?im)\bphase\s*[:=]\s*([A-Za-z0-9._/-]+)')
    foreach ($phaseMatch in $phaseMatches) {
        $claimedPhase = $phaseMatch.Groups[1].Value
        if ($claimedPhase -ne $trustedPhase) {
            $result.stale_hits += New-StaleHit -Type "STALE_PHASE" -Reference "Phase: claimed=$claimedPhase, current=$trustedPhase" -Status "STALE" -Severity "CRITICAL"
        }
    }

    $result.hit_count = $result.stale_hits.Count
    $result.context_trustworthy = ($result.hit_count -eq 0)
    $result | ConvertTo-Json -Depth 6
}
catch {
    $result.context_trustworthy = $false
    $result.stale_hits += New-StaleHit -Type "DETECTION_ERROR" -Reference $_.Exception.Message -Status "BLOCKED" -Severity "CRITICAL"
    $result.hit_count = $result.stale_hits.Count
    $result.error = "Detection error: $($_.Exception.Message)"
    $result | ConvertTo-Json -Depth 6
}
