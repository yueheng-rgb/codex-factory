# Resume Gate v1.0.0
# Validates that a resumed session has consistent context with trusted state
param(
    [string]$ResumeContextJson = "{}",
    [string]$StatePath = "C:\Codex_App_Factory\outputs\trusted-project-state.json"
)

try {
    $ctx = $ResumeContextJson | ConvertFrom-Json
    $state = if (Test-Path $StatePath) { Get-Content $StatePath -Raw | ConvertFrom-Json } else { $null }
    
    $result = [PSCustomObject]@{
        resume_id = "RESUME-$(Get-Date -Format 'yyyyMMddHHmmss')"
        allowed = $false
        checks = @()
        quarantine_items = @()
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    
    if (-not $state) {
        $result.checks += "No trusted state — resume blocked until state initialized"
        $result | ConvertToJson -Depth 3; return
    }
    
    # Check 1: Phase consistency
    if ($ctx.phase -and $ctx.phase -ne $state.phase) {
        $result.checks += "Phase mismatch: context=$($ctx.phase) vs trusted=$($state.phase)"
    } else {
        $result.checks += "Phase consistent: $($state.phase)"
    }
    
    # Check 2: Deprecated direction scan in context
    $deprecatedText = ($ctx.summary_text ?? "") + ($ctx.handoff_text ?? "") + ($ctx.plan_text ?? "")
    foreach ($dd in $state.deprecated_directions) {
        if ($deprecatedText -match $dd.direction) {
            $result.quarantine_items += "Deprecated direction: $($dd.direction)"
        }
    }
    
    # Check 3: Stale reference scan
    if ($ctx.previous_benchmark -and $ctx.previous_benchmark -ne $state.regression_baseline.passing) {
        $result.quarantine_items += "Stale benchmark: claimed=$($ctx.previous_benchmark), current=$($state.regression_baseline.passing)"
    }
    
    # Decision
    if ($result.quarantine_items.Count -gt 0) {
        $result.allowed = $false
        $result.reason = "QUARANTINED — $($result.quarantine_items.Count) items need reconciliation"
        $result.action = "Review quarantined items before resuming"
    } else {
        $result.allowed = $true
        $result.reason = "Context consistent with trusted state"
    }
    
    $result | ConvertTo-Json -Depth 3
} catch {
    [PSCustomObject]@{allowed=$false; error="Gate error: $_"} | ConvertTo-Json
}
