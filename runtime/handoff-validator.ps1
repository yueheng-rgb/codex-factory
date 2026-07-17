# Handoff Validator & Enforcement
# Part of: FACTORY-R2.2-AGENT-RUNTIME-BINDING
# Validates agent handoffs against schema and enforces rules.
# Usage: . .\runtime\handoff-validator.ps1; $result = Submit-Handoff -Handoff $obj -AgentId "IMPL-FE-001" -ProjectId "PROJ-099"

. "$PSScriptRoot\agent-loader.ps1"
. "$PSScriptRoot\permission-gate.ps1"

$script:HandoffSchemaPath = Join-Path $PSScriptRoot "..\governance\multi-agent\handoff-bus\handoff.schema.json"
$script:HandoffIndexPath  = Join-Path $PSScriptRoot "..\governance\multi-agent\handoff-bus\handoff-index.jsonl"

# Required handoff fields
$script:RequiredHandoffFields = @(
    "handoffId", "timestamp", "projectId", "fromAgent", "toAgent", "handoffType", "status"
)

# Valid agent IDs (known set)
$script:ValidAgentIds = @(
    "PM-001", "RSRC-001", "LIB-001", "ARCH-001",
    "IMPL-FE-001", "IMPL-BE-001", "IMPL-DB-001",
    "VER-001", "SEC-001", "INTG-001", "AUD-001"
)

<#
.SYNOPSIS
Validates a handoff object against the handoff schema and business rules.
Returns a result object with Valid (bool), Reason (string), and details.
#>
function Test-Handoff {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Handoff,

        [string]$AgentId = ""
    )

    $result = [PSCustomObject]@{
        Valid       = $false
        Reason      = ""
        HandoffId   = if ($Handoff.ContainsKey("handoffId")) { $Handoff["handoffId"] } else { "UNKNOWN" }
        Checks      = @()
        Warnings    = @()
    }

    # CHECK 1: Required fields
    $missingFields = @()
    foreach ($field in $script:RequiredHandoffFields) {
        if (-not $Handoff.ContainsKey($field) -or [string]::IsNullOrWhiteSpace($Handoff[$field])) {
            $missingFields += $field
        }
    }
    if ($missingFields.Count -gt 0) {
        $result.Reason = "HANDOFF_REJECTED: Missing required fields: $($missingFields -join ', ')"
        $result.Checks += "REQUIRED_FIELDS: FAIL (missing: $($missingFields -join ', '))"
        return $result
    }
    $result.Checks += "REQUIRED_FIELDS: PASS"

    # CHECK 2: Anonymous handoff check
    if ($Handoff["fromAgent"] -eq "anonymous" -or $Handoff["fromAgent"] -eq "" -or $Handoff["fromAgent"] -eq $null) {
        $result.Reason = "HANDOFF_REJECTED: Anonymous handoff not allowed. fromAgent is required."
        $result.Checks += "ANONYMOUS_CHECK: FAIL"
        return $result
    }
    $result.Checks += "ANONYMOUS_CHECK: PASS"

    # CHECK 3: Agent registration
    $fromAgent = $Handoff["fromAgent"]
    if ($fromAgent -notin $script:ValidAgentIds) {
        $result.Reason = "HANDOFF_REJECTED: Agent '$fromAgent' is not a registered agent."
        $result.Checks += "AGENT_REGISTRATION: FAIL"
        return $result
    }
    $result.Checks += "AGENT_REGISTRATION: PASS"

    # CHECK 4: projectId
    $projectId = $Handoff["projectId"]
    if (-not $projectId -or $projectId -eq "") {
        $result.Reason = "HANDOFF_REJECTED: projectId is missing or empty."
        $result.Checks += "PROJECT_ID: FAIL"
        return $result
    }
    $result.Checks += "PROJECT_ID: PASS"

    # CHECK 5: phaseId (optional but warn if missing)
    if (-not $Handoff.ContainsKey("phaseId") -or [string]::IsNullOrWhiteSpace($Handoff["phaseId"])) {
        $result.Warnings += "phaseId is missing (recommended but not required)"
    }

    # CHECK 6: taskId (optional but warn if missing)
    if (-not $Handoff.ContainsKey("taskId") -or [string]::IsNullOrWhiteSpace($Handoff["taskId"])) {
        $result.Warnings += "taskId is missing (recommended but not required)"
    }

    # CHECK 7: filesChanged scope violation
    if ($Handoff.ContainsKey("filesChanged") -and $Handoff["filesChanged"] -and $Handoff["filesChanged"].Count -gt 0) {
        foreach ($file in $Handoff["filesChanged"]) {
            $filePath = if ($file -is [hashtable]) { $file["path"] } elseif ($file -is [PSCustomObject]) { $file.path } else { $file }
            if ($filePath) {
                $permCheck = Test-AgentPermission -AgentId $fromAgent -Action "write" -TargetPath $filePath -ProjectId $projectId
                if (-not $permCheck.Allowed) {
                    $result.Reason = "HANDOFF_REJECTED: File '$filePath' is outside agent write scope. $($permCheck.Reason)"
                    $result.Checks += "FILES_CHANGED_SCOPE: FAIL ($filePath)"
                    return $result
                }
            }
        }
        $result.Checks += "FILES_CHANGED_SCOPE: PASS"
    }

    # CHECK 8: verificationResults
    if ($Handoff.ContainsKey("verificationResults") -and $Handoff["verificationResults"]) {
        $result.Checks += "VERIFICATION_RESULTS: PRESENT"
    } else {
        $result.Warnings += "verificationResults is missing — caveat required"
        $result.Checks += "VERIFICATION_RESULTS: MISSING (caveat recommended)"
    }

    # All checks passed
    $result.Valid = $true
    $result.Reason = "HANDOFF_ACCEPTED: All validation checks passed."
    return $result
}

<#
.SYNOPSIS
Validates and records a handoff to the handoff index.
#>
function Submit-Handoff {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Handoff,

        [Parameter(Mandatory=$true)]
        [string]$ProjectId,

        [string]$AgentId = ""
    )

    # Validate
    $validation = Test-Handoff -Handoff $Handoff -AgentId $AgentId
    if (-not $validation.Valid) {
        Write-Error "HANDOFF_SUBMIT: Validation failed: $($validation.Reason)"
        return $validation
    }

    # Show warnings
    foreach ($w in $validation.Warnings) {
        Write-Warning "HANDOFF_SUBMIT: $w"
    }

    # Record to index
    try {
        $handoffJson = $Handoff | ConvertTo-Json -Depth 4 -Compress
        Add-Content -Path $script:HandoffIndexPath -Value $handoffJson -Encoding UTF8
        Write-Host "HANDOFF_SUBMIT: Recorded handoff '$($Handoff['handoffId'])' to index. Checks passed: $($validation.Checks.Count)"
    } catch {
        Write-Error "HANDOFF_SUBMIT: Failed to write to handoff index: $($_.Exception.Message)"
        $validation.Valid = $false
        $validation.Reason = "HANDOFF_INDEX_WRITE_FAILED: $($_.Exception.Message)"
    }

    return $validation
}

<#
.SYNOPSIS
Reads the handoff index and returns entries for a given project.
#>
function Get-HandoffHistory {
    param([string]$ProjectId = "")

    if (-not (Test-Path $script:HandoffIndexPath)) {
        Write-Warning "Handoff index not found: $script:HandoffIndexPath"
        return @()
    }

    $entries = @()
    Get-Content $script:HandoffIndexPath -Encoding UTF8 | Where-Object { $_.Trim() -ne "" -and $_ -notmatch '^#' } | ForEach-Object {
        try {
            $entry = $_ | ConvertFrom-Json
            if (-not $ProjectId -or $entry.projectId -eq $ProjectId) {
                $entries += $entry
            }
        } catch {
            Write-Warning "Failed to parse handoff index entry"
        }
    }
    return $entries
}
