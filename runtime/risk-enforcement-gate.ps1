# Risk Enforcement Gate v1.0.0
# Part of: FACTORY-R2.13
# Enforces risk rules: BLOCKED if required tests/invariants/reviewers/audit not met.
# Does NOT merely warn — BLOCKS implementation when risk requirements are unsatisfied.

. (Join-Path $PSScriptRoot "runtime-risk-classifier.ps1")
. (Join-Path $PSScriptRoot "business-invariant-engine.ps1")

function Invoke-RiskEnforcementGate {
    param(
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [string[]]$ChangedFiles = @(),
        [string]$ProjectType = "",
        [string]$SurfacePlanId = "",
        [switch]$HasInvariantSpec,
        [switch]$HasTests,
        [switch]$HasHumanAudit,
        [switch]$HasReviewer,
        [switch]$HasDecompositionPlan,
        [switch]$ShowOutput
    )

    # Step 1: Classify risk
    $profile = Invoke-RuntimeRiskClassifier -TaskDescription $TaskDescription -ChangedFiles $ChangedFiles -ProjectType $ProjectType -SurfacePlanId $SurfacePlanId

    # Step 2: Generate invariant spec if CRITICAL or L_CLASS
    $invariantSpec = $null
    if ($profile.riskLevel -in @("CRITICAL", "L_CLASS")) {
        $invariantSpec = New-InvariantSpec -RiskProfile $profile
    }

    # Step 3: Enforcement checks
    $blocked = $false
    $blockReasons = @()

    switch ($profile.riskLevel) {
        "L_CLASS" {
            if (-not $HasDecompositionPlan) {
                $blocked = $true
                $blockReasons += "L_CLASS requires decomposition plan (not provided)"
            }
            if (-not $HasHumanAudit) {
                $blocked = $true
                $blockReasons += "L_CLASS requires human audit (not provided)"
            }
            if (-not $HasInvariantSpec) {
                $blocked = $true
                $blockReasons += "L_CLASS requires business invariant spec (not provided)"
            }
            if (-not $HasReviewer) {
                $blocked = $true
                $blockReasons += "L_CLASS requires architect + security reviewer (not provided)"
            }
        }
        "CRITICAL" {
            if (-not $HasInvariantSpec) {
                $blocked = $true
                $blockReasons += "CRITICAL risk requires business invariant spec (not provided)"
            }
            if (-not $HasTests) {
                $blocked = $true
                $blockReasons += "CRITICAL risk requires tests with invariant coverage (not provided)"
            }
            if (-not $HasHumanAudit) {
                $blocked = $true
                $blockReasons += "CRITICAL risk requires human audit (not provided)"
            }
            if (-not $HasReviewer) {
                $blocked = $true
                $blockReasons += "CRITICAL risk requires security + verifier reviewer (not provided)"
            }
        }
        "HIGH" {
            if (-not $HasTests) {
                $blocked = $true
                $blockReasons += "HIGH risk requires targeted test coverage (not provided)"
            }
        }
        "MEDIUM" {
            if (-not $HasTests) {
                # MEDIUM: recommended but not blocking
                if ($ShowOutput) { Write-Host "[MEDIUM] Tests recommended but not blocking" -F Yellow }
            }
        }
        "LOW" {
            # No enforcement needed
        }
    }

    # Step 4: Update profile
    $profile.enforcementStatus = if ($blocked) { "BLOCKED" } else { "ALLOWED" }
    $profile.blockedReason = if ($blocked) { ($blockReasons -join "; ") } else { "" }

    # Step 5: Output
    if ($Verbose -or $blocked) {
        Write-Host "`n===== RISK ENFORCEMENT GATE =====" -F Cyan
        Write-Host "Risk Level: $($profile.riskLevel)" -F $(if ($profile.riskLevel -in @("CRITICAL","L_CLASS")) { "Red" } elseif ($profile.riskLevel -eq "HIGH") { "Yellow" } else { "Green" })
        Write-Host "Risk Score: $($profile.riskScore)"
        Write-Host "Reasons: $($profile.riskReasons -join ' | ')"
        Write-Host "Required Reviewers: $($profile.requiredReviewers -join ', ')"
        Write-Host "Required Tests: $($profile.requiredTests -join ', ')"
        Write-Host "Human Audit: $($profile.humanAuditRequired)"
        if ($invariantSpec) {
            Write-Host "Invariants: $($invariantSpec.invariantCount) ($($invariantSpec.blockerCount) blocker, $($invariantSpec.criticalCount) critical)"
        }
        Write-Host "Enforcement: $($profile.enforcementStatus)" -F $(if ($blocked) { "Red" } else { "Green" })
        if ($blocked) {
            Write-Host "BLOCKED Reasons:" -F Red
            foreach ($r in $blockReasons) { Write-Host "  - $r" -F Red }
        }
    }

    return [PSCustomObject]@{
        profile = $profile
        invariantSpec = $invariantSpec
        blocked = $blocked
        blockReasons = $blockReasons
        enforcementStatus = $profile.enforcementStatus
    }
}

# =============================================
# Quick test: run with demo cases
# =============================================
function Invoke-RiskEnforcementDemo {
    Write-Host "===== RISK ENFORCEMENT DEMO CASES =====" -F Cyan

    $cases = @(
        @{desc="Update README wording for clarity"; tests=$false; audit=$false; reviewer=$false; inv=$false; decomp=$false; label="LOW: README wording"},
        @{desc="Add search filter to GET /api/products with pagination"; tests=$true; audit=$false; reviewer=$false; inv=$false; decomp=$false; label="MEDIUM: API filter + pagination"},
        @{desc="Modify product status transition rules for new lifecycle states"; tests=$true; audit=$false; reviewer=$false; inv=$false; decomp=$false; label="HIGH: Status transition change"},
        @{desc="Change product price calculation logic for discount handling"; tests=$true; audit=$true; reviewer=$true; inv=$true; decomp=$false; label="CRITICAL: Price logic change (with all gates)"},
        @{desc="Modify user role permission checks for admin escalation"; tests=$false; audit=$false; reviewer=$false; inv=$false; decomp=$false; label="CRITICAL: Permission bypass (MISSING gates - should BLOCK)"},
        @{desc="Build WeChat mini-program shopping mall with admin backend and payment API"; tests=$false; audit=$false; reviewer=$false; inv=$false; decomp=$false; label="L_CLASS: Mini-program mall (MISSING all gates - should BLOCK)"}
    )

    foreach ($c in $cases) {
        Write-Host "`n--- $($c.label) ---" -F Cyan
        $result = Invoke-RiskEnforcementGate -TaskDescription $c.desc `
            -HasTests:$c.tests -HasHumanAudit:$c.audit -HasReviewer:$c.reviewer `
            -HasInvariantSpec:$c.inv -HasDecompositionPlan:$c.decomp -ShowOutput
        Write-Host ""
    }
}
