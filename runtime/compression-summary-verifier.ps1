# Deprecated compatibility wrapper. Codex Factory V5 Context Space and its
# admission pipeline are authoritative. This verifier only protects callers
# that still emit the legacy trusted-project-state compression format.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$SummaryJson,
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
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Trusted state file is empty: $Path"
    }

    try {
        $trustedState = $raw | ConvertFrom-Json
    }
    catch {
        throw "Trusted state is malformed JSON: $($_.Exception.Message)"
    }

    foreach ($requiredName in @("project_id", "phase", "last_verified", "frozen_pipelines", "deprecated_directions", "engine_status", "regression_baseline")) {
        if (-not (Test-ObjectProperty -InputObject $trustedState -Name $requiredName)) {
            throw "Trusted state is missing required property '$requiredName'"
        }
    }

    foreach ($requiredTextName in @("project_id", "phase", "last_verified")) {
        $requiredText = [string](Get-ObjectPropertyValue -InputObject $trustedState -Name $requiredTextName -Default "")
        if ([string]::IsNullOrWhiteSpace($requiredText)) {
            throw "Trusted state property '$requiredTextName' is empty"
        }
    }

    try {
        $null = [datetimeoffset]::Parse([string](Get-ObjectPropertyValue -InputObject $trustedState -Name "last_verified"))
    }
    catch {
        throw "Trusted state last_verified is not a valid timestamp"
    }

    foreach ($arrayName in @("frozen_pipelines", "deprecated_directions", "engine_status")) {
        $arrayValue = Get-ObjectPropertyValue -InputObject $trustedState -Name $arrayName
        if ($null -eq $arrayValue) {
            throw "Trusted state property '$arrayName' is null"
        }
    }

    $baseline = Get-ObjectPropertyValue -InputObject $trustedState -Name "regression_baseline"
    foreach ($baselineName in @("passing", "total_tests")) {
        if (-not (Test-ObjectProperty -InputObject $baseline -Name $baselineName)) {
            throw "Trusted state regression_baseline is missing '$baselineName'"
        }
    }

    return $trustedState
}

function Add-Conflict {
    param($Result, [string]$Message)
    $Result.conflicts += $Message
}

function Compare-CompleteCollection {
    param(
        $Result,
        $Summary,
        $State,
        [string]$SectionName,
        [string]$IdentityName,
        [string[]]$ValueNames
    )

    if (-not (Test-ObjectProperty -InputObject $Summary -Name $SectionName)) {
        Add-Conflict -Result $Result -Message "Missing required summary section: $SectionName"
        return
    }

    $summaryItems = @(Get-ObjectPropertyValue -InputObject $Summary -Name $SectionName -Default @())
    $stateItems = @(Get-ObjectPropertyValue -InputObject $State -Name $SectionName -Default @())
    if ($summaryItems.Count -ne $stateItems.Count) {
        Add-Conflict -Result $Result -Message "$SectionName count: summary=$($summaryItems.Count) vs trusted=$($stateItems.Count)"
    }

    $seen = @{}
    foreach ($summaryItem in $summaryItems) {
        $identity = [string](Get-ObjectPropertyValue -InputObject $summaryItem -Name $IdentityName -Default "")
        if ([string]::IsNullOrWhiteSpace($identity)) {
            Add-Conflict -Result $Result -Message "$SectionName contains an item without $IdentityName"
            continue
        }
        if ($seen.ContainsKey($identity)) {
            Add-Conflict -Result $Result -Message "$SectionName contains duplicate $IdentityName '$identity'"
            continue
        }
        $seen[$identity] = $true

        $trustedItem = @($stateItems | Where-Object {
            [string](Get-ObjectPropertyValue -InputObject $_ -Name $IdentityName -Default "") -eq $identity
        })
        if ($trustedItem.Count -ne 1) {
            Add-Conflict -Result $Result -Message "$SectionName item '$identity' is not present exactly once in trusted state"
            continue
        }

        foreach ($valueName in $ValueNames) {
            if (-not (Test-ObjectProperty -InputObject $summaryItem -Name $valueName)) {
                Add-Conflict -Result $Result -Message "$SectionName item '$identity' is missing $valueName"
                continue
            }
            $summaryValue = [string](Get-ObjectPropertyValue -InputObject $summaryItem -Name $valueName -Default "")
            $trustedValue = [string](Get-ObjectPropertyValue -InputObject $trustedItem[0] -Name $valueName -Default "")
            if ($summaryValue -ne $trustedValue) {
                Add-Conflict -Result $Result -Message "$SectionName $identity $valueName`: summary=$summaryValue vs trusted=$trustedValue"
            }
        }
    }
}

$result = [PSCustomObject]@{
    summary_id = "COMP-$(Get-Date -Format 'yyyyMMddHHmmss')"
    verified = $false
    checks = @()
    conflicts = @()
    resolution = $null
    error = $null
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    compatibility_mode = "DEPRECATED_V5_CONTEXT_ADMISSION_AUTHORITATIVE"
}

try {
    try {
        $summary = $SummaryJson | ConvertFrom-Json
    }
    catch {
        throw "Compression summary is malformed JSON: $($_.Exception.Message)"
    }

    if ($null -eq $summary -or $summary -is [System.Array] -or $summary.PSObject.Properties.Count -eq 0) {
        throw "Compression summary must be a non-empty JSON object"
    }

    try {
        $state = Read-TrustedStateStrict -Path $StatePath
        $result.checks += "TRUSTED_STATE_VALID"
    }
    catch {
        $result.checks += "TRUSTED_STATE_INVALID"
        Add-Conflict -Result $result -Message $_.Exception.Message
        $result.resolution = "NEEDS_RECONCILIATION"
        $result | ConvertTo-Json -Depth 6
        return
    }

    foreach ($bindingName in @("project_id", "phase")) {
        if (-not (Test-ObjectProperty -InputObject $summary -Name $bindingName)) {
            Add-Conflict -Result $result -Message "Missing required summary binding: $bindingName"
            continue
        }
        $summaryBinding = [string](Get-ObjectPropertyValue -InputObject $summary -Name $bindingName -Default "")
        $trustedBinding = [string](Get-ObjectPropertyValue -InputObject $state -Name $bindingName -Default "")
        if ([string]::IsNullOrWhiteSpace($summaryBinding) -or $summaryBinding -ne $trustedBinding) {
            Add-Conflict -Result $result -Message "$bindingName`: summary=$summaryBinding vs trusted=$trustedBinding"
        }
    }

    Compare-CompleteCollection -Result $result -Summary $summary -State $state -SectionName "frozen_pipelines" -IdentityName "pipeline" -ValueNames @("status")
    Compare-CompleteCollection -Result $result -Summary $summary -State $state -SectionName "deprecated_directions" -IdentityName "direction" -ValueNames @("status")
    Compare-CompleteCollection -Result $result -Summary $summary -State $state -SectionName "engine_status" -IdentityName "engine_id" -ValueNames @("status")

    if (-not (Test-ObjectProperty -InputObject $summary -Name "regression")) {
        Add-Conflict -Result $result -Message "Missing required summary section: regression"
    }
    else {
        $summaryRegression = Get-ObjectPropertyValue -InputObject $summary -Name "regression"
        $trustedRegression = Get-ObjectPropertyValue -InputObject $state -Name "regression_baseline"
        foreach ($metricName in @("passing", "total_tests")) {
            if (-not (Test-ObjectProperty -InputObject $summaryRegression -Name $metricName)) {
                Add-Conflict -Result $result -Message "Regression summary is missing $metricName"
                continue
            }
            $summaryMetric = Get-ObjectPropertyValue -InputObject $summaryRegression -Name $metricName
            $trustedMetric = Get-ObjectPropertyValue -InputObject $trustedRegression -Name $metricName
            if ([string]$summaryMetric -ne [string]$trustedMetric) {
                Add-Conflict -Result $result -Message "Regression $metricName`: summary=$summaryMetric vs trusted=$trustedMetric"
            }
        }
    }

    $result.verified = ($result.conflicts.Count -eq 0)
    $result.checks += if ($result.verified) { "ALL_REQUIRED_FIELDS_CONSISTENT" } else { "CONFLICTS_DETECTED" }
    if (-not $result.verified) {
        $result.resolution = "NEEDS_RECONCILIATION"
    }

    $result | ConvertTo-Json -Depth 6
}
catch {
    $result.verified = $false
    $result.checks += "SUMMARY_INVALID"
    Add-Conflict -Result $result -Message $_.Exception.Message
    $result.resolution = "NEEDS_RECONCILIATION"
    $result | ConvertTo-Json -Depth 6
}
