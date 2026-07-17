# k6 Parser v1.0.0
# Parses k6 JSON summary output into structured engine evidence
param(
    [string]$JsonPath,
    [string]$TargetProject = "unknown"
)

function Invoke-K6Parse {
    param([string]$Path)
    
    if (-not $Path -or -not (Test-Path $Path)) {
        return [PSCustomObject]@{ parser_status = "NO_INPUT"; error = "k6 JSON output not found: $Path" }
    }
    
    try {
        $data = Get-Content $Path -Raw | ConvertFrom-Json
        $metrics = $data.metrics
        
        $result = [PSCustomObject]@{
            parser_status = "OK"
            target_project = $TargetProject
            duration_seconds = if ($metrics.http_req_duration) { $metrics.http_req_duration.values.avg } else { "N/A" }
            requests_total = if ($metrics.http_reqs) { $metrics.http_reqs.values.count } else { 0 }
            failed_rate = if ($metrics.http_req_failed) { $metrics.http_req_failed.values.rate } else { 0 }
            p95_latency_ms = if ($metrics.http_req_duration) { $metrics.http_req_duration.values.'p(95)' } else { "N/A" }
            checks_passed = if ($data.root_group) { ($data.root_group.checks | Where-Object { $_.passes -gt 0 }).Count } else { 0 }
            thresholds = if ($data.metrics) { ($data.metrics.PSObject.Properties | Where-Object { $_.Name -like "*threshold*" }).Count } else { 0 }
        }
        return $result
    } catch {
        return [PSCustomObject]@{ parser_status = "PARSE_ERROR"; error = $_.Exception.Message }
    }
}

$result = Invoke-K6Parse -Path $JsonPath
$result | ConvertTo-Json -Depth 3
