# Load Test Result Parser v1.0.0
# Part of: FACTORY-R3.0
# Parses k6 and autocannon JSON output into standardized performance metrics.

function Parse-LoadTestResult {
    param(
        [Parameter(Mandatory=$true)][string]$RawOutput,
        [string]$EngineId = "k6"
    )

    $result = @{
        engine_id = $EngineId
        status = "CLEAN"
        findings_count = 0
        findings_by_severity = @{ ERROR = 0; WARNING = 0; INFO = 0 }
        findings = @()
        raw_output_summary = ""
        threshold_results = @{
            requests = 0
            error_rate = 0.0
            p95_ms = 0.0
            threshold_passed = $true
        }
        evidence_binding = @{
            evidence_type = "performance_metrics"
            evidence_summary = ""
            evidence_files = @()
        }
    }

    if (-not $RawOutput -or $RawOutput.Trim().Length -eq 0) {
        $result.status = "TOOL_FAILED"
        $result.raw_output_summary = "Empty output"
        return [PSCustomObject]$result
    }

    try {
        $data = $RawOutput | ConvertFrom-Json

        # k6 summary format
        if ($data.metrics) {
            $result.threshold_results.requests = if ($data.metrics.http_reqs) { $data.metrics.http_reqs.count } else { 0 }
            $result.threshold_results.error_rate = if ($data.metrics.http_req_failed) {
                [math]::Round($data.metrics.http_req_failed.rate * 100, 2)
            } else { 0.0 }
            $result.threshold_results.p95_ms = if ($data.metrics.http_req_duration) {
                [math]::Round($data.metrics.http_req_duration."p(95)", 2)
            } else { 0.0 }

            if ($result.threshold_results.error_rate -gt 5.0) {
                $result.threshold_results.threshold_passed = $false
                $result.status = "FINDINGS_PRESENT"
                $result.findings_count = 1
            }
        }
        # autocannon format
        elseif ($data.requests) {
            $result.threshold_results.requests = $data.requests.total
            $result.threshold_results.error_rate = if ($data.errors -gt 0) {
                [math]::Round(($data.errors / $data.requests.total) * 100, 2)
            } else { 0.0 }
            $result.threshold_results.p95_ms = if ($data.latency.p99) { $data.latency.p99 } else { 0.0 }

            if ($result.threshold_results.error_rate -gt 5.0) {
                $result.threshold_results.threshold_passed = $false
                $result.status = "FINDINGS_PRESENT"
                $result.findings_count = 1
            }
        } else {
            $result.status = "CLEAN"
        }

        $result.raw_output_summary = "$EngineId load test: $($result.threshold_results.requests) requests, $($result.threshold_results.error_rate)% errors, p95=$($result.threshold_results.p95_ms)ms"
        $result.evidence_binding.evidence_summary = $result.raw_output_summary
    } catch {
        $result.raw_output_summary = ($RawOutput -split "`n" | Select-Object -First 5) -join "; "
        $result.status = "FINDINGS_PRESENT"
    }

    return [PSCustomObject]$result
}
