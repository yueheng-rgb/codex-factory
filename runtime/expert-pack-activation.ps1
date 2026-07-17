# Expert Pack Activation v1.0.0
# Codex Factory R5.1 — activates domain expert packs from task descriptions

param(
    [Parameter(Mandatory=$true)]
    [string]$TaskDescription,
    [string]$RegistryPath = "C:\Codex_App_Factory\governance\expert-packs\expert-pack-registry.json",
    [switch]$ShowVerbose
)

function Invoke-ExpertPackActivation {
    param([string]$Description)

    if (-not (Test-Path $RegistryPath)) {
        Write-Warning "Expert pack registry not found: $RegistryPath"
        return [PSCustomObject]@{
            activated = $false
            error = "Registry not found"
        }
    }

    try {
        $registry = Get-Content $RegistryPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Failed to parse registry: $_"
        return [PSCustomObject]@{ activated = $false; error = "Registry parse failed" }
    }

    $activatedPacks = @()
    $descLower = $Description.ToLower()

    foreach ($entry in $registry.packs) {
        $packPath = "C:\Codex_App_Factory\governance\expert-packs\$($entry.expert_pack_id)\$($entry.pack_file)"
        if (-not (Test-Path $packPath)) {
            if ($ShowVerbose) { Write-Warning "Pack file not found: $packPath" }
            continue
        }

        try {
            $pack = Get-Content $packPath -Raw | ConvertFrom-Json
        } catch {
            if ($ShowVerbose) { Write-Warning "Failed to parse pack: $packPath" }
            continue
        }

        $conditions = $pack.activation_conditions
        if (-not $conditions) { continue }

        # Check exclusion keywords first
        $excluded = $false
        if ($conditions.exclude_keywords) {
            foreach ($ex in $conditions.exclude_keywords) {
                if ($descLower -match [regex]::Escape($ex.ToLower())) {
                    $excluded = $true
                    if ($ShowVerbose) { Write-Output "  Excluded by keyword: $ex" }
                    break
                }
            }
        }
        if ($excluded) { continue }

        # Check activation keywords
        $matchedKeywords = @()
        foreach ($kw in $conditions.keywords) {
            if ($descLower -match [regex]::Escape($kw.ToLower())) {
                $matchedKeywords += $kw
            }
        }

        if ($matchedKeywords.Count -eq 0) { continue }

        # Pack activated
        $activation = [PSCustomObject]@{
            activated_expert_pack = $pack.expert_pack_id
            pack_version = $pack.version
            domain = $pack.domain
            activation_reason = "Matched keywords: $($matchedKeywords -join ', ')"
            matched_keywords = $matchedKeywords
            recommended_surfaces = @($pack.supported_surfaces | ForEach-Object {
                [PSCustomObject]@{
                    surface_id = $_.surface_id
                    surface_type = $_.surface_type
                    purpose = $_.purpose
                    required = if ($_.required) { $true } else { $false }
                    recommended_starter = if ($_.recommended_starter) { $_.recommended_starter } else { $null }
                }
            })
            default_surface_templates = $pack.default_surface_templates
            domain_risk_rules = $pack.domain_risk_rules
            required_invariants = $pack.business_invariants
            required_tests = $pack.required_tests
            required_engines = $pack.required_external_engines
            required_human_audit = $pack.human_audit_points
            non_claims = $pack.non_claims
            benchmark_cases = $pack.benchmark_cases
            integration_points = $pack.integration_points
        }

        $activatedPacks += $activation

        if ($ShowVerbose) {
            Write-Output "ACTIVATED: $($pack.expert_pack_id) v$($pack.version) — $($pack.domain)"
            Write-Output "  Keywords: $($matchedKeywords -join ', ')"
            Write-Output "  Surfaces: $(($pack.supported_surfaces | ForEach-Object { $_.surface_id }) -join ', ')"
            Write-Output "  Invariants: $($pack.business_invariants.Count)"
            Write-Output "  Risk Rules: $($pack.domain_risk_rules.Count)"
            Write-Output "  Tests: $($pack.required_tests.Count)"
            Write-Output "  Engines: $($pack.required_external_engines.Count)"
        }
    }

    if ($activatedPacks.Count -eq 0) {
        return [PSCustomObject]@{
            activated = $false
            expert_packs = @()
            message = "No expert pack activated. Task does not match any domain keywords."
            recommended_surfaces = @()
            risk_level = "GENERIC"
            human_audit_required = $false
        }
    }

    # For multiple activated packs, merge the most specific one
    # (in future, cross-domain packs can be merged)

    $primary = $activatedPacks[0]

    return [PSCustomObject]@{
        activated = $true
        expert_packs = $activatedPacks
        primary_pack = $primary.activated_expert_pack
        activation_reason = $primary.activation_reason
        recommended_surfaces = $primary.recommended_surfaces
        surface_templates = $primary.default_surface_templates
        domain_risk_rules = $primary.domain_risk_rules
        required_invariants = $primary.required_invariants
        required_tests = $primary.required_tests
        required_engines = $primary.required_engines
        required_human_audit = $primary.required_human_audit
        non_claims = $primary.non_claims
        benchmark_cases = $primary.benchmark_cases
        integration_points = $primary.integration_points
        risk_level = "DOMAIN_SPECIFIC"
        human_audit_required = $primary.required_human_audit.Count -gt 0
    }
}

# Main
$result = Invoke-ExpertPackActivation -Description $TaskDescription

if ($ShowVerbose) {
    Write-Output ""
    Write-Output "=== Activation Result ==="
}

$result | ConvertTo-Json -Depth 5

if ($result.activated) {
    Write-Output ""
    Write-Output "Expert pack activated. Integration points:"
    if ($result.integration_points.surface_plan) { Write-Output "  -> Surface Plan: $($result.recommended_surfaces.Count) surfaces" }
    if ($result.integration_points.risk_classifier) { Write-Output "  -> Risk Classifier: $($result.domain_risk_rules.Count) rules" }
    if ($result.integration_points.invariant_engine) { Write-Output "  -> Invariant Engine: $($result.required_invariants.Count) invariants" }
    if ($result.integration_points.engine_broker) { Write-Output "  -> Engine Broker: $($result.required_engines.Count) engines" }
    if ($result.integration_points.gate_detection) { Write-Output "  -> Gate Detection: $($result.required_tests.Count) test categories" }
    if ($result.integration_points.risk_gate) { Write-Output "  -> Risk Gate: $($result.required_human_audit.Count) audit points" }
}

