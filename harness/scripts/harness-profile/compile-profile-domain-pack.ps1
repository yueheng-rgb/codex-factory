# compile-profile-domain-pack.ps1 �?Phase 6C-H3
# Reads a profile, domain skill pack, and domain verifier pack,
# then emits a compiled run package with a generated run contract.
param(
    [Parameter(Mandatory=$true)][string]$ProfilePath,
    [Parameter(Mandatory=$true)][string]$DomainSkillPath,
    [Parameter(Mandatory=$true)][string]$DomainVerifierPath,
    [Parameter(Mandatory=$true)][string]$OutputDir
)

$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

# Load inputs
if (-not (Test-Path $ProfilePath)) { [void]$errors.Add("PROFILE_NOT_FOUND"); exit 1 }
if (-not (Test-Path $DomainSkillPath)) { [void]$errors.Add("DOMAIN_SKILL_NOT_FOUND"); exit 1 }
if (-not (Test-Path $DomainVerifierPath)) { [void]$errors.Add("VERIFIER_PACK_NOT_FOUND"); exit 1 }

try { $profile = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { [void]$errors.Add("PROFILE_INVALID_JSON"); exit 1 }
try { $domain = Get-Content $DomainSkillPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { [void]$errors.Add("DOMAIN_SKILL_INVALID_JSON"); exit 1 }
try { $verifier = Get-Content $DomainVerifierPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { [void]$errors.Add("VERIFIER_PACK_INVALID_JSON"); exit 1 }

[void]$passes.Add("All inputs loaded")

# Validate profile-domain match
if ($profile.profileId -and $domain.domainId) {
    [void]$passes.Add("Profile $($profile.profileId) + Domain $($domain.domainId)")
} else {
    [void]$errors.Add("PROFILE_DOMAIN_MISMATCH: missing IDs"); $exitCode = 1
}

# Validate worker responsibilities cover domain entities
$domainEntities = $domain.domainEntities | ForEach-Object { $_.entityId }
$assignedEntities = @()
if ($domain.requiredWorkerResponsibilities) {
    $domain.requiredWorkerResponsibilities | ForEach-Object {
        if ($_.assignedEntities) { $script:assignedEntities += $_.assignedEntities }
    }
}
$unassignedEntities = $domainEntities | Where-Object { $_ -notin $assignedEntities }
if ($unassignedEntities.Count -gt 0) {
    [void]$errors.Add("UNASSIGNED_ENTITIES: $($unassignedEntities -join ', ')")
    $exitCode = 1
} else {
    [void]$passes.Add("All $($domainEntities.Count) entities assigned to workers")
}

# Validate profile complexity is not lowered by domain
$profMinWorkers = $profile.defaultComplexityBudget.minimumWorkers
$domainWorkers = ($domain.requiredWorkerResponsibilities | Measure-Object).Count
if ($domainWorkers -lt $profMinWorkers) {
    [void]$errors.Add("PROFILE_COMPLEXITY_LOWERED: domain workers=$domainWorkers < profile minimum=$profMinWorkers")
    $exitCode = 1
} else {
    [void]$passes.Add("Complexity: domain workers $domainWorkers >= profile $profMinWorkers")
}

# Generate run contract
$runContract = [ordered]@{
    runId = "h3-compiled-$($profile.profileId)-$($domain.domainId)"
    phase = "Phase 6C-H3"
    projectProfile = $profile.profileId
    domainId = $domain.domainId
    requiredWorkers = $domainWorkers
    requiredTasks = $domain.requiredDomainScenarios.Count
    minimumJsFiles = $profile.defaultComplexityBudget.minimumJsFiles
    minimumNamedExports = $profile.defaultComplexityBudget.minimumNamedExports
    minimumCrossWorkerDeps = $profile.defaultComplexityBudget.minimumCrossWorkerDeps
    requiredScenarioCount = $verifier.acceptanceScenarios.Count
    requiredAcceptanceLayers = $profile.defaultAcceptanceLayers
    requiredArtifacts = $profile.recommendedArtifacts
    requiredNegativeControls = $verifier.negativeControls.Count
    noExternalPackages = $true
    nodeBuiltinsOnly = $true
    requireRunState = $true
    requireWorkerFreeze = $true
    requireIntegrationLedger = $true
    requireVerifierHashLock = $true
    forbiddenSimplifications = $profile.forbiddenSimplifications
    domainInvariants = $domain.invariants
    domainBusinessRuleCount = $domain.businessRules.Count
    sourceProfile = $ProfilePath
    sourceDomainSkill = $DomainSkillPath
    sourceVerifierPack = $DomainVerifierPath
}# compile-profile-domain-pack.ps1 �?Phase 6C-H3
# Reads a profile, domain skill pack, and domain verifier pack,
# then emits a compiled run package with a generated run contract.
param(
    [Parameter(Mandatory=$true)][string]$ProfilePath,
    [Parameter(Mandatory=$true)][string]$DomainSkillPath,
    [Parameter(Mandatory=$true)][string]$DomainVerifierPath,
    [Parameter(Mandatory=$true)][string]$OutputDir
)

$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

# Load inputs
if (-not (Test-Path $ProfilePath)) { [void]$errors.Add("PROFILE_NOT_FOUND"); exit 1 }
if (-not (Test-Path $DomainSkillPath)) { [void]$errors.Add("DOMAIN_SKILL_NOT_FOUND"); exit 1 }
if (-not (Test-Path $DomainVerifierPath)) { [void]$errors.Add("VERIFIER_PACK_NOT_FOUND"); exit 1 }

try { $profile = Get-Content $ProfilePath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { [void]$errors.Add("PROFILE_INVALID_JSON"); exit 1 }
try { $domain = Get-Content $DomainSkillPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { [void]$errors.Add("DOMAIN_SKILL_INVALID_JSON"); exit 1 }
try { $verifier = Get-Content $DomainVerifierPath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { [void]$errors.Add("VERIFIER_PACK_INVALID_JSON"); exit 1 }

[void]$passes.Add("All inputs loaded")

# Validate profile-domain match
if ($profile.profileId -and $domain.domainId) {
    [void]$passes.Add("Profile $($profile.profileId) + Domain $($domain.domainId)")
} else {
    [void]$errors.Add("PROFILE_DOMAIN_MISMATCH: missing IDs"); $exitCode = 1
}

# Validate worker responsibilities cover domain entities
$domainEntities = $domain.domainEntities | ForEach-Object { $_.entityId }
$assignedEntities = @()
if ($domain.requiredWorkerResponsibilities) {
    $domain.requiredWorkerResponsibilities | ForEach-Object {
        if ($_.assignedEntities) { $script:assignedEntities += $_.assignedEntities }
    }
}
$unassignedEntities = $domainEntities | Where-Object { $_ -notin $assignedEntities }
if ($unassignedEntities.Count -gt 0) {
    [void]$errors.Add("UNASSIGNED_ENTITIES: $($unassignedEntities -join ', ')")
    $exitCode = 1
} else {
    [void]$passes.Add("All $($domainEntities.Count) entities assigned to workers")
}

# Validate profile complexity is not lowered by domain
$profMinWorkers = $profile.defaultComplexityBudget.minimumWorkers
$domainWorkers = ($domain.requiredWorkerResponsibilities | Measure-Object).Count
if ($domainWorkers -lt $profMinWorkers) {
    [void]$errors.Add("PROFILE_COMPLEXITY_LOWERED: domain workers=$domainWorkers < profile minimum=$profMinWorkers")
    $exitCode = 1
} else {
    [void]$passes.Add("Complexity: domain workers $domainWorkers >= profile $profMinWorkers")
}

# Generate run contract
$runContract = [ordered]@{
    runId = "h3-compiled-$($profile.profileId)-$($domain.domainId)"
    phase = "Phase 6C-H3"
    projectProfile = $profile.profileId
    domainId = $domain.domainId
    requiredWorkers = $domainWorkers
    requiredTasks = $domain.requiredDomainScenarios.Count
    minimumJsFiles = $profile.defaultComplexityBudget.minimumJsFiles
    minimumNamedExports = $profile.defaultComplexityBudget.minimumNamedExports
    minimumCrossWorkerDeps = $profile.defaultComplexityBudget.minimumCrossWorkerDeps
    requiredScenarioCount = $verifier.acceptanceScenarios.Count
    requiredAcceptanceLayers = $profile.defaultAcceptanceLayers
    requiredArtifacts = $profile.recommendedArtifacts
    requiredNegativeControls = $verifier.negativeControls.Count
    noExternalPackages = $true
    nodeBuiltinsOnly = $true
    requireRunState = $true
    requireWorkerFreeze = $true
    requireIntegrationLedger = $true
    requireVerifierHashLock = $true
    forbiddenSimplifications = $profile.forbiddenSimplifications
    domainInvariants = $domain.invariants
    domainBusinessRuleCount = $domain.businessRules.Count
    sourceProfile = $ProfilePath
    sourceDomainSkill = $DomainSkillPath
    sourceVerifierPack = $DomainVerifierPath
}

# Write output
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$runContract | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputDir "run-contract.json") -Encoding UTF8
$profile | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputDir "profile.json") -Encoding UTF8
$domain | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputDir "domain-skill-pack.json") -Encoding UTF8
$verifier | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputDir "domain-verifier-pack.json") -Encoding UTF8

[void]$passes.Add("Compiled to $OutputDir")

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict = $verdict
    profileId = $profile.profileId
    domainId = $domain.domainId
    workerCount = $domainWorkers
    scenarioCount = $verifier.acceptanceScenarios.Count
    negativeCount = $verifier.negativeControls.Count
    entityCount = $domainEntities.Count
    unassignedEntities = $unassignedEntities
    outputDir = $OutputDir
    passCount = $passes.Count
    failCount = $errors.Count
    passes = $passes
    errors = $errors
    timestamp = (Get-Date).ToString("o")
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
