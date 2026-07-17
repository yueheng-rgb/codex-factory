# validate-report-sanitization.ps1 — Phase 6C-H2-P2
# Raw report sanitizer. Checks for control characters, corrupted paths, broken words,
# PENDING contradictions, and free-text Classified values.
param(
    [Parameter(Mandatory=$true)][string]$ReportPath,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$findings = [System.Collections.ArrayList]::new()
$exitCode = 0

if (-not (Test-Path $ReportPath)) {
    $result = @{
        verdict = "FAIL"
        reportPath = $ReportPath
        reason = "REPORT_NOT_FOUND"
        controlCharacterFindings = @()
        corruptedPathFindings = @()
        brokenWordFindings = @()
        pendingContradictionFindings = @()
        checkedAt = (Get-Date).ToString("o")
    }
    Write-Output ($result | ConvertTo-Json -Depth 3)
    exit 1
}

# Read as raw bytes to detect all control chars
$rawBytes = [System.IO.File]::ReadAllBytes($ReportPath)
$reportText = [System.Text.Encoding]::UTF8.GetString($rawBytes)

# Normalize line endings
$reportText = $reportText -replace "`r`n", "`n" -replace "`r", "`n"

# ===== Check 1: Embedded control characters =====
$controlFindings = @()
for ($i = 0; $i -lt $rawBytes.Length; $i++) {
    $b = $rawBytes[$i]
    $isBad = ($b -le 0x08) -or ($b -eq 0x09) -or ($b -eq 0x0B) -or ($b -eq 0x0C) -or ($b -ge 0x0E -and $b -le 0x1F) -or ($b -eq 0x7F)
    if ($isBad) {
        $start = [Math]::Max(0, $i - 20)
        $end = [Math]::Min($reportText.Length - 1, $i + 20)
        $context = $reportText.Substring($start, $end - $start + 1) -replace "`n","\\n" -replace "`r","\\r" -replace "`t","\\t"
        $controlFindings += "CONTROL_CHAR_0x{0:X2} at pos {1}: ...{2}..." -f $b, $i, $context
    }
}
if ($controlFindings.Count -gt 0) {
    [void]$findings.Add("CONTROL_CHARS: $($controlFindings.Count) found")
    $exitCode = 1
}

# ===== Check 2: Corrupted path fragments =====
$pathFindings = @()
$corruptPatterns = @(
    @{pattern='(?<!\w)uns/h1-'; desc='Corrupted path: uns/h1- (missing r)'},
    @{pattern='(?<!\w)uns/h2-'; desc='Corrupted path: uns/h2- (missing r)'}
)
foreach ($cp in $corruptPatterns) {
    if ($reportText -match $cp.pattern) {
        $pathFindings += $cp.desc
        $exitCode = 1
    }
}
if ($pathFindings.Count -gt 0) {
    [void]$findings.Add("CORRUPTED_PATHS: $($pathFindings.Count) found")
}

# ===== Check 3: Broken word fragments =====
$wordFindings = @()
$brokenWords = @(
    @{fragment='un-core-script'; correct='run-core-script'},
    @{fragment='ampered-registry'; correct='tampered-registry'},
    @{fragment='egister-verifier'; correct='register-verifier'},
    @{fragment='erify-verifier'; correct='verify-verifier'},
    @{fragment='reeze-worker'; correct='freeze-worker'},
    @{fragment='equire-run-state'; correct='require-run-state'},
    @{fragment='alidate-cfp'; correct='validate-cfp'}
)
foreach ($bw in $brokenWords) {
    if (($reportText -match [regex]::Escape($bw.fragment)) -and ($reportText -notmatch [regex]::Escape($bw.correct))) {
        $wordFindings += "BROKEN_WORD: '$($bw.fragment)' should be '$($bw.correct)'"
        $exitCode = 1
    }
}
if ($wordFindings.Count -gt 0) {
    [void]$findings.Add("BROKEN_WORDS: $($wordFindings.Count) found")
}

# ===== Check 4: PENDING in PASS report =====
$pendingFindings = @()
# Filter only fixture table rows (lines starting with |)
$checkLines = ($reportText -split "`n") | Where-Object { $_ -notmatch '^\|' }
$checkText = $checkLines -join "`n"

# Check 4a: Verdict says PASS but PENDING verifier status exists
if (($checkText -match 'Verdict.*PASS') -or ($checkText -match 'PASS.*\d+/\d+')) {
    if (($checkText -match '\bPENDING\b') -and ($checkText -match 'verifier not yet run')) {
        $pendingFindings += "PASS report contains PENDING verifier status"
        $exitCode = 1
    }
}

# Check 4b: PENDING/PASS contradiction (exclude taxonomy names and fixture names)
$pendLines = ($checkLines | Where-Object { ($_ -match '\bPENDING\b') -and ($_ -notmatch 'PASS_PENDING_RECONCILIATION') -and ($_ -notmatch 'report-pending') })
if ($pendLines.Count -gt 1) {
    $pendText = $pendLines -join "`n"
    if (($pendText -match '\bPASS\b') -or ($checkText -match 'Verdict.*PASS')) {
        $pendingFindings += "PASS/PENDING contradiction in same report"
        $exitCode = 1
    }
}

if ($pendingFindings.Count -gt 0) {
    [void]$findings.Add("PENDING_CONTRADICTIONS: $($pendingFindings.Count) found")
}

# ===== Check 5: Free-text Classified values =====
$validClasses = @("PASS","PASS_WITH_CAVEAT","PASS_PENDING_RECONCILIATION","FAIL_TARGET_GATE","FAIL_HARNESS_NOISE","FAIL_MISSING_EVIDENCE","FAIL_CONTRACT_DRIFT","FAIL_CLOSED_EVIDENCE_MUTATION","FAIL_VERIFIER_TAMPER","FAIL_INTEGRATION_UNRECORDED_PATCH","NOT PASS")
$classFindings = @()
$fixtureRows = [regex]::Matches($reportText, '\| (\d+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|')
foreach ($row in $fixtureRows) {
    $classified = $row.Groups[4].Value.Trim() -replace '\*\*', ''
    if ($classified -notin $validClasses) {
        $classFindings += "FREE_TEXT_CLASSIFIED: '$classified' is not a valid taxonomy class"
        $exitCode = 1
    }
}
if ($classFindings.Count -gt 0) {
    [void]$findings.Add("FREE_TEXT_CLASSIFIED: $($classFindings.Count) found")
}

# ===== Check 6: Duplicate fixture rows =====
$dupFindings = @()
$allRows = [regex]::Matches($reportText, '\| (\d+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \| ([^|]+) \|')
$seen = @{}
foreach ($row in $allRows) {
    $key = $row.Value
    if ($seen.ContainsKey($key)) {
        $dupFindings += "DUPLICATE_ROW: fixture $($row.Groups[1].Value)"
        $exitCode = 1
    }
    $seen[$key] = $true
}
if ($dupFindings.Count -gt 0) {
    [void]$findings.Add("DUPLICATE_ROWS: $($dupFindings.Count) found")
}

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{
    verdict = $verdict
    reportPath = $ReportPath
    controlCharacterFindings = $controlFindings
    corruptedPathFindings = $pathFindings
    brokenWordFindings = $wordFindings
    pendingContradictionFindings = $pendingFindings
    freeTextClassifiedFindings = $classFindings
    duplicateRowFindings = $dupFindings
    allFindings = $findings
    checkedAt = (Get-Date).ToString("o")
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode