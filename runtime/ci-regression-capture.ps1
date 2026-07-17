
# Codex Factory v2.1 - Full Regression Artifact Capture
param(
  [Parameter(Mandatory=$false)]
  [string]$RunId = ("RUN-V2_1-" + (Get-Date -Format "yyyyMMdd-HHmmss")),
  [Parameter(Mandatory=$false)]
  [string]$FactoryRoot = "C:\Codex_App_Factory"
)

. "$PSScriptRoot\ci-artifact-store.ps1"
Initialize-CIArtifactStore -RunIdParam $RunId -StoreRoot "$FactoryRoot\artifacts"

Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Codex Factory v2.1 - CI Artifact Capture" -ForegroundColor Cyan
Write-Host "Run ID: $RunId" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host ""

$artifacts = @()

$testbeds = @(
  @{Name="products-api"; Path="$FactoryRoot\testbeds\products-api"; Type="testbed"; Tags=@("regression","testbed","products-api")},
  @{Name="mini-inventory-admin"; Path="$FactoryRoot\pilots\mini-inventory-admin"; Type="pilot"; Tags=@("regression","pilot","inventory")},
  @{Name="ecommerce-runtime-validation"; Path="$FactoryRoot\testbeds\ecommerce-runtime-validation"; Type="testbed"; Tags=@("regression","testbed","ecommerce")},
  @{Name="saas-runtime-validation"; Path="$FactoryRoot\testbeds\saas-runtime-validation"; Type="testbed"; Tags=@("regression","testbed","saas")},
  @{Name="admin-system-runtime-validation"; Path="$FactoryRoot\testbeds\admin-system-runtime-validation"; Type="testbed"; Tags=@("regression","testbed","admin")},
  @{Name="node-api-postgres"; Path="$FactoryRoot\runnable-starters\node-api-postgres"; Type="starter"; Tags=@("regression","starter","api")},
  @{Name="inventory-subscription-admin"; Path="$FactoryRoot\missions\inventory-subscription-admin"; Type="mission"; Tags=@("regression","mission","v2.0-rc")}
)

Write-Host "=== PHASE 1: REGRESSION TEST CAPTURE (7 projects) ===" -ForegroundColor Yellow
foreach ($tb in $testbeds) {
  if (Test-Path (Join-Path $tb.Path "package.json")) {
    $a = Invoke-CICommand -Command "npm test" -WorkingDirectory $tb.Path -ProjectName $tb.Name -ProjectType $tb.Type -Tags $tb.Tags -TimeoutMs 60000
    if ($a) { $artifacts += $a }
  } else {
    Write-Host "[CI-SKIP] $($tb.Name): no package.json" -ForegroundColor DarkYellow
  }
}

Write-Host "`n=== PHASE 2: BUILD CHECK ===" -ForegroundColor Yellow
$threejsPath = "$FactoryRoot\runnable-starters\vite-threejs-interactive"
if (Test-Path (Join-Path $threejsPath "package.json")) {
  $a = Invoke-CICommand -Command "npm run build" -WorkingDirectory $threejsPath -ProjectName "vite-threejs-interactive" -ProjectType "starter" -Tags @("build","starter","threejs") -TimeoutMs 60000
  if ($a) { $artifacts += $a }
}

Write-Host "`n=== PHASE 3: ENGINE CHECK CAPTURE ===" -ForegroundColor Yellow
if (Get-Command semgrep -ErrorAction SilentlyContinue) {
  $a = Invoke-CICommand -Command "semgrep --config=auto --json -q src" -WorkingDirectory "$FactoryRoot\testbeds\products-api" -ProjectName "semgrep-products-api" -ProjectType "engine" -Tags @("engine","semgrep","security") -TimeoutMs 120000
  if ($a) { $artifacts += $a }
  $a = Invoke-CICommand -Command "semgrep --config=auto --json -q src" -WorkingDirectory "$FactoryRoot\missions\inventory-subscription-admin" -ProjectName "semgrep-mission" -ProjectType "engine" -Tags @("engine","semgrep","security") -TimeoutMs 120000
  if ($a) { $artifacts += $a }
} else {
  Write-Host "[CI-SKIP] semgrep: TOOL_UNAVAILABLE - documented" -ForegroundColor DarkYellow
}

Write-Host "`n=== PHASE 4: DIRECTORY SNAPSHOT ===" -ForegroundColor Yellow
$snapshot = Get-DirectorySnapshot -Path $FactoryRoot
Write-Host "[CI-SNAPSHOT] $($snapshot.files_count) files, hash: $($snapshot.hash.Substring(0,16))..." -ForegroundColor Green

Write-Host "`n=== PHASE 5: BUILD ARTIFACT STORE INDEX ===" -ForegroundColor Yellow
$index = Export-CIArtifactStoreIndex -Artifacts $artifacts -FactoryRoot $FactoryRoot -RunDescription "v2.1 full regression + engine capture"

Write-Host "`n=== PHASE 6: AUDIT LEDGER BINDING ===" -ForegroundColor Yellow
$ledgerEntry = @{
  timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"); event = "V2_1_CI_ARTIFACT_CAPTURE"
  run_id = $RunId; total_artifacts = $index.total_artifacts
  passed = $index.passed; failed = $index.failed; skipped = $index.skipped
  total_tests = $index.total_tests; total_passed = $index.total_tests_passed
  artifact_store_index = "artifacts/$RunId/artifact-store-index.json"
  directory_snapshot_hash = $index.directory_snapshot.hash
} | ConvertTo-Json -Compress
$ledgerEntry | Out-File -FilePath "$FactoryRoot\outputs\audit-ledger.json" -Append -Encoding utf8
Write-Host "[CI-LEDGER] Audit ledger entry appended." -ForegroundColor Green

Write-Host ""
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "CI ARTIFACT CAPTURE COMPLETE" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Cyan
Write-Host "Run ID:       $RunId"
Write-Host "Artifacts:    $($index.total_artifacts)"
Write-Host "Pass/Fail/Skip: $($index.passed)/$($index.failed)/$($index.skipped)"
Write-Host "Tests:        $($index.total_tests_passed)/$($index.total_tests) PASS"
Write-Host "Snapshot:     $($index.directory_snapshot.hash.Substring(0,16))... ($($index.directory_snapshot.files_count) files)"
Write-Host "Store Index:  artifacts/$RunId/artifact-store-index.json"
Write-Host ""
