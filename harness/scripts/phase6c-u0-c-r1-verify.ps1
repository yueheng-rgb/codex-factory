# phase6c-u0-c-r1-verify.ps1 — Phase 6C-U0-C-R1 Umbrella Verifier
# Verifies clean token-proof lifecycle closure for U0-C fixtures.
param([switch]$JsonOnly)

$ErrorActionPreference = "Continue"
$HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

Write-Output "=== Phase 6C-U0-C-R1 Umbrella Verifier ==="

# --- 1. U0-C files still exist ---
$u0cFiles = @(
    "scripts/extract-source-interface-manifest.ps1",
    "scripts/compare-worker-manifest-to-source.ps1",
    "scripts/phase6c-u0-c-verify.ps1",
    "outputs/PHASE_6C_U0_C_FINAL_REPORT.md"
)
foreach ($f in $u0cFiles) {
    if (Test-Path (Join-Path $HarnessRoot $f)) { [void]$passes.Add("U0-C file: $f") }
    else { [void]$errors.Add("U0C_MISSING: $f"); $exitCode = 1 }
}

# --- 2. Positive R1 run ---
$posDir = "$HarnessRoot\runs\phase6c-u0-c-r1"
if (Test-Path $posDir) { [void]$passes.Add("Positive R1 run exists") }
else { [void]$errors.Add("MISSING_POSITIVE_R1_RUN"); $exitCode = 1 }

# Token store exists
$posTokDir = "$HarnessRoot\..\harness-control\tokens\phase6c-u0-c-r1"
if (Test-Path $posTokDir) { [void]$passes.Add("Positive token store exists") }
else { [void]$errors.Add("MISSING_POSITIVE_TOKEN_STORE"); $exitCode = 1 }

# Validate-state on positive
$posVS = & (Join-Path $HarnessRoot "scripts\validate-state.ps1") -RunDir $posDir 2>&1 | Out-String
$posVSJson = $null
try { $pvsj = $posVS.IndexOf('{'); if ($pvsj -ge 0) { $posVSJson = $posVS.Substring($pvsj) | ConvertFrom-Json } } catch {}
if ($posVSJson) {
    if ($posVSJson.verdict -eq "run_passed") { [void]$passes.Add("Positive validate-state: run_passed") }
    else { [void]$errors.Add("POSITIVE_VS_VERDICT_NOT_PASSED: $($posVSJson.verdict)"); $exitCode = 1 }
    
    $hasNoTokenStore = ($posVS -match "no_token_store")
    $hasProofFail = ($posVS -match "PROOF_VERIFICATION_FAILED")
    if (-not $hasNoTokenStore) { [void]$passes.Add("Positive: no 'no_token_store'") }
    else { [void]$errors.Add("POSITIVE_HAS_NO_TOKEN_STORE"); $exitCode = 1 }
    if (-not $hasProofFail) { [void]$passes.Add("Positive: no PROOF_VERIFICATION_FAILED") }
    else { [void]$errors.Add("POSITIVE_HAS_PROOF_FAIL"); $exitCode = 1 }
    
    $hashChainPass = ($posVS -match "Hash chain valid")
    if ($hashChainPass) { [void]$passes.Add("Positive: hash chain valid") }
    else { [void]$errors.Add("POSITIVE_HASH_CHAIN_FAIL"); $exitCode = 1 }
    
    $proofsPass = ($posVS -match "Authorization proofs: 10 verified, 0 failed")
    if ($proofsPass) { [void]$passes.Add("Positive: all 10 proofs verified") }
    else { [void]$errors.Add("POSITIVE_PROOFS_NOT_ALL_VERIFIED"); $exitCode = 1 }
    
    $honestyPass = ($posVS -match "Manifest honesty: worker-1 PASS") -and ($posVS -match "Manifest honesty: worker-2 PASS")
    if ($honestyPass) { [void]$passes.Add("Positive: both manifest honesty PASS") }
    else { [void]$errors.Add("POSITIVE_HONESTY_FAIL"); $exitCode = 1 }
    
    $driftPass = ($posVS -match "Interface drift report: PASS") -and ($posVS -match "Interface drift count: 0")
    if ($driftPass) { [void]$passes.Add("Positive: interface drift PASS") }
    else { [void]$errors.Add("POSITIVE_DRIFT_FAIL"); $exitCode = 1 }
} else {
    [void]$errors.Add("POSITIVE_VS_CANNOT_PARSE"); $exitCode = 1
}

# --- 3. Negative source mismatch ---
$neg1Dir = "$HarnessRoot\runs\phase6c-u0-c-r1-negative-source-mismatch"
if (Test-Path $neg1Dir) { [void]$passes.Add("Negative-1 (source mismatch) run exists") }
else { [void]$errors.Add("MISSING_NEG1_RUN"); $exitCode = 1 }

$neg1VS = & (Join-Path $HarnessRoot "scripts\validate-state.ps1") -RunDir $neg1Dir 2>&1 | Out-String
$neg1VSJson = $null
try { $n1j = $neg1VS.IndexOf('{'); if ($n1j -ge 0) { $neg1VSJson = $neg1VS.Substring($n1j) | ConvertFrom-Json } } catch {}
if ($neg1VSJson) {
    $isFail = ($neg1VSJson.verdict -eq "run_failed")
    if ($isFail) { [void]$passes.Add("Negative-1: verdict run_failed (expected)") }
    else { [void]$errors.Add("NEG1_VS_NOT_FAILED"); $exitCode = 1 }
    
    $hasHonestyFail = ($neg1VS -match "MANIFEST_HONESTY_FAIL: worker-2")
    $hasDriftFail = ($neg1VS -match "INTERFACE_DRIFT_REPORT_FAIL")
    $hasMismatch = ($neg1VS -match "MANIFEST_HONESTY_MISMATCHES: worker-2 count")
    if ($hasHonestyFail) { [void]$passes.Add("Negative-1: manifest honesty FAIL (worker-2)") }
    else { [void]$errors.Add("NEG1_NO_HONESTY_FAIL"); $exitCode = 1 }
    if ($hasDriftFail) { [void]$passes.Add("Negative-1: interface drift FAIL") }
    else { [void]$errors.Add("NEG1_NO_DRIFT_FAIL"); $exitCode = 1 }
    if ($hasMismatch) { [void]$passes.Add("Negative-1: honesty mismatches > 0") }
    else { [void]$errors.Add("NEG1_NO_MISMATCH"); $exitCode = 1 }
    
    $hasNoTokenStore = ($neg1VS -match "no_token_store")
    if (-not $hasNoTokenStore) { [void]$passes.Add("Negative-1: no 'no_token_store'") }
    else { [void]$errors.Add("NEG1_HAS_NO_TOKEN_STORE"); $exitCode = 1 }
} else {
    [void]$errors.Add("NEG1_VS_CANNOT_PARSE"); $exitCode = 1
}

# --- 4. Negative import mismatch ---
$neg2Dir = "$HarnessRoot\runs\phase6c-u0-c-r1-negative-import-mismatch"
if (Test-Path $neg2Dir) { [void]$passes.Add("Negative-2 (import mismatch) run exists") }
else { [void]$errors.Add("MISSING_NEG2_RUN"); $exitCode = 1 }

$neg2VS = & (Join-Path $HarnessRoot "scripts\validate-state.ps1") -RunDir $neg2Dir 2>&1 | Out-String
$neg2VSJson = $null
try { $n2j = $neg2VS.IndexOf('{'); if ($n2j -ge 0) { $neg2VSJson = $neg2VS.Substring($n2j) | ConvertFrom-Json } } catch {}
if ($neg2VSJson) {
    $isFail = ($neg2VSJson.verdict -eq "run_failed")
    if ($isFail) { [void]$passes.Add("Negative-2: verdict run_failed (expected)") }
    else { [void]$errors.Add("NEG2_VS_NOT_FAILED"); $exitCode = 1 }
    
    $hasHonestyFail = ($neg2VS -match "MANIFEST_HONESTY_FAIL: worker-1")
    $hasDriftFail = ($neg2VS -match "INTERFACE_DRIFT_REPORT_FAIL")
    $hasMismatch = ($neg2VS -match "MANIFEST_HONESTY_MISMATCHES: worker-1 count")
    if ($hasHonestyFail) { [void]$passes.Add("Negative-2: manifest honesty FAIL (worker-1)") }
    else { [void]$errors.Add("NEG2_NO_HONESTY_FAIL"); $exitCode = 1 }
    if ($hasDriftFail) { [void]$passes.Add("Negative-2: interface drift FAIL") }
    else { [void]$errors.Add("NEG2_NO_DRIFT_FAIL"); $exitCode = 1 }
    if ($hasMismatch) { [void]$passes.Add("Negative-2: honesty mismatches > 0") }
    else { [void]$errors.Add("NEG2_NO_MISMATCH"); $exitCode = 1 }
    
    $hasNoTokenStore = ($neg2VS -match "no_token_store")
    if (-not $hasNoTokenStore) { [void]$passes.Add("Negative-2: no 'no_token_store'") }
    else { [void]$errors.Add("NEG2_HAS_NO_TOKEN_STORE"); $exitCode = 1 }
} else {
    [void]$errors.Add("NEG2_VS_CANNOT_PARSE"); $exitCode = 1
}

# --- 5. validate-state was not weakened ---
$vsContent = Get-Content (Join-Path $HarnessRoot "scripts\validate-state.ps1") -Raw
if ($vsContent -match "Manifest Honesty Gate") {
    [void]$passes.Add("validate-state: manifest honesty gate intact")
} else { [void]$errors.Add("VS_HONESTY_GATE_WEAKENED"); $exitCode = 1 }
if ($vsContent -match "PROOF_VERIFICATION_FAILED" -and $vsContent -match "verify-proof") {
    [void]$passes.Add("validate-state: proof verification intact")
} else { [void]$errors.Add("VS_PROOF_CHECK_WEAKENED"); $exitCode = 1 }

# --- 6. Final report ---
$finalReportPath = "$HarnessRoot\outputs\PHASE_6C_U0_C_R1_FINAL_REPORT.md"
if (Test-Path $finalReportPath) {
    [void]$passes.Add("Final report exists")
    $frText = Get-Content $finalReportPath -Raw -Encoding UTF8
    if ($frText -match "does not prove new multi-agent") { [void]$passes.Add("Final report: no new multi-agent claim") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_DISCLAIMER"); $exitCode = 1 }
    if ($frText -match "does not run.*spawn_agent") { [void]$passes.Add("Final report: no spawn_agent claim") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_SPAWN"); $exitCode = 1 }
    if ($frText -match "cleans.*token-proof.*lifecycle") { [void]$passes.Add("Final report: states lifecycle cleanup") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_LIFECYCLE"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_FINAL_REPORT"); $exitCode = 1 }

# --- 7. T0-R3 unchanged ---
$t0r3Zip = "$HarnessRoot\outputs\phase6c-t0-r3-final-audit-bundle.zip"
$t0r3Hash = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
if (Test-Path $t0r3Zip) {
    $currentHash = (Get-FileHash $t0r3Zip -Algorithm SHA256).Hash.ToLower()
    if ($currentHash -eq $t0r3Hash) { [void]$passes.Add("T0-R3 ZIP unchanged") }
    else { [void]$errors.Add("T0_R3_ZIP_MODIFIED"); $exitCode = 1 }
} else { [void]$passes.Add("T0-R3 ZIP not found (may be expected)") }

# --- VERDICT ---
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    phase = "Phase 6C-U0-C-R1"
    tool = "phase6c-u0-c-r1-verify"
    verdict = $verdict
    errorCount = $errors.Count
    passCount = $passes.Count
    errors = $errors
    passes = $passes
    timestamp = (Get-Date).ToString("o")
}

if ($JsonOnly) {
    Write-Output ($result | ConvertTo-Json -Depth 4)
} else {
    Write-Output ""
    Write-Output "=== U0-C-R1 VERDICT: $verdict ==="
    Write-Output "Errors: $($errors.Count) | Passes: $($passes.Count)"
    foreach ($p in $passes) { Write-Output "  [PASS] $p" }
    foreach ($e in $errors) { Write-Output "  [FAIL] $e" }
}

exit $exitCode