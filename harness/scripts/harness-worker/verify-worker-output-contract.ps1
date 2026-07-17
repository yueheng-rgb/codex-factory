# verify-worker-output-contract.ps1 - Phase 6C-H8 (H8-P1 hardened)
param($WorkerContractPath, $WorkerWorkspacePath, $EvidenceOutputPath)
$ErrorActionPreference = "Continue"
$ts = (Get-Date).ToString("o")
$harnessRoot = "C:\Codex_App_Factory\harness"
$analyzerScript = Join-Path (Split-Path $PSCommandPath -Parent) "analyze-worker-output.ps1"

$raw = & powershell -NoProfile -File $analyzerScript -WorkerContractPath $WorkerContractPath -WorkerWorkspacePath $WorkerWorkspacePath 2>$null | Out-String
$evidence = try { $raw | ConvertFrom-Json } catch { $null }

if (-not $evidence -or -not $evidence.derivedExports) {
    $result = @{verdict="FAIL"; classification="FAIL_HARNESS_NOISE"; reason="Analyzer returned null or empty"; failedChecks=@("Analyzer failed"); checkedAt=$ts; evidence=$evidence}
    Write-Output (ConvertTo-Json -InputObject $result -Depth 3 -Compress)
    exit 1
}

$wc = Get-Content $WorkerContractPath -Raw | ConvertFrom-Json
$errors = @()

# Owned file violations
if ($evidence.ownedFileViolations.Count -gt 0) { $errors += "Files outside owned: $($evidence.ownedFileViolations -join ', ')" }

# Forbidden file violations
if ($evidence.forbiddenFileViolations.Count -gt 0) { $errors += "Forbidden files: $($evidence.forbiddenFileViolations -join ', ')" }

# Missing required exports
$missingExports = @()
foreach ($re in $wc.requiredExports) {
    $found = $false
    foreach ($de in $evidence.derivedExports) { if ($de -eq $re) { $found = $true; break } }
    if (-not $found) { $missingExports += $re }
}
if ($missingExports.Count -gt 0) { $errors += "Missing exports: $($missingExports -join ', ')" }

# Missing evidence outputs
$missingEvidence = @()
if ($wc.requiredEvidenceOutputs) {
    foreach ($reo in $wc.requiredEvidenceOutputs) {
        if ($reo -notin $evidence.evidenceFilesPresent) { $missingEvidence += $reo }
    }
}
if ($missingEvidence.Count -gt 0) { $errors += "Missing evidence: $($missingEvidence -join ', ')" }

# Forbidden dependencies
if ($evidence.forbiddenDependencyViolations.Count -gt 0) { $errors += "Forbidden deps: $($evidence.forbiddenDependencyViolations -join ', ')" }

# Freeze manifest check
$freezeManifest = Join-Path $WorkerWorkspacePath "worker-freeze-manifest.json"
if (Test-Path $freezeManifest) {
    $fm = Get-Content $freezeManifest -Raw | ConvertFrom-Json
    if ($fm.verifiedBeforeFreeze -eq $false) { $errors += "Freeze manifest exists but verifiedBeforeFreeze=false" }
}
# External packages
if ($evidence.hasNodeModules -or $evidence.hasPackageJson) { $errors += "External package evidence (node_modules or package.json)" }

# Minimum source files
if ($evidence.sourceFileCount -lt $wc.minimumSourceFiles) { $errors += "Source files ($($evidence.sourceFileCount)) < min ($($wc.minimumSourceFiles))" }

# Minimum exports
if ($evidence.derivedExports.Count -lt $wc.minimumExports) { $errors += "Exports ($($evidence.derivedExports.Count)) < min ($($wc.minimumExports))" }

# Shallow signals
$criticalShallow = @($evidence.shallowImplementationSignals | Where-Object { $_.signal -match 'TODO|FIXME|placeholder|stub|return null' })
if ($criticalShallow.Count -gt 0) { $errors += "Shallow signals: $($criticalShallow.Count)" }

# Behavioral code
if ($evidence.totalLineCount -lt 15 -and $wc.minimumBehavioralResponsibilities -ge 3) { $errors += "Line count ($($evidence.totalLineCount)) below behavioral threshold" }

# --- H8-P1: Acceptance Evidence Integrity Checks ---
$accEvidence = $null
$acceptanceJson = Get-ChildItem $WorkerWorkspacePath -Recurse -Filter "*acceptance*.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $acceptanceJson) { $acceptanceJson = Get-ChildItem (Join-Path $WorkerWorkspacePath "reports") -Filter "*.json" -File -ErrorAction SilentlyContinue | Select-Object -First 1 }
if ($acceptanceJson) {
    $acceptanceAnalyzer = Join-Path $harnessRoot "scripts\harness-acceptance\analyze-acceptance-evidence.ps1"
    if (Test-Path $acceptanceAnalyzer) {
        $accRaw = & powershell -NoProfile -File $acceptanceAnalyzer -AcceptanceReportPath $acceptanceJson.FullName 2>$null | Out-String
        $accEvidence = try { $accRaw | ConvertFrom-Json } catch { $null }
        if ($accEvidence) {
            # Hardcoded PASS risk
            if ($accEvidence.hardcodedPassRisk) { $errors += "[H8-P1] Hardcoded PASS risk in acceptance runner"; if ($classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" } }
            # Skipped as PASS
            if ($accEvidence.skippedAsPass) { $errors += "[H8-P1] Skipped scenarios counted as PASS"; if ($classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" } }
            # Zero-assertion passes
            $zeroAsserts = $accEvidence.issues | Where-Object { $_ -match "PASS_WITH_ZERO_ASSERTIONS" }
            if ($zeroAsserts) { $errors += "[H8-P1] $zeroAsserts"; if ($classification -eq "PASS") { $classification = "FAIL_MISSING_EVIDENCE" } }
            # Missing transcript
            $missingTranscript = $accEvidence.issues | Where-Object { $_ -match "MISSING_TRANSCRIPT" }
            if ($missingTranscript) { $errors += "[H8-P1] $missingTranscript"; if ($classification -eq "PASS") { $classification = "FAIL_MISSING_EVIDENCE" } }
            # Missing command
            $missingCommand = $accEvidence.issues | Where-Object { $_ -match "MISSING_COMMAND" }
            if ($missingCommand) { $errors += "[H8-P1] $missingCommand"; if ($classification -eq "PASS") { $classification = "FAIL_MISSING_EVIDENCE" } }
            # Duplicate scenarios
            $dupes = $accEvidence.issues | Where-Object { $_ -match "DUPLICATE_SCENARIO" }
            if ($dupes) { $errors += "[H8-P1] $dupes"; if ($classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" } }
            # Exit code contradiction
            $exitContra = $accEvidence.issues | Where-Object { $_ -match "EXIT_CODE_CONTRADICTION" }
            if ($exitContra) { $errors += "[H8-P1] $exitContra"; if ($classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" } }
            # All identical expected/actual
            $allIdentical = $accEvidence.issues | Where-Object { $_ -match "ALL_IDENTICAL" }
            if ($allIdentical) { $errors += "[H8-P1] $allIdentical"; if ($classification -eq "PASS") { $classification = "FAIL_HARNESS_NOISE" } }
        }
    }
}

# Classify
$classification = "PASS"
if ($errors.Count -gt 0) {
    $errStr = $errors -join " | "
    if ($errStr -match "External|node_modules|package") { $classification = "FAIL_CONTRACT_DRIFT" }
    elseif ($errStr -match "Missing exports|Shallow|behavioral|Exports.*min|Line count") { $classification = "FAIL_CONTRACT_DRIFT" }
    elseif ($errStr -match "Missing evidence|Freeze manifest") { $classification = "FAIL_MISSING_EVIDENCE" }
    elseif ($errStr -match "Forbidden files|Forbidden deps|Files outside") { $classification = "FAIL_PROFILE_BOUNDARY_VIOLATION" }
    else { $classification = "FAIL_HARNESS_NOISE" }
}

$verdict = if ($errors.Count -eq 0) { "PASS" } else { "FAIL" }
$result = @{verdict=$verdict; classification=$classification; failedChecks=$errors; checkedAt=$ts; h8p1AcceptanceEvidence=if ($accEvidence) { $accEvidence.issues } else { @() }}
Write-Output (ConvertTo-Json -InputObject $result -Depth 3 -Compress)
exit $(if ($verdict -eq "FAIL") { 1 } else { 0 })