# External Engine Registry v1.0.0
# Part of: FACTORY-R3.0
# Loads and queries the external engine registry.

$script:EngineRegistryPath = Join-Path $PSScriptRoot "..\governance\external-engines\engine-registry.json"
if (-not (Test-Path $script:EngineRegistryPath)) {
    $script:EngineRegistryPath = Join-Path (Get-Location) "governance\external-engines\engine-registry.json"
}

$script:_registryCache = $null

function Get-EngineRegistry {
    if ($script:_registryCache) { return $script:_registryCache }
    if (-not (Test-Path $script:EngineRegistryPath)) {
        Write-Error "Engine registry not found: $script:EngineRegistryPath"
        return @()
    }
    $data = Get-Content $script:EngineRegistryPath -Raw | ConvertFrom-Json
    $script:_registryCache = $data.engines
    return $script:_registryCache
}

function Get-EnginesByRiskLevel {
    param([string]$RiskLevel)
    $engines = Get-EngineRegistry
    return $engines | Where-Object { $RiskLevel -in $_.trigger_risk_levels }
}

function Get-EnginesByProjectType {
    param([string]$ProjectType)
    $engines = Get-EngineRegistry
    return $engines | Where-Object { $ProjectType -in $_.supported_project_types }
}

function Get-EnginesBySurface {
    param([string]$Surface)
    $engines = Get-EngineRegistry
    return $engines | Where-Object { $Surface -in $_.supported_surfaces }
}

function Get-EngineById {
    param([string]$EngineId)
    $engines = Get-EngineRegistry
    return $engines | Where-Object { $_.engine_id -eq $EngineId }
}

function New-ExternalEnginePlan {
    param(
        [Parameter(Mandatory=$true)]$RiskProfile,
        [string]$ProjectType = "",
        [string[]]$Surfaces = @()
    )
    $engines = Get-EngineRegistry
    $plan = @{
        plan_id = "EEP-$(Get-Date -Format 'yyyyMMddHHmmss')"
        risk_level = $RiskProfile.riskLevel
        project_type = $ProjectType
        surfaces = @($Surfaces)
        planned_engines = @()
        generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    }

    $candidateEngines = @()

    foreach ($engine in $engines) {
        $matchRisk = ($RiskProfile.riskLevel -in $engine.trigger_risk_levels) -or
                     ($engine.trigger_risk_levels.Count -eq 0 -and $engine.enabled_by_default)
        $matchProject = (-not $ProjectType) -or ($ProjectType -in $engine.supported_project_types)
        $matchSurface = ($Surfaces.Count -eq 0) -or (($Surfaces | Where-Object { $_ -in $engine.supported_surfaces }).Count -gt 0)

        if ($matchRisk -or $engine.enabled_by_default) {
            $reason = @()
            if ($matchRisk) { $reason += "risk_match" }
            if ($matchProject) { $reason += "project_match" } else { $reason += "project_mismatch" }
            if ($matchSurface) { $reason += "surface_match" } else { $reason += "surface_mismatch" }
            if ($engine.enabled_by_default) { $reason += "default_enabled" }

            $candidateEngines += [PSCustomObject]@{
                engine_id = $engine.engine_id
                category = $engine.category
                match_risk = $matchRisk
                match_project = $matchProject
                match_surface = $matchSurface
                trigger_reason = $reason -join ", "
                engine = $engine
            }
        }
    }

    $plan.planned_engines = @($candidateEngines | ForEach-Object {
        [PSCustomObject]@{
            engine_id = $_.engine_id
            category = $_.engine.category
            trigger_reason = $_.trigger_reason
            required_executable = $_.engine.required_executable
            command_template = $_.engine.command_template
            timeout = $_.engine.timeout
            fail_policy = $_.engine.fail_policy
        }
    })

    return [PSCustomObject]$plan
}

# Functions available via dot-source