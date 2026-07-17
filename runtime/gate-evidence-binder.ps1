# Gate Evidence Binder v1.0.0
# Part of: FACTORY-R2.14
# Binds automated gate detection results to structured evidence output.
# Produces a GateEvidenceBinding with per-gate evidence files, commands, and confidence.

function New-GateEvidenceBinding {
    param(
        [Parameter(Mandatory=$true)]$DetectionResult,
        [string]$BindingId = ""
    )

    if (-not $BindingId) { $BindingId = "GEB-$(Get-Date -Format 'yyyyMMddHHmmss')" }

    # Compute final decision
    $missingGates = $DetectionResult.gates | Where-Object { $_.status -eq "MISSING" -and $_.gateName -ne "NOT_APPLICABLE" }
    $criticalMissing = $missingGates | Where-Object { $_.gateName -in @("invariant_spec_present", "human_audit_present", "decomposition_plan_present") }
    $blocked = $missingGates.Count -gt 0
    $blockedReasons = @($missingGates | ForEach-Object { $_.blockingReason } | Where-Object { $_ })

    $finalDecision = if ($blocked) { "BLOCKED" } else { "ALLOWED" }

    return [PSCustomObject]@{
        bindingId = $BindingId
        profileId = $DetectionResult.profileId
        riskLevel = $DetectionResult.riskLevel
        projectPath = $DetectionResult.projectPath
        gates = @($DetectionResult.gates | ForEach-Object {
            [PSCustomObject]@{
                gateName = $_.gateName
                status = $_.status
                evidenceFiles = $_.evidenceFiles
                evidenceCommands = $_.evidenceCommands
                evidenceSummary = $_.evidenceSummary
                confidence = $_.confidence
                blockingReason = $_.blockingReason
            }
        })
        finalDecision = $finalDecision
        blockedReasons = $blockedReasons
        satisfiedCount = $DetectionResult.satisfiedCount
        missingCount = $DetectionResult.missingCount
        partialCount = $DetectionResult.partialCount
        overrideApplied = $false
        overrideReason = ""
        createdAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    }
}

function Format-GateEvidenceReport {
    param([Parameter(Mandatory=$true)]$Binding)

    Write-Host "`n===== GATE EVIDENCE BINDING =====" -F Cyan
    Write-Host "Binding: $($Binding.bindingId) | Risk: $($Binding.riskLevel) | Decision: $($Binding.finalDecision)" -F $(if ($Binding.finalDecision -eq "BLOCKED") { "Red" } else { "Green" })

    foreach ($g in $Binding.gates) {
        $icon = switch ($g.status) {
            "SATISFIED" { "[+]" }
            "MISSING" { "[!]" }
            "PARTIAL" { "[~]" }
            "NOT_APPLICABLE" { "[-]" }
        }
        $color = switch ($g.status) {
            "SATISFIED" { "Green" }
            "MISSING" { "Red" }
            "PARTIAL" { "Yellow" }
            "NOT_APPLICABLE" { "DarkGray" }
        }
        Write-Host "  $icon $($g.gateName): $($g.status)" -F $color
        if ($g.evidenceSummary) { Write-Host "    -> $($g.evidenceSummary)" }
        if ($g.evidenceFiles.Count -gt 0) { Write-Host "    Files: $($g.evidenceFiles -join ', ')" -F DarkGray }
        if ($g.evidenceCommands.Count -gt 0) { Write-Host "    Commands: $($g.evidenceCommands -join '; ')" -F DarkGray }
        if ($g.blockingReason) { Write-Host "    BLOCKED: $($g.blockingReason)" -F Red }
    }

    if ($Binding.blockedReasons.Count -gt 0) {
        Write-Host "`n  BLOCKED REASONS:" -F Red
        foreach ($r in $Binding.blockedReasons) { Write-Host "    - $r" -F Red }
    }
    if ($Binding.overrideApplied) {
        Write-Host "  OVERRIDE: $($Binding.overrideReason)" -F Yellow
    }
}
