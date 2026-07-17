# R2.14 Products API Gate Detection
Push-Location C:\Codex_App_Factory
. .\runtime\runtime-risk-classifier.ps1
. .\runtime\automated-gate-detector.ps1
. .\runtime\gate-evidence-binder.ps1

$testbedPath = "C:\Codex_App_Factory\testbeds\products-api"

Write-Host "===== PRODUCTS API GATE DETECTION =====" -F Cyan
Write-Host "Project: $testbedPath" -F DarkGray

# Classify risk with a representative task
$taskDesc = "Products API CRUD testbed with price validation, status transitions, inventory tracking, archive protection"
$profile = Invoke-RuntimeRiskClassifier -TaskDescription $taskDesc -ProjectType "api-service"

Write-Host "`nRisk Profile:" -F Yellow
Write-Host "  Level: $($profile.riskLevel)"
Write-Host "  Score: $($profile.riskScore)"
Write-Host "  Reasons: $($profile.riskReasons -join '; ')"
Write-Host "  Critical Fields: $($profile.criticalFields -join ', ')"
Write-Host "  Required Reviewers: $($profile.requiredReviewers -join ', ')"
Write-Host "  Required Tests: $($profile.requiredTests -join ', ')"
Write-Host "  Human Audit: $($profile.humanAuditRequired)"
Write-Host "  Invariants Suggested: $($profile.invariantsSuggested -join ', ')"

# Run automated gate detection
Write-Host "`n--- Automated Gate Detection ---" -F Yellow
$detection = Invoke-AutomatedGateDetector -RiskProfile $profile -ProjectPath $testbedPath -AdditionalSearchPaths @($testbedPath)

# Create evidence binding
$binding = New-GateEvidenceBinding -DetectionResult $detection

Write-Host "`n=== GATE DETECTION RESULT ===" -F Green
Write-Host "Decision: $($binding.finalDecision)" -F $(if ($binding.finalDecision -eq "BLOCKED"){"Red"}else{"Green"})
Write-Host ""

foreach ($g in $binding.gates) {
    $icon = switch ($g.status) {
        "SATISFIED" { "PASS" }
        "MISSING" { "FAIL" }
        "PARTIAL" { "WARN" }
        "NOT_APPLICABLE" { "N/A" }
    }
    Write-Host "  [$icon] $($g.gateName): $($g.status)"
    Write-Host "    Evidence: $($g.evidenceSummary)"
    if ($g.evidenceFiles.Count -gt 0) {
        Write-Host "    Files: $($g.evidenceFiles[0])" -F DarkGray
    }
    if ($g.blockingReason) {
        Write-Host "    BLOCKER: $($g.blockingReason)" -F Red
    }
}

Write-Host "`n=== SUMMARY ===" -F Green
Write-Host "  Risk: $($binding.riskLevel)"
Write-Host "  Decision: $($binding.finalDecision)"
Write-Host "  SATISFIED: $($binding.satisfiedCount)"
Write-Host "  MISSING: $($binding.missingCount)"
Write-Host "  PARTIAL: $($binding.partialCount)"

# Export to JSON
$result = @{
    detection_id = "GATEDET-20260711-PRODUCTS-API"
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    risk_profile = @{
        risk_level = $profile.riskLevel
        risk_score = $profile.riskScore
        risk_reasons = @($profile.riskReasons)
        critical_fields = @($profile.criticalFields)
        required_reviewers = @($profile.requiredReviewers)
        required_tests = @($profile.requiredTests)
        human_audit_required = $profile.humanAuditRequired
        invariants_suggested = @($profile.invariantsSuggested)
    }
    detected_invariants = @($detection.gates | Where-Object { $_.gateName -eq "invariant_spec_present" } | ForEach-Object { $_.evidenceSummary })
    detected_tests = @($detection.gates | Where-Object { $_.gateName -eq "tests_present" } | ForEach-Object { $_.evidenceSummary })
    missing_gates = @($binding.gates | Where-Object { $_.status -eq "MISSING" } | ForEach-Object { $_.gateName })
    final_gate_decision = $binding.finalDecision
    gates = @($binding.gates | ForEach-Object { @{gate=$_.gateName; status=$_.status; evidence=$_.evidenceSummary} })
}
$resultJson = $result | ConvertTo-Json -Depth 4
$outPath = "C:\Codex_App_Factory\outputs\R2_14_PRODUCTS_API_GATE_DETECTION.json"
$resultJson | Set-Content -Path $outPath -Encoding UTF8
Write-Host "`nExported to: $outPath"

Pop-Location
