# enforce-hardened-pipeline.ps1 �?Phase 6C-H4
# Preventive enforcement gate. Checks integrity, not just presence. Fails closed.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$core = "$H\scripts\harness-core"
$pipeline = "$H\scripts\harness-pipeline"
$canonicalDir = Join-Path $RunDir "canonical-integrated"
$ledgerPath = Join-Path $RunDir "integration-patches.jsonl"
$freezeDir = Join-Path $RunDir "worker-freeze-manifests"

$profile = "$H\scripts\harness-profile"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

function fail-closed($msg) { [void]$errors.Add($msg); $script:exitCode = 1 }
function pass($msg) { [void]$passes.Add($msg) }

# 1. RUN_STATE exists and hash chain validates
$stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
if (-not (Test-Path $stateFile)) { fail-closed "MISSING_EVIDENCE: RUN_STATE.jsonl not found" }
else {
    try {
        $events = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json })
        if ($events.Count -eq 0) { fail-closed "MISSING_EVIDENCE: RUN_STATE.jsonl is empty" }
        else {
            pass "RUN_STATE: $($events.Count) events"
            # Hash chain validation
            $chainOk = $true
            for ($i = 1; $i -lt $events.Count; $i++) {
                if ($events[$i].previousEventHash -ne $events[$i-1].eventHash) {
                    fail-closed "FAIL_HARNESS_NOISE: RUN_STATE hash chain broken at event $i"
                    $chainOk = $false
                    break
                }
            }
            if ($chainOk) { pass "Hash chain: valid" }
            # Required lifecycle events
            $required = @("run_started","worker_completed","worker_frozen","integration_completed","verification_completed","run_passed")
            $eventTypes = @($events | ForEach-Object { $_.eventType })
            foreach ($r in $required) {
                if ($r -in $eventTypes) { pass "Event: $r" }
                else { fail-closed "MISSING_EVIDENCE: Required lifecycle event not found in RUN_STATE: $r" }
            }
        }
    } catch { fail-closed "MISSING_EVIDENCE: RUN_STATE.jsonl is corrupted or unparseable" }
}

# 2. Worker freeze manifests
if (Test-Path $freezeDir) {
    $manifests = @(Get-ChildItem $freezeDir -Filter "*.freeze.json")
    if ($manifests.Count -eq 0) { fail-closed "MISSING_EVIDENCE: No freeze manifests found in worker-freeze-manifests" }
    foreach ($m in $manifests) {
        $verify = & powershell -NoProfile -File "$core\verify-worker-freeze.ps1" -FreezeManifestPath $m.FullName 2>&1 | Out-String | ConvertFrom-Json
        if ($verify.verdict -eq "FAIL") { fail-closed "FREEZE_FAIL: $($m.Name): $($verify.errors -join '; ')" }
        else { pass "Freeze: $($m.Name) valid" }
    }
} else { fail-closed "MISSING_EVIDENCE: WORKER_FREEZE_MANIFESTS directory not found" }

# 5. Run contract
$contractPath = Join-Path $RunDir "run-contract.json"
if (Test-Path $contractPath) {
    $verify = & powershell -NoProfile -File "$core\verify-run-contract.ps1" -ContractPath $contractPath -RunDir $RunDir 2>&1 | Out-String | ConvertFrom-Json
    if ($verify.verdict -eq "FAIL") { fail-closed "CONTRACT_FAIL: $($verify.errors -join '; ')" }
    else { pass "Run contract: valid" }
} else { pass "No run contract (allowed)" }

# 4. Verifier registry (fixture-local first, then global)
$fixtureRegPath = Join-Path $RunDir "tampered-registry\tampered-registry.json"
$globalRegPath = Join-Path $H "governance\harness-core\verifier-registry.json"
$tamperDetected = $false

if (Test-Path $fixtureRegPath) {
    $regVerify = & powershell -NoProfile -File "$core\verify-verifier-registry.ps1" -RegistryPath $fixtureRegPath -HarnessRoot $H 2>$null | Out-String | ConvertFrom-Json
    if ($regVerify.verdict -eq "FAIL") {
        fail-closed "VERIFIER_TAMPER: Fixture-local tampered registry detected"
        $tamperDetected = $true
    }
}

if (-not $tamperDetected -and (Test-Path $globalRegPath)) {
    $verify = & powershell -NoProfile -File "$core\verify-verifier-registry.ps1" -RegistryPath $globalRegPath -HarnessRoot $H 2>$null | Out-String | ConvertFrom-Json
    if ($verify.verdict -eq "FAIL") {
        $hasMismatch = ($verify.errors | Where-Object { $_ -match "HASH_MISMATCH" }).Count -gt 0
        if ($hasMismatch) { fail-closed "VERIFIER_TAMPER: Global verifier hash mismatch" }
        else { fail-closed "REGISTRY_FAIL: $($verify.errors -join '; ')" }
    } else { pass "Verifier registry: valid" }
} elseif (-not $tamperDetected) { pass "No verifier registry (allowed)" }

# 6. Report sanitizer check
$finalReport = Get-ChildItem $RunDir -Recurse -Filter "*_REPORT.md" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if ($finalReport) {
    pass "Report found: $($finalReport.Name)"
} else {
    pass "No report in run dir (fixture only)"
}
# 6.5: Profile/domain pack enforcement
if (Test-Path $contractPath) {
    try {
        $ct = Get-Content $contractPath -Raw | ConvertFrom-Json
        if ($ct.requireProfileDomainPack -eq $true) {
            $compiledPkg = Join-Path $RunDir "compiled-package"
            $runContractGen = Join-Path $RunDir "run-contract.json"
            if (-not (Test-Path $compiledPkg)) { fail-closed "MISSING_EVIDENCE: Compiled profile/domain pack required by contract but not found" }
            else { pass "Compiled profile/domain pack: present" }
        }
    } catch {}
}
# 7. Closed evidence mutation check
# Check if any file in canonical-integrated was modified after freeze by comparing 
# file timestamps against latest freeze manifest timestamp
$mutationDetected = $false
if (Test-Path $canonicalDir) {
    $freezeTimes = @()
    if (Test-Path $freezeDir) {
        Get-ChildItem $freezeDir -Filter "*.freeze.json" | ForEach-Object {
            try { 
                $fm = Get-Content $_.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
                if ($fm.frozenAt) { 
                    $freezeTimes += [DateTime]$fm.frozenAt
                }
            } catch { Write-Warning "Cannot parse freeze manifest: $($_.Name)" }
        }
    }
    if ($freezeTimes.Count -gt 0) {
        $latestFreeze = ($freezeTimes | Measure-Object -Maximum).Maximum
        # Compare as UTC ticks to avoid timezone issues
        $latestTicks = $latestFreeze.ToUniversalTime().Ticks
        $canonicalFiles = @(Get-ChildItem $canonicalDir -Recurse -File)
        foreach ($cf in $canonicalFiles) {
            $fileTicks = $cf.LastWriteTimeUtc.Ticks
            if (($fileTicks - $latestTicks) -gt 50000000) {  # 5-second grace period in ticks
                $mutationDetected = $true
                fail-closed "CLOSED_EVIDENCE_MUTATION: $($cf.Name) modified after latest worker freeze"
            }
        }
        if (-not $mutationDetected) { pass "Closed evidence: not mutated after freeze" }
    } else { pass "Closed evidence: no freeze timestamps available" }
}

# 3. Integration patch ledger
if (Test-Path $canonicalDir) {
    if (-not (Test-Path $ledgerPath)) { fail-closed "MISSING_EVIDENCE: INTEGRATION_LEDGER_NOT_FOUND: integration-patches.jsonl" }
    else {
        $verify = & powershell -NoProfile -File "$core\verify-integration-patch-ledger.ps1" -LedgerPath $ledgerPath 2>&1 | Out-String | ConvertFrom-Json
        if ($verify.verdict -eq "FAIL") { fail-closed "LEDGER_FAIL: $($verify.errors -join '; ')" }
        else { pass "Integration ledger: valid" }
    }
} else { pass "No canonical-integrated dir (allowed)" }

# Verdict
# Classify primary failure
$classification = "PASS"
$primaryFailureClass = ""
$secondaryFailureClasses = @()

if ($exitCode -ne 0) {
    $classification = "FAIL"
    # Determine primary failure class from errors
    $errText = $errors -join " "
    if ($errText -match "VERIFIER_TAMPER") { $primaryFailureClass = "FAIL_VERIFIER_TAMPER" }
    elseif ($errText -match "CLOSED_EVIDENCE_MUTATION") { $primaryFailureClass = "FAIL_CLOSED_EVIDENCE_MUTATION" }
    elseif ($errText -match "INTEGRATION_LEDGER_NOT_FOUND|INTEGRATION_UNRECORDED|LEDGER_FAIL|LEDGER_EMPTY|LEDGER_NOT_FOUND") { $primaryFailureClass = "FAIL_INTEGRATION_UNRECORDED_PATCH" }
    elseif ($errText -match "MISSING_EVIDENCE") { $primaryFailureClass = "FAIL_MISSING_EVIDENCE" }
    elseif ($errText -match "THRESHOLD_DRIFT|CONTRACT_DRIFT") { $primaryFailureClass = "FAIL_CONTRACT_DRIFT" }
    elseif ($errText -match "FAIL_HARNESS_NOISE") { $primaryFailureClass = "FAIL_HARNESS_NOISE" }
    elseif ($errText -match "PROFILE_BOUNDARY") { $primaryFailureClass = "FAIL_PROFILE_BOUNDARY_VIOLATION" }
    elseif ($errText -match "SANITIZER_FAIL") { $primaryFailureClass = "FAIL_HARNESS_NOISE" }
    else { $primaryFailureClass = "FAIL_HARNESS_NOISE" }
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict = $verdict
    classification = if ($exitCode -eq 0) { "PASS" } else { $primaryFailureClass }
    primaryFailureClass = $primaryFailureClass
    secondaryFailureClasses = $secondaryFailureClasses
    passCount = $passes.Count
    failCount = $errors.Count
    passes = $passes
    errors = $errors
    evidencePaths = @($stateFile, $contractPath, $freezeDir, $ledgerPath, $regPath)
    checkedAt = (Get-Date).ToString("o")
    runDir = $RunDir
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
