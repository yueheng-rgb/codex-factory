# R3.1 Demo Cases Runner — Live Engine Activation & Calibration
Push-Location C:\Codex_App_Factory
. .\runtime\runtime-risk-classifier.ps1
. .\runtime\automated-gate-detector.ps1
. .\runtime\gate-evidence-binder.ps1
. .\runtime\external-engine-registry.ps1
. .\runtime\external-tool-availability-check.ps1
. .\runtime\external-engine-broker.ps1
. .\runtime\risk-enforcement-gate-v3.ps1

$testbedPath = "C:\Codex_App_Factory\testbeds\products-api"

Write-Host "===================================" -F Cyan
Write-Host "R3.1 DEMO 1: Tool Availability" -F Cyan
Write-Host "===================================" -F Cyan
$avail = Invoke-ToolAvailabilityCheck -ExportJson -OutputPath "C:\Codex_App_Factory\outputs\R3_1_TOOL_AVAILABILITY_AFTER.json"
Format-ToolAvailabilityReport -Results $avail
$availCount = ($avail | Where-Object { $_.available }).Count
Write-Host "`nEngines available: $availCount / $($avail.Count)" -F $(if($availCount -ge 2){"Green"}else{"Yellow"})

Write-Host "`n===================================" -F Cyan
Write-Host "R3.1 DEMO 2: Semgrep Real Run" -F Cyan
Write-Host "===================================" -F Cyan
$gateResult2 = Invoke-RiskEnforcementGateV3 `
    -TaskDescription "security scan on products-api codebase" `
    -ProjectPath $testbedPath `
    -AdditionalSearchPaths @($testbedPath) `
    -ProjectType "backend-api" `
    -Surfaces @("api-service") `
    -ShowOutput
Write-Host "Final: $($gateResult2.final_decision)"

Write-Host "`n===================================" -F Cyan
Write-Host "R3.1 DEMO 3: Autocannon Load Smoke" -F Cyan
Write-Host "===================================" -F Cyan
# Start server
$serverJob = Start-Job -ScriptBlock {
    Set-Location "C:\Codex_App_Factory\testbeds\products-api"
    node dist/server.js 2>&1 | Out-Null
}
Start-Sleep -Seconds 3
$gateResult3 = Invoke-RiskEnforcementGateV3 `
    -TaskDescription "verify API performance QPS throughput under load" `
    -ProjectPath $testbedPath `
    -AdditionalSearchPaths @($testbedPath) `
    -ProjectType "backend-api" `
    -Surfaces @("api-service") `
    -ShowOutput
Write-Host "Final: $($gateResult3.final_decision)"
Stop-Job $serverJob -ErrorAction SilentlyContinue
Remove-Job $serverJob -Force -ErrorAction SilentlyContinue
Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.Id -ne $PID } | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "`n===================================" -F Cyan
Write-Host "R3.1 DEMO 4: Playwright (SKIPPED)" -F Cyan
Write-Host "===================================" -F Cyan
$threejsPath = "C:\Codex_App_Factory\runnable-starters\vite-threejs-interactive"
$gateResult4 = Invoke-RiskEnforcementGateV3 `
    -TaskDescription "playwright e2e browser smoke test on threejs page component" `
    -ProjectPath $threejsPath `
    -AdditionalSearchPaths @($threejsPath) `
    -ProjectType "threejs-interactive" `
    -Surfaces @("threejs-interactive") `
    -ShowOutput
Write-Host "Final: $($gateResult4.final_decision)"

Write-Host "`n===================================" -F Cyan
Write-Host "R3.1 DEMO 5: Performance Calibration" -F Cyan
Write-Host "===================================" -F Cyan
Write-Host "--- Moderate performance claim ---"
$p1 = Invoke-RuntimeRiskClassifier -TaskDescription "API endpoint needs QPS 压测 performance verification under load"
Write-Host "Risk: $($p1.riskLevel) | Score: $($p1.riskScore) | Reviewers: $($p1.requiredReviewers -join ',')"

Write-Host "`n--- Extreme scale claim (100w users) ---"
$p2 = Invoke-RuntimeRiskClassifier -TaskDescription "API must support 100w users 百万并发 extreme scale high traffic"
Write-Host "Risk: $($p2.riskLevel) | Score: $($p2.riskScore) | Reviewers: $($p2.requiredReviewers -join ',')"
Write-Host "Tests: $($p2.requiredTests -join ',')"
Write-Host "Invariants: $($p2.invariantsSuggested -join ',')"

Write-Host "`n--- R3.0 Demo 5 case (was MEDIUM, now should be HIGH) ---"
$p3 = Invoke-RuntimeRiskClassifier -TaskDescription "验证 Products API endpoint 支持高并发 performance 和 load testing"
Write-Host "Risk: $($p3.riskLevel) | Score: $($p3.riskScore)"

Write-Host "`n===================================" -F Green
Write-Host "R3.1 ALL DEMOS COMPLETE" -F Green
Write-Host "===================================" -F Green
$calPass = ($p1.riskLevel -eq "HIGH") -and ($p2.riskLevel -eq "CRITICAL") -and ($p3.riskLevel -eq "HIGH")
Write-Host "Calibration: $(if($calPass){'PASS'}else{'FAIL'}) — p1=$($p1.riskLevel) p2=$($p2.riskLevel) p3=$($p3.riskLevel)"
Write-Host "Semgrep: $($gateResult2.final_decision)"
Write-Host "Autocannon: $($gateResult3.final_decision)"
Write-Host "Playwright: $($gateResult4.final_decision)"

Pop-Location
