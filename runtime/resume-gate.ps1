# Deprecated compatibility wrapper. Codex Factory V5 Context Packets and
# resume validation are authoritative. This gate only protects legacy JSON
# handoffs and always fails closed on incomplete or untrusted state.
[CmdletBinding()]
param(
    [string]$ResumeContextJson = "{}",
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

function Add-QuarantineItem {
    param($Result, [string]$Message)
    if ($Message -notin @($Result.quarantine_items)) {
        $Result.quarantine_items += $Message
    }
}

$result = [PSCustomObject]@{
    resume_id = "RESUME-$(Get-Date -Format 'yyyyMMddHHmmss')"
    allowed = $false
    checks = @()
    quarantine_items = @()
    reason = $null
    action = $null
    error = $null
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    compatibility_mode = "DEPRECATED_V5_CONTEXT_ADMISSION_AUTHORITATIVE"
}

try {
    try { $ctx = $ResumeContextJson | ConvertFrom-Json }
    catch { throw "Resume context is malformed JSON: $($_.Exception.Message)" }
    if ($null -eq $ctx -or $ctx -is [System.Array]) { throw "Resume context must be a JSON object" }

    try {
        $state = Read-TrustedStateStrict -Path $StatePath
        $result.checks += "Trusted state valid"
    }
    catch {
        $result.checks += "Trusted state invalid: $($_.Exception.Message)"
        Add-QuarantineItem -Result $result -Message "Trusted state unavailable or malformed"
        $result.reason = "BLOCKED - trusted state is unavailable or malformed"
        $result.action = "Initialize or repair trusted state before resuming"
        $result.error = $_.Exception.Message
        $result | ConvertTo-Json -Depth 6
        return
    }

    $contextPhase = [string](Get-ObjectPropertyValue -InputObject $ctx -Name "phase" -Default "")
    $trustedPhase = [string](Get-ObjectPropertyValue -InputObject $state -Name "phase" -Default "")
    if ([string]::IsNullOrWhiteSpace($contextPhase)) {
        $result.checks += "Phase missing from resume context"
        Add-QuarantineItem -Result $result -Message "Missing phase binding"
    }
    elseif ($contextPhase -ne $trustedPhase) {
        $result.checks += "Phase mismatch: context=$contextPhase vs trusted=$trustedPhase"
        Add-QuarantineItem -Result $result -Message "Phase mismatch: context=$contextPhase, trusted=$trustedPhase"
    }
    else {
        $result.checks += "Phase consistent: $trustedPhase"
    }

    $summaryText = [string](Get-ObjectPropertyValue -InputObject $ctx -Name "summary_text" -Default "")
    $handoffText = [string](Get-ObjectPropertyValue -InputObject $ctx -Name "handoff_text" -Default "")
    $planText = [string](Get-ObjectPropertyValue -InputObject $ctx -Name "plan_text" -Default "")
    $deprecatedText = "$summaryText`n$handoffText`n$planText"

    foreach ($deprecatedDirection in @(Get-ObjectPropertyValue -InputObject $state -Name "deprecated_directions" -Default @())) {
        $direction = [string](Get-ObjectPropertyValue -InputObject $deprecatedDirection -Name "direction" -Default "")
        if (Test-ContainsLiteral -Text $deprecatedText -Needle $direction) {
            Add-QuarantineItem -Result $result -Message "Deprecated direction: $direction"
        }
    }

    foreach ($staleReference in @(Get-ObjectPropertyValue -InputObject $state -Name "stale_references" -Default @())) {
        $reference = [string](Get-ObjectPropertyValue -InputObject $staleReference -Name "reference" -Default "")
        if (Test-ContainsLiteral -Text $deprecatedText -Needle $reference) {
            Add-QuarantineItem -Result $result -Message "Stale reference: $reference"
        }
    }

    $contextStatus = [string](Get-ObjectPropertyValue -InputObject $ctx -Name "verification_status" -Default "")
    if ($contextStatus -in @("STALE", "QUARANTINED", "REJECTED", "PENDING")) {
        Add-QuarantineItem -Result $result -Message "Resume context status is $contextStatus"
    }

    $trustedBaseline = Get-ObjectPropertyValue -InputObject $state -Name "regression_baseline"
    $trustedPassing = [int](Get-ObjectPropertyValue -InputObject $trustedBaseline -Name "passing")
    $trustedTotal = [int](Get-ObjectPropertyValue -InputObject $trustedBaseline -Name "total_tests")

    if (Test-ObjectProperty -InputObject $ctx -Name "previous_benchmark") {
        $claimedBenchmarkText = [string](Get-ObjectPropertyValue -InputObject $ctx -Name "previous_benchmark")
        $claimedPassing = 0
        if (-not [int]::TryParse($claimedBenchmarkText, [ref]$claimedPassing)) {
            Add-QuarantineItem -Result $result -Message "Previous benchmark is not an integer"
        }
        elseif ($claimedPassing -ne $trustedPassing) {
            Add-QuarantineItem -Result $result -Message "Stale benchmark: claimed=$claimedPassing, current=$trustedPassing"
        }
    }
    if (Test-ObjectProperty -InputObject $ctx -Name "previous_benchmark_total") {
        $claimedTotalText = [string](Get-ObjectPropertyValue -InputObject $ctx -Name "previous_benchmark_total")
        $claimedTotal = 0
        if (-not [int]::TryParse($claimedTotalText, [ref]$claimedTotal)) {
            Add-QuarantineItem -Result $result -Message "Previous benchmark total is not an integer"
        }
        elseif ($claimedTotal -ne $trustedTotal) {
            Add-QuarantineItem -Result $result -Message "Stale benchmark total: claimed=$claimedTotal, current=$trustedTotal"
        }
    }

    try {
        $detectorPath = Join-Path $PSScriptRoot "stale-context-detector.ps1"
        $detectorOutput = & $detectorPath -ContextText $deprecatedText -StatePath $StatePath
        $detectorResult = (@($detectorOutput) -join [Environment]::NewLine) | ConvertFrom-Json
        $contextTrustworthy = [bool](Get-ObjectPropertyValue -InputObject $detectorResult -Name "context_trustworthy" -Default $false)
        if (-not $contextTrustworthy) {
            foreach ($staleHit in @(Get-ObjectPropertyValue -InputObject $detectorResult -Name "stale_hits" -Default @())) {
                $hitType = [string](Get-ObjectPropertyValue -InputObject $staleHit -Name "type" -Default "STALE_CONTEXT")
                $hitReference = [string](Get-ObjectPropertyValue -InputObject $staleHit -Name "reference" -Default "Unspecified stale context")
                Add-QuarantineItem -Result $result -Message "$hitType`: $hitReference"
            }
        }
    }
    catch {
        Add-QuarantineItem -Result $result -Message "Stale context detector failed: $($_.Exception.Message)"
    }

    if ($result.quarantine_items.Count -gt 0) {
        $result.allowed = $false
        $result.reason = "QUARANTINED - $($result.quarantine_items.Count) items need reconciliation"
        $result.action = "Review quarantined items before resuming"
    }
    else {
        $result.allowed = $true
        $result.reason = "Context consistent with trusted state"
    }

    $result | ConvertTo-Json -Depth 6
}
catch {
    $result.allowed = $false
    Add-QuarantineItem -Result $result -Message "Resume context invalid"
    $result.reason = "BLOCKED - invalid resume context"
    $result.error = "Gate error: $($_.Exception.Message)"
    $result | ConvertTo-Json -Depth 6
}
