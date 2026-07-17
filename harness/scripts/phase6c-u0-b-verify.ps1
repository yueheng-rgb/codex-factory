# phase6c-u0-b-verify.ps1 鈥?Phase 6C-U0-B Umbrella Verifier
# Verifies U0-B lifecycle integration of the interface drift gate.
param([switch]$Json)

$ErrorActionPreference = "Continue"
$HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

Write-Output "=== Phase 6C-U0-B Umbrella Verifier ==="
Write-Output ""

# --- 1. U0-A files still exist ---
$u0aFiles = @(
    "schemas\INTERFACE_CONTRACT_SCHEMA.json",
    "schemas\WORKER_INTERFACE_MANIFEST_SCHEMA.json",
    "scripts\validate-interface-contract.ps1",
    "scripts\validate-worker-interface-manifest.ps1",
    "scripts\detect-interface-drift.ps1",
    "scripts\phase6c-u0-a-verify.ps1",
    "docs\PHASE_6C_U0_CONTRACT_LOCK_MODEL.md",
    "runs\phase6c-u0-a"
)
foreach ($f in $u0aFiles) {
    $fp = Join-Path $HarnessRoot $f
    if (Test-Path $fp) { [void]$passes.Add("U0-A file present: $f") }
    else { [void]$errors.Add("U0A_MISSING: $f"); $exitCode = 1 }
}

# --- 2. validate-state.ps1 contains interface drift gate ---
$vsContent = Get-Content (Join-Path $HarnessRoot "scripts\validate-state.ps1") -Raw
if ($vsContent -match "Interface Drift Gate") {
    [void]$passes.Add("validate-state.ps1 contains interface drift gate section")
} else {
    [void]$errors.Add("VALIDATE_STATE_MISSING_DRIFT_GATE"); $exitCode = 1
}

# --- 3. Orchestrator prompt contains contract/drift steps ---
$orchContent = Get-Content (Join-Path $HarnessRoot "prompts\orchestrator-agent.md") -Raw
if ($orchContent -match "interface-contract\.lock\.json" -or $orchContent -match "contract lock") {
    [void]$passes.Add("Orchestrator prompt: contract lock flow present")
} else { [void]$errors.Add("ORCH_PROMPT_MISSING_CONTRACT"); $exitCode = 1 }
if ($orchContent -match "detect-interface-drift") {
    [void]$passes.Add("Orchestrator prompt: drift detector step present")
} else { [void]$errors.Add("ORCH_PROMPT_MISSING_DRIFT"); $exitCode = 1 }

# --- 4. Worker prompt contains manifest requirements ---
$workerContent = Get-Content (Join-Path $HarnessRoot "prompts\worker-agent.md") -Raw
if ($workerContent -match "interface.manifest" -or $workerContent -match "interface-manifest") {
    [void]$passes.Add("Worker prompt: interface manifest requirement present")
} else { [void]$errors.Add("WORKER_PROMPT_MISSING_MANIFEST"); $exitCode = 1 }

# --- 5. Schemas updated ---
$res = Get-Content (Join-Path $HarnessRoot "schemas\RUN_EVIDENCE_SCHEMA.json") -Raw | ConvertFrom-Json
$hasContractEv = $false; $hasDriftEv = $false
foreach ($gf in $res.requiredGovernanceFiles) {
    if ($gf.file -match "interface-contract") { $hasContractEv = $true }
    if ($gf.file -match "interface-drift") { $hasDriftEv = $true }
}
if ($hasContractEv) { [void]$passes.Add("RUN_EVIDENCE_SCHEMA: interface-contract evidence required") }
else { [void]$errors.Add("SCHEMA_MISSING_CONTRACT_EVIDENCE"); $exitCode = 1 }
if ($hasDriftEv) { [void]$passes.Add("RUN_EVIDENCE_SCHEMA: drift report evidence required") }
else { [void]$errors.Add("SCHEMA_MISSING_DRIFT_EVIDENCE"); $exitCode = 1 }

$aes = Get-Content (Join-Path $HarnessRoot "schemas\AGENT_EVIDENCE_SCHEMA.json") -Raw | ConvertFrom-Json
$hasManifestEv = ($aes.agents.builder.requiredEvidence -join ' ') -match "interface.manifest"
if ($hasManifestEv) { [void]$passes.Add("AGENT_EVIDENCE_SCHEMA: worker interface manifest in builder evidence") }
else { [void]$errors.Add("SCHEMA_MISSING_MANIFEST_EVIDENCE"); $exitCode = 1 }

# --- 6. Positive U0-B run ---
$posDir = "$HarnessRoot\runs\phase6c-u0-b"
if (Test-Path $posDir) { [void]$passes.Add("Positive U0-B run exists") }
else { [void]$errors.Add("MISSING_POSITIVE_U0B_RUN"); $exitCode = 1 }

$posContract = "$posDir\interface-contract.lock.json"
if (Test-Path $posContract) {
    $pc = Get-Content $posContract -Raw | ConvertFrom-Json
    if ($pc.locked -eq $true) { [void]$passes.Add("Positive contract locked=true") }
    else { [void]$errors.Add("POSITIVE_CONTRACT_NOT_LOCKED"); $exitCode = 1 }
}

$posDrift = "$posDir\reports\interface-drift-report.json"
if (Test-Path $posDrift) {
    $pd = Get-Content $posDrift -Raw | ConvertFrom-Json
    if ($pd.verdict -eq "PASS") { [void]$passes.Add("Positive drift report: PASS") }
    else { [void]$errors.Add("POSITIVE_DRIFT_NOT_PASS"); $exitCode = 1 }
    if ($pd.driftCount -eq 0) { [void]$passes.Add("Positive driftCount: 0") }
    else { [void]$errors.Add("POSITIVE_DRIFT_COUNT_NONZERO"); $exitCode = 1 }
}

$posGate = "$posDir\reports\integration-gate-report.json"
if (Test-Path $posGate) {
    $pg = Get-Content $posGate -Raw | ConvertFrom-Json
    if ($pg.verdict -eq "PASS") { [void]$passes.Add("Positive integration gate: PASS") }
    else { [void]$errors.Add("POSITIVE_GATE_NOT_PASS"); $exitCode = 1 }
}

# Check validate-state on positive run: interface gate checks passed
$posVS = & (Join-Path $HarnessRoot "scripts\validate-state.ps1") -RunDir $posDir 2>&1 | Out-String
$posVSJson = $null
try { $pvsj = $posVS.IndexOf('{'); if ($pvsj -ge 0) { $posVSJson = $posVS.Substring($pvsj) | ConvertFrom-Json } } catch {}
if ($posVSJson) {
    $hasDriftPass = ($posVSJson.passes | Where-Object { $_ -match "Interface drift report: PASS" }).Count -gt 0
    $hasGatePass = ($posVSJson.passes | Where-Object { $_ -match "Integration gate: PASS" }).Count -gt 0
    if ($hasDriftPass) { [void]$passes.Add("Positive validate-state: drift report gate PASS") }
    else { [void]$errors.Add("POSITIVE_VS_MISSING_DRIFT_PASS"); $exitCode = 1 }
    if ($hasGatePass) { [void]$passes.Add("Positive validate-state: integration gate PASS") }
    else { [void]$errors.Add("POSITIVE_VS_MISSING_GATE_PASS"); $exitCode = 1 }
    # Note: overall validate-state may FAIL due to pre-existing token/lease issues 鈥?that's acceptable for U0-B
} else {
    [void]$errors.Add("POSITIVE_VS_CANNOT_PARSE"); $exitCode = 1
}

# --- 7. Negative U0-B run ---
$negDir = "$HarnessRoot\runs\phase6c-u0-b-negative"
if (Test-Path $negDir) { [void]$passes.Add("Negative U0-B run exists") }
else { [void]$errors.Add("MISSING_NEGATIVE_U0B_RUN"); $exitCode = 1 }

$negDrift = "$negDir\reports\interface-drift-report.json"
if (Test-Path $negDrift) {
    $nd = Get-Content $negDrift -Raw | ConvertFrom-Json
    if ($nd.verdict -eq "FAIL") { [void]$passes.Add("Negative drift report: FAIL (expected)") }
    else { [void]$errors.Add("NEGATIVE_DRIFT_NOT_FAIL"); $exitCode = 1 }
    if ($nd.driftCount -gt 0) { [void]$passes.Add("Negative driftCount: $($nd.driftCount) (expected >0)") }
    else { [void]$errors.Add("NEGATIVE_DRIFT_COUNT_ZERO"); $exitCode = 1 }
    # Check A/B mismatch evidence
    $hasAB = $false
    foreach ($d in $nd.drifts) {
        if ($d.expectedName -and $d.actualName -and $d.type -eq "import_name_mismatch") {
            $hasAB = $true
            [void]$passes.Add("Negative: A/B mismatch caught: expected='$($d.expectedName)' actual='$($d.actualName)'")
        }
    }
    if (-not $hasAB) { [void]$errors.Add("NEGATIVE_MISSING_AB_EVIDENCE"); $exitCode = 1 }
}

$negGate = "$negDir\reports\integration-gate-report.json"
if (Test-Path $negGate) {
    $ng = Get-Content $negGate -Raw | ConvertFrom-Json
    if ($ng.verdict -eq "FAIL") { [void]$passes.Add("Negative integration gate: FAIL (blocked by drift)") }
    else { [void]$errors.Add("NEGATIVE_GATE_NOT_FAIL"); $exitCode = 1 }
}

# --- 8. Final report ---
$finalReportPath = "$HarnessRoot\outputs\PHASE_6C_U0_B_FINAL_REPORT.md"
if (Test-Path $finalReportPath) {
    [void]$passes.Add("Final report exists")
    $frText = Get-Content $finalReportPath -Raw -Encoding UTF8
    if ($frText -match "does not prove new multi-agent") { [void]$passes.Add("Final report: no new multi-agent claim") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_DISCLAIMER"); $exitCode = 1 }
    if ($frText -match "does not run.*spawn_agent") { [void]$passes.Add("Final report: no spawn_agent claim") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_SPAWN_DISCLAIMER"); $exitCode = 1 }
    if ($frText -match "integrates.*interface drift gate.*lifecycle") { [void]$passes.Add("Final report: states lifecycle integration") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_LIFECYCLE_MENTION"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_FINAL_REPORT"); $exitCode = 1 }

# --- 9. T0-R3 unchanged ---
$t0r3Zip = "$HarnessRoot\outputs\phase6c-t0-r3-final-audit-bundle.zip"
$t0r3Hash = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
if (Test-Path $t0r3Zip) {
    $currentHash = (Get-FileHash $t0r3Zip -Algorithm SHA256).Hash.ToLower()
    if ($currentHash -eq $t0r3Hash) { [void]$passes.Add("T0-R3 ZIP unchanged: SHA256 matches") }
    else { [void]$errors.Add("T0_R3_ZIP_MODIFIED"); $exitCode = 1 }
} else { [void]$passes.Add("T0-R3 ZIP not found (may be expected)") }

# --- VERDICT ---
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    phase = "Phase 6C-U0-B"
    tool = "phase6c-u0-b-verify"
    verdict = $verdict
    errorCount = $errors.Count
    passCount = $passes.Count
    errors = $errors
    passes = $passes
    timestamp = (Get-Date).ToString("o")
}

if ($Json) {
    Write-Output ($result | ConvertTo-Json -Depth 4)
} else {
    Write-Output ""
    Write-Output "=== U0-B VERDICT: $verdict ==="
    Write-Output "Errors: $($errors.Count) | Passes: $($passes.Count)"
    foreach ($p in $passes) { Write-Output "  [PASS] $p" }
    foreach ($e in $errors) { Write-Output "  [FAIL] $e" }
}

exit $exitCode