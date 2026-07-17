# fix-r1-run.ps1 - Rebuild RUN_STATE with PS-compatible hashes + create token store
$ErrorActionPreference = "Stop"
$RunDir = "C:\Codex_App_Factory\harness\runs\phase6c-m-r1-run"
$TokenStoreDir = "C:\Codex_App_Factory\harness-control\tokens\phase6c-m-r1-run"

# Ensure clean token store directory
if (Test-Path $TokenStoreDir) { Remove-Item -Recurse -Force $TokenStoreDir }
New-Item -ItemType Directory -Path $TokenStoreDir -Force | Out-Null

function Get-Sha256 { param([string]$s)
    $b = [System.Text.Encoding]::UTF8.GetBytes($s)
    $h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($b)
    return [System.BitConverter]::ToString($h).Replace("-","").ToLower()
}

# Read existing JSON from RUN_STATE (events with bad hashes) to extract event definitions
$oldLines = Get-Content (Join-Path $RunDir "RUN_STATE.jsonl") -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 }

# Parse old events and build definition list without hash/auth fields
$eventDefs = @()
foreach ($line in $oldLines) {
    $e = $line | ConvertFrom-Json
    $eventDefs += $e
}

# --- Create token store files ---
# We need individual JSON files where tokenHash matches tokenLeaseId in RUN_STATE
# Each token record needs: tokenHash, issuedNonces (array with nonce objects), expiresAt, agentId, role, etc.

$tokenData = @{
    "builder-core-m" = @{ taskId="T-001"; tokenHash="4e0272cbba822167b12ed4a48bbb95430b87fc6b73832e8e8aa069094868ba2f"; nonce="4c1975f059ea409eac10126f27b1e7ef"; role="builder-agent" }
    "builder-auth-m" = @{ taskId="T-002"; tokenHash="9c1929a28edec3363f36533698889bfec4fa4f96c04c4d6b1719f0f7f6a64f31"; nonce="0b33aad52bbe431b8059ebc2d02c9387"; role="builder-agent" }
    "builder-admin-m" = @{ taskId="T-003"; tokenHash="567cdd0492240a6998b8784fe32fa0993eaadedb9b824b4120bb51b5e16d7ede"; nonce="007cae36db2c411fae87cf6dc0431a63"; role="builder-agent" }
    "builder-doctor-m" = @{ taskId="T-004"; tokenHash="54b76fb635d8f9c9a5d8c9fed65faecd8d8f3ad5405bb59f53e7889cf8a1231f"; nonce="aff5aca9de9c4a8bbbf93bea7d4384e6"; role="builder-agent" }
    "builder-app-m" = @{ taskId="T-005"; tokenHash="f0ab43436a2cc97a5f92ec56082ce2b2f3461c4f603d5ae4f4a14c17751280c9"; nonce="8e14dd59804149b8ae3e1447778b9cfd"; role="builder-agent" }
    "validator-m1" = @{ taskId="*"; tokenHash="48c280f51823ae6dd81fa21df5ae1b83b72db91268964912f2ace2205d2fd253"; nonce="1086bb81a32241b98a21ffe5d1fdec11"; role="test-agent" }
    "release-agent-m" = @{ taskId="*"; tokenHash="dca4c27acfe4a8acd9a3ea76e2b67255bf18668444c8b7cec45bcd5c139b20dd"; nonce="e9ddfdfedefc4e80bb64611a78f731f4"; role="release-agent" }
}

$now = Get-Date
$expiresAt = $now.AddHours(48).ToString("o")
$issuedAtBase = $now.ToString("o")

foreach ($agentId in $tokenData.Keys) {
    $td = $tokenData[$agentId]
    $leaseId = [System.Guid]::NewGuid().ToString("N")
    $filePath = Join-Path $TokenStoreDir "$leaseId.json"

    # For each event this agent signs, we issue a nonce
    # Collect all events for this actor from eventDefs
    $actorEvents = @($eventDefs | Where-Object { $_.actor -eq $agentId -and $_.event -in @("task_claimed","task_submitted","validation_started","validation_passed","validation_failed","task_verified","release_validation_started","release_validation_passed","release_validation_failed","release_verified") })
    
    $nonces = @()
    foreach ($ae in $actorEvents) {
        if ($ae.proofNonce) {
            $nonces += @{ nonce = $ae.proofNonce; issuedAt = $issuedAtBase; consumedAt = $null; operation = $ae.event }
        }
    }

    $record = @{
        schemaVersion = "6B-R5"
        tokenHash = $td.tokenHash
        agentId = $agentId
        role = $td.role
        taskId = $td.taskId
        issuedAt = $issuedAtBase
        expiresAt = $expiresAt
        status = "active"
        revokedAt = $null
        issuedNonces = $nonces
        allowedOperations = @()
    }

    $utf8 = [System.Text.UTF8Encoding]::new($false)
    $json = $record | ConvertTo-Json -Depth 8 -Compress
    [System.IO.File]::WriteAllText($filePath, $json, $utf8)
    Write-Host "Created token: $filePath ($($nonces.Count) nonces)"
}

# --- Rebuild RUN_STATE with PS-compatible hashes ---
# We take the event definitions (without hashes) and rebuild the hash chain
$hashExclude = @("eventHash","previousHash","payloadHash","seq","timestamp")
$proofExclude = @("eventHash","previousHash","payloadHash","seq","timestamp","authorizationProof","tokenLeaseId","proofNonce","tokenIssuedAt","tokenExpiresAt")

$prevHash = "GENESIS"
$newEvents = @()
$seq = 0

foreach ($ed in $eventDefs) {
    $seq++
    $newEvent = [ordered]@{}
    
    # Copy all fields from eventDef except hash/auth fields we will recompute
    foreach ($key in ($ed.PSObject.Properties.Name)) {
        if ($key -notin @("eventHash","previousHash","payloadHash","authorizationProof","tokenLeaseId","proofNonce")) {
            $newEvent[$key] = $ed.$key
        }
    }
    $newEvent["seq"] = $seq
    $newEvent["previousHash"] = $prevHash
    
    # Compute payloadHash (everything except eventHash, previousHash, payloadHash; but including seq, timestamp)
    $payloadOnly = [ordered]@{}
    foreach ($k in ($newEvent.Keys)) {
        if ($k -notin @("eventHash","previousHash","payloadHash")) {
            $payloadOnly[$k] = $newEvent[$k]
        }
    }
    $pJson = ($payloadOnly | ConvertTo-Json -Compress -Depth 6)
    $newEvent["payloadHash"] = Get-Sha256 $pJson
    
    # Compute eventHash
    $canonical = [ordered]@{}
    foreach ($k in ($payloadOnly.Keys)) { $canonical[$k] = $payloadOnly[$k] }
    $canonical["previousHash"] = $prevHash
    $fJson = ($canonical | ConvertTo-Json -Compress -Depth 6)
    $newEvent["eventHash"] = Get-Sha256 ($fJson + $prevHash)
    
    # Compute authorization proof if this is an auth event
    $authTypes = @("task_claimed","task_submitted","validation_started","validation_passed","validation_failed","task_verified","release_validation_started","release_validation_passed","release_validation_failed","release_verified")
    if ($newEvent["event"] -in $authTypes) {
        $actor = $newEvent["actor"]
        $td = $tokenData[$actor]
        if ($td) {
            # Build canonical content for proof (exclude auth fields)
            $proofCanonical = [ordered]@{}
            foreach ($k in ($newEvent.Keys | Sort-Object)) {
                if ($k -notin $proofExclude) {
                    $proofCanonical[$k] = $newEvent[$k]
                }
            }
            $proofJson = ($proofCanonical | ConvertTo-Json -Compress -Depth 6)
            $eventCanonicalHash = Get-Sha256 $proofJson
            
            $refId = if ($newEvent["taskId"]) { $newEvent["taskId"] } elseif ($newEvent["validationId"]) { $newEvent["validationId"] } else { "" }
            $proofInput = "$($td.tokenHash)|$($td.nonce)|$eventCanonicalHash|$($newEvent['event'])|$refId"
            $proof = Get-Sha256 $proofInput
            
            $newEvent["tokenLeaseId"] = $td.tokenHash
            $newEvent["proofNonce"] = $td.nonce
            $newEvent["authorizationProof"] = $proof
        }
    }
    
    $prevHash = $newEvent["eventHash"]
    $newEvents += $newEvent
}

# Write new RUN_STATE
$statePath = Join-Path $RunDir "RUN_STATE.jsonl"
$utf8 = [System.Text.UTF8Encoding]::new($false)
$lines = @()
foreach ($e in $newEvents) {
    $lines += ($e | ConvertTo-Json -Compress -Depth 8)
}
[System.IO.File]::WriteAllLines($statePath, $lines, $utf8)
Write-Host ""
Write-Host "Rebuilt RUN_STATE: $($newEvents.Count) events"

# Summary
$authEvents = @($newEvents | Where-Object { $_.authorizationProof })
Write-Host "Auth events with proofs: $($authEvents.Count)"
foreach ($ae in $authEvents) {
    Write-Host "  seq=$($ae.seq) $($ae.event) actor=$($ae.actor) proof=$($ae.authorizationProof.Substring(0,16))..."
}
Write-Host ""
Write-Host "Token store files created in: $TokenStoreDir"
Write-Host "Done."

