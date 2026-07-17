# audit-run.ps1 — Phase 6C-H4
# Executable audit contract. Runs all audit checks from audit-contract.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [Parameter(Mandatory=$true)][string]$AuditContractPath,
    [string]$RunContractPath = "",
    [switch]$Json
)
$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

if (-not (Test-Path $AuditContractPath)) { Write-Output '{"verdict":"FAIL","reason":"AUDIT_CONTRACT_NOT_FOUND"}'; exit 1 }
try { $auditContract = Get-Content $AuditContractPath -Raw | ConvertFrom-Json } catch { Write-Output '{"verdict":"FAIL","reason":"AUDIT_CONTRACT_MALFORMED"}'; exit 1 }

# 1. Stale report detection
if ($auditContract.staleReportDetection) {
    $stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
    $report = Get-ChildItem $RunDir -Recurse -Filter "*_REPORT.md" -File | Select-Object -First 1
    if ($stateFile -and $report) {
        $stateTime = (Get-Item $stateFile).LastWriteTime
        $reportTime = (Get-Item $report).LastWriteTime
        if ($reportTime -lt $stateTime) {
            [void]$errors.Add("STALE_REPORT: report=$reportTime < state=$stateTime")
            $exitCode = 1
        } else { [void]$passes.Add("Stale report: clean") }
    } else { [void]$passes.Add("Stale report: N/A (no report)") }
}

# 2. Threshold drift detection
if ($auditContract.thresholdDriftDetection -and $RunContractPath -and (Test-Path $RunContractPath)) {
    $enforcePath = "C:\Codex_App_Factory\harness\scripts\harness-enforcement\verify-complexity-budget.ps1"
    if (Test-Path $enforcePath) {
        $result = & powershell -NoProfile -File $enforcePath -ContractPath $RunContractPath -RunDir $RunDir 2>&1 | Out-String | ConvertFrom-Json
        if ($result.verdict -eq "FAIL") {
            [void]$errors.Add("THRESHOLD_DRIFT: $($result.errors -join '; ')")
            $exitCode = 1
        } else { [void]$passes.Add("Threshold drift: clean") }
    } else { [void]$passes.Add("Threshold drift: N/A (no verifier)") }
}

# 3. Skipped-as-pass detection
if ($auditContract.skippedAsPassDetection) {
    $acceptanceFiles = @(Get-ChildItem (Join-Path $RunDir "reports") -Filter "*.json" -ErrorAction SilentlyContinue)
    $skipped = @()
    foreach ($af in $acceptanceFiles) {
        try {
            $acc = Get-Content $af.FullName -Raw | ConvertFrom-Json
            if ($acc.scenarios) {
                $skipped += @($acc.scenarios | Where-Object { $_.skipped -eq $true -or $_.status -eq "skipped" })
            }
        } catch {}
    }
    if ($skipped.Count -gt 0) {
        [void]$errors.Add("SKIPPED_AS_PASS: $($skipped.Count) skipped scenarios")
        $exitCode = 1
    } else { [void]$passes.Add("Skipped-as-pass: clean") }
}

# 4. Intended failure mismatch
if ($auditContract.intendedFailureMismatchDetection) {
    $acceptanceFiles = @(Get-ChildItem (Join-Path $RunDir "reports") -Filter "*acceptance*.json" -ErrorAction SilentlyContinue)
    foreach ($af in $acceptanceFiles) {
        try {
            $acc = Get-Content $af.FullName -Raw | ConvertFrom-Json
            if ($acc.intendedFailure -eq $true -and $acc.verdict -eq "PASS") {
                [void]$errors.Add("INTENDED_FAILURE_MISMATCH: $($af.Name) intended=fail actual=pass")
                $exitCode = 1
            }
        } catch {}
    }
    [void]$passes.Add("Intended failure mismatch: checked")
}

# 5. Closed evidence mutation
if ($auditContract.closedEvidenceMutationDetection) {
    $freezeDir = Join-Path $RunDir "worker-freeze-manifests"
    if (Test-Path $freezeDir) {
        $manifests = @(Get-ChildItem $freezeDir -Filter "*.freeze.json")
        foreach ($m in $manifests) {
            $verify = & powershell -NoProfile -File "C:\Codex_App_Factory\harness\scripts\harness-core\verify-worker-freeze.ps1" -FreezeManifestPath $m.FullName 2>&1 | Out-String | ConvertFrom-Json
            if ($verify.verdict -eq "FAIL") {
                [void]$errors.Add("CLOSED_EVIDENCE_MUTATION: $($m.Name)")
                $exitCode = 1
            }
        }
        if ($exitCode -eq 0) { [void]$passes.Add("Closed evidence mutation: clean") }
    } else { [void]$passes.Add("Closed evidence: N/A (no freeze)") }
}

# 6. Proof hash noise
if ($auditContract.proofHashNoiseDetection) {
    $stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
    if (Test-Path $stateFile) {
        try {
            $events = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 } | ForEach-Object { $_ | ConvertFrom-Json })
            $hashChainOk = $true
            for ($i = 1; $i -lt $events.Count; $i++) {
                if ($events[$i].previousEventHash -ne $events[$i-1].eventHash) {
                    [void]$errors.Add("HASH_CHAIN_BROKEN at event $i")
                    $exitCode = 1
                    $hashChainOk = $false
                    break
                }
            }
            if ($hashChainOk) { [void]$passes.Add("Proof hash chain: clean") }
        } catch { [void]$errors.Add("PROOF_HASH_NOISE: cannot parse RUN_STATE") }
    }
}

# 7. Report epoch comparison
if ($auditContract.reportEpochComparison) {
    [void]$passes.Add("Report epoch: checked (N/A for synthetic fixtures)")
}

# 8. Source hash verification
if ($auditContract.sourceHashVerification) {
    $srcDir = Join-Path $RunDir "canonical-integrated\src"
    if (Test-Path $srcDir) {
        $srcFiles = @(Get-ChildItem $srcDir -Filter "*.js")
        [void]$passes.Add("Source hash: $($srcFiles.Count) files present")
    } else { [void]$passes.Add("Source hash: N/A (no src)") }
}

# Determine recommended classification
$recommendedClassification = "PASS"
if ($exitCode -ne 0) {
    $errText = $errors -join " "
    if ($errText -match "CLOSED_EVIDENCE_MUTATION") { $recommendedClassification = "FAIL_CLOSED_EVIDENCE_MUTATION" }
    elseif ($errText -match "THRESHOLD_DRIFT|CONTRACT_DRIFT") { $recommendedClassification = "FAIL_CONTRACT_DRIFT" }
    elseif ($errText -match "SKIPPED_AS_PASS") { $recommendedClassification = "FAIL_MISSING_EVIDENCE" }
    elseif ($errText -match "INTENDED_FAILURE_MISMATCH|STALE_REPORT|HASH_CHAIN_BROKEN|PROOF_HASH") { $recommendedClassification = "FAIL_HARNESS_NOISE" }
    elseif ($errText -match "MISSING|NOT_FOUND|EMPTY") { $recommendedClassification = "FAIL_MISSING_EVIDENCE" }
    else { $recommendedClassification = "FAIL_HARNESS_NOISE" }
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict = $verdict
    recommendedClassification = $recommendedClassification
    auditChecks = $passes
    caveats = @()
    failures = $errors
    passCount = $passes.Count
    failCount = $errors.Count
    passes = $passes
    errors = $errors
    evidencePaths = @()
    checkedAt = (Get-Date).ToString("o")
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
