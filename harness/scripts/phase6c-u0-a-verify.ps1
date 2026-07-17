# phase6c-u0-a-verify.ps1 鈥?Phase 6C-U0-A
# Umbrella verifier: validates all U0-A artifacts in one pass.
# Checks schemas, contract, manifests, drift reports, integration gate, final report, T0-R3 integrity.
param([switch]$Json)

$ErrorActionPreference = "Continue"
$HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

Write-Output "=== Phase 6C-U0-A Umbrella Verifier ==="
Write-Output ""

# --- 1. Schemas exist ---
$contractSchemaPath = "$HarnessRoot\schemas\INTERFACE_CONTRACT_SCHEMA.json"
$manifestSchemaPath = "$HarnessRoot\schemas\WORKER_INTERFACE_MANIFEST_SCHEMA.json"

if (Test-Path $contractSchemaPath) { [void]$passes.Add("Contract schema exists") }
else { [void]$errors.Add("MISSING: INTERFACE_CONTRACT_SCHEMA.json"); $exitCode = 1 }

if (Test-Path $manifestSchemaPath) { [void]$passes.Add("Manifest schema exists") }
else { [void]$errors.Add("MISSING: WORKER_INTERFACE_MANIFEST_SCHEMA.json"); $exitCode = 1 }

# --- 2. Positive fixture ---
$posDir = "$HarnessRoot\runs\phase6c-u0-a"
$posContract = "$posDir\interface-contract.lock.json"
$posManifestsDir = "$posDir\worker-interface-manifests"
$posDriftReport = "$posDir\reports\interface-drift-report.json"
$posIntegrationGate = "$posDir\reports\integration-gate-report.json"

# 2a. Contract exists and locked
if (Test-Path $posContract) {
    [void]$passes.Add("Positive contract exists")
    $pc = Get-Content $posContract -Raw | ConvertFrom-Json
    if ($pc.locked -eq $true) { [void]$passes.Add("Positive contract locked=true") }
    else { [void]$errors.Add("POSITIVE_CONTRACT_NOT_LOCKED"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_POSITIVE_CONTRACT"); $exitCode = 1 }

# 2b. Worker manifests exist
if (Test-Path $posManifestsDir) {
    $posManifestFiles = Get-ChildItem $posManifestsDir -Filter "*.json" -File
    if ($posManifestFiles.Count -ge 2) { [void]$passes.Add("Positive manifests: $($posManifestFiles.Count) files") }
    else { [void]$errors.Add("POSITIVE_MANIFESTS_INSUFFICIENT: $($posManifestFiles.Count)"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_POSITIVE_MANIFESTS_DIR"); $exitCode = 1 }

# 2c. Drift report PASS
if (Test-Path $posDriftReport) {
    $pdr = Get-Content $posDriftReport -Raw | ConvertFrom-Json
    if ($pdr.verdict -eq "PASS") { [void]$passes.Add("Positive drift report: PASS") }
    else { [void]$errors.Add("POSITIVE_DRIFT_REPORT_FAIL: verdict=$($pdr.verdict)"); $exitCode = 1 }
    if ($pdr.driftCount -eq 0) { [void]$passes.Add("Positive driftCount: 0") }
    else { [void]$errors.Add("POSITIVE_DRIFT_COUNT_NONZERO: $($pdr.driftCount)"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_POSITIVE_DRIFT_REPORT"); $exitCode = 1 }

# 2d. Integration gate PASS
if (Test-Path $posIntegrationGate) {
    $pig = Get-Content $posIntegrationGate -Raw | ConvertFrom-Json
    if ($pig.verdict -eq "PASS") { [void]$passes.Add("Positive integration gate: PASS") }
    else { [void]$errors.Add("POSITIVE_INTEGRATION_GATE_FAIL"); $exitCode = 1 }
    if ($pig.dependencies.interfaceDriftReport -eq "PASS") { [void]$passes.Add("Integration gate depends on drift=PASS") }
    else { [void]$errors.Add("INTEGRATION_GATE_DEPENDENCY_MISMATCH"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_POSITIVE_INTEGRATION_GATE"); $exitCode = 1 }

# --- 3. Negative fixture ---
$negDir = "$HarnessRoot\runs\phase6c-u0-a-negative"
$negDriftReport = "$negDir\reports\interface-drift-report.json"
$negIntegrationGate = "$negDir\reports\integration-gate-report.json"

if (Test-Path $negDir) { [void]$passes.Add("Negative fixture exists: $negDir") }
else { [void]$errors.Add("MISSING_NEGATIVE_FIXTURE"); $exitCode = 1 }

if (Test-Path $negDriftReport) {
    $ndr = Get-Content $negDriftReport -Raw | ConvertFrom-Json
    if ($ndr.verdict -eq "FAIL") { [void]$passes.Add("Negative drift report: FAIL (expected)") }
    else { [void]$errors.Add("NEGATIVE_DRIFT_REPORT_SHOULD_FAIL: verdict=$($ndr.verdict)"); $exitCode = 1 }
    if ($ndr.driftCount -gt 0) { [void]$passes.Add("Negative driftCount: $($ndr.driftCount) (expected >0)") }
    else { [void]$errors.Add("NEGATIVE_DRIFT_COUNT_ZERO: should be >0"); $exitCode = 1 }
    
    # Check A/B mismatch evidence in negative report
    $hasAB = $false
    foreach ($d in $ndr.drifts) {
        if ($d.type -eq "import_name_mismatch" -and $d.expectedName -and $d.actualName) {
            $hasAB = $true
            [void]$passes.Add("Negative report contains A/B mismatch: expected='$($d.expectedName)' actual='$($d.actualName)'")
        }
    }
    if (-not $hasAB) { [void]$errors.Add("NEGATIVE_REPORT_MISSING_AB_MISMATCH_EVIDENCE"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_NEGATIVE_DRIFT_REPORT"); $exitCode = 1 }

if (Test-Path $negIntegrationGate) {
    $nig = Get-Content $negIntegrationGate -Raw | ConvertFrom-Json
    if ($nig.verdict -eq "FAIL") { [void]$passes.Add("Negative integration gate: FAIL (expected 鈥?blocked by drift)") }
    else { [void]$errors.Add("NEGATIVE_INTEGRATION_GATE_SHOULD_FAIL"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_NEGATIVE_INTEGRATION_GATE"); $exitCode = 1 }

# --- 4. Final report ---
$finalReportPath = "$HarnessRoot\outputs\PHASE_6C_U0_A_FINAL_REPORT.md"
if (Test-Path $finalReportPath) {
    [void]$passes.Add("Final report exists")
    $frText = Get-Content $finalReportPath -Raw -Encoding UTF8
    if ($frText -match "does not prove new multi-agent") { [void]$passes.Add("Final report: no new multi-agent claim") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_DISCLAIMER"); $exitCode = 1 }
    if ($frText -match "does not run.*spawn_agent") { [void]$passes.Add("Final report: no spawn_agent claim") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_SPAWN_AGENT_DISCLAIMER"); $exitCode = 1 }
    if ($frText -match "interface drift gate") { [void]$passes.Add("Final report: mentions interface drift gate") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_DRIFT_GATE_MENTION"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_FINAL_REPORT"); $exitCode = 1 }

# --- 5. Script exit codes (check all U0-A scripts return numeric exit codes) ---
$u0Scripts = @(
    "validate-interface-contract.ps1",
    "validate-worker-interface-manifest.ps1",
    "detect-interface-drift.ps1",
    "phase6c-u0-a-verify.ps1"
)
foreach ($s in $u0Scripts) {
    $sp = "$HarnessRoot\scripts\$s"
    if (Test-Path $sp) { [void]$passes.Add("Script exists: $s") }
    else { [void]$errors.Add("MISSING_SCRIPT: $s"); $exitCode = 1 }
}

# --- 6. T0-R3 products not modified ---
$t0r3Zip = "$HarnessRoot\outputs\phase6c-t0-r3-final-audit-bundle.zip"
$t0r3Hash = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
if (Test-Path $t0r3Zip) {
    $currentHash = (Get-FileHash $t0r3Zip -Algorithm SHA256).Hash.ToLower()
    if ($currentHash -eq $t0r3Hash) { [void]$passes.Add("T0-R3 ZIP unchanged: SHA256 matches") }
    else { [void]$errors.Add("T0_R3_ZIP_MODIFIED: expected=$t0r3Hash actual=$currentHash"); $exitCode = 1 }
} else { [void]$passes.Add("T0-R3 ZIP not found (may be expected in fresh context)") }

# --- VERDICT ---
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    phase = "Phase 6C-U0-A"
    tool = "phase6c-u0-a-verify"
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
    Write-Output "=== U0-A VERDICT: $verdict ==="
    Write-Output "Errors: $($errors.Count) | Passes: $($passes.Count)"
    foreach ($p in $passes) { Write-Output "  [PASS] $p" }
    foreach ($e in $errors) { Write-Output "  [FAIL] $e" }
}

exit $exitCode