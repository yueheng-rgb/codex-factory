# Memory Admission Gate v1.0.0
param(
    [Parameter(Mandatory=$true)][string]$ClaimJson,
    [string]$StatePath = "C:\Codex_App_Factory\outputs\trusted-project-state.json"
)

$DEPRECATED_PATTERNS = @(
    "Independent Search Agent","Dual Search Channel","Search Agent as Future Default",
    "Implementer direct search","chat URL extraction","mock/dry_run",
    "Firecrawl as canonical search","multi-agent default mode"
)

try {
    $claim = $ClaimJson | ConvertFrom-Json
    $state = if (Test-Path $StatePath) { Get-Content $StatePath -Raw | ConvertFrom-Json } else { $null }
    $summary = if ($claim.content_summary) { $claim.content_summary } else { "" }
    $claimText = if ($claim.claim_text) { $claim.claim_text } else { "" }
    
    $result = [PSCustomObject]@{
        claim_id = "CLAIM-$(Get-Date -Format 'yyyyMMddHHmmss')"
        admitted = $false
        checks = @()
        timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
    }
    
    $validSources = @("runtime_result","report","handoff","benchmark","engine_output","compression_summary")
    $sourceCheck = if ($claim.source -in $validSources) { "PASS" } else { "FAIL: Untrusted source" }
    $result.checks += @{check="source_validity"; result=$sourceCheck}
    
    $evidenceCheck = if ($claim.evidence_path) { "PASS" } else { "FAIL: No evidence binding" }
    $result.checks += @{check="evidence_binding"; result=$evidenceCheck}
    
    $deprecatedHit = $null
    foreach ($pattern in $DEPRECATED_PATTERNS) {
        if (($summary -match $pattern) -or ($claimText -match $pattern)) {
            $deprecatedHit = $pattern; break
        }
    }
    $depCheck = if ($deprecatedHit) { "FAIL: References deprecated direction: $deprecatedHit" } else { "PASS" }
    $result.checks += @{check="deprecated_direction_scan"; result=$depCheck}
    
    if ($state -and $state.stale_references) {
        $staleHits = @()
        foreach ($ref in $state.stale_references) {
            if ($summary -match $ref.reference) { $staleHits += $ref }
        }
        $staleCheck = if ($staleHits.Count -gt 0) { "FAIL: References stale data" } else { "PASS" }
        $result.checks += @{check="stale_reference_scan"; result=$staleCheck}
    }
    
    $verStatus = if ($claim.verification_status) { $claim.verification_status } else { "" }
    if ($claim.source -eq "compression_summary" -and $verStatus -ne "VERIFIED") {
        $result.checks += @{check="compression_verification"; result="FAIL: Compression summaries require VERIFIED status"}
    }
    
    $failures = ($result.checks | Where-Object { $_.result -like "FAIL*" }).Count
    $result.admitted = ($failures -eq 0)
    $result.failure_count = $failures
    
    $result | ConvertTo-Json -Depth 4
} catch {
    [PSCustomObject]@{admitted=$false; error="Parse error: $_"} | ConvertTo-Json
}
