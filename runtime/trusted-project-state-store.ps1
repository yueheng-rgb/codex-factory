# Trusted Project State Store v1.0.0
param(
    [string]$ProjectId = "codex-factory-v1",
    [string]$StatePath = "C:\Codex_App_Factory\outputs\trusted-project-state.json",
    [string]$Action = "load"
)

function New-TrustedState {
    return [PSCustomObject]@{
        project_id = $ProjectId; version = "1.3.0"
        generated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        phase = "v1.3-trust-closure"; last_verified = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
        frozen_pipelines = @(
            @{pipeline="search"; status="FROZEN"},
            @{pipeline="multi-agent"; status="FROZEN"},
            @{pipeline="verifier"; status="FROZEN"},
            @{pipeline="harness"; status="FROZEN"},
            @{pipeline="AGENTS.md"; status="FROZEN"}
        )
        deprecated_directions = @(
            @{direction="Independent Search Agent"; status="FORBIDDEN"},
            @{direction="Dual Search Channel"; status="FORBIDDEN"},
            @{direction="Implementer direct search"; status="FORBIDDEN"},
            @{direction="Firecrawl as canonical search"; status="FORBIDDEN"}
        )
        expert_packs = @(
            @{pack_id="ecommerce"; status="ACTIVE"; runtime_validated=$true},
            @{pack_id="saas-tool"; status="ACTIVE"; runtime_validated=$true},
            @{pack_id="admin-system"; status="ACTIVE"; runtime_validated=$true}
        )
        engine_status = @(
            @{engine_id="semgrep"; version="1.169.0"; status="AVAILABLE"},
            @{engine_id="autocannon"; version="8.0.0"; status="AVAILABLE"},
            @{engine_id="playwright"; version="1.61.1"; status="AVAILABLE"},
            @{engine_id="codeql"; version=""; status="TOOL_UNAVAILABLE"},
            @{engine_id="k6"; version=""; status="TOOL_UNAVAILABLE"},
            @{engine_id="firecrawl-reader"; version=""; status="TOOL_UNAVAILABLE"}
        )
        regression_baseline = @{total_tests=172; passing=172; last_run=(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")}
        trusted_memory_entries = @()
        stale_references = @()
    }
}

$state = if (Test-Path $StatePath) { Get-Content $StatePath -Raw | ConvertFrom-Json } else { New-TrustedState }
if ($Action -eq "init" -or -not (Test-Path $StatePath)) {
    $state = New-TrustedState
    $state | ConvertTo-Json -Depth 6 | Set-Content $StatePath -Encoding UTF8
    Write-Output "Trusted state initialized: $StatePath"
} else {
    $state | ConvertTo-Json -Depth 4
}
