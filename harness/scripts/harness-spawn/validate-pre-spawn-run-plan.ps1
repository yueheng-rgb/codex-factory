# validate-pre-spawn-run-plan.ps1 - Phase 6C-H7
param(
    [Parameter(Mandatory=$true)][string]$RunPlanPath,
    [Parameter(Mandatory=$true)][string]$ProfilePath,
    [Parameter(Mandatory=$true)][string]$DomainSkillPath,
    [Parameter(Mandatory=$true)][string]$VerifierPackPath,
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$errors = @()
$passes = @()
$workerResults = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")

if (-not (Test-Path $RunPlanPath)) { 
    $result = @{verdict="FAIL"; spawnAllowed=$false; failedChecks=@("Run plan MISSING"); checkedAt=$ts}
    Write-Output ($result | ConvertTo-Json)
    exit 1 
}
$plan = Get-Content $RunPlanPath -Raw | ConvertFrom-Json
$domainSkill = if (Test-Path $DomainSkillPath) { Get-Content $DomainSkillPath -Raw | ConvertFrom-Json } else { $null }

$domainEntities = @()
if ($domainSkill -and $domainSkill.domainEntities) {
    foreach ($de in $domainSkill.domainEntities) {
        if ($de -is [string]) { $domainEntities += $de }
        elseif ($de.entityId) { $domainEntities += $de.entityId }
    }
}

$businessRules = @()
if ($domainSkill -and $domainSkill.businessRules) {
    foreach ($br in $domainSkill.businessRules) {
        if ($br -is [string]) { $businessRules += $br }
        elseif ($br.ruleId) { $businessRules += $br.ruleId }
    }
}

$invariants = @(if ($plan.domainInvariants) { $plan.domainInvariants } else { @() })
$allAssignedEntities = @{}
$allAssignedRules = @{}

foreach ($wc in $plan.workerContracts) {
    $wr = @{workerId=$wc.workerId; workerRole=$wc.workerRole; checks=@(); failures=@(); spawnAllowed=$false}
    
    if ($wc.workerMission.Length -lt 20) { $wr.failures += "Vague mission"; $exitCode=1 }
    else { $wr.checks += "Mission OK" }
    
    if (-not $wc.requiredExports -or $wc.requiredExports.Count -eq 0) { $wr.failures += "No exports"; $exitCode=1 }
    else { $wr.checks += "Exports: $($wc.requiredExports.Count)" }
    
    if (-not $wc.requiredEvidenceOutputs -or $wc.requiredEvidenceOutputs.Count -eq 0) { $wr.failures += "No evidence"; $exitCode=1 }
    else { $wr.checks += "Evidence: $($wc.requiredEvidenceOutputs.Count)" }
    
    if ($wc.minimumBehavioralResponsibilities -lt 3) { $wr.failures += "Behavioral<3"; $exitCode=1 }
    if (-not $wc.edgeCasesRequired -or $wc.edgeCasesRequired.Count -eq 0) { $wr.failures += "No edge cases"; $exitCode=1 }
    if (-not $wc.failureModesRequired -or $wc.failureModesRequired.Count -eq 0) { $wr.failures += "No failure modes"; $exitCode=1 }
    if ($wc.requiredNegativeControls.Count -eq 0) { $wr.failures += "No negatives"; $exitCode=1 }
    else { $wr.checks += "Negatives: $($wc.requiredNegativeControls.Count)" }
    if ($wc.acceptanceLayersTouched.Count -eq 0) { $wr.failures += "No acceptance layers"; $exitCode=1 }
    if ($wc.spawnAllowed) { $wr.failures += "spawnAllowed=true pre-validation"; $exitCode=1 }
    
    foreach ($e in $wc.requiredDomainEntities) { $allAssignedEntities[$e] = $true }
    foreach ($r in $wc.requiredBusinessRules) { $allAssignedRules[$r] = $true }
    
    if ($wr.failures.Count -eq 0) { $wr.spawnAllowed = $true }
    $workerResults += $wr
}

foreach ($de in $domainEntities) {
    if (-not $allAssignedEntities[$de]) { $errors += "Domain entity '$de' unassigned"; $exitCode=1 }
}

foreach ($br in $businessRules) {
    if (-not $allAssignedRules[$br]) { $errors += "Business rule '$br' unassigned"; $exitCode=1 }
}

foreach ($inv in $invariants) {
    $hasScenario = $false; $hasNegative = $false
    foreach ($wc in $plan.workerContracts) {
        if ($wc.requiredScenarios -contains $inv) { $hasScenario = $true }
        if ($wc.requiredNegativeControls -contains "negative-$inv") { $hasNegative = $true }
    }
    if (-not $hasScenario) { $errors += "Invariant lacks scenario: $inv"; $exitCode=1 }
    if (-not $hasNegative) { $errors += "Invariant lacks negative: $inv"; $exitCode=1 }
}

foreach ($al in $plan.requiredAcceptanceLayers) {
    $covered = $false
    foreach ($wc in $plan.workerContracts) {
        if ($wc.acceptanceLayersTouched -contains $al) { $covered = $true }
    }
    if (-not $covered) { $errors += "Layer '$al' uncovered"; $exitCode=1 }
}

$coreLayers = @("GateCheck","FunctionalAcceptance","RuntimeAcceptance","HTTPAcceptance","StaticAcceptance")
foreach ($wc in $plan.workerContracts) {
    $coreCount = 0
    foreach ($cl in $coreLayers) { if ($wc.acceptanceLayersTouched -contains $cl) { $coreCount++ } }
    if ($coreCount -eq $coreLayers.Count) { $errors += "Worker $($wc.workerId) owns all core"; $exitCode=1 }
}

$totalDeps = 0
foreach ($wc in $plan.workerContracts) { $totalDeps += $wc.expectedCrossWorkerProviders.Count }
if ($totalDeps -lt $plan.globalComplexityBudget.minimumCrossWorkerDeps) { 
    $errors += "Cross-deps $totalDeps < $($plan.globalComplexityBudget.minimumCrossWorkerDeps)"; $exitCode=1 
}

foreach ($wc in $plan.workerContracts) {
    if ($wc.requiredEvidenceOutputs.Count -eq 0) { $errors += "Worker $($wc.workerId) evidence-empty"; $exitCode=1 }
}

$allValid = ($workerResults | Where-Object { $_.failures.Count -gt 0 }).Count -eq 0
$spawnAllowed = ($exitCode -eq 0 -and $allValid)
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict=$verdict; spawnAllowed=$spawnAllowed; checkedAt=$ts
    workerResults=@($workerResults); failedChecks=@($errors); passes=@($passes)
    complexitySummary=@{totalCrossDeps=$totalDeps; workerCount=$plan.workerContracts.Count}
}
Write-Output ($result | ConvertTo-Json -Depth 4)
exit $exitCode
