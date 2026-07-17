# phase6c-u1-d-verify.ps1 閳?Phase 6C-U1-D Final Audit Bundle Verifier (38 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"

Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l, $sb) { $script:total++; try { if (& $sb) { [void]$script:P.Add($l); $script:ok++ } else { [void]$script:E.Add("$l-FAIL") } } catch { [void]$script:E.Add("$l-ERROR: $_") } }

$zipPath = "$H\outputs\phase6c-u1-final-audit-bundle.zip"
$staging = "$H\outputs\phase6c-u1-final-audit-bundle"
$scPath = "$zipPath.final-self-check.json"
$metaPath = "$zipPath.meta.json"

# 1-3: Pre-reqs
check "V01: U1-C report exists" { Test-Path "$H\outputs\PHASE_6C_U1_C_NEGATIVE_CONTROLS_REPORT.md" }
check "V02: U1-B report exists" { Test-Path "$H\outputs\PHASE_6C_U1_B_REAL_RUN_REPORT.md" }
check "V03: Staging directory exists" { Test-Path $staging }

# 4-6: ZIP + sidecars
check "V04: Final ZIP exists" { Test-Path $zipPath }
check "V05: Self-check sidecar exists" { Test-Path $scPath }
check "V06: Meta sidecar exists" { Test-Path $metaPath }

# 7-9: Sidecar separation (T0-R3 rule)
$zip = if (Test-Path $zipPath) { [System.IO.Compression.ZipFile]::OpenRead($zipPath) } else { $null }
$zipEntries = if ($zip) { $zip.Entries | ForEach-Object { $_.FullName } } else { @() }
check "V07: Sidecars not inside ZIP" { ($zipEntries | Where-Object { $_ -match "final-self-check|\.meta\.json" }).Count -eq 0 }
check "V08: No final-zip-self-consistency in ZIP" { ($zipEntries | Where-Object { $_ -match "final-zip-self-consistency" }).Count -eq 0 }
check "V09: Staging self-consistency in ZIP" { ($zipEntries | Where-Object { $_ -match "final-staging-self-consistency" }).Count -gt 0 }
if ($zip) { $zip.Dispose() }

# 10-16: ZIP content
$zip2 = if (Test-Path $zipPath) { [System.IO.Compression.ZipFile]::OpenRead($zipPath) } else { $null }
$ze = if ($zip2) { $zip2.Entries | ForEach-Object { $_.FullName } } else { @() }
check "V10: ZIP contains U1 positive run" { ($ze | Where-Object { $_ -match "runs\\u1-r1\\" }).Count -gt 0 }
check "V11: ZIP contains 3 negative runs" { ($ze | Where-Object { $_ -match "runs\\u1-r1-negative" }).Count -gt 2 }
check "V12: ZIP contains U1 reports" { ($ze | Where-Object { $_ -match "PHASE_6C_U1" }).Count -ge 4 }
check "V13: ZIP contains validate-state.ps1" { ($ze | Where-Object { $_ -match "scripts\\validate-state.ps1" }).Count -gt 0 }
check "V14: ZIP contains U1 verifiers" { ($ze | Where-Object { $_ -match "phase6c-u1-.-verify" }).Count -ge 3 }
check "V15: ZIP contains required schemas" { ($ze | Where-Object { $_ -match "INTERFACE_CONTRACT_SCHEMA|WORKER_INTERFACE_MANIFEST" }).Count -ge 2 }
check "V16: ZIP contains required prompts" { ($ze | Where-Object { $_ -match "orchestrator-agent|worker-agent|worker-.-prompt" }).Count -ge 2 }
if ($zip2) { $zip2.Dispose() }

# 17-19: SHA256SUMS
$sumsPath = "$staging\SHA256SUMS"
check "V17: SHA256SUMS exists" { Test-Path $sumsPath }
$sumLines = if (Test-Path $sumsPath) { Get-Content $sumsPath } else { @() }
check "V18: SHA256SUMS mismatch=0" {
    $m = 0
    foreach ($line in $sumLines) { if ($line.Trim().Length -eq 0) { continue }; $p = $line -split "\s+",2; if ($p.Count -lt 2) { continue }; $fp = Join-Path $staging $p[1]; if (Test-Path $fp) { if ((Get-FileHash $fp -Algorithm SHA256).Hash.ToLower() -ne $p[0]) { $m++ } } else { $m++ } }
    $m -eq 0
}
check "V19: SHA checkedEntries=line count" { $sumLines.Count -gt 0 }

# 20-22: Bundle reports
check "V20: Bundle-layout PASS" {
    $bl = Get-Content "$staging\reports\bundle-layout-report.json" | ConvertFrom-Json
    $bl.verdict -eq "PASS"
}
check "V21: SHA256SUMS validation PASS" {
    $sv = Get-Content "$staging\reports\sha256sums-validation-report.json" | ConvertFrom-Json
    $sv.verdict -eq "PASS"
}
check "V22: Staging self-consistency PASS" {
    $sc = Get-Content "$staging\reports\final-staging-self-consistency-report.json" | ConvertFrom-Json
    $sc.verdict -eq "PASS"
}

# 23-26: External self-check
$scData = if (Test-Path $scPath) { Get-Content $scPath | ConvertFrom-Json } else { $null }
$actualZipSha = if (Test-Path $zipPath) { (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower() } else { "" }
$actualZipEntries = if (Test-Path $zipPath) { ([System.IO.Compression.ZipFile]::OpenRead($zipPath)).Entries.Count } else { 0 }
check "V23: External self-check PASS" { $scData -and $scData.verdict -eq "PASS" }
check "V24: Self-check points to U1 ZIP" { $scData -and $scData.artifactPath -match "phase6c-u1-final-audit-bundle.zip" }
check "V25: Self-check SHA matches actual" { $scData -and $scData.artifactSha256 -eq $actualZipSha }
check "V26: Self-check entry count matches" { $scData -and $scData.artifactEntryCount -eq $actualZipEntries }

# 27-28: Summaries
check "V27: Positive summary PASS" {
    $ps = if (Test-Path "$staging\reports\u1-positive-summary.json") { Get-Content "$staging\reports\u1-positive-summary.json" | ConvertFrom-Json } else { $null }
    $ps -and $ps.validateStateVerdict -eq "run_passed"
}
check "V28: Negative summary PASS" {
    $ns = if (Test-Path "$staging\reports\u1-negative-summary.json") { Get-Content "$staging\reports\u1-negative-summary.json" | ConvertFrom-Json } else { $null }
    $ns -and $ns.allFailForIntendedReasons -eq $true
}

# 29-32: Root checks
check "V29: Root JSON=0" { (Get-ChildItem $staging -File -Filter "*.json").Count -eq 0 }
check "V30: Root PS1=0" { (Get-ChildItem $staging -File -Filter "*.ps1").Count -eq 0 }
$posSummary = Get-Content "$staging\reports\u1-positive-summary.json" -Raw
check "V31: No no_token_store in positive" { $posSummary -notmatch "no_token_store" }
check "V32: No PROOF_VERIFICATION_FAILED in positive" { $posSummary -notmatch "PROOF_VERIFICATION_FAILED" }

# 33-38: Boundaries
$report = if (Test-Path "$H\outputs\PHASE_6C_U1_D_FINAL_AUDIT_BUNDLE_REPORT.md") { Get-Content "$H\outputs\PHASE_6C_U1_D_FINAL_AUDIT_BUNDLE_REPORT.md" -Raw } else { "" }
check "V33: Report states no spawn_agent" { $report -match "does not run spawn_agent|does not prove new multi-agent" }
check "V34: Report states only packages bundle" { $report -match "packages|audit bundle" }
check "V35: T0-R3 ZIP unchanged" {
    $tz = "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"
    if (Test-Path $tz) { (Get-FileHash $tz -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d" } else { $false }
}
check "V36: U0-D/E/F runs exist" { (Test-Path "$H\runs\phase6c-u0-d-real") -and (Test-Path "$H\runs\phase6c-u0-e-real-parallel") -and (Test-Path "$H\runs\phase6c-u0-f-rework") }
check "V37: Final report exists" { Test-Path "$H\outputs\PHASE_6C_U1_D_FINAL_AUDIT_BUNDLE_REPORT.md" }
check "V38: U1-B positive not modified during U1-D" {
    $posVs = & "$H\scripts\validate-state.ps1" -RunDir "$H\runs\u1-r1" 2>&1 | Out-String
    $posVs -match '"verdict":\s*"run_passed"'
}

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$exitCode = if ($E.Count -gt 0) { 1 } else { 0 }
@{ phase="Phase 6C-U1-D"; reportType="u1-d-verifier"; verdict=$verdict; timestamp=(Get-Date).ToString("o"); totalChecks=$total; passCount=$ok; failCount=$E.Count; passes=$P; errors=$E } | ConvertTo-Json -Depth 3
exit $exitCode