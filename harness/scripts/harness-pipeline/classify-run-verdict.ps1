# classify-run-verdict.ps1 — Phase 6C-H2 (H2-P1 hardened)
# Reads evidence JSON from fixture runs and classifies verdict using H2 taxonomy.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$harnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$coreScripts = "$harnessRoot\scripts\harness-core"

function classify($code, $reason) {
    return @{ classifiedVerdict=$code; reason=$reason; timestamp=(Get-Date).ToString("o") }
}

function run-core-script($scriptName, $arguments) {
    $scriptPath = Join-Path $coreScripts $scriptName
    if (-not (Test-Path $scriptPath)) {
        return @{ verdict="FAIL"; errors=@("SCRIPT_NOT_FOUND: $scriptName") }
    }
    $argsList = @("-NoProfile", "-File", $scriptPath) + $arguments
    $out = & powershell @argsList 2>&1 | Out-String
    if ($out.Trim().Length -gt 0) {
        try { return ($out.Trim() | ConvertFrom-Json) } catch { return @{ verdict="PARSE_ERROR" } }
    }
    return @{ verdict="NO_OUTPUT" }
}

# Check 1: Missing RUN_STATE
$stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
if (-not (Test-Path $stateFile)) {
    $result = classify "FAIL_MISSING_EVIDENCE" "RUN_STATE.jsonl not found"
    Write-Output ($result | ConvertTo-Json)
    exit 3
}

# Load RUN_STATE events
$events = @()
try {
    $lines = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
    foreach ($l in $lines) { $events += ($l | ConvertFrom-Json) }
} catch {
    $result = classify "FAIL_HARNESS_NOISE" "Cannot parse RUN_STATE.jsonl"
    Write-Output ($result | ConvertTo-Json)
    exit 4
}

if ($events.Count -eq 0) {
    $result = classify "FAIL_MISSING_EVIDENCE" "RUN_STATE.jsonl is empty"
    Write-Output ($result | ConvertTo-Json)
    exit 3
}

# Check 2: Worker freeze mutations
$freezeDir = Join-Path $RunDir "worker-freeze-manifests"
if (Test-Path $freezeDir) {
    $manifests = @(Get-ChildItem $freezeDir -Filter "*.freeze.json")
    foreach ($m in $manifests) {
        $verifyResult = run-core-script "verify-worker-freeze.ps1" @("-FreezeManifestPath", $m.FullName)
        if ($verifyResult.verdict -eq "FAIL") {
            $hasMutation = ($verifyResult.errors | Where-Object { $_ -match "FILE_HASH_CHANGED|FILE_ADDED_AFTER_FREEZE" }).Count -gt 0
            if ($hasMutation) {
                $result = classify "FAIL_CLOSED_EVIDENCE_MUTATION" "Worker freeze mutation: $($verifyResult.errors -join '; ')"
                Write-Output ($result | ConvertTo-Json)
                exit 7
            }
        }
    }
}

# Check 3: Integration unrecorded patch
$ledgerPath = Join-Path $RunDir "integration-patches.jsonl"
$canonicalDir = Join-Path $RunDir "canonical-integrated"
if ((Test-Path $canonicalDir) -and (-not (Test-Path $ledgerPath))) {
    $result = classify "FAIL_INTEGRATION_UNRECORDED_PATCH" "Canonical output exists but no integration-patches.jsonl"
    Write-Output ($result | ConvertTo-Json)
    exit 9
}

if (Test-Path $ledgerPath) {
    $ledgerVerify = run-core-script "verify-integration-patch-ledger.ps1" @("-LedgerPath", $ledgerPath)
    if ($ledgerVerify.verdict -eq "FAIL") {
        $result = classify "FAIL_INTEGRATION_UNRECORDED_PATCH" "Integration ledger validation failed"
        Write-Output ($result | ConvertTo-Json)
        exit 9
    }
}

# Check 4: Verifier tamper — fixture-local first, then global
$fixtureTamperReg = Join-Path $RunDir "tampered-registry\tampered-registry.json"
$tamperDetected = $false
if (Test-Path $fixtureTamperReg) {
    $regVerify = run-core-script "verify-verifier-registry.ps1" @("-RegistryPath", $fixtureTamperReg, "-HarnessRoot", $harnessRoot)
    if ($regVerify.verdict -eq "FAIL") {
        $hasHashMismatch = ($regVerify.errors | Where-Object { $_ -match "HASH_MISMATCH" }).Count -gt 0
        if ($hasHashMismatch) {
            $tamperDetected = $true
            $result = classify "FAIL_VERIFIER_TAMPER" "Fixture-local tampered verifier registry: hash mismatch"
            Write-Output ($result | ConvertTo-Json)
            exit 8
        }
    }
}
if (-not $tamperDetected) {
    $regPath = Join-Path $harnessRoot "governance\harness-core\verifier-registry.json"
    if (Test-Path $regPath) {
        $regVerify = run-core-script "verify-verifier-registry.ps1" @("-RegistryPath", $regPath, "-HarnessRoot", $harnessRoot)
        if ($regVerify.verdict -eq "FAIL") {
            $hasHashMismatch = ($regVerify.errors | Where-Object { $_ -match "HASH_MISMATCH" }).Count -gt 0
            if ($hasHashMismatch) {
                $result = classify "FAIL_VERIFIER_TAMPER" "Global verifier hash mismatch detected"
                Write-Output ($result | ConvertTo-Json)
                exit 8
            }
        }
    }
}

# Check 5: Threshold drift
$contractPath = Join-Path $RunDir "run-contract.json"
if ((Test-Path $contractPath) -and (Test-Path $canonicalDir)) {
    $ctVerify = run-core-script "verify-run-contract.ps1" @("-ContractPath", $contractPath, "-RunDir", $RunDir)
    if ($ctVerify.verdict -eq "FAIL") {
        $hasThresholdDrift = ($ctVerify.errors | Where-Object { $_ -match "THRESHOLD_DRIFT" }).Count -gt 0
        if ($hasThresholdDrift) {
            $result = classify "FAIL_CONTRACT_DRIFT" "Threshold drift without reconciliation"
            Write-Output ($result | ConvertTo-Json)
            exit 6
        }
    }
}

# Check 6: Target gate failure
$reportsDir = Join-Path $RunDir "reports"
if (Test-Path $reportsDir) {
    $searchReport = Join-Path $reportsDir "search-pagination-performance-acceptance-report.json"
    if (Test-Path $searchReport) {
        try {
            $sr = Get-Content $searchReport -Raw | ConvertFrom-Json
            if ($sr.verdict -eq "FAIL" -and $sr.intendedFailure -eq $true) {
                $evidenceIntact = (Test-Path $stateFile) -and ($events.Count -gt 0)
                if ($evidenceIntact) {
                    $result = classify "FAIL_TARGET_GATE" "Target acceptance gate failed: $($sr.scenario)"
                    Write-Output ($result | ConvertTo-Json)
                    exit 3
                }
            }
            if ($sr.verdict -eq "PASS" -and $sr.scenarioCount -lt 1) {
                $result = classify "FAIL_HARNESS_NOISE" "Acceptance report has 0 scenarios"
                Write-Output ($result | ConvertTo-Json)
                exit 4
            }
        } catch {
            $result = classify "FAIL_HARNESS_NOISE" "Cannot parse acceptance report"
            Write-Output ($result | ConvertTo-Json)
            exit 4
        }
    }
}

# Check 7: PENDING in report
$finalReport = Get-ChildItem $RunDir -Recurse -Filter "*_REPORT.md" -File | Select-Object -First 1
if ($finalReport) {
    $content = Get-Content $finalReport.FullName -Raw
    if ($content -match 'Verdict.*PENDING' -and $content -match 'Summary.*PASS') {
        $result = classify "PASS_PENDING_RECONCILIATION" "Report says PASS but verifier PENDING"
        Write-Output ($result | ConvertTo-Json)
        exit 2
    }
}

# Check 8: CFP fail-closed
$cfpResult = run-core-script "validate-cfp-fail-closed.ps1" @("-RunDir", $RunDir)
if ($cfpResult.verdict -eq "FAIL_MISSING_EVIDENCE") {
    $result = classify "FAIL_MISSING_EVIDENCE" "CFP fail-closed: evidence missing"
    Write-Output ($result | ConvertTo-Json)
    exit 3
}


# Check 9: Domain missing business rules
$domainSkillPath = Join-Path $RunDir "domain-skill-pack.json"
if (Test-Path $domainSkillPath) {
    try {
        $domainSkill = Get-Content $domainSkillPath -Raw | ConvertFrom-Json
        if ($domainSkill.businessRules -and $domainSkill.businessRules.Count -eq 0) {
            $result = classify "FAIL_MISSING_DOMAIN_RULES" "Domain skill pack has no business rules"
            Write-Output ($result | ConvertTo-Json)
            exit 10
        }
    } catch {}
}

# Check 10: Domain missing negative controls
$verifierPackPath = Join-Path $RunDir "domain-verifier-pack.json"
if (Test-Path $verifierPackPath) {
    try {
        $verifierPack = Get-Content $verifierPackPath -Raw | ConvertFrom-Json
        if ($verifierPack.negativeControls -and $verifierPack.negativeControls.Count -eq 0) {
            $result = classify "FAIL_MISSING_NEGATIVE_CONTROLS" "Domain verifier pack has no negative controls"
            Write-Output ($result | ConvertTo-Json)
            exit 11
        }
    } catch {}
}

# Check 11: Domain coverage gap (invariant w/o scenario or unassigned entity)
$gapReport = Join-Path $RunDir "gap-report.json"
if (Test-Path $gapReport) {
    try {
        $gap = Get-Content $gapReport -Raw | ConvertFrom-Json
        if ($gap.gaps -and ($gap.gaps | Where-Object { $_ -match "INVARIANT_WITHOUT_SCENARIO|UNASSIGNED_ENTITY|MISSING_BUSINESS_RULES|MISSING_NEGATIVE_CONTROLS" }).Count -gt 0) {
            $matchGap = $gap.gaps[0]
            if ($matchGap -match "INVARIANT_WITHOUT_SCENARIO|UNASSIGNED_ENTITY") {
                $result = classify "FAIL_DOMAIN_COVERAGE_GAP" "Domain coverage gap: $matchGap"
                Write-Output ($result | ConvertTo-Json)
                exit 12
            } elseif ($matchGap -match "MISSING_BUSINESS_RULES") {
                $result = classify "FAIL_MISSING_DOMAIN_RULES" "Domain missing business rules: $matchGap"
                Write-Output ($result | ConvertTo-Json)
                exit 10
            } elseif ($matchGap -match "MISSING_NEGATIVE_CONTROLS") {
                $result = classify "FAIL_MISSING_NEGATIVE_CONTROLS" "Missing negative controls: $matchGap"
                Write-Output ($result | ConvertTo-Json)
                exit 11
            }
        }
        if ($gap.gaps -and ($gap.gaps | Where-Object { $_ -match "PROFILE_COMPLEXITY_LOWERED" }).Count -gt 0) {
            $result = classify "FAIL_CONTRACT_DRIFT" "Profile complexity lowered: $($gap.gaps[0])"
            Write-Output ($result | ConvertTo-Json)
            exit 6
        }
    } catch {}
}

# Check 12: Profile boundary violation
$boundaryReport = Join-Path $RunDir "boundary-violation.json"
if (Test-Path $boundaryReport) {
    try {
        $bv = Get-Content $boundaryReport -Raw | ConvertFrom-Json
        if ($bv.verdict -eq "FAIL") {
            $result = classify "FAIL_PROFILE_BOUNDARY_VIOLATION" "Profile boundary violation: $($bv.violations[0])"
            Write-Output ($result | ConvertTo-Json)
            exit 13
        }
    } catch {}
}


# Check 13: PASS_WITH_CAVEAT detection
$caveatFile = Join-Path $RunDir "caveat-declaration.json"
if (Test-Path $caveatFile) {
    try {
        $caveat = Get-Content $caveatFile -Raw | ConvertFrom-Json
        if ($caveat.allowed -eq $true -and $caveat.type -eq "declared_limitation") {
            $result = classify "PASS_WITH_CAVEAT" "Allowed caveat: $($caveat.reason)"
            Write-Output ($result | ConvertTo-Json)
            exit 1  # exit 1 with PASS_WITH_CAVEAT verdict
        } elseif ($caveat.allowed -eq $false -and $caveat.type -eq "missing_evidence") {
            $result = classify "FAIL_MISSING_EVIDENCE" "Disallowed caveat: $($caveat.reason)"
            Write-Output ($result | ConvertTo-Json)
            exit 3
        } elseif ($caveat.type -eq "pending_reconciliation") {
            $result = classify "PASS_PENDING_RECONCILIATION" "Pending reconciliation: $($caveat.reason)"
            Write-Output ($result | ConvertTo-Json)
            exit 2
        }
    } catch {}
}

# All checks passed
$result = classify "PASS" "All evidence present, all gates pass, no mutations detected"
Write-Output ($result | ConvertTo-Json)
exit 0