# Compression Summary Verifier v1.0.0
# Verifies that compression summaries are consistent with trusted state
param(
    [Parameter(Mandatory=$true)][string]$SummaryJson,
    [string]$StatePath = "C:\Codex_App_Factory\outputs\trusted-project-state.json"
)

try {
    $summary = $SummaryJson | ConvertFrom-Json
    $state = if (Test-Path $StatePath) { Get-Content $StatePath -Raw | ConvertFrom-Json } else { $null }
    
    $result = [PSCustomObject]@{
        summary_id = "COMP-$(Get-Date -Format 'yyyyMMddHHmmss')"
        verified = $false
        checks = @()
        conflicts = @()
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    
    if (-not $state) {
        $result.verified = $false
        $result.conflicts += "No trusted state exists for comparison"
        $result | ConvertTo-Json -Depth 3; return
    }
    
    # Verify frozen pipelines
    if ($summary.frozen_pipelines) {
        foreach ($fp in $summary.frozen_pipelines) {
            $match = $state.frozen_pipelines | Where-Object { $_.pipeline -eq $fp.pipeline }
            if ($match -and $match.status -ne $fp.status) {
                $result.conflicts += "Pipeline $($fp.pipeline): summary=$($fp.status) vs trusted=$($match.status)"
            }
        }
    }
    
    # Verify deprecated directions
    if ($summary.deprecated_directions) {
        foreach ($dd in $summary.deprecated_directions) {
            $match = $state.deprecated_directions | Where-Object { $_.direction -eq $dd.direction }
            if ($match -and $match.status -ne $dd.status) {
                $result.conflicts += "Deprecated $($dd.direction): summary=$($dd.status) vs trusted=$($match.status)"
            }
        }
    }
    
    # Verify engine status
    if ($summary.engine_status) {
        foreach ($es in $summary.engine_status) {
            $match = $state.engine_status | Where-Object { $_.engine_id -eq $es.engine_id }
            if ($match -and $match.status -ne $es.status) {
                $result.conflicts += "Engine $($es.engine_id): summary=$($es.status) vs trusted=$($match.status)"
            }
        }
    }
    
    # Verify regression baseline
    if ($summary.regression -and $state.regression_baseline) {
        if ($summary.regression.passing -ne $state.regression_baseline.passing) {
            $result.conflicts += "Regression: summary=$($summary.regression.passing) vs trusted=$($state.regression_baseline.passing)"
        }
    }
    
    $result.verified = ($result.conflicts.Count -eq 0)
    $result.checks += if ($result.verified) { "ALL_CONSISTENT" } else { "CONFLICTS_DETECTED" }
    
    if (-not $result.verified) {
        $result.resolution = "NEEDS_RECONCILIATION"
    }
    
    $result | ConvertTo-Json -Depth 3
} catch {
    [PSCustomObject]@{verified=$false; error="Parse error: $_"} | ConvertTo-Json
}
