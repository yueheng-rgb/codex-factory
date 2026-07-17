# Risk Enforcement Gate v2.0.0
# Part of: FACTORY-R2.14
# Upgrades R2.13 gate: uses Automated Gate Detector as primary source.
# Manual flags only allowed as override with recorded reason.
# CRITICAL/L_CLASS cannot be overridden without evidence.

. (Join-Path $PSScriptRoot "runtime-risk-classifier.ps1")
. (Join-Path $PSScriptRoot "automated-gate-detector.ps1")
. (Join-Path $PSScriptRoot "gate-evidence-binder.ps1")

function Invoke-RiskEnforcementGateV2 {
    param(
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [Parameter(Mandatory=$true)][string]$ProjectPath,
        [string[]]$AdditionalSearchPaths = @(),
        [string]$ProjectType = "",
        [string]$SurfacePlanId = "",
        [hashtable]$ManualOverrides = @{},
        [string]$OverrideReason = "",
        [switch]$ShowOutput
    )

    # Step 1: Classify risk
    $profile = Invoke-RuntimeRiskClassifier -TaskDescription $TaskDescription -ProjectType $ProjectType -SurfacePlanId $SurfacePlanId

    if ($ShowOutput) {
        Write-Host "Risk: $($profile.riskLevel) | Score: $($profile.riskScore)" -F $(if ($profile.riskLevel -in @("CRITICAL","L_CLASS")) { "Red" } else { "Cyan" })
    }

    # Step 2: Automated gate detection
    $detection = Invoke-AutomatedGateDetector -RiskProfile $profile -ProjectPath $ProjectPath -AdditionalSearchPaths $AdditionalSearchPaths

    # Step 3: Create evidence binding
    $binding = New-GateEvidenceBinding -DetectionResult $detection

    # Step 4: Apply manual overrides (if any)
    if ($ManualOverrides.Count -gt 0) {
        $binding.overrideApplied = $true
        $binding.overrideReason = $OverrideReason

        foreach ($gateName in $ManualOverrides.Keys) {
            $gate = $binding.gates | Where-Object { $_.gateName -eq $gateName }
            if ($gate) {
                $newStatus = $ManualOverrides[$gateName]
                # Block overrides for CRITICAL/L_CLASS without evidence
                if ($profile.riskLevel -in @("CRITICAL", "L_CLASS") -and $gate.status -eq "MISSING" -and $newStatus -eq "SATISFIED") {
                    Write-Warning "OVERRIDE REJECTED: Cannot override $gateName to SATISFIED for $($profile.riskLevel) risk without real evidence"
                    $binding.blockedReasons += "Override rejected: $gateName cannot be marked SATISFIED without evidence at $($profile.riskLevel) level"
                } else {
                    $gate.status = $newStatus
                    if ($newStatus -eq "SATISFIED") { $gate.evidenceSummary += " [MANUAL OVERRIDE: $OverrideReason]" }
                }
            }
        }

        # Recompute final decision
        $missingGates = $binding.gates | Where-Object { $_.status -eq "MISSING" -and $_.gateName -ne "NOT_APPLICABLE" }
        $binding.finalDecision = if ($missingGates.Count -gt 0) { "BLOCKED" } else { "ALLOWED" }
    }

    # Step 5: Output
    if ($ShowOutput) {
        Format-GateEvidenceReport -Binding $binding
    }

    return $binding
}
