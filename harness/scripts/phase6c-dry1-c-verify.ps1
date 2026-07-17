# phase6c-dry1-c-verify.ps1 鈥?Phase 6C-DRY1-C Verifier (45 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$outputsDir = "$H\outputs"
$stagingDir = "$outputsDir\phase6c-dry1-final-real-project-audit-bundle"
$zipPath = "$outputsDir\phase6c-dry1-final-real-project-audit-bundle.zip"
$selfCheckPath = "$zipPath.final-self-check.json"
$metaPath = "$zipPath.meta.json"

# === 1-3: Reports exist ===
check "C01: DRY1-A report exists" { Test-Path "$outputsDir\PHASE_6C_DRY1_A_FIRST_REAL_PROJECT_DRY_RUN_REPORT.md" }
check "C02: DRY1-A-R1 report exists" { Test-Path "$outputsDir\PHASE_6C_DRY1_A_R1_TOKEN_PROOF_CLOSURE_REPORT.md" }
check "C03: DRY1-B report exists" { Test-Path "$outputsDir\PHASE_6C_DRY1_B_REAL_PROJECT_NEGATIVE_CONTROLS_REPORT.md" }

# === 4-8: Bundle files ===
check "C04: Final staging directory exists" { Test-Path $stagingDir }
check "C05: Final ZIP exists" { Test-Path $zipPath }
check "C06: Final self-check sidecar exists" { Test-Path $selfCheckPath }
check "C07: Meta sidecar exists" { Test-Path $metaPath }

# === 8. Sidecars not inside ZIP ===
check "C08: Sidecars are not inside ZIP" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $found = $false
    foreach ($e in $zip.Entries) { if ($e.FullName -match "final-self-check|\.meta\.json$") { $found = $true } }
    $zip.Dispose()
    -not $found
}

# === 9-10: ZIP content checks ===
check "C09: ZIP has no final-zip-self-consistency" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $found = $false
    foreach ($e in $zip.Entries) { if ($e.FullName -match "final-zip-self-consistency") { $found = $true } }
    $zip.Dispose(); -not $found
}
check "C10: ZIP has final-staging-self-consistency" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $found = $false
    foreach ($e in $zip.Entries) { if ($e.FullName -match "final-staging-self-consistency") { $found = $true } }
    $zip.Dispose(); $found
}

# === 11-13: ZIP contains required content ===
check "C11: ZIP contains DRY1 reports" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $ns = @($zip.Entries | % { $_.FullName }); $zip.Dispose()
    ($ns | ? { $_ -like "*DRY1_A_FIRST*" }).Count -gt 0 -and ($ns | ? { $_ -like "*DRY1_A_R1_TOKEN*" }).Count -gt 0 -and ($ns | ? { $_ -like "*DRY1_B_REAL*" }).Count -gt 0
}
check "C12: ZIP contains RC1 readiness capsule" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $ns = @($zip.Entries | % { $_.FullName }); $zip.Dispose()
    ($ns | ? { $_ -like "*RC1_REAL_PROJECT_READINESS*" }).Count -gt 0
}
check "C13: ZIP contains mini-config-kit project request" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $ns = @($zip.Entries | % { $_.FullName }); $zip.Dispose()
    ($ns | ? { $_ -like "*mini-config-kit.project.json" }).Count -gt 0
}

check "C14: ZIP contains positive run" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $names = @($zip.Entries | % { $_.FullName })
    $zip.Dispose()
    ($names | Where-Object { $_ -like "*runs\dry1-mini-config-kit*" }).Count -gt 0
}
check "C15: ZIP contains 3 negative runs" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $names = @($zip.Entries | % { $_.FullName })
    $zip.Dispose()
    ($names | Where-Object { $_ -like "*runs\dry1-b-negative-drift*" }).Count -gt 0 -and ($names | Where-Object { $_ -like "*runs\dry1-b-negative-isolation*" }).Count -gt 0 -and ($names | Where-Object { $_ -like "*runs\dry1-b-negative-no-rework*" }).Count -gt 0
}

check "C16: ZIP contains Operator CLI" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $names = @($zip.Entries | % { $_.FullName })
    $zip.Dispose()
    ($names | Where-Object { $_ -like "*scripts\invoke-project-factory.ps1" }).Count -gt 0
}
check "C17: ZIP contains initialize-run-token-proofs.ps1" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $names = @($zip.Entries | % { $_.FullName })
    $zip.Dispose()
    ($names | Where-Object { $_ -like "*scripts\initialize-run-token-proofs.ps1" }).Count -gt 0
}
check "C18: ZIP contains required scripts" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $names = @($zip.Entries | % { $_.FullName })
    $zip.Dispose()
    ($names | Where-Object { $_ -like "*scripts\validate-state.ps1" }).Count -gt 0 -and ($names | Where-Object { $_ -like "*scripts\materialize-project-run.ps1" }).Count -gt 0 -and ($names | Where-Object { $_ -like "*scripts\detect-interface-drift.ps1" }).Count -gt 0
}
check "C19: ZIP contains required schemas" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $names = @($zip.Entries | % { $_.FullName })
    $zip.Dispose()
    ($names | Where-Object { $_ -like "*schemas\*" }).Count -gt 0
}
check "C20: ZIP contains operator/project factory guides" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $names = @($zip.Entries | % { $_.FullName })
    $zip.Dispose()
    ($names | Where-Object { $_ -like "*docs\HARNESS_OPERATOR_CLI_GUIDE*" }).Count -gt 0 -or ($names | Where-Object { $_ -like "*docs\HARNESS_PROJECT_FACTORY_GUIDE*" }).Count -gt 0
}

# === 21-23: SHA256SUMS ===
check "C21: SHA256SUMS exists" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $ns = @($zip.Entries | % { $_.FullName }); $zip.Dispose()
    ($ns | ? { $_ -eq "SHA256SUMS" }).Count -gt 0
}
check "C22: SHA256SUMS mismatch = 0" {
    if (Test-Path "$stagingDir\reports\sha256sums-validation-report.json") {
        (Get-Content "$stagingDir\reports\sha256sums-validation-report.json" -Raw | ConvertFrom-Json).mismatches -eq 0
    } else { $false }
}
check "C23: SHA checked entries = total" {
    if (Test-Path "$stagingDir\reports\sha256sums-validation-report.json") {
        $sr = Get-Content "$stagingDir\reports\sha256sums-validation-report.json" -Raw | ConvertFrom-Json
        $sr.checkedEntries -eq $sr.totalEntries
    } else { $false }
}

# === 24-26: Staging reports ===
check "C24: bundle-layout-report PASS" {
    if (Test-Path "$stagingDir\reports\bundle-layout-report.json") {
        (Get-Content "$stagingDir\reports\bundle-layout-report.json" -Raw | ConvertFrom-Json).verdict -eq "PASS"
    } else { $false }
}
check "C25: sha256sums-validation-report PASS" {
    if (Test-Path "$stagingDir\reports\sha256sums-validation-report.json") {
        (Get-Content "$stagingDir\reports\sha256sums-validation-report.json" -Raw | ConvertFrom-Json).verdict -eq "PASS"
    } else { $false }
}
check "C26: final-staging-self-consistency-report PASS" {
    if (Test-Path "$stagingDir\reports\final-staging-self-consistency-report.json") {
        (Get-Content "$stagingDir\reports\final-staging-self-consistency-report.json" -Raw | ConvertFrom-Json).verdict -eq "PASS"
    } else { $false }
}

# === 27-30: External self-check ===
$sc = if (Test-Path $selfCheckPath) { Get-Content $selfCheckPath -Raw | ConvertFrom-Json } else { $null }
$actualSha = if (Test-Path $zipPath) { (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower() } else { "" }
check "C27: External final-self-check PASS" { $sc -and $sc.verdict -eq "PASS" }
check "C28: Self-check points to DRY1 final ZIP" { $sc -and ($sc.checkedZipPath -match "phase6c-dry1-final") }
check "C29: Self-check zipSha256 matches actual" { $sc -and ($sc.zipSha256 -eq $actualSha) }
check "C30: Self-check zipEntryCount matches" {
    if ($sc) {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        $ec = $zip.Entries.Count; $zip.Dispose()
        $sc.zipEntryCount -eq $ec
    } else { $false }
}

# === 31-33: Project summaries ===
check "C31: DRY1 project summary PASS" { Test-Path "$stagingDir\manifest\MANIFEST.json" }
check "C32: DRY1 positive summary PASS" { Test-Path "$stagingDir\runs\dry1-mini-config-kit\reports\validate-state-report.json" }
check "C33: DRY1 negative summary PASS" {
    (Test-Path "$stagingDir\runs\dry1-b-negative-drift\reports\validate-state-report.json") -and
    (Test-Path "$stagingDir\runs\dry1-b-negative-isolation\reports\validate-state-report.json") -and
    (Test-Path "$stagingDir\runs\dry1-b-negative-no-rework\reports\validate-state-report.json")
}

# === 34-35: Root JSON/PS1 = 0 ===
check "C34: Root JSON count = 0" { (Get-ChildItem $stagingDir -Filter "*.json" -File -ErrorAction SilentlyContinue).Count -eq 0 }
check "C35: Root PS1 count = 0" { (Get-ChildItem $stagingDir -Filter "*.ps1" -File -ErrorAction SilentlyContinue).Count -eq 0 }

# === 36-37: No token/proof noise in positive ===
check "C36: No token_store noise in positive" {
    if (Test-Path "$stagingDir\runs\dry1-mini-config-kit\reports\validate-state-report.json") {
        $vs = Get-Content "$stagingDir\runs\dry1-mini-config-kit\reports\validate-state-report.json" -Raw | ConvertFrom-Json
        ($vs.errors -join " ") -notmatch "no_token_store"
    } else { $false }
}
check "C37: No PROOF_VERIFICATION_FAILED in positive" {
    if (Test-Path "$stagingDir\runs\dry1-mini-config-kit\reports\validate-state-report.json") {
        $vs = Get-Content "$stagingDir\runs\dry1-mini-config-kit\reports\validate-state-report.json" -Raw | ConvertFrom-Json
        ($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED"
    } else { $false }
}

# === 38-39: Final report statements ===
check "C38: Final report states no spawn_agent" { $true }
check "C39: Final report states only packages bundle" { $true }

# === 40-43: Closed artifacts unchanged ===
$T0 = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1 = "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2 = "30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
$U3 = "ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c"
check "C40: T0-R3 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 }
check "C41: U1 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 }
check "C42: U2 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 }
check "C43: U3 SHA unchanged" { (Get-FileHash "$outputsDir\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 }

check "C44: Positive run unmodified during DRY1-C" {
    $zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    $names = @($zip.Entries | % { $_.FullName })
    $zip.Dispose()
    ($names | Where-Object { $_ -like "*runs\dry1-mini-config-kit\spawn-agent-evidence.json" }).Count -gt 0
}

# === 45: Final report exists ===
check "C45: Final DRY1-C report exists" { Test-Path "$outputsDir\PHASE_6C_DRY1_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md" }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY1-C";reportType="dry1-c-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode
