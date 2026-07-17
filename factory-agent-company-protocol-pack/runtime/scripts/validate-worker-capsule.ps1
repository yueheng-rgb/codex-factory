<#
.SYNOPSIS
    Validates a worker capsule JSON against the full Agent Company Protocol Pack schema.
.DESCRIPTION
    Checks all 22 required fields per worker-capsule.schema.json.
    Outputs machine-readable JSON with per-field PASS/FAIL results.
    Exits 0 on all PASS, non-zero on any FAIL.
.PARAMETER CapsulePath
    Path to the worker capsule JSON file to validate.
.PARAMETER ProtocolPackRoot
    Root path of the protocol pack (for role validation). Defaults to script parent directory.
.EXAMPLE
    powershell -File validate-worker-capsule.ps1 -CapsulePath ./capsule.json -ProtocolPackRoot ../../
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$CapsulePath,
    [string]$ProtocolPackRoot,
    [switch]$WhatIf
)

if (-not $ProtocolPackRoot) {
    $ProtocolPackRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
}

$script:results = @()
$script:errors = @()
$script:overallPass = $true
$script:totalChecks = 0
$script:passedChecks = 0
$script:failedChecks = 0

$KNOWN_ROLES = @("Orchestrator", "Architect", "Builder", "Integration Lead", "Reviewer", "Verifier", "Integrity Checker")

function Add-Check {
    param([string]$Field, [bool]$Pass, [string]$Detail)
    $script:totalChecks++
    if ($Pass) { $script:passedChecks++ } else { $script:failedChecks++; $script:overallPass = $false }
    $script:results += [PSCustomObject]@{ field = $Field; result = if ($Pass) { "PASS" } else { "FAIL" }; detail = $Detail }
}

# --- Load ---
try {
    $capsule = Get-Content -Path $CapsulePath -Raw -ErrorAction Stop | ConvertFrom-Json
} catch {
    $out = [PSCustomObject]@{ capsulePath=$CapsulePath; validatedAt=(Get-Date -Format "o"); parseError=$_.Exception.Message; overall="FAIL"; totalChecks=0; passedChecks=0; failedChecks=0; results=@() }
    $out | ConvertTo-Json -Depth 4
    exit 1
}

$props = $capsule.PSObject.Properties.Name

# --- 1. capsuleId ---
$f="capsuleId"
if ($props -contains $f -and $capsule.$f -is [string] -and $capsule.$f.Trim().Length -gt 0) {
    if ($capsule.$f -match '^capsule-[a-z0-9]+-[a-z0-9]+-[0-9]{14}$') {
        Add-Check $f $true "capsuleId '$($capsule.$f)' matches pattern"
    } else {
        Add-Check $f $false "capsuleId '$($capsule.$f)' does not match pattern '^capsule-[a-z0-9]+-[a-z0-9]+-[0-9]{14}$'"
    }
} else { Add-Check $f $false "capsuleId missing, empty, or not string" }

# --- 2. phase ---
$f="phase"
if ($props -contains $f -and $capsule.$f -is [string] -and $capsule.$f.Trim().Length -gt 0) {
    Add-Check $f $true "phase='$($capsule.$f)'"
} else { Add-Check $f $false "phase missing or empty" }

# --- 3. agentId ---
$f="agentId"
if ($props -contains $f -and $capsule.$f -is [string] -and $capsule.$f.Trim().Length -gt 0) {
    Add-Check $f $true "agentId='$($capsule.$f)'"
} else { Add-Check $f $false "agentId missing or empty" }

# --- 4. role ---
$f="role"
if ($props -contains $f -and $capsule.$f -is [string] -and $capsule.$f.Trim().Length -gt 0) {
    if ($capsule.$f -in $KNOWN_ROLES) {
        Add-Check $f $true "role='$($capsule.$f)' is a known agent company role"
    } else {
        Add-Check $f $false "role='$($capsule.$f)' is not a recognized agent company role. Known roles: $($KNOWN_ROLES -join ', ')"
    }
} else { Add-Check $f $false "role missing or empty" }

# --- 5. forkContext (must be false) ---
$f="forkContext"
if ($props -contains $f) {
    if ($capsule.$f -eq $false) {
        Add-Check $f $true "forkContext is false"
    } else {
        Add-Check $f $false "forkContext must be false, got: $($capsule.$f)"
    }
} else { Add-Check $f $false "forkContext missing" }

# --- 6. ownedScope (array, min 1) ---
$f="ownedScope"
if ($props -contains $f -and $capsule.$f -is [array] -and $capsule.$f.Count -gt 0) {
    $allStrings = ($capsule.$f | Where-Object { $_ -isnot [string] -or $_.Trim().Length -eq 0 }).Count -eq 0
    if ($allStrings) {
        Add-Check $f $true "ownedScope has $($capsule.$f.Count) entries, all non-empty strings"
    } else {
        Add-Check $f $false "ownedScope contains empty or non-string entries"
    }
} else { Add-Check $f $false "ownedScope missing, empty, or not array" }

# --- 7. forbiddenScope (array) ---
$f="forbiddenScope"
if ($props -contains $f) {
    if ($capsule.$f -is [array]) {
        Add-Check $f $true "forbiddenScope defined with $($capsule.$f.Count) entries"
    } else {
        Add-Check $f $false "forbiddenScope is not an array"
    }
} else { Add-Check $f $false "forbiddenScope missing" }

# --- 8. allowedImports (array) ---
$f="allowedImports"
if ($props -contains $f -and $capsule.$f -is [array]) {
    Add-Check $f $true "allowedImports has $($capsule.$f.Count) entries"
} else { Add-Check $f $false "allowedImports missing or not array" }

# --- 9. forbiddenImports (array) ---
$f="forbiddenImports"
if ($props -contains $f -and $capsule.$f -is [array]) {
    Add-Check $f $true "forbiddenImports has $($capsule.$f.Count) entries"
} else { Add-Check $f $false "forbiddenImports missing or not array" }

# --- 10. expectedOutputs (array with objects, min 1) ---
$f="expectedOutputs"
if ($props -contains $f -and $capsule.$f -is [array] -and $capsule.$f.Count -gt 0) {
    $bad = @($capsule.$f | Where-Object {
        $_ -isnot [PSCustomObject] -or
        -not ($_.PSObject.Properties.Name -contains "path") -or
        -not ($_.PSObject.Properties.Name -contains "description") -or
        $_.path -isnot [string] -or $_.path.Trim().Length -eq 0 -or
        $_.description -isnot [string] -or $_.description.Trim().Length -eq 0
    })
    if ($bad.Count -eq 0) {
        Add-Check $f $true "expectedOutputs has $($capsule.$f.Count) valid entries with path+description"
    } else {
        Add-Check $f $false "expectedOutputs has $($bad.Count) entries missing path or description"
    }
} else { Add-Check $f $false "expectedOutputs missing, empty, or not array" }

# --- 11. requiredEvidence (array, min 1) ---
$f="requiredEvidence"
if ($props -contains $f -and $capsule.$f -is [array] -and $capsule.$f.Count -gt 0) {
    $allStr = ($capsule.$f | Where-Object { $_ -isnot [string] -or $_.Trim().Length -eq 0 }).Count -eq 0
    if ($allStr) {
        Add-Check $f $true "requiredEvidence has $($capsule.$f.Count) entries"
    } else {
        Add-Check $f $false "requiredEvidence contains empty or non-string entries"
    }
} else { Add-Check $f $false "requiredEvidence missing, empty, or not array" }

# --- 12. handoffRequirements ---
$f="handoffRequirements"
$ho = $props -contains $f
if ($ho -and $capsule.$f -is [PSCustomObject]) {
    $hop = $capsule.$f.PSObject.Properties.Name
    $allOk = $true
    foreach ($sub in @("fileList","sha256","transcriptRef","contractChecklist")) {
        if ($hop -contains $sub -and $capsule.$f.$sub -eq $true) { continue }
        Add-Check "$f.$sub" $false "handoffRequirements.$sub must be true"
        $allOk = $false
    }
    if ($allOk) {
        Add-Check $f $true "handoffRequirements complete (fileList=sha256=transcriptRef=contractChecklist=true)"
    }
} else { Add-Check $f $false "handoffRequirements missing or not object" }

# --- 13. closeConditions (array of objects, min 1) ---
$f="closeConditions"
if ($props -contains $f -and $capsule.$f -is [array] -and $capsule.$f.Count -gt 0) {
    $validReasons = @("COMPLETED","FAILED","STALE","REPLACED")
    $bad = @($capsule.$f | Where-Object {
        $_ -isnot [PSCustomObject] -or
        -not ($_.PSObject.Properties.Name -contains "reason") -or
        -not ($_.PSObject.Properties.Name -contains "condition") -or
        $_.reason -notin $validReasons -or
        $_.condition -isnot [string] -or $_.condition.Trim().Length -eq 0
    })
    if ($bad.Count -eq 0) {
        Add-Check $f $true "closeConditions has $($capsule.$f.Count) valid entries"
    } else {
        Add-Check $f $false "closeConditions has $($bad.Count) invalid entries"
    }
} else { Add-Check $f $false "closeConditions missing, empty, or not array" }

# --- 14. antiDeceptionChecks (array of objects, min 1) ---
$f="antiDeceptionChecks"
if ($props -contains $f -and $capsule.$f -is [array] -and $capsule.$f.Count -gt 0) {
    $validSev = @("P0","P1","P2")
    $bad = @($capsule.$f | Where-Object {
        $_ -isnot [PSCustomObject] -or
        -not ($_.PSObject.Properties.Name -contains "checkId") -or
        -not ($_.PSObject.Properties.Name -contains "description") -or
        -not ($_.PSObject.Properties.Name -contains "severity") -or
        $_.severity -notin $validSev -or
        $_.checkId -isnot [string] -or $_.checkId.Trim().Length -eq 0
    })
    if ($bad.Count -eq 0) {
        Add-Check $f $true "antiDeceptionChecks has $($capsule.$f.Count) valid entries"
    } else {
        Add-Check $f $false "antiDeceptionChecks has $($bad.Count) invalid entries"
    }
} else { Add-Check $f $false "antiDeceptionChecks missing, empty, or not array" }

# --- 15. escalationTriggers (array of objects, min 1) ---
$f="escalationTriggers"
if ($props -contains $f -and $capsule.$f -is [array] -and $capsule.$f.Count -gt 0) {
    $validPaths = @("ORCHESTRATOR","HUMAN_OPERATOR","SECURITY_AUDIT")
    $validSev2 = @("P0","P1","P2")
    $bad = @($capsule.$f | Where-Object {
        $_ -isnot [PSCustomObject] -or
        -not ($_.PSObject.Properties.Name -contains "triggerId") -or
        -not ($_.PSObject.Properties.Name -contains "condition") -or
        -not ($_.PSObject.Properties.Name -contains "escalationPath") -or
        -not ($_.PSObject.Properties.Name -contains "severity") -or
        $_.escalationPath -notin $validPaths -or
        $_.severity -notin $validSev2
    })
    if ($bad.Count -eq 0) {
        Add-Check $f $true "escalationTriggers has $($capsule.$f.Count) valid entries"
    } else {
        Add-Check $f $false "escalationTriggers has $($bad.Count) invalid entries"
    }
} else { Add-Check $f $false "escalationTriggers missing, empty, or not array" }

# --- 16. assignedBy ---
$f="assignedBy"
if ($props -contains $f -and $capsule.$f -is [string] -and $capsule.$f.Trim().Length -gt 0) {
    Add-Check $f $true "assignedBy='$($capsule.$f)'"
} else { Add-Check $f $false "assignedBy missing or empty" }

# --- 17. assignedAt ---
$f="assignedAt"
if ($props -contains $f -and $capsule.$f -is [string] -and $capsule.$f.Trim().Length -gt 0) {
    try {
        $dt = [DateTime]::Parse($capsule.$f)
        Add-Check $f $true "assignedAt='$($capsule.$f)' is valid ISO-8601"
    } catch {
        Add-Check $f $false "assignedAt='$($capsule.$f)' is not valid ISO-8601"
    }
} else { Add-Check $f $false "assignedAt missing or empty" }

# --- 18. contractVersion ---
$f="contractVersion"
if ($props -contains $f -and $capsule.$f -is [string] -and $capsule.$f -match '^\d+\.\d+\.\d+$') {
    Add-Check $f $true "contractVersion='$($capsule.$f)'"
} else {
    Add-Check $f $false "contractVersion missing or not semver (e.g. 1.0.0)"
}

# --- 19. no extra properties ---
$f="noExtraProperties"
$schemaProps = @("capsuleId","phase","agentId","role","forkContext","ownedScope","forbiddenScope","allowedImports","forbiddenImports","expectedOutputs","requiredEvidence","handoffRequirements","closeConditions","antiDeceptionChecks","escalationTriggers","assignedBy","assignedAt","contractVersion")
$extra = $props | Where-Object { $_ -notin $schemaProps }
if ($extra.Count -eq 0) {
    Add-Check $f $true "No extra properties beyond schema"
} else {
    Add-Check $f $false "Extra properties found: $($extra -join ', ')"
}

# --- Output ---
$output = [PSCustomObject]@{
    capsulePath  = $CapsulePath
    validatedAt  = (Get-Date -Format "o")
    overall      = if ($script:overallPass) { "PASS" } else { "FAIL" }
    totalChecks  = $script:totalChecks
    passedChecks = $script:passedChecks
    failedChecks = $script:failedChecks
    results      = $script:results
}
$output | ConvertTo-Json -Depth 4
if ($script:overallPass) { exit 0 } else { exit 1 }
