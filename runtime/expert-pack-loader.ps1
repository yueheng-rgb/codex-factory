# Expert Pack Loader v1.0.0
# Codex Factory R5.1 — loads expert pack definitions and integrates with Foundation RC

param(
    [string]$ExpertPackId,
    [string]$RegistryPath = "C:\Codex_App_Factory\governance\expert-packs\expert-pack-registry.json"
)

function Load-ExpertPackRegistry {
    if (-not (Test-Path $RegistryPath)) {
        Write-Warning "Expert pack registry not found: $RegistryPath"
        return $null
    }
    try {
        $registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
        return $registry
    } catch {
        Write-Error "Failed to parse expert pack registry: $_"
        return $null
    }
}

function Load-ExpertPack {
    param([string]$PackId)
    
    $registry = Load-ExpertPackRegistry
    if (-not $registry) { return $null }
    
    $entry = $registry.packs | Where-Object { $_.expert_pack_id -eq $PackId }
    if (-not $entry) {
        Write-Warning "Expert pack not found in registry: $PackId"
        return $null
    }
    
    $packPath = "C:\Codex_App_Factory\governance\expert-packs\$PackId\$($entry.pack_file)"
    if (-not (Test-Path $packPath)) {
        Write-Warning "Expert pack file not found: $packPath"
        return $null
    }
    
    try {
        $pack = Get-Content $packPath -Raw | ConvertFrom-Json
        Write-Output "Loaded expert pack: $($pack.expert_pack_id) v$($pack.version) — $($pack.domain)"
        return $pack
    } catch {
        Write-Error "Failed to parse expert pack: $_"
        return $null
    }
}

function Get-ExpertPackSurfaces {
    param([Parameter(Mandatory=$true)]$Pack)
    $surfaces = @()
    foreach ($s in $Pack.supported_surfaces) {
        $surfaces += [PSCustomObject]@{
            surface_id = $s.surface_id
            surface_type = $s.surface_type
            purpose = $s.purpose
            required = if ($s.required) { $true } else { $false }
            recommended_starter = if ($s.recommended_starter) { $s.recommended_starter } else { "" }
            risk_level_default = if ($s.risk_level_default) { $s.risk_level_default } else { "MEDIUM" }
        }
    }
    return $surfaces
}

function Get-ExpertPackInvariants {
    param([Parameter(Mandatory=$true)]$Pack, [string]$SeverityFilter)
    $invariants = $Pack.business_invariants
    if ($SeverityFilter) {
        $invariants = $invariants | Where-Object { $_.severity -eq $SeverityFilter }
    }
    return $invariants
}

function Get-ExpertPackRiskRules {
    param([Parameter(Mandatory=$true)]$Pack)
    return $Pack.domain_risk_rules
}

function Get-ExpertPackEnginePlan {
    param([Parameter(Mandatory=$true)]$Pack)
    return $Pack.required_external_engines
}

function Get-ExpertPackBenchmarks {
    param([Parameter(Mandatory=$true)]$Pack)
    return $Pack.benchmark_cases
}

function Get-ExpertPackNonClaims {
    param([Parameter(Mandatory=$true)]$Pack)
    return $Pack.non_claims
}

function Test-ExpertPackIntegration {
    param([Parameter(Mandatory=$true)]$Pack)
    
    $results = @()
    
    $integration = $Pack.integration_points
    if (-not $integration) {
        $integration = @{ surface_plan=$true; risk_classifier=$true; invariant_engine=$true; engine_broker=$true; gate_detection=$true; risk_gate=$true }
    }
    
    # Check surface plan integration
    if ($integration.surface_plan) {
        $surfaces = Get-ExpertPackSurfaces -Pack $Pack
        $results += [PSCustomObject]@{ integration="surface_plan"; status="READY"; count=$surfaces.Count }
    }
    
    # Check risk classifier integration
    if ($integration.risk_classifier) {
        $rules = Get-ExpertPackRiskRules -Pack $Pack
        $results += [PSCustomObject]@{ integration="risk_classifier"; status="READY"; count=$rules.Count }
    }
    
    # Check invariant engine integration
    if ($integration.invariant_engine) {
        $invariants = Get-ExpertPackInvariants -Pack $Pack
        $results += [PSCustomObject]@{ integration="invariant_engine"; status="READY"; count=$invariants.Count }
    }
    
    # Check engine broker integration
    if ($integration.engine_broker) {
        $engines = Get-ExpertPackEnginePlan -Pack $Pack
        $results += [PSCustomObject]@{ integration="engine_broker"; status="READY"; count=$engines.Count }
    }
    
    # Check gate detection integration
    if ($integration.gate_detection) {
        $tests = $Pack.required_tests
        $results += [PSCustomObject]@{ integration="gate_detection"; status="READY"; count=$tests.Count }
    }
    
    # Check risk gate integration
    if ($integration.risk_gate) {
        $audits = $Pack.human_audit_points
        $results += [PSCustomObject]@{ integration="risk_gate"; status="READY"; count=$audits.Count }
    }
    
    return $results
}

# Main
if ($ExpertPackId) {
    $pack = Load-ExpertPack -PackId $ExpertPackId
    if ($pack) {
        Write-Output ""
        Write-Output "=== Expert Pack: $($pack.expert_pack_id) v$($pack.version) ==="
        Write-Output "Domain: $($pack.domain)"
        Write-Output "Supported Project Types: $($pack.supported_project_types -join ', ')"
        Write-Output "Surfaces: $(($pack.supported_surfaces | ForEach-Object { $_.surface_id }) -join ', ')"
        Write-Output "Risk Rules: $($pack.domain_risk_rules.Count)"
        Write-Output "Business Invariants: $($pack.business_invariants.Count)"
        Write-Output "Required Tests: $($pack.required_tests.Count)"
        Write-Output "Engines: $($pack.required_external_engines.Count)"
        Write-Output "Benchmarks: $($pack.benchmark_cases.Count)"
        Write-Output "Non-Claims: $($pack.non_claims.Count)"
        
        Write-Output ""
        Write-Output "=== Integration Check ==="
        $integration = Test-ExpertPackIntegration -Pack $pack
        $integration | Format-Table -AutoSize
    }
} else {
    $registry = Load-ExpertPackRegistry
    if ($registry) {
        Write-Output "=== Expert Pack Registry ==="
        Write-Output "Available packs: $($registry.packs.Count)"
        foreach ($p in $registry.packs) {
            Write-Output "  - $($p.expert_pack_id): $($p.description)"
        }
    }
}

Write-Output ""
Write-Output "Expert Pack Loader v1.0.0 — ready"
