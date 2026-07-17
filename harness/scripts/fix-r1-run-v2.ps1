# fix-r1-run-v2.ps1 - Complete fix: hash ordering + token timestamps + trust root
$ErrorActionPreference = "Stop"
$RunDir = "C:\Codex_App_Factory\harness\runs\phase6c-m-r1-run"
$HarnessRoot = "C:\Codex_App_Factory\harness"
$TokenStoreDir = "C:\Codex_App_Factory\harness-control\tokens\phase6c-m-r1-run"
$LocksDir = "C:\Codex_App_Factory\harness-control\locks\phase6c-m-r1-run"

# Ensure clean directories
if (Test-Path $TokenStoreDir) { Remove-Item -Recurse -Force $TokenStoreDir }
New-Item -ItemType Directory -Path $TokenStoreDir -Force | Out-Null
if (Test-Path $LocksDir) { Remove-Item -Recurse -Force $LocksDir }
New-Item -ItemType Directory -Path $LocksDir -Force | Out-Null

function Get-Sha256 { param([string]$s)
    $b = [System.Text.Encoding]::UTF8.GetBytes($s)
    $h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($b)
    return [System.BitConverter]::ToString($h).Replace("-","").ToLower()
}

function Get-FileSha256 { param([string]$Path)
    $b = [System.IO.File]::ReadAllBytes($Path)
    $h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($b)
    return [System.BitConverter]::ToString($h).Replace("-","").ToLower()
}

function Get-DirSha256 { param([string]$Dir)
    $files = Get-ChildItem $Dir -Recurse -File | Sort-Object FullName
    $combined = ($files | ForEach-Object {
        $hash = Get-FileSha256 $_.FullName
        "$($_.FullName):$hash"
    }) -join "|"
    return Get-Sha256 $combined
}

# Read existing events to get definitions
$oldLines = Get-Content (Join-Path $RunDir "RUN_STATE.jsonl") -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 }
$eventDefs = @()
foreach ($line in $oldLines) {
    $eventDefs += ($line | ConvertFrom-Json)
}

# --- Token data ---
$tokenData = @{
    "builder-core-m" = @{ taskId="T-001"; tokenHash="4e0272cbba822167b12ed4a48bbb95430b87fc6b73832e8e8aa069094868ba2f"; nonce="4c1975f059ea409eac10126f27b1e7ef"; role="builder-agent" }
    "builder-auth-m" = @{ taskId="T-002"; tokenHash="9c1929a28edec3363f36533698889bfec4fa4f96c04c4d6b1719f0f7f6a64f31"; nonce="0b33aad52bbe431b8059ebc2d02c9387"; role="builder-agent" }
    "builder-admin-m" = @{ taskId="T-003"; tokenHash="567cdd0492240a6998b8784fe32fa0993eaadedb9b824b4120bb51b5e16d7ede"; nonce="007cae36db2c411fae87cf6dc0431a63"; role="builder-agent" }
    "builder-doctor-m" = @{ taskId="T-004"; tokenHash="54b76fb635d8f9c9a5d8c9fed65faecd8d8f3ad5405bb59f53e7889cf8a1231f"; nonce="aff5aca9de9c4a8bbbf93bea7d4384e6"; role="builder-agent" }
    "builder-app-m" = @{ taskId="T-005"; tokenHash="f0ab43436a2cc97a5f92ec56082ce2b2f3461c4f603d5ae4f4a14c17751280c9"; nonce="8e14dd59804149b8ae3e1447778b9cfd"; role="builder-agent" }
    "validator-m1" = @{ taskId="*"; tokenHash="48c280f51823ae6dd81fa21df5ae1b83b72db91268964912f2ace2205d2fd253"; nonce="1086bb81a32241b98a21ffe5d1fdec11"; role="test-agent" }
    "release-agent-m" = @{ taskId="*"; tokenHash="dca4c27acfe4a8acd9a3ea76e2b67255bf18668444c8b7cec45bcd5c139b20dd"; nonce="e9ddfdfedefc4e80bb64611a78f731f4"; role="release-agent" }
}

# Token store: use a timestamp BEFORE all event timestamps (events are at 2026-06-20T00:34:53+08:00)
$issuedAtBase = "2026-06-19T16:00:00.0000000Z"
$expiresAt = "2026-06-21T16:00:00.0000000Z"

# Create token store files
foreach ($agentId in $tokenData.Keys) {
    $td = $tokenData[$agentId]
    $leaseId = [System.Guid]::NewGuid().ToString("N")
    $filePath = Join-Path $TokenStoreDir "$leaseId.json"

    $actorEvents = @($eventDefs | Where-Object { $_.actor -eq $agentId -and $_.proofNonce })
    $nonces = @()
    foreach ($ae in $actorEvents) {
        $nonces += @{ nonce = $ae.proofNonce; issuedAt = $issuedAtBase; consumedAt = $null; operation = $ae.event }
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
    $json = $record | ConvertTo-Json -Depth 10 -Compress
    [System.IO.File]::WriteAllText($filePath, $json, $utf8)
    Write-Host "Token: $agentId -> $filePath ($($nonces.Count) nonces)"
}

# --- Rebuild RUN_STATE with exact PS-compatible hash chain ---
# Validate-state algorithm:
# - Exclude for payload: eventHash, previousHash, payloadHash, seq, timestamp
# - Sort remaining keys, THEN append seq, timestamp (in that order)
# - payloadHash = SHA256(JSON of payloadOnly) where payloadOnly is sorted fields + seq + timestamp
# - canonical = payloadOnly fields (sorted) + seq + timestamp + previousHash
# - eventHash = SHA256(JSON of canonical + previousHash value)

$hashExclude = @("eventHash","previousHash","payloadHash","seq","timestamp")
$proofExclude = @("eventHash","previousHash","payloadHash","seq","timestamp","authorizationProof","tokenLeaseId","proofNonce","tokenIssuedAt","tokenExpiresAt")
$authTypes = @("task_claimed","task_submitted","validation_started","validation_passed","validation_failed","task_verified","release_validation_started","release_validation_passed","release_validation_failed","release_verified")

$prevHash = "GENESIS"
$newEvents = @()
$seq = 0

foreach ($ed in $eventDefs) {
    $seq++
    
    # Build payloadOnly: sorted fields + seq + timestamp (MATCHING validate-state)
    $payloadOnly = [ordered]@{}
    foreach ($key in ($ed.PSObject.Properties.Name | Sort-Object)) {
        if ($key -notin $hashExclude) {
            $payloadOnly[$key] = $ed.$key
        }
    }
    $payloadOnly["seq"] = $seq
    $payloadOnly["timestamp"] = $ed.timestamp
    # Ensure timestamp from original event is preserved
    
    $pJson = ($payloadOnly | ConvertTo-Json -Compress -Depth 6)
    $payloadHash = Get-Sha256 $pJson
    
    # Build canonical: payloadOnly fields + previousHash (MATCHING validate-state)
    $canonical = [ordered]@{}
    foreach ($k in $payloadOnly.Keys) { $canonical[$k] = $payloadOnly[$k] }
    $canonical["previousHash"] = $prevHash
    
    $cJson = ($canonical | ConvertTo-Json -Compress -Depth 6)
    $eventHash = Get-Sha256 ($cJson + $prevHash)
    
    # Build the full event
    $newEvent = [ordered]@{}
    foreach ($key in ($ed.PSObject.Properties.Name | Sort-Object)) {
        if ($key -notin @("eventHash","previousHash","payloadHash","seq","timestamp","authorizationProof","tokenLeaseId","proofNonce")) {
            $newEvent[$key] = $ed.$key
        }
    }
    $newEvent["seq"] = $seq
    $newEvent["timestamp"] = $ed.timestamp
    $newEvent["previousHash"] = $prevHash
    $newEvent["payloadHash"] = $payloadHash
    $newEvent["eventHash"] = $eventHash
    
    # Authorization proof
    if ($newEvent["event"] -in $authTypes) {
        $actor = $newEvent["actor"].ToString()
        $td = $tokenData[$actor]
        if ($td) {
            # Build proof canonical (sorted, excluding proof fields)
            $proofCanonical = [ordered]@{}
            foreach ($k in ($newEvent.Keys | Sort-Object)) {
                if ($k -notin $proofExclude) {
                    $proofCanonical[$k] = $newEvent[$k]
                }
            }
            $proofJson = ($proofCanonical | ConvertTo-Json -Compress -Depth 6)
            $eventCanonicalHash = Get-Sha256 $proofJson
            
            $refId = if ($newEvent["taskId"]) { $newEvent["taskId"].ToString() } elseif ($newEvent["validationId"]) { $newEvent["validationId"].ToString() } else { "" }
            $proofInput = "$($td.tokenHash)|$($td.nonce)|$eventCanonicalHash|$($newEvent['event'])|$refId"
            $proof = Get-Sha256 $proofInput
            
            $newEvent["tokenLeaseId"] = $td.tokenHash
            $newEvent["proofNonce"] = $td.nonce
            $newEvent["authorizationProof"] = $proof
        }
    }
    
    $prevHash = $eventHash
    $newEvents += $newEvent
}

# Write new RUN_STATE
$statePath = Join-Path $RunDir "RUN_STATE.jsonl"
$utf8 = [System.Text.UTF8Encoding]::new($false)
$lines = @()
foreach ($e in $newEvents) {
    $lines += ($e | ConvertTo-Json -Compress -Depth 10)
}
[System.IO.File]::WriteAllLines($statePath, $lines, $utf8)
Write-Host "RUN_STATE rebuilt: $($newEvents.Count) events"

# --- Create external trust root ---
$cpLockPath = Join-Path $RunDir "CONTROL_PLANE_LOCK.json"
$cpLockSha = Get-FileSha256 $cpLockPath
$scriptsSha = Get-DirSha256 (Join-Path $HarnessRoot "scripts")

$trustRootFile = Join-Path $LocksDir "trust-root.json"
$trustRoot = @{
    schemaVersion = "6B-R3"
    runId = "phase6c-m-r1-run"
    controlPlaneLockSha256 = $cpLockSha
    harnessBaselineSha256 = $scriptsSha
    frozenAt = (Get-Date).ToString("o")
    freezeSequence = 1
    trustRootFile = $trustRootFile
}
$utf8 = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($trustRootFile, ($trustRoot | ConvertTo-Json -Depth 4), $utf8)
Write-Host "Trust root created: $trustRootFile"
Write-Host "  cpLockSha: $cpLockSha"
Write-Host "  scriptsSha: $scriptsSha"

# Also write _freeze_sequence.json
$seqFile = Join-Path "C:\Codex_App_Factory\harness-control\locks" "_freeze_sequence.json"
$seqData = @{ lastSequence = 1 }
[System.IO.File]::WriteAllText($seqFile, ($seqData | ConvertTo-Json -Compress), $utf8)
Write-Host "Freeze sequence initialized"

# --- Summary ---
$authEvents = @($newEvents | Where-Object { $_.authorizationProof })
Write-Host ""
Write-Host "Auth events with proofs: $($authEvents.Count)"
Write-Host "Done."

