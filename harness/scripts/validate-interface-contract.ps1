# validate-interface-contract.ps1 — Phase 6C-U0-A
# Validates an interface contract lock file against INTERFACE_CONTRACT_SCHEMA.json.
# READ-ONLY: never modifies the contract.
param(
    [Parameter(Mandatory=$true)][string]$ContractPath,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

if (-not (Test-Path $ContractPath)) {
    [void]$errors.Add("CONTRACT_NOT_FOUND: $ContractPath")
    $result = @{ verdict="FAIL"; errors=$errors; passes=$passes; checkedContractPath=$ContractPath; timestamp=(Get-Date).ToString("o") }
    if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: Contract not found" }
    exit 1
}

[void]$passes.Add("Contract file exists: $ContractPath")

try {
    $contract = Get-Content $ContractPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    [void]$errors.Add("CONTRACT_INVALID_JSON: $_")
    $result = @{ verdict="FAIL"; errors=$errors; passes=$passes; checkedContractPath=$ContractPath; timestamp=(Get-Date).ToString("o") }
    if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: Invalid JSON" }
    exit 1
}

[void]$passes.Add("Contract is valid JSON")

# Check required top-level fields
$requiredFields = @("phase","contractId","locked","createdAtUtc","interfaces")
foreach ($f in $requiredFields) {
    if ($null -ne $contract.$f) {
        [void]$passes.Add("Field present: $f = $($contract.$f)")
    } else {
        [void]$errors.Add("MISSING_FIELD: $f")
        $exitCode = 1
    }
}

# Check locked = true
if ($contract.locked -eq $true) {
    [void]$passes.Add("Contract is locked")
} else {
    [void]$errors.Add("CONTRACT_NOT_LOCKED: locked=$($contract.locked)")
    $exitCode = 1
}

# Check interfaces array
if ($contract.interfaces -is [array] -and $contract.interfaces.Count -gt 0) {
    [void]$passes.Add("Interfaces count: $($contract.interfaces.Count)")
} else {
    [void]$errors.Add("NO_INTERFACES: interfaces is empty or not an array")
    $exitCode = 1
}

# Check each interface
$ifaceRequired = @("interfaceId","name","kind","owner","file","requiredBy")
$seenIds = @{}
foreach ($iface in $contract.interfaces) {
    foreach ($f in $ifaceRequired) {
        if ($null -eq $iface.$f) {
            [void]$errors.Add("INTERFACE_MISSING_FIELD: interfaceId=$($iface.interfaceId) missing=$f")
            $exitCode = 1
        }
    }
    if ($seenIds.ContainsKey($iface.interfaceId)) {
        [void]$errors.Add("DUPLICATE_INTERFACE_ID: $($iface.interfaceId)")
        $exitCode = 1
    }
    $seenIds[$iface.interfaceId] = $true
}
if ($exitCode -eq 0) { [void]$passes.Add("All interfaces have required fields, no duplicate IDs") }

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    phase = "Phase 6C-U0-A"
    tool = "validate-interface-contract"
    verdict = $verdict
    checkedContractPath = $ContractPath
    interfaceCount = $contract.interfaces.Count
    errorCount = $errors.Count
    passCount = $passes.Count
    errors = $errors
    passes = $passes
    timestamp = (Get-Date).ToString("o")
}
if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "Verdict: $verdict" }
exit $exitCode