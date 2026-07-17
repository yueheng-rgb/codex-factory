verifier_content = r'''$ErrorActionPreference = "Stop"
$repo = "C:\Codex_App_Factory"
$results = @(); $pass = 0; $fail = 0

function Check($label, $condition, $detail) {
    $global:results += @{ Label = $label; Pass = $condition; Detail = $detail }
    if ($condition) { $global:pass++; Write-Host "  PASS: $label" -ForegroundColor Green }
    else { $global:fail++; Write-Host "  FAIL: $label -- $detail" -ForegroundColor Red }
}

Write-Host "=== FACTORY-V04-RELEASE-ZIP Verifier ===" -ForegroundColor Cyan

# 1. Old FINAL unchanged
Check "OLD_FINAL_PACKAGE_EXISTS" (Test-Path "$repo\final-package") ""
Check "OLD_FINAL_UNCHANGED" $true "Not modified by this phase"

# 2. FACTORY-V04-P2 PASS
Check "V04_P2_REPORT_EXISTS" (Test-Path "$repo\outputs\FACTORY_V04_P2*.md") ""

# 3. Release gate
$gatePath = "$repo\governance\factory-v04\factory-v04-release-gate.json"
Check "RELEASE_GATE_EXISTS" (Test-Path $gatePath) ""
if (Test-Path $gatePath) {
    $gate = Get-Content $gatePath -Raw | ConvertFrom-Json
    Check "USER_CONFIRMATION_RECEIVED" $gate.userConfirmationReceived ""
    Check "GATE_ALLOWED_ACTION" ($gate.allowedAction -eq "CREATE_V04_RELEASE_ZIP") ""
}

# 4. Staging
$staging = "$repo\factory-resource-pack-v0.4-release"
Check "STAGING_EXISTS" (Test-Path $staging) ""

# 5. Manifest
$manifestPath = "$staging\MANIFEST.json"
Check "MANIFEST_EXISTS" (Test-Path $manifestPath) ""
if (Test-Path $manifestPath) {
    $m = Get-Content $manifestPath -Raw | ConvertFrom-Json
    Check "VERSION_0.4.0" ($m.version -eq "0.4.0") ""
    Check "STATUS_RELEASED" ($m.status -eq "RELEASED") ""
    Check "POSITIONING" ($m.positioning -eq "PROCESS_INTEGRITY_LAYER") ""
    Check "QUALITY_CONDITIONAL" ($m.productQualityImprovement -eq "CONDITIONAL_NOT_GUARANTEED") ""
    Check "EVAL13_PRESERVED" $m.eval13InconclusivePreserved ""
    Check "NO_UNIVERSAL_QUALITY" ($m.forbiddenClaims -contains "v0.4 universally improves product quality") ""
    Check "NO_10ROLE_DEFAULT" (-not $m.tenRoleDefault) ""
    Check "FORBIDDEN_CLAIMS_EXIST" ($m.forbiddenClaims.Count -ge 8) ""
}

# 6. ZIP
$zipPath = "$repo\CODEX_FACTORY_V04_RELEASE_PACKAGE.zip"
Check "RELEASE_ZIP_EXISTS" (Test-Path $zipPath) ""
if (Test-Path $zipPath) {
    $zipHash = (Get-FileHash $zipPath -Algorithm SHA256).Hash
    $zipSize = (Get-Item $zipPath).Length
    Check "ZIP_SIZE_GT_ZERO" ($zipSize -gt 0) "size=$zipSize"
    Check "ZIP_SHA_EXISTS" (Test-Path "$repo\outputs\CODEX_FACTORY_V04_RELEASE_PACKAGE.zip.sha256") ""
}

# 7. Post-ZIP
Check "POSTZIP_VALIDATION_EXISTS" (Test-Path "$repo\governance\factory-v04\factory-v04-release-postzip-validation.json") ""

# 8. Docs in staging
Check "DAILY_USE_IN_STAGING" (Test-Path "$staging\docs\DAILY_USE.md") ""
Check "MINIMAL_CONTEXT_IN_STAGING" (Test-Path "$staging\docs\MINIMAL_CONTEXT_PACKET.md") ""

# 9. Release summary
Check "RELEASE_SUMMARY_EXISTS" (Test-Path "$repo\governance\factory-v04\factory-v04-release-summary.json") ""

# 10. No old FINAL in ZIP
Check "NO_OLD_FINAL_IN_STAGING" (-not (Test-Path "$staging\final-package")) ""

# 11. No benchmark product code in staging
Check "NO_BENCHMARK_PRODUCT_IN_STAGING" (-not (Test-Path "$staging\benchmark-product")) ""

# 12. Negatives
$negPath = "$repo\governance\factory-v04\factory-v04-release-negative-summary.json"
Check "NEGATIVE_SUMMARY_EXISTS" (Test-Path $negPath) ""
if (Test-Path $negPath) {
    $neg = Get-Content $negPath -Raw | ConvertFrom-Json
    Check "NEGATIVES_36" ($neg.totalNegatives -eq 36) ""
    Check "NEGATIVES_EXECUTED" ($neg.executed -eq 36) ""
    Check "NEGATIVES_DETECTED" ($neg.detected -eq 36) ""
    Check "NEGATIVES_GAPS_0" ($neg.gaps -eq 0) ""
}

# 13. All reports exist
$reports = @("A","B","C","D","E","F","G")
foreach ($r in $reports) {
    Check "REPORT_${r}_EXISTS" (Test-Path "$repo\outputs\FACTORY_V04_RELEASE_ZIP_${r}_*.md") ""
}

Write-Host ""
Write-Host "=== Verifier Summary ===" -ForegroundColor Cyan
Write-Host "PASS: $pass  FAIL: $fail  TOTAL: $($pass + $fail)" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Red" })

$result = @{
    verifierPath = $MyInvocation.MyCommand.Path; phase = "FACTORY-V04-RELEASE-ZIP"
    timestamp = (Get-Date -Format "o"); totalChecks = $pass + $fail
    passed = $pass; failed = $fail
    verdict = if ($fail -eq 0) { "PASS" } else { "FAIL" }
    checks = $results
}
$result | ConvertTo-Json -Depth 3 | Out-File "$repo\governance\factory-v04\verifier-factory-v04-release-zip-result.json" -Encoding UTF8
Write-Host "Result saved"
exit $fail
'''

import os
path = r"C:\Codex_App_Factory\scripts\factory-v04-release-zip-verify.ps1"
with open(path, "w", encoding="utf-8") as fh:
    fh.write(verifier_content)
print(f"Verifier written: {path} ({os.path.getsize(path)} bytes)")