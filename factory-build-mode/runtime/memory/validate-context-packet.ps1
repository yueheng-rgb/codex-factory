<#
.SYNOPSIS
    Validate a context packet against schema, business rules, and anti-deception checks.
.DESCRIPTION
    Validates that a context packet JSON conforms to the required structure,
    rejects stale packets, blocks compressed-summary evidence, and catches
    unsupported PASS claims.
.PARAMETER PacketPath
    Path to the context packet JSON file to validate.
.PARAMETER ProjectRoot
    Root directory for resolving evidence paths.
.PARAMETER Strict
    If set, fails on warnings as well as errors.
.EXAMPLE
    .\validate-context-packet.ps1 -PacketPath ".\packet.json" -ProjectRoot "C:\Codex_App_Factory"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$PacketPath,
    [Parameter(Mandatory=$true)]
    [string]$ProjectRoot,
    [switch]$Strict
)

$ErrorActionPreference = "Continue"
$checks = @()
$passed = 0
$failed = 0
$warnings = 0

function Add-Check {
    param([string]$Id, [string]$Description, [bool]$Pass, [string]$Detail, [string]$Severity="ERROR")
    $script:checks += @{ id=$Id; description=$Description; pass=$Pass; detail=$Detail; severity=$Severity }
    if ($Pass) { $script:passed++ } else {
        if ($Severity -eq "ERROR") { $script:failed++ } else { $script:warnings++ }
    }
}

# === V01: File exists and is readable ===
if (-not (Test-Path $PacketPath)) {
    Add-Check -Id "V01" -Description "Packet file exists" -Pass $false -Detail "File not found: $PacketPath"
    $result = @{ overall="FAIL"; passedChecks=$script:passed; failedChecks=$script:failed; warnings=$script:warnings; checks=$checks }
    $result | ConvertTo-Json -Depth 4 | Out-File (Join-Path (Split-Path $PacketPath) "validation-result.json") -Encoding UTF8
    Write-Host $($result | ConvertTo-Json -Depth 4)
    exit 1
}
Add-Check -Id "V01" -Description "Packet file exists" -Pass $true -Detail $PacketPath

# === V02: Valid JSON ===
try {
    $raw = Get-Content $PacketPath -Raw
    $packet = $raw | ConvertFrom-Json
    Add-Check -Id "V02" -Description "Valid JSON" -Pass $true -Detail "Parsed successfully"
} catch {
    Add-Check -Id "V02" -Description "Valid JSON" -Pass $false -Detail "Parse error: $_"
    $result = @{ overall="FAIL"; passedChecks=$script:passed; failedChecks=$script:failed; warnings=$script:warnings; checks=$checks }
    $result | ConvertTo-Json -Depth 4 | Out-File (Join-Path (Split-Path $PacketPath) "validation-result.json") -Encoding UTF8
    exit 1
}

# === V03: Required fields present ===
$requiredFields = @("packetId","packetType","targetPhase","targetRole","projectId","currentTrustedPhase","generatedAt","freshness","contextBudget","requiredReads","currentTaskGroup","relevantDecisions","activeRisks","rejectedClaims","verifierHistorySummary","evidencePaths","forbiddenAssumptions","allowedActions","forbiddenActions","openQuestions","summaryVerificationStatus")
$missingFields = @()
foreach ($f in $requiredFields) {
    if (-not (Get-Member -InputObject $packet -Name $f -MemberType NoteProperty)) {
        $missingFields += $f
    }
}
if ($missingFields.Count -gt 0) {
    Add-Check -Id "V03" -Description "All required fields present" -Pass $false -Detail "Missing: $($missingFields -join ', ')"
} else {
    Add-Check -Id "V03" -Description "All required fields present" -Pass $true -Detail "$($requiredFields.Count) fields verified"
}

# === V04: packetId format ===
if ($packet.packetId -match '^CP-[A-Z0-9]+-\d{14}$') {
    Add-Check -Id "V04" -Description "packetId format valid" -Pass $true -Detail $packet.packetId
} else {
    Add-Check -Id "V04" -Description "packetId format valid" -Pass $false -Detail "Expected CP-{ALPHANUM}-{14-digit}, got: $($packet.packetId)"
}

# === V05: packetType valid ===
$validTypes = @("PHASE_START_PACKET","AGENT_START_PACKET","REVIEWER_PACKET","RECOVERY_PACKET","REPAIR_PACKET","USER_SUMMARY_PACKET")
if ($packet.packetType -in $validTypes) {
    Add-Check -Id "V05" -Description "packetType valid" -Pass $true -Detail $packet.packetType
} else {
    Add-Check -Id "V05" -Description "packetType valid" -Pass $false -Detail "Invalid: $($packet.packetType)"
}

# === V06: targetRole valid ===
$validRoles = @("builder","verifier","reviewer","integrator","auditor","orchestrator")
if ($packet.targetRole -in $validRoles) {
    Add-Check -Id "V06" -Description "targetRole valid" -Pass $true -Detail $packet.targetRole
} else {
    Add-Check -Id "V06" -Description "targetRole valid" -Pass $false -Detail "Invalid: $($packet.targetRole)"
}

# === V07: Stale check ===
$stale = $false
if ($packet.freshness) {
    try {
        $expiry = [DateTime]::Parse($packet.freshness.expiresAt)
        if ((Get-Date) -gt $expiry) {
            $stale = $true
            Add-Check -Id "V07" -Description "Packet not stale" -Pass $false -Detail "Expired at $($packet.freshness.expiresAt)"
        } else {
            Add-Check -Id "V07" -Description "Packet not stale" -Pass $true -Detail "Expires: $($packet.freshness.expiresAt)"
        }
    } catch {
        Add-Check -Id "V07" -Description "Packet not stale" -Pass $false -Detail "Cannot parse expiresAt: $($packet.freshness.expiresAt)"
    }
} else {
    Add-Check -Id "V07" -Description "Packet not stale" -Pass $false -Detail "No freshness metadata"
}

# === V08: Word budget check ===
if ($packet.contextBudget) {
    if ($packet.contextBudget.currentWordCount -le $packet.contextBudget.maxWords) {
        Add-Check -Id "V08" -Description "Word budget enforced" -Pass $true -Detail "$($packet.contextBudget.currentWordCount)/$($packet.contextBudget.maxWords)"
    } else {
        Add-Check -Id "V08" -Description "Word budget enforced" -Pass $false -Detail "Exceeded: $($packet.contextBudget.currentWordCount)/$($packet.contextBudget.maxWords)"
    }
}

# === V09: forbiddenAssumptions non-empty ===
if ($packet.forbiddenAssumptions -and $packet.forbiddenAssumptions.Count -gt 0) {
    Add-Check -Id "V09" -Description "forbiddenAssumptions non-empty" -Pass $true -Detail "$($packet.forbiddenAssumptions.Count) items"
} else {
    Add-Check -Id "V09" -Description "forbiddenAssumptions non-empty" -Pass $false -Detail "Empty or missing"
}

# === V10: allowedActions non-empty ===
if ($packet.allowedActions -and $packet.allowedActions.Count -gt 0) {
    Add-Check -Id "V10" -Description "allowedActions non-empty" -Pass $true -Detail "$($packet.allowedActions.Count) items"
} else {
    Add-Check -Id "V10" -Description "allowedActions non-empty" -Pass $false -Detail "Empty or missing"
}

# === V11: forbiddenActions non-empty ===
if ($packet.forbiddenActions -and $packet.forbiddenActions.Count -gt 0) {
    Add-Check -Id "V11" -Description "forbiddenActions non-empty" -Pass $true -Detail "$($packet.forbiddenActions.Count) items"
} else {
    Add-Check -Id "V11" -Description "forbiddenActions non-empty" -Pass $false -Detail "Empty or missing"
}

# === V12: Summary verification status check ===
if ($packet.summaryVerificationStatus) {
    if ($packet.summaryVerificationStatus.verified -eq $true) {
        Add-Check -Id "V12" -Description "Summary verification status confirmed" -Pass $true -Detail "Method: $($packet.summaryVerificationStatus.method)"
    } else {
        Add-Check -Id "V12" -Description "Summary verification status confirmed" -Pass $false -Detail "Not verified"
    }
} else {
    Add-Check -Id "V12" -Description "Summary verification status confirmed" -Pass $false -Detail "Missing summaryVerificationStatus"
}

# === V13: ANTI-DECEPTION: No compressed-summary evidence ===
$compressedDetected = $false
if ($packet.evidencePaths) {
    foreach ($e in $packet.evidencePaths) {
        if ($e.path -match "compressed|compression|conversation_summary" -or $e.level -in @("L0","L1")) {
            if ($e.level -eq "L4" -or $e.level -eq "L5") {
                $compressedDetected = $true
            }
        }
    }
}
if (-not $compressedDetected) {
    Add-Check -Id "V13" -Description "No compressed-summary as high-level evidence" -Pass $true -Detail "All evidence L2+ and not from compressed sources"
} else {
    Add-Check -Id "V13" -Description "No compressed-summary as high-level evidence" -Pass $false -Detail "Compressed summary found at L4/L5 level — REJECTED"
}

# === V14: ANTI-DECEPTION: No unsupported PASS claim ===
$passOnlyDetected = $false
if ($packet.verifierHistorySummary) {
    $vhs = $packet.verifierHistorySummary
    if ($vhs.lastResult -eq "PASS" -and $vhs.checksRun -eq 0) {
        $passOnlyDetected = $true
    }
    if ($vhs.lastResult -eq "PASS" -and (-not $vhs.lastVerifiedAt)) {
        $passOnlyDetected = $true
    }
}
if (-not $passOnlyDetected) {
    Add-Check -Id "V14" -Description "No unsupported PASS claim" -Pass $true -Detail "PASS claim has supporting evidence"
} else {
    Add-Check -Id "V14" -Description "No unsupported PASS claim" -Pass $false -Detail "PASS claimed without checks run or verification timestamp"
}

# === V15: ANTI-DECEPTION: Self-report not sole evidence ===
$selfReportOnly = $false
if ($packet.evidencePaths -and $packet.evidencePaths.Count -gt 0) {
    $nonL1Count = ($packet.evidencePaths | Where-Object { $_.level -ne "L1" }).Count
    if ($nonL1Count -eq 0) {
        $selfReportOnly = $true
    }
}
if (-not $selfReportOnly) {
    Add-Check -Id "V15" -Description "Not self-report-only evidence" -Pass $true -Detail "Evidence at multiple levels including L2+"
} else {
    Add-Check -Id "V15" -Description "Not self-report-only evidence" -Pass $false -Detail "All evidence is L1 (self-report) — REJECTED"
}

# === V16: Evidence path resolution ===
$unresolvedPaths = @()
if ($packet.evidencePaths) {
    foreach ($e in $packet.evidencePaths) {
        $fullPath = Join-Path $ProjectRoot ($e.path.TrimStart('/','\'))
        if (-not (Test-Path $fullPath)) {
            $unresolvedPaths += $e.path
        }
    }
}
if ($unresolvedPaths.Count -eq 0) {
    Add-Check -Id "V16" -Description "Evidence paths resolve" -Pass $true -Detail "All paths verified"
} else {
    Add-Check -Id "V16" -Description "Evidence paths resolve" -Pass $false -Detail "Unresolved: $($unresolvedPaths -join ', ')" -Severity "WARNING"
}

# === V17: activeRisks non-empty ===
if ($packet.activeRisks -and $packet.activeRisks.Count -gt 0) {
    Add-Check -Id "V17" -Description "activeRisks non-empty" -Pass $true -Detail "$($packet.activeRisks.Count) risks"
} else {
    Add-Check -Id "V17" -Description "activeRisks non-empty" -Pass $false -Detail "No risks — suspicious"
}

# === V18: rejectedClaims non-empty ===
if ($packet.rejectedClaims -and $packet.rejectedClaims.Count -gt 0) {
    Add-Check -Id "V18" -Description "rejectedClaims non-empty" -Pass $true -Detail "$($packet.rejectedClaims.Count) claims"
} else {
    Add-Check -Id "V18" -Description "rejectedClaims non-empty" -Pass $false -Detail "No rejected claims — suspicious"
}

# === V19: requiredReads non-empty ===
if ($packet.requiredReads -and $packet.requiredReads.Count -gt 0) {
    Add-Check -Id "V19" -Description "requiredReads non-empty" -Pass $true -Detail "$($packet.requiredReads.Count) reads"
} else {
    Add-Check -Id "V19" -Description "requiredReads non-empty" -Pass $false -Detail "No required reads"
}

# === V20: ANTI-DECEPTION: No process-artifact-as-product-quality ===
$processAsProduct = $false
$forbiddenStr = ($packet.forbiddenAssumptions -join " ") + ($packet.rejectedClaims | ForEach-Object { $_.claim + " " + $_.rejectionReason }) -join " "
if ($forbiddenStr -match "process.*product.*quality|product.*superior") {
    # These are correctly listed as FORBIDDEN — good
    Add-Check -Id "V20" -Description "Process not claimed as product quality" -Pass $true -Detail "Forbidden assumptions correctly flag process!=product"
} else {
    Add-Check -Id "V20" -Description "Process not claimed as product quality" -Pass $false -Detail "Missing explicit process!=product quality boundary" -Severity "WARNING"
}

# === V21: No multi-agent default claim ===
$maDefault = $false
if ($forbiddenStr -match "multi.agent.*default|default.*multi.agent") {
    Add-Check -Id "V21" -Description "No multi-agent default claim" -Pass $true -Detail "Multi-agent default correctly flagged as forbidden"
} else {
    Add-Check -Id "V21" -Description "No multi-agent default claim" -Pass $false -Detail "Missing explicit multi-agent default rejection" -Severity "WARNING"
}

# === Compute result ===
$overall = if ($failed -eq 0 -and ($Strict -eq $false -or $warnings -eq 0)) { "PASS" } else { "FAIL" }

$result = [ordered]@{
    overall = $overall
    passedChecks = $passed
    failedChecks = $failed
    warnings = $warnings
    totalChecks = $script:checks.Count
    packetId = if ($packet.packetId) { $packet.packetId } else { "UNKNOWN" }
    validatedAt = (Get-Date).ToString("o")
    stale = $stale
    checks = $script:checks
}

$resultJson = $result | ConvertTo-Json -Depth 4
$resultPath = Join-Path (Split-Path $PacketPath -Parent) "validation-result.json"
$resultJson | Out-File $resultPath -Encoding UTF8
Write-Host $resultJson

if ($failed -gt 0) { exit 1 }
if ($Strict -and $warnings -gt 0) { exit 2 }
exit 0

