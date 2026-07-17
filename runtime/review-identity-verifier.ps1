# Codex Factory V3.0 — Review Identity Verifier
# Validates review receipts against identity modes

param(
    [string]$ReceiptPath,
    [string]$RequiredMode = "self_declared_automated",
    [switch]$Json
)

$result = @{ receipt_path=$ReceiptPath; checks=@(); overall="PENDING" }

if (-not (Test-Path $ReceiptPath)) {
    $result.checks += @{ check="receipt_exists"; status="FAIL"; detail="Receipt not found: $ReceiptPath" }
    $result.overall = "FAIL"
    if ($Json) { $result | ConvertTo-Json -Depth 3 }; return
}

try {
    $receipt = Get-Content $ReceiptPath -Raw | ConvertFrom-Json
    $result.checks += @{ check="receipt_valid_json"; status="PASS" }
    
    # Check identity mode
    $mode = $receipt.signature_mode -or $receipt.identity_mode
    if ($mode) {
        $result.checks += @{ check="identity_mode_present"; status="PASS"; detail="Mode: $mode" }
    } else {
        $result.checks += @{ check="identity_mode_present"; status="FAIL"; detail="No signature_mode or identity_mode found" }
    }
    
    # Check upgrade eligibility
    if ($mode -eq "self_declared_automated") {
        $result.checks += @{ check="identity_upgrade_available"; status="INFO"; detail="Can upgrade to local_named_reviewer or signed_local_receipt" }
    }
    
    # Check non-claims present for APPROVED_WITH_RISK
    if ($receipt.decision -eq "APPROVED_WITH_RISK") {
        $hasNonClaims = $receipt.non_claims -and $receipt.non_claims.Count -gt 0
        $result.checks += @{ check="non_claims_required_for_risk"; status=if($hasNonClaims){"PASS"}else{"FAIL"}; detail="Non-claims present: $hasNonClaims" }
    }
    
    # Check no fake production approval
    if ($receipt.decision -match "READY_FOR_PRODUCTION" -and $receipt.decision -notmatch "REVIEW") {
        $result.checks += @{ check="no_production_exaggeration"; status="FAIL"; detail="Receipt claims READY_FOR_PRODUCTION without REVIEW qualifier" }
    } else {
        $result.checks += @{ check="no_production_exaggeration"; status="PASS" }
    }
    
    $result.overall = if (($result.checks | Where-Object { $_.status -eq "FAIL" }).Count -gt 0) { "FAIL" } else { "PASS" }
    
} catch {
    $result.checks += @{ check="receipt_parse"; status="FAIL"; detail="Parse error: $_" }
    $result.overall = "FAIL"
}

if ($Json) { $result | ConvertTo-Json -Depth 3 }
else { Write-Output "Review identity check: $($result.overall)" }
