
# Codex Factory v2.2 ¡ª Human Review Gate
# Enforces: CRITICAL / L_CLASS / release / production claims MUST have human review receipt.
# Integrates with existing Risk Gate and CI Artifact Store.

param(
  [Parameter(Mandatory=$true)]
  [string]$RiskLevel,
  [Parameter(Mandatory=$false)]
  [string[]]$RequiredArtifactIds = @(),
  [Parameter(Mandatory=$false)]
  [string]$ClaimType = "",
  [Parameter(Mandatory=$false)]
  [string]$FactoryRoot = "C:\Codex_App_Factory",
  [Parameter(Mandatory=$false)]
  [string]$ArtifactStoreIndex = ""
)

$reviewDir = "$FactoryRoot\reviews"

function Get-ReviewReceipts {
  Get-ChildItem "$reviewDir\REV-*.json" -ErrorAction SilentlyContinue | ForEach-Object {
    Get-Content $_.FullName | ConvertFrom-Json
  }
}

$receipts = @(Get-ReviewReceipts)
$issues = @()
$verdict = "ALLOWED"

Write-Host "=== HUMAN REVIEW GATE ===" -ForegroundColor Cyan
Write-Host "Risk Level: $RiskLevel" -ForegroundColor Cyan
Write-Host "Required Artifacts: $($RequiredArtifactIds -join ', ')" -ForegroundColor Cyan
Write-Host "Claim Type: $ClaimType" -ForegroundColor Cyan
Write-Host ""

# Rule 1: CRITICAL must have receipt
if ($RiskLevel -eq "CRITICAL") {
  $matched = $receipts | Where-Object { $_.risk_level -eq "CRITICAL" -and $_.decision -notin @("REJECTED") }
  if (-not $matched) {
    $issues += "CRITICAL_NO_RECEIPT: No human review receipt found for CRITICAL risk"
    $verdict = "BLOCKED"
    Write-Host "[BLOCKED] CRITICAL risk requires human review receipt" -ForegroundColor Red
  } else {
    Write-Host "[PASS] $($matched.Count) CRITICAL review receipt(s) found" -ForegroundColor Green
  }
}

# Rule 2: L_CLASS must have receipt
if ($RiskLevel -eq "L_CLASS") {
  $matched = $receipts | Where-Object { $_.risk_level -eq "L_CLASS" -and $_.decision -notin @("REJECTED") }
  if (-not $matched) {
    $issues += "L_CLASS_NO_RECEIPT: No human review receipt found for L_CLASS project"
    $verdict = "BLOCKED"
    Write-Host "[BLOCKED] L_CLASS project requires human review receipt" -ForegroundColor Red
  } else {
    Write-Host "[PASS] $($matched.Count) L_CLASS review receipt(s) found" -ForegroundColor Green
  }
}

# Rule 3: Required artifacts must be in at least one receipt
foreach ($artId in $RequiredArtifactIds) {
  $found = $receipts | Where-Object { $artId -in $_.reviewed_artifacts }
  if (-not $found) {
    $issues += "ARTIFACT_NOT_REVIEWED: $artId not in any review receipt"
    $verdict = "BLOCKED"
    Write-Host "[BLOCKED] Artifact $artId not reviewed by any human" -ForegroundColor Red
  } else {
    Write-Host "[PASS] Artifact $artId reviewed in $($found[0].review_id)" -ForegroundColor Green
  }
}

# Rule 4: Production readiness claims require receipt
if ($ClaimType -eq "READY_FOR_PRODUCTION" -or $ClaimType -eq "PRODUCTION_READINESS") {
  $matched = $receipts | Where-Object { $_.review_scope -match "production|release" -and $_.decision -ne "REJECTED" }
  if (-not $matched) {
    $issues += "PRODUCTION_CLAIM_NO_RECEIPT"
    $verdict = "BLOCKED"
    Write-Host "[BLOCKED] Production readiness claim requires human review receipt" -ForegroundColor Red
  } else {
    Write-Host "[PASS] Production readiness reviewed in $($matched[0].review_id)" -ForegroundColor Green
  }
}

# Rule 5: Check non_claims for APPROVED_WITH_RISK
$riskyApprovals = $receipts | Where-Object { $_.decision -eq "APPROVED_WITH_RISK" -and (-not $_.non_claims -or $_.non_claims.Count -eq 0) }
if ($riskyApprovals) {
  $issues += "APPROVED_WITH_RISK_NO_NON_CLAIMS: $($riskyApprovals.Count) receipt(s) missing non_claims"
  Write-Host "[WARN] APPROVED_WITH_RISK receipt(s) missing non_claims" -ForegroundColor Yellow
}

# Rule 6: No auto-generated receipts (enforced by schema ¡ª check cannot_be_auto_generated_by_agent)
$autoGen = $receipts | Where-Object { $_.cannot_be_auto_generated_by_agent -ne $true }
if ($autoGen) {
  $issues += "AUTO_GENERATED_RECEIPT: $($autoGen.Count) receipt(s) not marked as human-generated"
  $verdict = "BLOCKED"
  Write-Host "[BLOCKED] Receipt(s) not marked as human-generated" -ForegroundColor Red
}

# Final
Write-Host ""
if ($verdict -eq "ALLOWED") {
  Write-Host "HUMAN REVIEW GATE: ALLOWED" -ForegroundColor Green
} else {
  Write-Host "HUMAN REVIEW GATE: BLOCKED ¡ª $($issues.Count) issue(s)" -ForegroundColor Red
  $issues | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

@{
  verdict = $verdict
  risk_level = $RiskLevel
  required_artifacts = $RequiredArtifactIds
  receipts_found = $receipts.Count
  issues = $issues
  gate_passed = ($verdict -eq "ALLOWED")
}
