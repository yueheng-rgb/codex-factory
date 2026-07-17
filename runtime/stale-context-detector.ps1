# Stale Context Detector v1.0.0
param(
    [Parameter(Mandatory=$true)][string]$ContextText,
    [string]$StatePath = "C:\Codex_App_Factory\outputs\trusted-project-state.json"
)

try {
    $state = if (Test-Path $StatePath) { Get-Content $StatePath -Raw | ConvertFrom-Json } else { $null }
    
    $staleHits = @()
    
    if ($state) {
        foreach ($dd in $state.deprecated_directions) {
            if ($ContextText -match [regex]::Escape($dd.direction)) {
                $staleHits += [PSCustomObject]@{type="DEPRECATED_DIRECTION"; reference=$dd.direction; status=$dd.status; severity="CRITICAL"}
            }
        }
    }
    
    if ($ContextText -match "old.*benchmark|stale.*benchmark|previous.*benchmark") {
        $staleHits += [PSCustomObject]@{type="STALE_BENCHMARK"; reference="Old benchmark reference"; status="STALE"; severity="HIGH"}
    }
    
    $regMatch = [regex]::Match($ContextText, '(\d+)/(\d+)\s*(?:tests\s*)?PASS')
    if ($regMatch.Success -and $state -and $state.regression_baseline) {
        $claimedPassing = [int]$regMatch.Groups[1].Value
        if ($claimedPassing -ne $state.regression_baseline.passing) {
            $staleHits += [PSCustomObject]@{type="STALE_METRIC"; reference="Regression: claimed=$claimedPassing, current=$($state.regression_baseline.passing)"; severity="HIGH"}
        }
    }
    
    $result = [PSCustomObject]@{
        detection_id = "STALE-$(Get-Date -Format 'yyyyMMddHHmmss')"
        stale_hits = $staleHits
        hit_count = $staleHits.Count
        context_trustworthy = ($staleHits.Count -eq 0)
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    
    $result | ConvertTo-Json -Depth 4
} catch {
    [PSCustomObject]@{error="Detection error: $_"} | ConvertTo-Json
}
