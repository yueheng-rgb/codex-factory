# R4.0 Benchmark Suite v2 Runner
Push-Location C:\Codex_App_Factory
. .\runtime\runtime-risk-classifier.ps1
. .\runtime\automated-gate-detector.ps1
. .\runtime\gate-evidence-binder.ps1
. .\runtime\external-engine-registry.ps1
. .\runtime\external-tool-availability-check.ps1
. .\runtime\external-engine-broker.ps1
. .\runtime\risk-enforcement-gate-v3.ps1

$suite = Get-Content "outputs\R4_0_benchmark_suite_v2.json" -Raw | ConvertFrom-Json
$results = @()

foreach ($bm in $suite.benchmarks) {
    Write-Host "`n========================================" -F Cyan
    Write-Host "BENCHMARK: $($bm.benchmark_id)" -F Cyan
    Write-Host "$($bm.task_description)" -F DarkGray
    Write-Host "Expected: $($bm.expected_surfaces -join ', ') | Risk: $($bm.expected_risk_level) | $($bm.runnable_or_design_only)" -F DarkGray
    Write-Host "========================================" -F Cyan

    $row = [PSCustomObject]@{
        benchmark_id = $bm.benchmark_id
        runnable = $bm.runnable_or_design_only -eq "runnable"
        surfaces_expected = $bm.expected_surfaces -join ", "
        surfaces_detected = ""
        surface_plan_accuracy = ""
        risk_expected = $bm.expected_risk_level
        risk_detected = ""
        risk_accuracy = ""
        invariant_expected = ($bm.expected_invariants -join ", ")
        invariant_detected = ""
        invariant_accuracy = ""
        engine_plan_expected = ($bm.expected_engine_plan -join ", ")
        engine_plan_detected = ""
        engine_plan_accuracy = ""
        tests_result = ""
        semgrep_result = ""
        autocannon_result = ""
        playwright_result = ""
        final_verdict = ""
        failure_mode = ""
        confidence = 0.0
    }

    try {
        # Step 1: Risk Classification
        $profile = Invoke-RuntimeRiskClassifier -TaskDescription $bm.task_description -ProjectType "backend-api"
        $row.risk_detected = $profile.riskLevel
        $row.risk_accuracy = if ($profile.riskLevel -eq $bm.expected_risk_level) { "MATCH" } else { "MISMATCH ($($profile.riskLevel) vs $($bm.expected_risk_level))" }

        # Step 2: Surface detection (from task description)
        $surfaces = @()
        if ($bm.task_description -match '(?i)api|REST|endpoint|backend') { $surfaces += "api-service" }
        if ($bm.task_description -match '(?i)admin|dashboard|panel') { $surfaces += "admin-web" }
        if ($bm.task_description -match '(?i)database|store|data') { $surfaces += "database" }
        if ($bm.task_description -match '(?i)public|content|landing|website') { $surfaces += "public-web" }
        if ($bm.task_description -match '(?i)frontend|web.app|saas') { $surfaces += "frontend-web" }
        if ($bm.task_description -match '(?i)3d|threejs|interactive.scene|canvas') { $surfaces += "threejs-interactive" }
        if ($bm.task_description -match '(?i)miniapp|wechat|mini.program') { $surfaces += "miniapp" }
        if ($bm.task_description -match '(?i)mobile.app|mobile') { $surfaces += "mobile-app" }
        if ($bm.task_description -match '(?i)background|worker|cron|job|queue') { $surfaces += "background-worker" }
        if ($bm.task_description -match '(?i)doc|readme|release') { $surfaces += "docs-release" }
        if ($surfaces.Count -eq 0) { $surfaces = @("api-service") }
        $row.surfaces_detected = $surfaces -join ", "

        $expectedSet = @($bm.expected_surfaces | Sort-Object)
        $detectedSet = @($surfaces | Sort-Object)
        $matchCount = ($expectedSet | Where-Object { $_ -in $detectedSet }).Count
        $row.surface_plan_accuracy = [math]::Round(($matchCount / [Math]::Max($expectedSet.Count, 1)) * 100, 0)

        # Step 3: Invariant detection
        $row.invariant_detected = ($profile.invariantsSuggested -join ", ")
        $invExpected = @($bm.expected_invariants | Sort-Object)
        $invDetected = @($profile.invariantsSuggested | Sort-Object)
        $invMatch = ($invExpected | Where-Object { $_ -in $invDetected }).Count
        $row.invariant_accuracy = if ($invExpected.Count -eq 0) { "N/A" } else { [math]::Round(($invMatch / $invExpected.Count) * 100, 0) }

        # Step 4: For runnable benchmarks, run gate + engines
        if ($bm.runnable_or_design_only -eq "runnable") {
            $projPath = $bm.project_path
            if (Test-Path $projPath) {
                $gate = Invoke-RiskEnforcementGateV3 `
                    -TaskDescription $bm.task_description `
                    -ProjectPath $projPath `
                    -AdditionalSearchPaths @($projPath) `
                    -ProjectType "backend-api" `
                    -Surfaces $surfaces `
                    -ShowOutput:$false

                $row.tests_result = "$($gate.lightweight_gate_result.satisfiedCount) gates satisfied, decision: $($gate.lightweight_gate_result.finalDecision)"

                # Engine results
                $engineResults = @($gate.external_engine_results)
                $semgrepR = $engineResults | Where-Object { $_.engine_id -eq "semgrep" }
                $autoR = $engineResults | Where-Object { $_.engine_id -eq "autocannon" }
                $playR = $engineResults | Where-Object { $_.engine_id -eq "playwright" }
                $row.semgrep_result = if ($semgrepR) { "$($semgrepR.status)" } else { "NOT_PLANNED" }
                $row.autocannon_result = if ($autoR) { "$($autoR.status)" } else { "NOT_PLANNED" }
                $row.playwright_result = if ($playR) { "$($playR.status)" } else { "NOT_PLANNED" }

                # Engine plan accuracy
                $plannedEngines = if ($gate.external_engine_plan) { @($gate.external_engine_plan.planned_engines | ForEach-Object { $_.engine_id }) } else { @() }
                $row.engine_plan_detected = $plannedEngines -join ", "
                $expEngines = @($bm.expected_engine_plan)
                $engMatch = ($expEngines | Where-Object { $_ -in $plannedEngines }).Count
                $row.engine_plan_accuracy = if ($expEngines.Count -eq 0) { "N/A" } else { [math]::Round(($engMatch / $expEngines.Count) * 100, 0) }

                # Final verdict
                $row.final_verdict = if ($gate.final_decision -eq "BLOCKED") { "BLOCKED" }
                    elseif ($row.tests_result -match "ALLOWED") { "PASS" }
                    else { "PARTIAL" }
            } else {
                $row.tests_result = "PROJECT_NOT_FOUND: $projPath"
                $row.final_verdict = "BLOCKED"
                $row.failure_mode = "Project path not found"
            }
        } else {
            # Design-only benchmarks
            $row.tests_result = "DESIGN_ONLY"
            $row.semgrep_result = "DESIGN_ONLY"
            $row.autocannon_result = "DESIGN_ONLY"
            $row.playwright_result = "DESIGN_ONLY"
            $row.engine_plan_detected = "DESIGN_ONLY"
            $row.engine_plan_accuracy = "DESIGN_ONLY"

            # Evaluate design-level accuracy
            $designIssues = @()
            if ($row.risk_accuracy -notmatch "MATCH") { $designIssues += "Risk mismatch" }
            if ($row.surface_plan_accuracy -lt 50) { $designIssues += "Surface detection low ($($row.surface_plan_accuracy)%)" }
            if ($profile.riskLevel -eq "L_CLASS" -and $profile.humanAuditRequired -eq $false) { $designIssues += "Human audit not required for L_CLASS" }

            $row.final_verdict = if ($designIssues.Count -eq 0) { "PASS (DESIGN)" } else { "PARTIAL (DESIGN): $($designIssues -join '; ')" }
            $row.failure_mode = if ($designIssues.Count -gt 0) { $designIssues -join "; " } else { "" }
        }

        $row.confidence = if ($row.final_verdict -match "PASS") { 0.9 } elseif ($row.final_verdict -match "PARTIAL") { 0.5 } else { 0.2 }

    } catch {
        $row.final_verdict = "ERROR"
        $row.failure_mode = $_.Exception.Message
        $row.confidence = 0.0
    }

    Write-Host "Risk: $($row.risk_detected) ($($row.risk_accuracy))"
    Write-Host "Surfaces: $($row.surfaces_detected) ($($row.surface_plan_accuracy)%)"
    Write-Host "Invariants: $($row.invariant_accuracy)"
    Write-Host "Tests: $($row.tests_result)"
    Write-Host "Semgrep: $($row.semgrep_result) | Autocannon: $($row.autocannon_result) | Playwright: $($row.playwright_result)"
    Write-Host "Verdict: $($row.final_verdict)" -F $(if($row.final_verdict -match "PASS"){"Green"}else{"Yellow"})

    $results += $row
}

# Output capability matrix
Write-Host "`n==============================" -F Green
Write-Host "CAPABILITY MATRIX v2" -F Green
Write-Host "==============================" -F Green
$results | Format-Table benchmark_id, risk_expected, risk_detected, risk_accuracy, surface_plan_accuracy, invariant_accuracy, engine_plan_accuracy, final_verdict -AutoSize

# Metrics
$total = $results.Count
$runnable = ($results | Where-Object { $_.runnable }).Count
$designOnly = $total - $runnable
$passCount = ($results | Where-Object { $_.final_verdict -match "^PASS" }).Count
$partialCount = ($results | Where-Object { $_.final_verdict -match "^PARTIAL" }).Count
$failCount = ($results | Where-Object { $_.final_verdict -in @("BLOCKED","ERROR","FAIL") }).Count
$riskMatchCount = ($results | Where-Object { $_.risk_accuracy -eq "MATCH" }).Count

Write-Host "`n=== METRICS ===" -F Green
Write-Host "Total: $total | Runnable: $runnable | Design-only: $designOnly"
Write-Host "PASS: $passCount | PARTIAL: $partialCount | FAIL/BLOCKED: $failCount"
Write-Host "Risk accuracy: $riskMatchCount / $total"
Write-Host "`nTop failure modes:"
$results | Where-Object { $_.failure_mode } | ForEach-Object { Write-Host "  $($_.benchmark_id): $($_.failure_mode)" -F Yellow }

# Export matrix
$results | ConvertTo-Json -Depth 3 | Set-Content "outputs\R4_0_capability_matrix_v2.json" -Encoding UTF8
Write-Host "`nMatrix exported to outputs\R4_0_capability_matrix_v2.json"

Pop-Location
