# External Engine Broker v1.1.0
# Part of: FACTORY-R3.0 / R4.0
# Orchestrates external engine runs. TargetUrl is now configurable.

. (Join-Path $PSScriptRoot "external-engine-registry.ps1")
. (Join-Path $PSScriptRoot "external-tool-availability-check.ps1")
$parserDir = Join-Path $PSScriptRoot "parsers"
if (Test-Path $parserDir) { Get-ChildItem $parserDir -Filter "parse-*.ps1" | ForEach-Object { . $_.FullName } }

function Invoke-ExternalEngineBroker {
    param(
        [Parameter(Mandatory=$true)]$RiskProfile,
        [string]$ProjectType = "",
        [string[]]$Surfaces = @(),
        [string]$ProjectPath = ".",
        [string]$TargetUrl = "http://localhost:3000",
        [int]$DefaultTimeout = 120,
        [switch]$DryRun,
        [switch]$ShowOutput
    )

    $plan = New-ExternalEnginePlan -RiskProfile $RiskProfile -ProjectType $ProjectType -Surfaces $Surfaces

    if ($ShowOutput) {
        Write-Host "`n===== ENGINE PLAN =====" -F Cyan
        Write-Host "Plan: $($plan.plan_id) | Risk: $($plan.risk_level)"
        Write-Host "Engines planned: $($plan.planned_engines.Count)"
        foreach ($e in $plan.planned_engines) { Write-Host "  - $($e.engine_id): $($e.trigger_reason)" -F DarkGray }
    }

    $engineIds = $plan.planned_engines | ForEach-Object { $_.engine_id }
    $availability = Invoke-ToolAvailabilityCheck -EngineIds $engineIds
    $availMap = @{}
    $availability | ForEach-Object { $availMap[$_.engine_id] = $_ }

    if ($ShowOutput) { Format-ToolAvailabilityReport -Results $availability }

    $runResults = @()
    foreach ($plannedEngine in $plan.planned_engines) {
        $engineId = $plannedEngine.engine_id
        $avail = $availMap[$engineId]

        $runResult = [PSCustomObject]@{
            run_id = "EER-$(Get-Date -Format 'yyyyMMddHHmmss')-$engineId"
            engine_id = $engineId
            status = "SKIPPED"
            timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
            command_executed = ""
            execution_time_ms = 0
            findings_count = 0
            findings_by_severity = @{ ERROR = 0; WARNING = 0; INFO = 0 }
            findings = @()
            raw_output_summary = ""
            threshold_results = $null
            evidence_binding = @{ evidence_type = ""; evidence_summary = ""; evidence_files = @() }
            skip_reason = ""
            error_message = ""
        }

        if (-not $avail -or -not $avail.available) {
            $runResult.status = "TOOL_UNAVAILABLE"
            $runResult.skip_reason = if ($avail) { $avail.skip_reason } else { "Engine not registered" }
            $runResult.raw_output_summary = "SKIPPED: $engineId not available"
            if ($ShowOutput) { Write-Host "  [SKIP] $engineId" -F Yellow }
            $runResults += $runResult
            continue
        }

        if ($DryRun) {
            $runResult.status = "SKIPPED"
            $runResult.skip_reason = "Dry run mode"
            $runResult.raw_output_summary = "DRY_RUN: Would execute $engineId"
            $runResults += $runResult
            continue
        }

        $cmdTemplate = $plannedEngine.command_template
        $timeout = if ($plannedEngine.timeout) { $plannedEngine.timeout } else { $DefaultTimeout }
        $cmd = $cmdTemplate.Replace("{target_path}", $ProjectPath)
        $cmd = $cmd.Replace("{target_url}", $TargetUrl)
        $cmd = $cmd.Replace("{script_path}", (Join-Path $ProjectPath "load-test.js"))
        $cmd = $cmd.Replace("{test_path}", $ProjectPath)
        $cmd = $cmd.Replace("{output_path}", (Join-Path $env:TEMP "engine-output-$engineId.json"))
        $runResult.command_executed = $cmd

        try {
            $startTime = Get-Date
            if ($ShowOutput) { Write-Host "  [RUN] $engineId" -F Cyan }

            $job = Start-Job -ScriptBlock {
                param($c, $d); Set-Location $d; Invoke-Expression $c 2>&1 | Out-String
            } -ArgumentList $cmd, $ProjectPath

            $completed = Wait-Job $job -Timeout $timeout
            if (-not $completed) {
                Stop-Job $job
                $runResult.status = "TIMEOUT"
                $runResult.skip_reason = "Execution timed out after ${timeout}s"
                $runResult.raw_output_summary = "TIMEOUT"
            } else {
                $rawOutput = Receive-Job $job
                $runResult.execution_time_ms = [math]::Round(((Get-Date) - $startTime).TotalMilliseconds, 0)
                $parserName = $plannedEngine.output_parser
                if ($parserName -and (Get-Command $parserName -ErrorAction SilentlyContinue)) {
                    $parsed = & $parserName -RawOutput $rawOutput -EngineId $engineId
                    $runResult.status = $parsed.status
                    $runResult.findings_count = $parsed.findings_count
                    $runResult.findings_by_severity = $parsed.findings_by_severity
                    $runResult.findings = $parsed.findings
                    $runResult.raw_output_summary = $parsed.raw_output_summary
                    if ($parsed.threshold_results) { $runResult.threshold_results = $parsed.threshold_results }
                    $runResult.evidence_binding = $parsed.evidence_binding
                } else {
                    $runResult.status = "CLEAN"
                    $runResult.raw_output_summary = "Ran without parser"
                    $runResult.evidence_binding.evidence_summary = $runResult.raw_output_summary
                }
                if ($ShowOutput) { Write-Host "    $($runResult.status): $($runResult.raw_output_summary)" }
            }
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        } catch {
            $runResult.status = "TOOL_FAILED"
            $runResult.error_message = $_.Exception.Message
            $runResult.raw_output_summary = "FAILED: $engineId"
            if ($ShowOutput) { Write-Host "  [FAIL] $engineId" -F Red }
        }
        $runResults += $runResult
    }

    $ranCount = ($runResults | Where-Object { $_.status -notin @("SKIPPED","TOOL_UNAVAILABLE") }).Count
    $cleanCount = ($runResults | Where-Object { $_.status -eq "CLEAN" }).Count
    $findingsCount = ($runResults | Where-Object { $_.status -eq "FINDINGS_PRESENT" }).Count
    $skippedCount = ($runResults | Where-Object { $_.status -in @("SKIPPED","TOOL_UNAVAILABLE") }).Count

    [PSCustomObject]@{
        plan = $plan
        availability = $availability
        run_results = @($runResults)
        summary = [PSCustomObject]@{ total_planned = $plan.planned_engines.Count; ran = $ranCount; clean = $cleanCount; findings = $findingsCount; skipped = $skippedCount; dry_run = $DryRun.IsPresent }
        generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    }
}

function Format-EngineBrokerReport { param($BrokerResult)
    Write-Host "`n===== ENGINE BROKER REPORT =====" -F Cyan
    Write-Host "Ran: $($BrokerResult.summary.ran) | Clean: $($BrokerResult.summary.clean) | Findings: $($BrokerResult.summary.findings) | Skipped: $($BrokerResult.summary.skipped)"
    foreach ($r in $BrokerResult.run_results) { Write-Host "  $($r.engine_id): $($r.status) — $($r.raw_output_summary)" }
}
