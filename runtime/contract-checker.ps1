# Contract Awareness Checker
# Part of: FACTORY-R2.2-AGENT-RUNTIME-BINDING
# Checks that contract schema files exist and are parseable.
# Usage: . .\runtime\contract-checker.ps1; Test-AllContractSchemas

$script:ContractSchemas = @{
    "PIC" = "governance\contracts\templates\pic.schema.json"
    "AC"  = "governance\contracts\templates\ac.schema.json"
    "FC"  = "governance\contracts\templates\fc.schema.json"
    "NGC" = "governance\contracts\templates\ngc.schema.json"
}

$script:FactoryRoot = Join-Path $PSScriptRoot ".."

<#
.SYNOPSIS
Checks a single contract schema file exists and is valid JSON.
#>
function Test-ContractSchema {
    param([string]$ContractType)

    if (-not $script:ContractSchemas.ContainsKey($ContractType)) {
        return [PSCustomObject]@{
            ContractType = $ContractType
            Exists       = $false
            ValidJson    = $false
            Reason       = "Unknown contract type"
        }
    }

    $relPath = $script:ContractSchemas[$ContractType]
    $fullPath = Join-Path $script:FactoryRoot $relPath

    $exists = Test-Path $fullPath
    $validJson = $false
    $reason = ""

    if ($exists) {
        try {
            $null = Get-Content $fullPath -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop
            $validJson = $true
            $reason = "Schema exists and is valid JSON"
        } catch {
            $reason = "Schema exists but JSON is invalid: $($_.Exception.Message)"
        }
    } else {
        $reason = "Schema file not found: $fullPath"
    }

    return [PSCustomObject]@{
        ContractType = $ContractType
        Exists       = $exists
        ValidJson    = $validJson
        Path         = $relPath
        Reason       = $reason
    }
}

<#
.SYNOPSIS
Checks all 4 contract schemas plus skill registry and drift schemas.
#>
function Test-AllContractSchemas {
    $results = @()

    # Contract schemas
    foreach ($type in $script:ContractSchemas.Keys) {
        $results += Test-ContractSchema -ContractType $type
    }

    # Skill registry schema
    $skillRegPath = Join-Path $script:FactoryRoot "knowledge-bank\skill-registry.schema.json"
    $results += [PSCustomObject]@{
        ContractType = "SKILL_REGISTRY"
        Exists       = (Test-Path $skillRegPath)
        ValidJson    = $false
        Path         = "knowledge-bank\skill-registry.schema.json"
        Reason       = ""
    }
    if ($results[-1].Exists) {
        try {
            $null = Get-Content $skillRegPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $results[-1].ValidJson = $true
            $results[-1].Reason = "Valid JSON"
        } catch {
            $results[-1].Reason = "Invalid JSON: $($_.Exception.Message)"
        }
    } else {
        $results[-1].Reason = "File not found"
    }

    # Drift schema
    $driftPath = Join-Path $script:FactoryRoot "governance\drift-control\drift-check.schema.json"
    $results += [PSCustomObject]@{
        ContractType = "DRIFT_CHECK"
        Exists       = (Test-Path $driftPath)
        ValidJson    = $false
        Path         = "governance\drift-control\drift-check.schema.json"
        Reason       = ""
    }
    if ($results[-1].Exists) {
        try {
            $null = Get-Content $driftPath -Raw -Encoding UTF8 | ConvertFrom-Json
            $results[-1].ValidJson = $true
            $results[-1].Reason = "Valid JSON"
        } catch {
            $results[-1].Reason = "Invalid JSON: $($_.Exception.Message)"
        }
    } else {
        $results[-1].Reason = "File not found"
    }

    return $results
}
