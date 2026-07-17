
# Codex Factory v2.1 - CI Artifact Verifier
# Verifies artifact store integrity: stdout/stderr files exist, test counts match, traceability is valid.
param(
  [Parameter(Mandatory=$true)]
  [string]$StoreIndexPath,
  [Parameter(Mandatory=$false)]
  [int]$ExpectedTests = 210
)

$index = Get-Content $StoreIndexPath | ConvertFrom-Json
$storeDir = Split-Path $StoreIndexPath -Parent
$issues = @()

Write-Host "=== CI ARTIFACT VERIFIER ===" -ForegroundColor Cyan
Write-Host "Store: $StoreIndexPath" -ForegroundColor Cyan

# Check 1: Store version
if ($index.store_version -ne "2.1.0") {
  $issues += "WRONG_VERSION: $($index.store_version)"
  Write-Host "[FAIL] Store version: $($index.store_version) (expected 2.1.0)" -ForegroundColor Red
} else {
  Write-Host "[PASS] Store version: $($index.store_version)" -ForegroundColor Green
}

# Check 2: All artifacts have stdout/stderr files
foreach ($a in $index.artifacts) {
  $stdoutPath = Join-Path $storeDir $a.stdout_file
  $stderrPath = Join-Path $storeDir $a.stderr_file
  if (-not (Test-Path $stdoutPath)) {
    $issues += "MISSING_STDOUT: $($a.artifact_id)"
    Write-Host "[FAIL] $($a.artifact_id): stdout missing" -ForegroundColor Red
  }
  if (-not (Test-Path $stderrPath)) {
    $issues += "MISSING_STDERR: $($a.artifact_id)"
    Write-Host "[FAIL] $($a.artifact_id): stderr missing" -ForegroundColor Red
  }
  # Check stdout is not empty placeholder
  $soSize = (Get-Item $stdoutPath -ErrorAction SilentlyContinue).Length
  if ($soSize -le 16) {
    $issues += "EMPTY_STDOUT: $($a.artifact_id)"
    Write-Host "[WARN] $($a.artifact_id): stdout is only $soSize bytes" -ForegroundColor Yellow
  }
}
Write-Host "[PASS] All $($index.total_artifacts) artifacts have stdout/stderr files" -ForegroundColor Green

# Check 3: Test counts sum correctly
$sum = 0
foreach ($a in $index.artifacts) {
  if ($a.test_counts -and $a.test_counts.total) {
    $sum += $a.test_counts.total
  }
}
if ($sum -eq $ExpectedTests) {
  Write-Host "[PASS] Test sum: $sum = expected $ExpectedTests" -ForegroundColor Green
} else {
  $issues += "TEST_SUM_MISMATCH: $sum vs $ExpectedTests"
  Write-Host "[FAIL] Test sum: $sum != expected $ExpectedTests" -ForegroundColor Red
}

# Check 4: All artifacts have exit_code=0
$nonZero = $index.artifacts | Where-Object { $_.exit_code -ne 0 }
if ($nonZero.Count -eq 0) {
  Write-Host "[PASS] All artifacts exit_code=0" -ForegroundColor Green
} else {
  foreach ($nz in $nonZero) {
    $issues += "NONZERO_EXIT: $($nz.artifact_id) exit=$($nz.exit_code)"
    Write-Host "[FAIL] $($nz.artifact_id): exit_code=$($nz.exit_code)" -ForegroundColor Red
  }
}

# Check 5: Traceability matrix covers all test artifacts
$coveredIds = @{}
foreach ($kv in $index.traceability_matrix.PSObject.Properties) {
  foreach ($id in $kv.Value) { $coveredIds[$id] = $true }
}
foreach ($a in $index.artifacts) {
  if (-not $coveredIds[$a.artifact_id]) {
    $issues += "NOT_IN_TRACEABILITY: $($a.artifact_id)"
    Write-Host "[WARN] $($a.artifact_id): not in traceability matrix" -ForegroundColor Yellow
  }
}
Write-Host "[PASS] Traceability matrix covers artifacts" -ForegroundColor Green

# Check 6: No fake PASS - test counts must match claim
foreach ($a in $index.artifacts) {
  if ($a.test_counts -and $a.test_counts.total) {
    $claim = "$($a.project_name): $($a.test_counts.passed)/$($a.test_counts.total) PASS"
    if (-not $index.traceability_matrix.PSObject.Properties[$claim]) {
      $issues += "TRACEABILITY_MISMATCH: $claim not in matrix"
      Write-Host "[WARN] Claim '$claim' not found in traceability matrix" -ForegroundColor Yellow
    }
  }
}

# Check 7: Directory snapshot present
if ($index.directory_snapshot -and $index.directory_snapshot.hash) {
  Write-Host "[PASS] Directory snapshot: $($index.directory_snapshot.hash.Substring(0,16))... ($($index.directory_snapshot.files_count) files)" -ForegroundColor Green
} else {
  $issues += "NO_DIRECTORY_SNAPSHOT"
  Write-Host "[FAIL] No directory snapshot" -ForegroundColor Red
}

# Final
Write-Host ""
if ($issues.Count -eq 0) {
  Write-Host "VERIFIER VERDICT: ALL CHECKS PASS" -ForegroundColor Green
  Write-Host "No issues found. Artifact store is trustworthy." -ForegroundColor Green
} else {
  Write-Host "VERIFIER VERDICT: $($issues.Count) ISSUES FOUND" -ForegroundColor Red
  $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

@{
  store = $StoreIndexPath
  artifacts_count = $index.total_artifacts
  tests_sum = $sum
  expected_tests = $ExpectedTests
  issues = $issues
  verdict = if ($issues.Count -eq 0) { "PASS" } else { "ISSUES_FOUND" }
}

