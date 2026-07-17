# Risk Enforcement Gate v3.0.0
# Part of: FACTORY-R3.0
# Integrates External Engine Broker with R2.14 Automated Gate Detection.
# Default fast path: R2.14 lightweight detection.
# External engines: triggered when risk/surface/project match.

. (Join-Path $PSScriptRoot "runtime-risk-classifier.ps1")
. (Join-Path $PSScriptRoot "automated-gate-detector.ps1")
. (Join-Path $PSScriptRoot "gate-evidence-binder.ps1")
. (Join-Path $PSScriptRoot "external-engine-broker.ps1")

function Invoke-RiskEnforcementGateV3 {
    param(
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [Parameter(Mandatory=$true)][string]$ProjectPath,
        [string[]]$AdditionalSearchPaths = @(),
        [string]$ProjectType = "",
        [string[]]$Surfaces = @(),
        [hashtable]$ManualOverrides = @{},
        [string]$OverrideReason = "",
        [switch]$ShowOutput,
        [switch]$SkipExternalEngines
    )

    # Step 1: Classify risk (R2.13)
    $profile = Invoke-RuntimeRiskClassifier -TaskDescription $TaskDescription -ProjectType $ProjectType
    if ($ShowOutput) {
        Write-Host "Risk: $($profile.riskLevel) | Score: $($profile.riskScore)" -F $(if ($profile.riskLevel -in @("CRITICAL","L_CLASS")){"Red"}else{"Cyan"})
    }

    # Step 2: Lightweight gate detection (R2.14) ¡ª always runs
    $detection = Invoke-AutomatedGateDetector -RiskProfile $profile -ProjectPath $ProjectPath -AdditionalSearchPaths $AdditionalSearchPaths -Surfaces $Surfaces
    $lightweightBinding = New-GateEvidenceBinding -DetectionResult $detection

    # Step 3: External engine broker ¡ª runs when risk >= MEDIUM
    $brokerResult = $null
    if (-not $SkipExternalEngines -and $profile.riskLevel -ne "LOW") {
        $brokerResult = Invoke-ExternalEngineBroker `
            -RiskProfile $profile `
            -ProjectType $ProjectType `
            -Surfaces $Surfaces `
            -ProjectPath $ProjectPath `
            -ShowOutput:$ShowOutput
    }

    # Step 4: Merge engine results into evidence binding
    $engineBindings = @()
    if ($brokerResult) {
        foreach ($rr in $brokerResult.run_results) {
            $engineBindings += [PSCustomObject]@{
                engine_id = $rr.engine_id
                status = $rr.status
                evidence_type = $rr.evidence_binding.evidence_type
                evidence_summary = $rr.evidence_binding.evidence_summary
                raw_output_summary = $rr.raw_output_summary
                skip_reason = $rr.skip_reason
            }
        }
    }

    # Step 5: Compute final decision
    $finalDecision = $lightweightBinding.finalDecision
    $allReasons = @($lightweightBinding.blockedReasons)
    $engineDecisionOverrides = @()

    if ($brokerResult) {
        # Check if any external engine found critical issues
        $criticalFindings = $brokerResult.run_results | Where-Object {
            $_.status -eq "FINDINGS_PRESENT" -and $_.findings_by_severity.ERROR -gt 0
        }

        if ($criticalFindings.Count -gt 0) {
            $engineDecisionOverrides += "External engine found $($criticalFindings.Count) engine(s) with ERROR findings"
            if ($profile.riskLevel -in @("CRITICAL", "L_CLASS")) {
                # Critical findings from engines + CRITICAL risk = potential BLOCKED
                if ($finalDecision -eq "ALLOWED") {
                    $finalDecision = "BLOCKED"
                    $allReasons += "External engine findings override: CRITICAL risk with engine errors"
                }
            }
        }

        # Check for missing key engines at CRITICAL/L_CLASS
        if ($profile.riskLevel -in @("CRITICAL", "L_CLASS")) {
            $unavailEngines = $brokerResult.run_results | Where-Object { $_.status -eq "TOOL_UNAVAILABLE" }
            $hasHumanAudit = ($lightweightBinding.gates | Where-Object { $_.gateName -eq "human_audit_present" -and $_.status -eq "SATISFIED" }).Count -gt 0

            if ($unavailEngines.Count -gt 0 -and -not $hasHumanAudit) {
                $engineDecisionOverrides += "$($unavailEngines.Count) engine(s) unavailable without human audit"
                if ($profile.riskLevel -eq "L_CLASS" -and $finalDecision -eq "ALLOWED") {
                    $finalDecision = "PARTIAL"
                    $allReasons += "L_CLASS: key engines unavailable and no human audit ¡ª downgraded to PARTIAL"
                }
            }
        }
    }

    # Step 6: Apply manual overrides (last resort, with audit)
    if ($ManualOverrides.Count -gt 0) {
        foreach ($gateName in $ManualOverrides.Keys) {
            $newStatus = $ManualOverrides[$gateName]
            if ($profile.riskLevel -in @("CRITICAL", "L_CLASS") -and $newStatus -eq "SATISFIED") {
                Write-Warning "OVERRIDE REJECTED: Cannot override $gateName to SATISFIED at $($profile.riskLevel) without evidence"
                $allReasons += "Override rejected: $gateName at $($profile.riskLevel)"
            }
        }
        $finalDecision = if ($finalDecision -eq "BLOCKED" -and $allReasons.Count -eq $lightweightBinding.blockedReasons.Count) { "BLOCKED" } else { $finalDecision }
    }

    # Compile full result
    $result = [PSCustomObject]@{
        gate_version = "v3.0.0"
        profile = $profile
        lightweight_gate_result = $lightweightBinding
        external_engine_plan = if ($brokerResult) { $brokerResult.plan } else { $null }
        external_engine_results = if ($brokerResult) { $brokerResult.run_results } else { @() }
        engine_bindings = $engineBindings
        engine_decision_overrides = $engineDecisionOverrides
        final_decision = $finalDecision
        all_reasons = $allReasons
        generated_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    }

    if ($ShowOutput) {
        Write-Host "`n===== FINAL GATE DECISION (v3) =====" -F $(if ($finalDecision -eq "BLOCKED"){"Red"}else{"Green"})
        Write-Host "Decision: $finalDecision"
        Write-Host "Lightweight: $($lightweightBinding.finalDecision)"
        if ($brokerResult) {
            Write-Host "Engines planned: $($brokerResult.summary.total_planned) | Ran: $($brokerResult.summary.ran) | Skipped: $($brokerResult.summary.skipped)"
        }
        if ($engineDecisionOverrides.Count -gt 0) {
            Write-Host "Engine overrides:" -F Yellow
            foreach ($o in $engineDecisionOverrides) { Write-Host "  - $o" -F Yellow }
        }
        if ($allReasons.Count -gt 0) {
            Write-Host "Reasons:" -F $(if ($finalDecision -eq "BLOCKED"){"Red"}else{"DarkGray"})
            foreach ($r in $allReasons) { Write-Host "  - $r" }
        }
    }

    return $result
}
