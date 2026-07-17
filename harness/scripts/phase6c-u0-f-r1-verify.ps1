# phase6c-u0-f-r1-verify.ps1 -- Phase 6C-U0-F-R1 validate-state Reconstruction Integrity Regression Verifier
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$VS = Join-Path $H "scripts\validate-state.ps1"
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$W = [System.Collections.ArrayList]@()
$total = 0; $ok = 0

function check($label, $scriptBlock) {
    $script:total++
    try { if (& $scriptBlock) { [void]$script:P.Add($label); $script:ok++ } else { [void]$script:E.Add("$label-FAIL") } }
    catch { [void]$script:E.Add("$label-ERROR: $_") }
}

function runVs($dir) {
    $o = & $script:VS -RunDir $dir 2>&1 | Out-String
    try { return ($o | ConvertFrom-Json) } catch { return $null }
}

# ============================================================
# 1-5: validate-state.ps1 source integrity
# ============================================================
$vsContent = [System.IO.File]::ReadAllText($VS, $utf8)
$vsLines = (Get-Content $VS).Count

check "CHK-01: validate-state.ps1 exists" { Test-Path $VS }
check "CHK-02: validate-state.ps1 non-empty" { $vsLines -gt 10 }
check "CHK-03: Contains Sections 1-14" {
    ($vsContent -match "# --- 1\. File existence" -and
     $vsContent -match "# --- 14\. U0-F Rework Loop Gate")
}
check "CHK-04: Authorization proof validation present" { $vsContent -match "verify-proof|authorizationProof" }
check "CHK-05: Hash chain validation present" { $vsContent -match "previousHash|HASH_CHAIN_BREAK" }

# ============================================================
# 6-9: Positive regression (U0-C, U0-D, U0-E, U0-F)
# ============================================================
$posDirs = @{
    "U0-C-R1" = "$H\runs\phase6c-u0-c-r1"
    "U0-D"    = "$H\runs\phase6c-u0-d-real"
    "U0-E"    = "$H\runs\phase6c-u0-e-real-parallel"
    "U0-F"    = "$H\runs\phase6c-u0-f-rework"
}
$posResults = @{}
foreach ($k in $posDirs.Keys) {
    $posResults[$k] = runVs $posDirs[$k]
}

check "CHK-06: U0-C-R1 validate-state PASS" { $posResults["U0-C-R1"].verdict -eq "run_passed" }
check "CHK-07: U0-D validate-state PASS"    { $posResults["U0-D"].verdict -eq "run_passed" }
check "CHK-08: U0-E validate-state PASS"    { $posResults["U0-E"].verdict -eq "run_passed" }
check "CHK-09: U0-F validate-state PASS"    { $posResults["U0-F"].verdict -eq "run_passed" }

# ============================================================
# 10-14: Negative regression (U0-C source, U0-C import, U0-D, U0-E, U0-F)
# ============================================================
$negDirs = @{
    "U0-C-SRC" = "$H\runs\phase6c-u0-c-r1-negative-source-mismatch"
    "U0-C-IMP" = "$H\runs\phase6c-u0-c-r1-negative-import-mismatch"
    "U0-D"     = "$H\runs\phase6c-u0-d-negative"
    "U0-E"     = "$H\runs\phase6c-u0-e-negative-isolation"
    "U0-F"     = "$H\runs\phase6c-u0-f-negative-no-rework"
}
$negResults = @{}
foreach ($k in $negDirs.Keys) {
    $negResults[$k] = runVs $negDirs[$k]
}

check "CHK-10: U0-C source mismatch FAIL for drift/honesty" {
    $r = $negResults["U0-C-SRC"]; ($r.verdict -eq "run_failed") -and ($r.errors -join " " -match "INTERFACE_DRIFT_FAIL|MANIFEST_HONESTY_FAIL")
}
check "CHK-11: U0-C import mismatch FAIL for drift/honesty" {
    $r = $negResults["U0-C-IMP"]; ($r.verdict -eq "run_failed") -and ($r.errors -join " " -match "INTERFACE_DRIFT_FAIL|MANIFEST_HONESTY_FAIL")
}
check "CHK-12: U0-D negative FAIL for drift/honesty" {
    $r = $negResults["U0-D"]; ($r.verdict -eq "run_failed") -and ($r.errors -join " " -match "INTERFACE_DRIFT_FAIL|MANIFEST_HONESTY_FAIL")
}
check "CHK-13: U0-E negative FAIL for isolation/ownership" {
    $r = $negResults["U0-E"]; ($r.verdict -eq "run_failed") -and ($r.errors -join " " -match "WORKSPACE_ISOLATION_FAIL|OWNERSHIP_VIOLATION")
}
check "CHK-14: U0-F negative FAIL for REWORK_NO_RESOLUTION" {
    $r = $negResults["U0-F"]; ($r.verdict -eq "run_failed") -and ($r.errors -join " " -match "REWORK_NO_RESOLUTION")
}

# ============================================================
# 15-16: New trust-root negatives
# ============================================================
$tokNegDir = "$H\runs\phase6c-u0-f-r1-negative-missing-token-store"
$hashNegDir = "$H\runs\phase6c-u0-f-r1-negative-broken-hash-chain"
$tokNegResult = runVs $tokNegDir
$hashNegResult = runVs $hashNegDir

check "CHK-15: Missing token store FAIL" {
    ($tokNegResult.verdict -eq "run_failed") -and ($tokNegResult.errors -join " " -match "no_token_store")
}
check "CHK-16: Broken hash chain FAIL" {
    ($hashNegResult.verdict -eq "run_failed") -and ($hashNegResult.errors -join " " -match "HASH_CHAIN_BREAK")
}

# ============================================================
# 17-19: No noise in positives (no no_token_store, no PROOF_VERIFICATION_FAILED, no script crash)
# ============================================================
check "CHK-17: No positive has no_token_store" {
    ($posResults.Values | Where-Object { ($_.errors -join " " -match "no_token_store") }).Count -eq 0
}
check "CHK-18: No positive has PROOF_VERIFICATION_FAILED" {
    ($posResults.Values | Where-Object { ($_.errors -join " " -match "PROOF_VERIFICATION_FAILED") }).Count -eq 0
}
check "CHK-19: No negative fails due to script crash" {
    ($negResults.Values | Where-Object { $null -eq $_ }).Count -eq 0
}

# ============================================================
# 20-24: Misc checks
# ============================================================
check "CHK-20: validate-state.ps1 > 500 lines" { $vsLines -gt 500 }
check "CHK-21: validate-state.ps1 < 600 lines" { $vsLines -lt 600 }
check "CHK-22: All 14 section headers present" {
    $nums = @(1,2,3,4,5,6,7,8,9,10,11,12,13,14)
    $allFound = $true
    foreach ($n in $nums) {
        if ($vsContent -notmatch "# --- $n\.") { $allFound = $false }
    }
    $allFound
}
check "CHK-23: T0-R3 artifacts unchanged" {
    # Check T0-R3 ZIP still exists with known SHA256
    $zip = "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"
    if (Test-Path $zip) {
        $sha = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
        $sha -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
    } else {
        $false
    }
}
check "CHK-24: U0-D/U0-E/U0-F closed artifacts exist" {
    (Test-Path "$H\runs\phase6c-u0-d-real") -and
    (Test-Path "$H\runs\phase6c-u0-e-real-parallel") -and
    (Test-Path "$H\runs\phase6c-u0-f-rework") -and
    (Test-Path "$H\outputs\PHASE_6C_U0_F_FINAL_REPORT.md")
}

# ============================================================
$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$exitCode = if ($E.Count -gt 0) { 1 } else { 0 }

@{
    phase="Phase 6C-U0-F-R1"; reportType="u0-f-r1-verifier"; verdict=$verdict
    timestamp=(Get-Date).ToString("o"); totalChecks=$total; passCount=$ok; failCount=$E.Count
    passes=$P; errors=$E; warnings=$W
} | ConvertTo-Json -Depth 3

exit $exitCode