<#
.SYNOPSIS
    Validates a worker capsule JSON file against the Agent Company Protocol Pack schema.
.DESCRIPTION
    Checks that a worker capsule JSON contains all required fields with valid values.
    Outputs machine-readable JSON with per-field PASS/FAIL results.
    Exits 0 on all PASS, non-zero on any FAIL.
.PARAMETER CapsulePath
    Path to the worker capsule JSON file to validate.
.EXAMPLE
    powershell -File validate-capsule.ps1 -CapsulePath worker-capsule.json
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$CapsulePath
)

$script:results = @()
$script:overallPass = $true

function Add-Result {
    param([string]$Field, [bool]$Pass, [string]$Detail)
    $script:results += [PSCustomObject]@{
        field  = $Field
        result = if ($Pass) { "PASS" } else { "FAIL" }
        detail = $Detail
    }
    if (-not $Pass) { $script:overallPass = $false }
}

# --- Load and parse JSON ---
try {
    $capsule = Get-Content -Path $CapsulePath -Raw -ErrorAction Stop | ConvertFrom-Json
} catch {
    $output = [PSCustomObject]@{
        capsulePath = $CapsulePath
        validatedAt = (Get-Date -Format "o")
        parseError  = $_.Exception.Message
        overall     = "FAIL"
        results     = @()
    }
    $output | ConvertTo-Json -Depth 4
    exit 1
}

# --- Field validations ---

# 1. capsuleId
$field = "capsuleId"
if ($capsule.PSObject.Properties.Name -contains "capsuleId" -and
    $capsule.capsuleId -is [string] -and
    $capsule.capsuleId.Trim().Length -gt 0) {
    Add-Result -Field $field -Pass $true -Detail "capsuleId='$($capsule.capsuleId)'"
} else {
    Add-Result -Field $field -Pass $false -Detail "capsuleId missing, empty, or not a string"
}

# 2. ownedScope (non-empty array)
$field = "ownedScope"
if ($capsule.PSObject.Properties.Name -contains "ownedScope" -and
    $capsule.ownedScope -is [array] -and
    $capsule.ownedScope.Count -gt 0) {
    Add-Result -Field $field -Pass $true -Detail "ownedScope has $($capsule.ownedScope.Count) entries"
} else {
    Add-Result -Field $field -Pass $false -Detail "ownedScope missing, empty, or not an array"
}

# 3. forbiddenScope (defined)
$field = "forbiddenScope"
if ($capsule.PSObject.Properties.Name -contains "forbiddenScope" -and
    $capsule.forbiddenScope -ne $null) {
    Add-Result -Field $field -Pass $true -Detail "forbiddenScope defined with $($capsule.forbiddenScope.Count) entries"
} else {
    Add-Result -Field $field -Pass $false -Detail "forbiddenScope missing or null"
}

# 4. forkContext (must be false)
$field = "forkContext"
if ($capsule.PSObject.Properties.Name -contains "forkContext" -and
    $capsule.forkContext -eq $false) {
    Add-Result -Field $field -Pass $true -Detail "forkContext is false"
} else {
    $val = if ($capsule.PSObject.Properties.Name -contains "forkContext") { $capsule.forkContext } else { "<missing>" }
    Add-Result -Field $field -Pass $false -Detail "forkContext must be false, got: $val"
}

# 5. expectedOutputs (non-empty)
$field = "expectedOutputs"
if ($capsule.PSObject.Properties.Name -contains "expectedOutputs" -and
    $capsule.expectedOutputs -is [array] -and
    $capsule.expectedOutputs.Count -gt 0) {
    Add-Result -Field $field -Pass $true -Detail "expectedOutputs has $($capsule.expectedOutputs.Count) entries"
} else {
    Add-Result -Field $field -Pass $false -Detail "expectedOutputs missing, empty, or not an array"
}

# 6. handoffRequirements.fileList (non-empty array)
$field = "handoffRequirements.fileList"
$ho = $capsule.PSObject.Properties.Name -contains "handoffRequirements"
if ($ho -and $capsule.handoffRequirements.PSObject.Properties.Name -contains "fileList" -and
    $capsule.handoffRequirements.fileList -is [array] -and
    $capsule.handoffRequirements.fileList.Count -gt 0) {
    Add-Result -Field $field -Pass $true -Detail "fileList has $($capsule.handoffRequirements.fileList.Count) entries"
} else {
    Add-Result -Field $field -Pass $false -Detail "handoffRequirements.fileList missing, empty, or not an array"
}

# 7. handoffRequirements.sha256 (non-empty)
$field = "handoffRequirements.sha256"
if ($ho -and $capsule.handoffRequirements.PSObject.Properties.Name -contains "sha256" -and
    $capsule.handoffRequirements.sha256 -eq $true) {
    Add-Result -Field $field -Pass $true -Detail "sha256 requirement is true"
} else {
    Add-Result -Field $field -Pass $false -Detail "handoffRequirements.sha256 must be true"
}

# 8. handoffRequirements.transcriptRef (non-empty)
$field = "handoffRequirements.transcriptRef"
if ($ho -and $capsule.handoffRequirements.PSObject.Properties.Name -contains "transcriptRef" -and
    $capsule.handoffRequirements.transcriptRef -is [string] -and
    $capsule.handoffRequirements.transcriptRef.Trim().Length -gt 0) {
    Add-Result -Field $field -Pass $true -Detail "transcriptRef='$($capsule.handoffRequirements.transcriptRef)'"
} else {
    Add-Result -Field $field -Pass $false -Detail "handoffRequirements.transcriptRef missing or empty"
}

# 9. handoffRequirements.contractChecklist (non-empty)
$field = "handoffRequirements.contractChecklist"
if ($ho -and $capsule.handoffRequirements.PSObject.Properties.Name -contains "contractChecklist" -and
    $capsule.handoffRequirements.contractChecklist -is [array] -and
    $capsule.handoffRequirements.contractChecklist.Count -gt 0) {
    Add-Result -Field $field -Pass $true -Detail "contractChecklist has $($capsule.handoffRequirements.contractChecklist.Count) entries"
} else {
    Add-Result -Field $field -Pass $false -Detail "handoffRequirements.contractChecklist missing, empty, or not an array"
}

# --- Build output ---
$output = [PSCustomObject]@{
    capsulePath  = $CapsulePath
    validatedAt  = (Get-Date -Format "o")
    overall      = if ($script:overallPass) { "PASS" } else { "FAIL" }
    totalChecks  = $script:results.Count
    passedChecks = ($script:results | Where-Object { $_.result -eq "PASS" }).Count
    failedChecks = ($script:results | Where-Object { $_.result -eq "FAIL" }).Count
    results      = $script:results
}

$output | ConvertTo-Json -Depth 4

if ($script:overallPass) {
    exit 0
} else {
    exit 1
}
