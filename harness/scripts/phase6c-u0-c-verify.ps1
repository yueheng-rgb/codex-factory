# phase6c-u0-c-verify.ps1 -- Phase 6C-U0-C Umbrella Verifier
# Verifies source-derived interface manifest extraction and honesty gate.
param([switch]$JsonOnly)

$ErrorActionPreference = "Continue"
$HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

Write-Output "=== Phase 6C-U0-C Umbrella Verifier ==="
Write-Output ""

# --- 1. U0-B files still exist ---
$u0bFiles = @(
    "schemas\INTERFACE_CONTRACT_SCHEMA.json",
    "schemas\WORKER_INTERFACE_MANIFEST_SCHEMA.json",
    "scripts\validate-interface-contract.ps1",
    "scripts\validate-worker-interface-manifest.ps1",
    "scripts\detect-interface-drift.ps1",
    "scripts\phase6c-u0-a-verify.ps1",
    "scripts\phase6c-u0-b-verify.ps1",
    "docs\PHASE_6C_U0_CONTRACT_LOCK_MODEL.md",
    "runs\phase6c-u0-b",
    "runs\phase6c-u0-b-negative"
)
foreach ($f in $u0bFiles) {
    $fp = Join-Path $HarnessRoot $f
    if (Test-Path $fp) { [void]$passes.Add("U0-B file present: $f") }
    else { [void]$errors.Add("U0B_MISSING: $f"); $exitCode = 1 }
}

# --- 2. U0-C scripts exist ---
$u0cScripts = @(
    "scripts\extract-source-interface-manifest.ps1",
    "scripts\compare-worker-manifest-to-source.ps1"
)
foreach ($s in $u0cScripts) {
    $sp = Join-Path $HarnessRoot $s
    if (Test-Path $sp) { [void]$passes.Add("U0-C script present: $s") }
    else { [void]$errors.Add("U0C_SCRIPT_MISSING: $s"); $exitCode = 1 }
}

# --- 3. validate-state.ps1 contains manifest honesty gate (Section 12) ---
$vsContent = Get-Content (Join-Path $HarnessRoot "scripts\validate-state.ps1") -Raw
if ($vsContent -match "Manifest Honesty Gate") {
    [void]$passes.Add("validate-state.ps1 contains manifest honesty gate (Section 12)")
} else {
    [void]$errors.Add("VALIDATE_STATE_MISSING_HONESTY_GATE"); $exitCode = 1
}
if ($vsContent -match "MANIFEST_HONESTY_FAIL" -and $vsContent -match "MANIFEST_HONESTY_MISMATCHES") {
    [void]$passes.Add("validate-state.ps1: honesty failure handling present")
} else {
    [void]$errors.Add("VALIDATE_STATE_MISSING_HONESTY_FAIL_HANDLING"); $exitCode = 1
}

# --- 4. Orchestrator prompt contains source extraction + honesty steps ---
$orchContent = Get-Content (Join-Path $HarnessRoot "prompts\orchestrator-agent.md") -Raw
if ($orchContent -match "extract-source-interface-manifest" -or $orchContent -match "source-derived") {
    [void]$passes.Add("Orchestrator prompt: source extraction step present")
} else { [void]$errors.Add("ORCH_PROMPT_MISSING_SOURCE_EXTRACTION"); $exitCode = 1 }
if ($orchContent -match "compare-worker-manifest-to-source" -or $orchContent -match "manifest.honesty") {
    [void]$passes.Add("Orchestrator prompt: honesty comparison step present")
} else { [void]$errors.Add("ORCH_PROMPT_MISSING_HONESTY"); $exitCode = 1 }

# --- 5. Positive U0-C run ---
$posDir = "$HarnessRoot\runs\phase6c-u0-c"
if (Test-Path $posDir) { [void]$passes.Add("Positive U0-C run exists") }
else { [void]$errors.Add("MISSING_POSITIVE_U0C_RUN"); $exitCode = 1 }

# Source-derived manifests exist
$srcM1 = "$posDir\source-derived-interface-manifests\worker-1.json"
$srcM2 = "$posDir\source-derived-interface-manifests\worker-2.json"
if (Test-Path $srcM1) { [void]$passes.Add("Positive: source-derived manifest worker-1 exists") }
else { [void]$errors.Add("MISSING_SOURCE_MANIFEST_WORKER1"); $exitCode = 1 }
if (Test-Path $srcM2) { [void]$passes.Add("Positive: source-derived manifest worker-2 exists") }
else { [void]$errors.Add("MISSING_SOURCE_MANIFEST_WORKER2"); $exitCode = 1 }

# Honesty reports PASS
$hon1 = "$posDir\reports\manifest-honesty-report-worker-1.json"
$hon2 = "$posDir\reports\manifest-honesty-report-worker-2.json"
if (Test-Path $hon1) {
    $h1 = Get-Content $hon1 -Raw | ConvertFrom-Json
    if ($h1.verdict -eq "PASS") { [void]$passes.Add("Positive honesty worker-1: PASS") }
    else { [void]$errors.Add("POSITIVE_HONESTY_W1_NOT_PASS"); $exitCode = 1 }
    if ($h1.mismatchCount -eq 0) { [void]$passes.Add("Positive honesty worker-1 mismatchCount: 0") }
    else { [void]$errors.Add("POSITIVE_HONESTY_W1_MISMATCHES"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_HONESTY_REPORT_W1"); $exitCode = 1 }
if (Test-Path $hon2) {
    $h2 = Get-Content $hon2 -Raw | ConvertFrom-Json
    if ($h2.verdict -eq "PASS") { [void]$passes.Add("Positive honesty worker-2: PASS") }
    else { [void]$errors.Add("POSITIVE_HONESTY_W2_NOT_PASS"); $exitCode = 1 }
    if ($h2.mismatchCount -eq 0) { [void]$passes.Add("Positive honesty worker-2 mismatchCount: 0") }
    else { [void]$errors.Add("POSITIVE_HONESTY_W2_MISMATCHES"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_HONESTY_REPORT_W2"); $exitCode = 1 }

# Drift report PASS
$posDrift = "$posDir\reports\interface-drift-report.json"
if (Test-Path $posDrift) {
    $pd = Get-Content $posDrift -Raw | ConvertFrom-Json
    if ($pd.verdict -eq "PASS") { [void]$passes.Add("Positive drift report: PASS") }
    else { [void]$errors.Add("POSITIVE_DRIFT_NOT_PASS"); $exitCode = 1 }
    if ($pd.driftCount -eq 0) { [void]$passes.Add("Positive driftCount: 0") }
    else { [void]$errors.Add("POSITIVE_DRIFT_COUNT_NONZERO"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_POSITIVE_DRIFT"); $exitCode = 1 }

# Integration gate PASS
$posGate = "$posDir\reports\integration-gate-report.json"
if (Test-Path $posGate) {
    $pg = Get-Content $posGate -Raw | ConvertFrom-Json
    if ($pg.verdict -eq "PASS") { [void]$passes.Add("Positive integration gate: PASS") }
    else { [void]$errors.Add("POSITIVE_GATE_NOT_PASS"); $exitCode = 1 }
    $dep1 = $pg.dependencies.manifestHonestyWorker1
    $dep2 = $pg.dependencies.manifestHonestyWorker2
    if ($dep1 -and $dep2) {
        [void]$passes.Add("Positive integration gate: depends on both honesty reports")
    } else { [void]$errors.Add("POSITIVE_GATE_MISSING_HONESTY_DEP"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_POSITIVE_GATE"); $exitCode = 1 }

# --- 6. Negative 1: Source Mismatch (export format_date vs source formatDate) ---
$neg1Dir = "$HarnessRoot\runs\phase6c-u0-c-negative-source-mismatch"
if (Test-Path $neg1Dir) { [void]$passes.Add("Negative-1 (source mismatch) run exists") }
else { [void]$errors.Add("MISSING_NEG1_RUN"); $exitCode = 1 }

$neg1SrcManifest = "$neg1Dir\source-derived-interface-manifests\worker-2.json"
if (Test-Path $neg1SrcManifest) {
    $n1s = Get-Content $neg1SrcManifest -Raw | ConvertFrom-Json
    $n1sExportCount = @($n1s.exports).Count
    if ($n1sExportCount -gt 0) { [void]$passes.Add("Negative-1: source extraction found exports") }
    else { [void]$errors.Add("NEG1_NO_EXPORTS_EXTRACTED"); $exitCode = 1 }
    $formatDateMatches = @(@($n1s.exports) | Where-Object { $_.name -eq "formatDate" })
    $hasFormatDate = ($formatDateMatches.Count -gt 0)
    if ($hasFormatDate) { [void]$passes.Add("Negative-1: source exports 'formatDate' (correct)") }
    else { [void]$errors.Add("NEG1_EXTRACTION_WRONG"); $exitCode = 1 }
} else { [void]$errors.Add("NEG1_MISSING_SOURCE_MANIFEST"); $exitCode = 1 }

$neg1Honesty = "$neg1Dir\reports\manifest-honesty-report-worker-2.json"
if (Test-Path $neg1Honesty) {
    $n1h = Get-Content $neg1Honesty -Raw | ConvertFrom-Json
    if ($n1h.verdict -eq "FAIL") { [void]$passes.Add("Negative-1 honesty: FAIL (expected)") }
    else { [void]$errors.Add("NEG1_HONESTY_NOT_FAIL"); $exitCode = 1 }
    if ($n1h.mismatchCount -gt 0) { [void]$passes.Add("Negative-1 mismatchCount: $($n1h.mismatchCount) (expected >0)") }
    else { [void]$errors.Add("NEG1_MISMATCH_COUNT_ZERO"); $exitCode = 1 }
    $exportMismatches = @(@($n1h.mismatches) | Where-Object { $_.type -eq "export_mismatch" })
    $hasExportMismatch = ($exportMismatches.Count -gt 0)
    if ($hasExportMismatch) { [void]$passes.Add("Negative-1: export_mismatch detected (format_date vs formatDate)") }
    else { [void]$errors.Add("NEG1_NO_EXPORT_MISMATCH_TYPE"); $exitCode = 1 }
} else { [void]$errors.Add("NEG1_MISSING_HONESTY_REPORT"); $exitCode = 1 }

# --- 7. Negative 2: Import Mismatch (import format_date vs source formatDate) ---
$neg2Dir = "$HarnessRoot\runs\phase6c-u0-c-negative-import-mismatch"
if (Test-Path $neg2Dir) { [void]$passes.Add("Negative-2 (import mismatch) run exists") }
else { [void]$errors.Add("MISSING_NEG2_RUN"); $exitCode = 1 }

$neg2SrcManifest = "$neg2Dir\source-derived-interface-manifests\worker-1.json"
if (Test-Path $neg2SrcManifest) {
    $n2s = Get-Content $neg2SrcManifest -Raw | ConvertFrom-Json
    $n2sImportCount = @($n2s.imports).Count
    if ($n2sImportCount -gt 0) { [void]$passes.Add("Negative-2: source extraction found imports") }
    else { [void]$errors.Add("NEG2_NO_IMPORTS_EXTRACTED"); $exitCode = 1 }
    $formatDateMatches = @(@($n2s.imports) | Where-Object { $_.name -eq "formatDate" })
    $hasFormatDate = ($formatDateMatches.Count -gt 0)
    if ($hasFormatDate) { [void]$passes.Add("Negative-2: source imports 'formatDate' (correct)") }
    else { [void]$errors.Add("NEG2_EXTRACTION_WRONG"); $exitCode = 1 }
} else { [void]$errors.Add("NEG2_MISSING_SOURCE_MANIFEST"); $exitCode = 1 }

$neg2Honesty = "$neg2Dir\reports\manifest-honesty-report-worker-1.json"
if (Test-Path $neg2Honesty) {
    $n2h = Get-Content $neg2Honesty -Raw | ConvertFrom-Json
    if ($n2h.verdict -eq "FAIL") { [void]$passes.Add("Negative-2 honesty: FAIL (expected)") }
    else { [void]$errors.Add("NEG2_HONESTY_NOT_FAIL"); $exitCode = 1 }
    if ($n2h.mismatchCount -gt 0) { [void]$passes.Add("Negative-2 mismatchCount: $($n2h.mismatchCount) (expected >0)") }
    else { [void]$errors.Add("NEG2_MISMATCH_COUNT_ZERO"); $exitCode = 1 }
    $importMismatches = @(@($n2h.mismatches) | Where-Object { $_.type -eq "import_mismatch" })
    $hasImportMismatch = ($importMismatches.Count -gt 0)
    if ($hasImportMismatch) { [void]$passes.Add("Negative-2: import_mismatch detected (format_date vs formatDate)") }
    else { [void]$errors.Add("NEG2_NO_IMPORT_MISMATCH_TYPE"); $exitCode = 1 }
} else { [void]$errors.Add("NEG2_MISSING_HONESTY_REPORT"); $exitCode = 1 }

# --- 8. validate-state runs on positive (honesty pass as best effort, token-store failures ok) ---
$posVS = & (Join-Path $HarnessRoot "scripts\validate-state.ps1") -RunDir $posDir 2>&1 | Out-String
$posVSJson = $null
try { $pvsj = $posVS.IndexOf('{'); if ($pvsj -ge 0) { $posVSJson = $posVS.Substring($pvsj) | ConvertFrom-Json } } catch {}
if ($posVSJson) {
    $hasHonestyPass = (@($posVSJson.passes) | Where-Object { $_ -match "Manifest honesty.*PASS" }).Count -gt 0
    $hasZeroMismatches = (@($posVSJson.passes) | Where-Object { $_ -match "Manifest honesty mismatches: 0" }).Count -gt 0
    if ($hasHonestyPass) { [void]$passes.Add("Positive validate-state: manifest honesty gate PASS") }
    else { [void]$errors.Add("POSITIVE_VS_MISSING_HONESTY_PASS"); $exitCode = 1 }
    if ($hasZeroMismatches) { [void]$passes.Add("Positive validate-state: honesty mismatches = 0") }
    else { [void]$errors.Add("POSITIVE_VS_MISSING_ZERO_MISMATCHES"); $exitCode = 1 }
} else {
    [void]$errors.Add("POSITIVE_VS_CANNOT_PARSE"); $exitCode = 1
}

# --- 9. Final report ---
$finalReportPath = "$HarnessRoot\outputs\PHASE_6C_U0_C_FINAL_REPORT.md"
if (Test-Path $finalReportPath) {
    [void]$passes.Add("Final report exists")
    $frText = Get-Content $finalReportPath -Raw -Encoding UTF8
    if ($frText -match "does not prove new multi-agent") { [void]$passes.Add("Final report: no new multi-agent claim") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_DISCLAIMER"); $exitCode = 1 }
    if ($frText -match "does not run.*spawn_agent") { [void]$passes.Add("Final report: no spawn_agent claim") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_SPAWN_DISCLAIMER"); $exitCode = 1 }
    if ($frText -match "source-derived") { [void]$passes.Add("Final report: mentions source-derived manifest") }
    else { [void]$errors.Add("FINAL_REPORT_MISSING_SOURCE_DERIVED"); $exitCode = 1 }
} else { [void]$errors.Add("MISSING_FINAL_REPORT"); $exitCode = 1 }

# --- 10. T0-R3 unchanged ---
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
    phase = "Phase 6C-U0-C"
    tool = "phase6c-u0-c-verify"
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
    Write-Output "=== U0-C VERDICT: $verdict ==="
    Write-Output "Errors: $($errors.Count) | Passes: $($passes.Count)"
    foreach ($p in $passes) { Write-Output "  [PASS] $p" }
    foreach ($e in $errors) { Write-Output "  [FAIL] $e" }
}

exit $exitCode