# Registry Integrity Check
# Part of: FACTORY-R2.3-C-CAPABILITY-REGISTRY-RUNTIME
# Validates all 7 capability candidate registries.
# Usage: . .\runtime\registry-integrity-check.ps1; Test-AllRegistries

$script:FactoryRoot = if ($PSScriptRoot) { Split-Path $PSScriptRoot -Parent } else { "C:\Codex_App_Factory" }
$script:RegistryPath = Join-Path $script:FactoryRoot "registries"

# Valid enum values
$script:ValidTypes = @("skill", "mcp_server", "cli_tool", "sdk", "template", "generator", "verifier", "search_provider", "runner", "cloud_service", "knowledge_source", "monitor", "scanner")
$script:ValidTrustLevels = @("VERIFIED", "TRUSTED", "AVAILABLE", "CAUTION", "UNTRUSTED", "QUARANTINE")
$script:ValidActions = @("import", "adapt", "monitor", "quarantine", "reject", "defer")
$script:ValidPriorities = @("P0", "P1", "P2", "P3")
$script:ValidProjectTypes = @("content-site", "fullstack-admin", "saas-tool", "api-service", "miniapp", "mobile-app", "threejs-interactive", "all")
$script:KnownAgentIds = @("PM-001", "RSRC-001", "LIB-001", "ARCH-001", "IMPL-FE-001", "IMPL-BE-001", "IMPL-DB-001", "VER-001", "SEC-001", "INTG-001", "AUD-001")

# Required fields in every registry entry
$script:RegistryRequiredFields = @(
    "capabilityId", "name", "type", "provider", "sourceRef", "officialStatus",
    "shortDescription", "capabilitySummary", "applicableProjectTypes", "applicableAgents",
    "requiredSecrets", "networkAccess", "fileWriteAccess", "externalServiceAccess",
    "localRunnerRequired", "cloudRequired", "licenseConcern", "securityRisk",
    "privacyRisk", "supplyChainRisk", "trustLevel", "freshnessRequirement",
    "importDifficulty", "integrationDifficulty", "verificationMethod",
    "fallbackPlan", "recommendedAction", "priority", "reason"
)

$script:BooleanFields = @("networkAccess", "fileWriteAccess", "externalServiceAccess", "localRunnerRequired", "cloudRequired")
$script:ArrayFields = @("applicableProjectTypes", "applicableAgents", "requiredSecrets")

$script:RegistryFiles = @{
    "master"    = "capability-candidate-registry.jsonl"
    "skill"     = "skill-candidate-registry.jsonl"
    "mcp"       = "mcp-candidate-registry.jsonl"
    "search"    = "search-provider-candidate-registry.jsonl"
    "template"  = "template-starter-candidate-registry.jsonl"
    "verifier"  = "verifier-candidate-registry.jsonl"
    "runner"    = "runner-candidate-registry.jsonl"
}

function Get-RegistryEntries {
    param([string]$FilePath)
    if (-not (Test-Path $FilePath)) {
        Write-Error "REGISTRY: File not found: $FilePath"
        return @()
    }
    $entries = @()
    $lines = Get-Content $FilePath -Encoding UTF8
    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -eq "" -or $trimmed.StartsWith("#")) { continue }
        try {
            $obj = $trimmed | ConvertFrom-Json -ErrorAction Stop
            $entries += $obj
        } catch {
            Write-Warning "REGISTRY: JSON parse error in $FilePath : $($_.Exception.Message)"
            $entries += [PSCustomObject]@{_parseError=$true; _rawLine=$trimmed}
        }
    }
    return $entries
}

function Test-CapabilityEntry {
    param([Parameter(Mandatory=$true)]$Entry, [string]$SourceRegistry = "master")
    $errors = @()
    $warnings = @()

    if ($Entry._parseError) {
        $errors += "JSON_PARSE_ERROR"
        return [PSCustomObject]@{ valid=$false; capabilityId="UNKNOWN"; errors=$errors; warnings=$warnings }
    }

    foreach ($field in $script:RegistryRequiredFields) {
        if (-not (Get-Member -InputObject $Entry -Name $field -MemberType Properties -ErrorAction SilentlyContinue)) {
            $errors += "MISSING_FIELD: $field"
        }
    }

    $cid = if (Get-Member -InputObject $Entry -Name "capabilityId") { $Entry.capabilityId } else { "UNKNOWN" }

    if ($cid -ne "UNKNOWN" -and $cid -notmatch "^CAP-[A-Z]+-[0-9]{3}$") {
        $warnings += "CAPABILITYID_FORMAT: $cid"
    }

    if (Get-Member -InputObject $Entry -Name "type") {
        if ($Entry.type -notin $script:ValidTypes) {
            $errors += "INVALID_TYPE: $($Entry.type)"
        }
    }

    if (Get-Member -InputObject $Entry -Name "trustLevel") {
        if ($Entry.trustLevel -notin $script:ValidTrustLevels) {
            $errors += "INVALID_TRUST_LEVEL: $($Entry.trustLevel)"
        }
    }

    if (Get-Member -InputObject $Entry -Name "recommendedAction") {
        if ($Entry.recommendedAction -notin $script:ValidActions) {
            $errors += "INVALID_ACTION: $($Entry.recommendedAction)"
        }
    }

    if (Get-Member -InputObject $Entry -Name "priority") {
        if ($Entry.priority -notin $script:ValidPriorities) {
            $errors += "INVALID_PRIORITY: $($Entry.priority)"
        }
    }

    foreach ($bf in $script:BooleanFields) {
        if (Get-Member -InputObject $Entry -Name $bf) {
            $val = $Entry.$bf
            if ($val -isnot [bool] -and $val -ne "true" -and $val -ne "false" -and $val -ne $true -and $val -ne $false) {
                $errors += "INVALID_BOOLEAN: $bf = $val"
            }
        }
    }

    foreach ($af in $script:ArrayFields) {
        if (Get-Member -InputObject $Entry -Name $af) {
            if ($Entry.$af -isnot [array] -and $null -ne $Entry.$af) {
                $errors += "NOT_ARRAY: $af"
            }
        }
    }

    if (Get-Member -InputObject $Entry -Name "applicableProjectTypes") {
        $apt = $Entry.applicableProjectTypes
        if ($apt -is [array]) {
            foreach ($pt in $apt) {
                if ($pt -ne "all" -and $pt -notin $script:ValidProjectTypes) {
                    $warnings += "UNKNOWN_PROJECT_TYPE: $pt"
                }
            }
        }
    }

    if (Get-Member -InputObject $Entry -Name "applicableAgents") {
        $aa = $Entry.applicableAgents
        if ($aa -is [array]) {
            foreach ($a in $aa) {
                if ($a -notin $script:KnownAgentIds) {
                    $warnings += "UNKNOWN_AGENT: $a"
                }
            }
        }
    }

    foreach ($risk in @("securityRisk", "privacyRisk", "supplyChainRisk")) {
        if (Get-Member -InputObject $Entry -Name $risk) {
            $rv = $Entry.$risk
            if ($rv -notin @("none", "low", "medium", "high", "critical", "unknown") -and $rv -ne $null) {
                $warnings += "UNKNOWN_RISK: $risk=$rv"
            }
        }
    }

    return [PSCustomObject]@{
        valid       = ($errors.Count -eq 0)
        capabilityId = $cid
        errors      = $errors
        warnings    = $warnings
    }
}

function Test-Registry {
    param([string]$RegistryName, [string]$FilePath)
    Write-Host "Validating $RegistryName registry..." -ForegroundColor Yellow
    $entries = Get-RegistryEntries -FilePath $FilePath
    $results = @()
    $seenIds = @{}
    $duplicateIds = @()

    foreach ($entry in $entries) {
        $r = Test-CapabilityEntry -Entry $entry -SourceRegistry $RegistryName
        $results += $r
        if ($r.capabilityId -ne "UNKNOWN") {
            if ($seenIds.ContainsKey($r.capabilityId)) { $duplicateIds += $r.capabilityId }
            else { $seenIds[$r.capabilityId] = $true }
        }
    }

    $validCount = ($results | Where-Object { $_.valid }).Count
    $invalidCount = ($results | Where-Object { -not $_.valid }).Count
    $totalWarnings = ($results | ForEach-Object { $_.warnings.Count } | Measure-Object -Sum).Sum

    return [PSCustomObject]@{
        registryName   = $RegistryName
        filePath       = $FilePath
        totalEntries   = $entries.Count
        validEntries   = $validCount
        invalidEntries = $invalidCount
        duplicateIds   = $duplicateIds
        totalWarnings  = $totalWarnings
        allValid       = ($invalidCount -eq 0 -and $duplicateIds.Count -eq 0)
        entries        = $results
    }
}

function Test-AllRegistries {
    $allResults = @()
    foreach ($reg in $script:RegistryFiles.GetEnumerator()) {
        $filePath = Join-Path $script:RegistryPath $reg.Value
        $result = Test-Registry -RegistryName $reg.Key -FilePath $filePath
        $allResults += $result
    }

    $masterFile = Join-Path $script:RegistryPath $script:RegistryFiles["master"]
    $masterEntries = Get-RegistryEntries -FilePath $masterFile
    $masterIds = @{}
    $masterDups = @()
    foreach ($e in $masterEntries) {
        $cid = if (Get-Member -InputObject $e -Name "capabilityId") { $e.capabilityId } else { $null }
        if ($cid) {
            if ($masterIds.ContainsKey($cid)) { $masterDups += $cid }
            else { $masterIds[$cid] = $true }
        }
    }

    $masterIdSet = $masterIds.Keys
    $consistencyErrors = @()
    foreach ($reg in $allResults) {
        if ($reg.registryName -eq "master") { continue }
        foreach ($entry in $reg.entries) {
            if ($entry.capabilityId -ne "UNKNOWN" -and $entry.capabilityId -notin $masterIdSet) {
                $consistencyErrors += "$($reg.registryName): $($entry.capabilityId) not in master"
            }
        }
    }

    $totalEntries = ($allResults | Measure-Object -Property totalEntries -Sum).Sum
    $totalValid = ($allResults | Measure-Object -Property validEntries -Sum).Sum
    $totalInvalid = ($allResults | Measure-Object -Property invalidEntries -Sum).Sum
    $allPassed = $allResults.AllValid -notcontains $false -and $masterDups.Count -eq 0 -and $consistencyErrors.Count -eq 0

    Write-Host ""
    Write-Host "REGISTRY INTEGRITY SUMMARY" -ForegroundColor Cyan
    Write-Host "  Registries: $($allResults.Count) | Entries: $totalEntries | Valid: $totalValid | Invalid: $totalInvalid" -ForegroundColor White
    Write-Host "  Master duplicates: $($masterDups.Count) | Consistency errors: $($consistencyErrors.Count)" -ForegroundColor White
    if ($allPassed) { Write-Host ">>> ALL REGISTRIES PASS <<<" -ForegroundColor Green }
    else { Write-Host ">>> ISSUES FOUND <<<" -ForegroundColor Red }

    return [PSCustomObject]@{
        allPassed          = $allPassed
        registryResults    = $allResults
        masterDuplicateIds = $masterDups
        consistencyErrors  = $consistencyErrors
        summary = @{
            totalRegistries   = $allResults.Count
            totalEntries      = $totalEntries
            totalValid        = $totalValid
            totalInvalid      = $totalInvalid
            masterDuplicates  = $masterDups.Count
            consistencyErrors = $consistencyErrors.Count
        }
    }
}

Write-Verbose "Registry Integrity Check loaded."
