# validate-profile-boundary.ps1 — Phase 6C-H3
# Profiling guard. Fails if profile attempts to hardcode domain knowledge.
param(
    [Parameter(Mandatory=$true)][string]$ProfilePath
)

$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

if (-not (Test-Path $ProfilePath)) {
    Write-Output (@{ verdict="FAIL"; reason="PROFILE_NOT_FOUND" } | ConvertTo-Json)
    exit 1
}

try { $profile = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json }
catch { Write-Output (@{ verdict="FAIL"; reason="PROFILE_INVALID_JSON" } | ConvertTo-Json); exit 1 }

# Domain-specific terms that should NOT appear in profiles
$domainTerms = @("SKU","stock","inventory","ticket","agent","workload","invoice","payment","shipment","customer","order","booking","schedule","notification")

$profileText = Get-Content $ProfilePath -Raw -Encoding UTF8
$foundTerms = @()
foreach ($term in $domainTerms) {
    if ($profileText -match "\b$term\b") { $foundTerms += $term }
}

if ($foundTerms.Count -gt 0) {
    [void]$errors.Add("PROFILE_BOUNDARY_VIOLATION: domain terms in profile: $($foundTerms -join 
)")
    $exitCode = 1
} else {
    [void]$passes.Add("Profile boundary clean: no domain terms in profile")
}

# Check profile does not define domain entities or business rules
if ($profile.domainEntities -or $profile.businessRules -or $profile.invariants) {
    [void]$errors.Add("PROFILE_CONTAINS_DOMAIN_STRUCTURES: domain entities/rules/invariants must be in domain pack, not profile")
    $exitCode = 1
} else {
    [void]$passes.Add("Profile has no domain structures (correct)")
}

# Check complexity budget has not been zeroed
$budget = $profile.defaultComplexityBudget
if ($budget.minimumWorkers -le 0) { [void]$errors.Add("COMPLEXITY_ZEROED: minimumWorkers <= 0"); $exitCode = 1 }
if ($budget.minimumJsFiles -le 0) { [void]$errors.Add("COMPLEXITY_ZEROED: minimumJsFiles <= 0"); $exitCode = 1 }
if ($budget.minimumScenarios -le 0) { [void]$errors.Add("COMPLEXITY_ZEROED: minimumScenarios <= 0"); $exitCode = 1 }

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict = $verdict
    profileId = $profile.profileId
    domainTermsFound = $foundTerms
    passCount = $passes.Count
    failCount = $errors.Count
    passes = $passes
    errors = $errors
    timestamp = (Get-Date).ToString("o")
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode