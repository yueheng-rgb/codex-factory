# verify-dry18-readiness.ps1 - Phase 6C-H9-P1 (mandatory floor enforcement)
param(
    [Parameter(Mandatory=$true)][string]$ReadinessJsonPath,
    [string]$RunPlanPath = "",
    [string]$ProfilePath = "",
    [string]$DomainPackPath = "",
    [string]$VerifierPackPath = ""
)
$ErrorActionPreference = "Continue"
$ts = (Get-Date).ToString("o")
$errors = @()
$passes = @()
$missingControls = @()
$legacyFindings = @()
$requiredUpgrades = @()
$exitCode = 0
$floorViolations = @()

function Check($name, $condition, $detail) {
    if ($condition) { $script:passes += "${name}: PASS - ${detail}" }
    else { $script:errors += "${name}: FAIL - ${detail}"; $script:missingControls += $name; $script:exitCode = 1 }
}

if (-not (Test-Path $ReadinessJsonPath)) {
    Write-Output (ConvertTo-Json -InputObject @{verdict="FAIL"; classification="FAIL_MISSING_EVIDENCE"; errors=@("READINESS_JSON_NOT_FOUND")} -Depth 3 -Compress)
    exit 1
}

try { $r = Get-Content $ReadinessJsonPath -Raw | ConvertFrom-Json } catch {
    Write-Output (ConvertTo-Json -InputObject @{verdict="FAIL"; classification="FAIL_HARNESS_NOISE"; errors=@("READINESS_JSON_INVALID")} -Depth 3 -Compress)
    exit 1
}

# Resolve relative paths against readiness JSON directory
$readinessDir = Split-Path $ReadinessJsonPath -Parent
function Resolve-Path($p) {
    if (-not $p -or $p -eq "not-required") { return $p }
    if ([System.IO.Path]::IsPathRooted($p)) { return $p }
    return Join-Path $script:readinessDir $p
}

# Schema validation
$requiredFields = @("readinessId","phase","targetPhase","projectProfile","domainPack","verifierPack","securitySensitiveDomain","externalReferencePlan","preSpawnRunPlanPath","preSpawnValidationResultPath","workerContracts","postSpawnValidationRequired","acceptanceEvidenceStandard","negativeControlStandard","complexityStandard","pipelineControlsRequired","auditControlsRequired","reportSanitizerRequired","runStateRequired","workerFreezeRequired","integrationLedgerRequired","noExternalPackages","readinessVerdict")
$missing = @($requiredFields | Where-Object { $null -eq $r.$_ })
if ($missing.Count -gt 0) { $errors += "MISSING_REQUIRED_FIELDS: $($missing -join ', ')"; $exitCode = 1 }
$passes += "SCHEMA_VALID: All required fields present"

# Profile
$profilePath = if ($ProfilePath) { $ProfilePath } else { Resolve-Path $r.projectProfile }
if ($profilePath -and $profilePath -ne "not-required") {
    if (Test-Path $profilePath) { $passes += "PROFILE: Profile exists" }
    else { Check "PROFILE_MISSING" $false "Project profile not found: $profilePath" }
} else { Check "PROFILE_MISSING" $false "Profile path not specified" }

# Domain pack
$domainPath = if ($DomainPackPath) { $DomainPackPath } else { Resolve-Path $r.domainPack }
if ($domainPath -and $domainPath -ne "not-required") {
    if (Test-Path $domainPath) { $passes += "DOMAIN_PACK: Domain pack exists" }
    else { Check "DOMAIN_PACK_MISSING" $false "Domain pack not found: $domainPath" }
} else { Check "DOMAIN_PACK_MISSING" $false "Domain pack path not specified" }

# Pre-spawn
$preSpawnPath = Resolve-Path $r.preSpawnValidationResultPath
if ($preSpawnPath -and $preSpawnPath -ne "not-required" -and (Test-Path $preSpawnPath)) {
    try {
        $preResult = Get-Content $preSpawnPath -Raw | ConvertFrom-Json
        if ($preResult.verdict -eq "PASS") { $passes += "PRE_SPAWN: Validation PASS" }
        else { Check "PRE_SPAWN_FAILED" $false "Pre-spawn validation not PASS: $($preResult.verdict)" }
    } catch { Check "PRE_SPAWN_INVALID" $false "Cannot parse pre-spawn validation result" }
} else { Check "PRE_SPAWN_MISSING" $false "Pre-spawn validation result missing" }

# Worker contracts
$wcs = @(if ($r.workerContracts) { $r.workerContracts } else { @() })
if ($wcs.Count -gt 0) {
    $allSpawnAllowed = ($wcs | Where-Object { $_.spawnAllowed -ne $true }).Count -eq 0
    $allPreSpawnPassed = ($wcs | Where-Object { $_.preSpawnValidationPassed -ne $true }).Count -eq 0
    if ($allSpawnAllowed -and $allPreSpawnPassed) { $passes += "WORKER_CONTRACTS: All $($wcs.Count) workers spawnAllowed after validation" }
    else { Check "WORKER_CONTRACTS_WEAK" $false "$(($wcs | Where-Object { -not $_.spawnAllowed }).Count) without spawnAllowed" }
} else { Check "WORKER_CONTRACTS_MISSING" $false "No worker contracts defined" }

# Post-spawn
Check "POST_SPAWN" $r.postSpawnValidationRequired "Post-spawn validation is required"
$h8v = "C:\Codex_App_Factory\harness\scripts\harness-worker\verify-worker-output-contract.ps1"
Check "H8_WORKER_VERIFIER" (Test-Path $h8v) "H8 worker verifier exists"

# Acceptance evidence
$aes = $r.acceptanceEvidenceStandard
if ($aes) {
    Check "ACCEPTANCE_TRANSCRIPT" $aes.requiresTranscript "Transcript required"
    Check "ACCEPTANCE_COMMAND" $aes.requiresCommand "Command required"
    Check "ACCEPTANCE_EXIT_CODE" $aes.requiresExitCode "Exit code required"
    Check "ACCEPTANCE_ASSERTIONS" $aes.requiresScenarioAssertions "Scenario assertions required"
    Check "ACCEPTANCE_TARGET_ID" $aes.requiresTargetScenarioIdForNegatives "TargetScenarioId required"
    Check "ACCEPTANCE_NO_PRECLASSIFIED" $aes.forbidsPreclassifiedOnly "Preclassified-only forbidden"
} else { Check "ACCEPTANCE_STANDARD_MISSING" $false "Acceptance evidence standard not defined" }

$h8p1a = "C:\Codex_App_Factory\harness\scripts\harness-acceptance\analyze-acceptance-evidence.ps1"
Check "H8P1_ANALYZER" (Test-Path $h8p1a) "H8-P1 analyzer exists"
$h8p2v = "C:\Codex_App_Factory\harness\scripts\harness-acceptance\verify-acceptance-evidence-integrity.ps1"
Check "H8P2_VERIFIER" (Test-Path $h8p2v) "H8-P2 verifier exists"

# Negative controls
$ncs = $r.negativeControlStandard
if ($ncs) {
    Check "NEG_LIVE_EXEC" $ncs.liveExecutionRequired "Live execution required"
    Check "NEG_FAULT_MANIFEST" $ncs.faultManifestRequired "Fault manifest required"
    Check "NEG_HASHES" $ncs.beforeAfterHashesRequired "Before/after hashes required"
    Check "NEG_NON_TARGET" $ncs.nonTargetGateEvidenceRequired "Non-target gate evidence required"
    Check "NEG_ADAPTATION" $ncs.scenarioAdaptationGovernanceRequired "Scenario adaptation governance required"
} else { Check "NEGATIVE_STANDARD_MISSING" $false "Negative control standard not defined" }

# === H9-P1: Complexity Standard with Mandatory Floor Enforcement ===
$cs = $r.complexityStandard
if ($cs) {
    $mandatoryFloors = @{
        minimumWorkers = 5
        minimumJsFiles = 45
        minimumNamedExports = 85
        minimumCrossWorkerDeps = 40
        minimumScenarios = 20
    }
    
    $floorViolations = @()
    if ($cs.minimumWorkers -lt $mandatoryFloors.minimumWorkers) { $floorViolations += "Workers: $($cs.minimumWorkers) < $($mandatoryFloors.minimumWorkers)" }
    if ($cs.minimumJsFiles -lt $mandatoryFloors.minimumJsFiles) { $floorViolations += "JS files: $($cs.minimumJsFiles) < $($mandatoryFloors.minimumJsFiles)" }
    if ($cs.minimumNamedExports -lt $mandatoryFloors.minimumNamedExports) { $floorViolations += "Named exports: $($cs.minimumNamedExports) < $($mandatoryFloors.minimumNamedExports)" }
    if ($cs.minimumCrossWorkerDeps -lt $mandatoryFloors.minimumCrossWorkerDeps) { $floorViolations += "Cross-worker deps: $($cs.minimumCrossWorkerDeps) < $($mandatoryFloors.minimumCrossWorkerDeps)" }
    if ($cs.minimumScenarios -lt $mandatoryFloors.minimumScenarios) { $floorViolations += "Scenarios: $($cs.minimumScenarios) < $($mandatoryFloors.minimumScenarios)" }
    
    if ($floorViolations.Count -gt 0) {
        $errors += "FLOOR_VIOLATION: $($floorViolations -join '; ')"
        $classification = "FAIL_CONTRACT_DRIFT"
        $exitCode = 1
        
        # CAVEAT_ABUSE: PASS_WITH_CAVEAT cannot hide floor violations
        if ($r.readinessVerdict -eq "PASS_WITH_CAVEAT") {
            $errors += "CAVEAT_ABUSE: PASS_WITH_CAVEAT cannot hide mandatory floor violations"
        }
    }
    
    if ($floorViolations.Count -eq 0) {
        Check "COMPLEXITY_DERIVED" $cs.derivedMetricsRequired "Derived metrics required"
        Check "COMPLEXITY_NO_CLAIMED" $cs.reportClaimedMetricsForbidden "Report-claimed metrics forbidden"
        Check "COMPLEXITY_WORKERS" ($cs.minimumWorkers -ge $mandatoryFloors.minimumWorkers) "Workers: $($cs.minimumWorkers) >= $($mandatoryFloors.minimumWorkers)"
        Check "COMPLEXITY_JS" ($cs.minimumJsFiles -ge $mandatoryFloors.minimumJsFiles) "JS: $($cs.minimumJsFiles) >= $($mandatoryFloors.minimumJsFiles)"
        Check "COMPLEXITY_EXPORTS" ($cs.minimumNamedExports -ge $mandatoryFloors.minimumNamedExports) "Exports: $($cs.minimumNamedExports) >= $($mandatoryFloors.minimumNamedExports)"
        Check "COMPLEXITY_DEPS" ($cs.minimumCrossWorkerDeps -ge $mandatoryFloors.minimumCrossWorkerDeps) "Deps: $($cs.minimumCrossWorkerDeps) >= $($mandatoryFloors.minimumCrossWorkerDeps)"
        Check "COMPLEXITY_SCENARIOS" ($cs.minimumScenarios -ge $mandatoryFloors.minimumScenarios) "Scenarios: $($cs.minimumScenarios) >= $($mandatoryFloors.minimumScenarios)"
    }
} else {
    $errors += "COMPLEXITY_STANDARD_MISSING"
    $classification = "FAIL_CONTRACT_DRIFT"
    $exitCode = 1
}

# Pipeline controls
$pipeline = @(if ($r.pipelineControlsRequired) { $r.pipelineControlsRequired } else { @() })
$requiredPipeline = @("RUN_STATE","worker-freeze-manifests","integration-patches.jsonl","classify-run-verdict","report-sanitizer")
foreach ($rp in $requiredPipeline) { Check "PIPELINE_$rp" ($rp -in $pipeline) "Pipeline: $rp" }

# Audit controls
$audit = @(if ($r.auditControlsRequired) { $r.auditControlsRequired } else { @() })
$requiredAudit = @("stale-report","threshold-drift","skipped-as-pass","intended-failure-mismatch","closed-evidence-mutation")
foreach ($ra in $requiredAudit) { Check "AUDIT_$ra" ($ra -in $audit) "Audit: $ra" }

# Report sanitizer
Check "REPORT_SANITIZER" $r.reportSanitizerRequired "Report sanitizer required"

# RUN_STATE
Check "RUN_STATE" $r.runStateRequired "RUN_STATE required"

# Worker freeze
Check "WORKER_FREEZE" $r.workerFreezeRequired "Worker freeze required"

# Integration ledger
Check "INTEGRATION_LEDGER" $r.integrationLedgerRequired "Integration ledger required"

# No external packages
Check "NO_EXTERNAL_PACKAGES" $r.noExternalPackages "No external packages"

# Security domain external reference
if ($r.securitySensitiveDomain -eq $true) {
    if ($r.externalReferencePlan -and $r.externalReferencePlan -ne "not-required") {
        $passes += "EXTERNAL_REF: Security domain has external reference plan"
    } else { Check "EXTERNAL_REF_MISSING" $false "Security-sensitive domain requires external reference plan" }
}

# Legacy evidence rejection
if ($r.targetPhase -and $r.targetPhase -match "DRY1[89]|DRY2\d") {
    if ($r.acceptanceEvidenceStandard.requiresTranscript -and $r.acceptanceEvidenceStandard.requiresCommand -and $r.acceptanceEvidenceStandard.forbidsPreclassifiedOnly) {
        $passes += "LEGACY_REJECTED: DRY18+ standard rejects legacy format"
    } else { Check "LEGACY_NOT_REJECTED" $false "DRY18+ must reject legacy evidence format" }
}

# Classification
$classification = if ($exitCode -eq 0) { "PASS" }
    elseif ($floorViolations.Count -gt 0) { "FAIL_CONTRACT_DRIFT" }
    else { "FAIL_MISSING_EVIDENCE" }

if ($classification -eq "FAIL") { $classification = "FAIL_HARNESS_NOISE" }

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict = $verdict
    classification = $classification
    totalChecks = ($passes.Count + $errors.Count)
    passCount = $passes.Count
    failCount = $errors.Count
    readinessChecks = $passes
    failedChecks = $errors
    missingControls = $missingControls
    legacyEvidenceFindings = $legacyFindings
    requiredUpgrades = $requiredUpgrades
    checkedAt = $ts
    readinessId = $r.readinessId
}
Write-Output (ConvertTo-Json -InputObject $result -Depth 4 -Compress)
exit $exitCode