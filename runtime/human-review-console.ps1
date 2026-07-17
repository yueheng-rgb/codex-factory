
# Codex Factory v2.2 ¡ª Human Review Console
# CLI-based human review tool. No Web UI. Creates review sessions, records decisions, exports receipts.

param(
  [Parameter(Mandatory=$false)]
  [string]$Action = "help",
  [Parameter(Mandatory=$false)]
  [string]$SessionId,
  [Parameter(Mandatory=$false)]
  [string]$ReviewerRole,
  [Parameter(Mandatory=$false)]
  [string]$ReviewerName,
  [Parameter(Mandatory=$false)]
  [string]$ReviewScope,
  [Parameter(Mandatory=$false)]
  [string]$RiskLevel,
  [Parameter(Mandatory=$false)]
  [string[]]$ArtifactIds,
  [Parameter(Mandatory=$false)]
  [string[]]$Claims,
  [Parameter(Mandatory=$false)]
  [string]$Decision,
  [Parameter(Mandatory=$false)]
  [string]$Notes,
  [Parameter(Mandatory=$false)]
  [string]$FactoryRoot = "C:\Codex_App_Factory",
  [Parameter(Mandatory=$false)]
  [string]$ArtifactStoreIndex
)

$reviewDir = "$FactoryRoot\reviews"
New-Item -ItemType Directory -Force -Path $reviewDir | Out-Null

function New-ReviewSession {
  $sid = "SESS-{0:yyyyMMdd-HHmmss}" -f (Get-Date)
  $session = [PSCustomObject]@{
    session_id = $sid
    created_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
    closed_at = $null
    reviewer_role = $ReviewerRole
    reviewer_name_or_alias = $ReviewerName
    reviews = @()
    session_status = "OPEN"
    linked_artifact_store_index = $ArtifactStoreIndex
    linked_audit_ledger_entries = @()
    session_notes = ""
  }
  $session | ConvertTo-Json -Depth 4 | Set-Content "$reviewDir\$sid.json" -Encoding utf8
  Write-Host "[REVIEW] Session created: $sid" -ForegroundColor Green
  return $sid
}

function Add-ReviewReceipt {
  param([string]$Sid)
  $sessionFile = "$reviewDir\$Sid.json"
  if (-not (Test-Path $sessionFile)) { throw "Session not found: $Sid" }

  $rid = "REV-{0:D4}" -f ((Get-ChildItem $reviewDir\*.json | Where-Object { $_.Name -match '^REV-' }).Count + 1)
  $receipt = [PSCustomObject]@{
    review_id = $rid
    session_id = $Sid
    reviewer_role = $ReviewerRole
    reviewer_name_or_alias = $ReviewerName
    review_scope = $ReviewScope
    risk_level = $RiskLevel
    reviewed_artifacts = @($ArtifactIds)
    reviewed_claims = @($Claims)
    decision = $Decision
    required_changes = @()
    reviewer_notes = $Notes
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssK")
    linked_audit_ledger_entry = ""
    linked_artifact_ids = @($ArtifactIds)
    linked_artifact_store_index = $ArtifactStoreIndex
    non_claims = @()
    signature_mode = "local_receipt"
    cannot_be_auto_generated_by_agent = $true
  }

  # Validate: decision rules
  if ($ArtifactIds.Count -eq 0) {
    Write-Host "[REVIEW-WARN] No artifact IDs linked ¡ª review may not be valid per policy" -ForegroundColor Yellow
  }

  # Save receipt
  $receipt | ConvertTo-Json -Depth 4 | Set-Content "$reviewDir\$rid.json" -Encoding utf8

  # Update session
  $session = Get-Content $sessionFile | ConvertFrom-Json
  $session.reviews += $receipt
  $session | ConvertTo-Json -Depth 5 | Set-Content $sessionFile -Encoding utf8

  Write-Host "[REVIEW] Receipt created: $rid (decision: $Decision)" -ForegroundColor $(if ($Decision -eq "APPROVED") { "Green" } elseif ($Decision -eq "REJECTED") { "Red" } else { "Yellow" })
  return $rid
}

function Get-RequiredArtifacts {
  param([string]$ClaimPattern)
  if ($ArtifactStoreIndex -and (Test-Path $ArtifactStoreIndex)) {
    $index = Get-Content $ArtifactStoreIndex | ConvertFrom-Json
    Write-Host "=== REQUIRED ARTIFACTS ==="
    foreach ($kv in $index.traceability_matrix.PSObject.Properties) {
      if (-not $ClaimPattern -or $kv.Name -match $ClaimPattern) {
        Write-Host "  Claim: $($kv.Name)"
        Write-Host "    Artifact(s): $($kv.Value -join ', ')" -ForegroundColor Cyan
      }
    }
  } else {
    Write-Host "[REVIEW-WARN] No artifact store index provided. Cannot list required artifacts." -ForegroundColor Yellow
  }
}

function Get-ReviewStatus {
  Write-Host "=== REVIEW SESSIONS ==="
  Get-ChildItem "$reviewDir\SESS-*.json" | ForEach-Object {
    $s = Get-Content $_.FullName | ConvertFrom-Json
    $count = $s.reviews.Count
    Write-Host "  $($s.session_id) | $($s.reviewer_role) | $($s.session_status) | $count reviews"
  }
  Write-Host ""
  Write-Host "=== REVIEW RECEIPTS ==="
  Get-ChildItem "$reviewDir\REV-*.json" | ForEach-Object {
    $r = Get-Content $_.FullName | ConvertFrom-Json
    Write-Host "  $($r.review_id) | $($r.decision) | $($r.risk_level) | $($r.review_scope)"
  }
}

function Invoke-ReviewGateCheck {
  param([string]$RiskLevel, [string[]]$RequiredArtifactIds)
  $receipts = Get-ChildItem "$reviewDir\REV-*.json" -ErrorAction SilentlyContinue | ForEach-Object {
    Get-Content $_.FullName | ConvertFrom-Json
  }

  $matched = $receipts | Where-Object {
    $_.risk_level -eq $RiskLevel -and $_.decision -ne "REJECTED"
  }

  if ($RiskLevel -in @("CRITICAL","L_CLASS")) {
    if (-not $matched) {
      Write-Host "[REVIEW-GATE] BLOCKED: No human review receipt for $RiskLevel risk" -ForegroundColor Red
      return "BLOCKED"
    }
    # Check artifacts
    foreach ($r in $matched) {
      $missing = $RequiredArtifactIds | Where-Object { $_ -notin $r.reviewed_artifacts }
      if ($missing) {
        Write-Host "[REVIEW-GATE] BLOCKED: Review $($r.review_id) missing artifacts: $($missing -join ', ')" -ForegroundColor Red
        return "BLOCKED"
      }
    }
    Write-Host "[REVIEW-GATE] PASS: $($matched.Count) review(s) found for $RiskLevel" -ForegroundColor Green
    return "ALLOWED"
  }
  return "NOT_REQUIRED"
}

# === MAIN DISPATCH ===
switch ($Action) {
  "create-session" {
    if (-not $ReviewerRole -or -not $ReviewerName) {
      Write-Host "Usage: -Action create-session -ReviewerRole <role> -ReviewerName <name> [-ArtifactStoreIndex <path>]"
      return
    }
    $sid = New-ReviewSession
    Write-Output "SESSION_ID=$sid"
  }
  "add-review" {
    if (-not $SessionId -or -not $Decision -or -not $RiskLevel) {
      Write-Host "Usage: -Action add-review -SessionId <sid> -ReviewerRole <role> -ReviewerName <name> -ReviewScope <scope> -RiskLevel <LOW|MEDIUM|HIGH|CRITICAL|L_CLASS> -ArtifactIds <id1,id2> -Claims <claim1,claim2> -Decision <APPROVED|REJECTED|NEEDS_CHANGES|PARTIAL|APPROVED_WITH_RISK> -Notes <notes>"
      return
    }
    $rid = Add-ReviewReceipt -Sid $SessionId
    Write-Output "RECEIPT_ID=$rid"
  }
  "list-artifacts" {
    Get-RequiredArtifacts
  }
  "status" {
    Get-ReviewStatus
  }
  "gate-check" {
    if (-not $RiskLevel) {
      Write-Host "Usage: -Action gate-check -RiskLevel <CRITICAL|L_CLASS> [-ArtifactIds <ids>]"
      return
    }
    $result = Invoke-ReviewGateCheck -RiskLevel $RiskLevel -RequiredArtifactIds $ArtifactIds
    Write-Output "GATE_RESULT=$result"
  }
  "help" {
    Write-Host "Human Review Console ¡ª Actions:" -ForegroundColor Cyan
    Write-Host "  create-session   : Start a new review session"
    Write-Host "  add-review       : Add a review receipt to a session"
    Write-Host "  list-artifacts   : List artifacts required for claims"
    Write-Host "  status           : Show all sessions and receipts"
    Write-Host "  gate-check       : Check if required reviews exist"
  }
}
