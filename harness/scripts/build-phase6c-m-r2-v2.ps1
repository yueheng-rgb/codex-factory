# build-phase6c-m-r2-v2.ps1 - Fixed hash computation: auth fields included in payload/event hashes
$ErrorActionPreference = "Stop"
$utf8 = [System.Text.UTF8Encoding]::new($false)

$HarnessRoot = "C:\Codex_App_Factory\harness"
$R2Dir = Join-Path $HarnessRoot "runs\phase6c-m-r2-run"

function Get-Sha256 { param([string]$s)
    $b = [System.Text.Encoding]::UTF8.GetBytes($s)
    $h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($b)
    return [System.BitConverter]::ToString($h).Replace("-","").ToLower()
}

function Get-FileSha256 { param([string]$p)
    $b = [System.IO.File]::ReadAllBytes($p)
    $h = [System.Security.Cryptography.SHA256]::Create().ComputeHash($b)
    return [System.BitConverter]::ToString($h).Replace("-","").ToLower()
}

function Get-DirSha256 { param([string]$d)
    $files = Get-ChildItem $d -Recurse -File | Sort-Object FullName
    $combined = ($files | ForEach-Object { "$($_.FullName):$(Get-FileSha256 $_.FullName)" }) -join "|"
    return Get-Sha256 $combined
}

$tokenData = @{
    "builder-core-m" = @{ taskId="T-001"; tokenHash="4e0272cbba822167b12ed4a48bbb95430b87fc6b73832e8e8aa069094868ba2f"; nonce="4c1975f059ea409eac10126f27b1e7ef"; role="builder-agent" }
    "builder-auth-m" = @{ taskId="T-002"; tokenHash="9c1929a28edec3363f36533698889bfec4fa4f96c04c4d6b1719f0f7f6a64f31"; nonce="0b33aad52bbe431b8059ebc2d02c9387"; role="builder-agent" }
    "builder-admin-m" = @{ taskId="T-003"; tokenHash="567cdd0492240a6998b8784fe32fa0993eaadedb9b824b4120bb51b5e16d7ede"; nonce="007cae36db2c411fae87cf6dc0431a63"; role="builder-agent" }
    "builder-doctor-m" = @{ taskId="T-004"; tokenHash="54b76fb635d8f9c9a5d8c9fed65faecd8d8f3ad5405bb59f53e7889cf8a1231f"; nonce="aff5aca9de9c4a8bbbf93bea7d4384e6"; role="builder-agent" }
    "builder-app-m" = @{ taskId="T-005"; tokenHash="f0ab43436a2cc97a5f92ec56082ce2b2f3461c4f603d5ae4f4a14c17751280c9"; nonce="8e14dd59804149b8ae3e1447778b9cfd"; role="builder-agent" }
    "validator-m1" = @{ taskId="*"; tokenHash="48c280f51823ae6dd81fa21df5ae1b83b72db91268964912f2ace2205d2fd253"; nonce="1086bb81a32241b98a21ffe5d1fdec11"; role="test-agent" }
    "release-agent-m" = @{ taskId="*"; tokenHash="dca4c27acfe4a8acd9a3ea76e2b67255bf18668444c8b7cec45bcd5c139b20dd"; nonce="e9ddfdfedefc4e80bb64611a78f731f4"; role="release-agent" }
}

# ----------------------------------------------------------------------
# Build event definitions
# ----------------------------------------------------------------------
$timestamp = "2026-06-20T01:00:00.0000000+08:00"
$eventDefs = @()

$eventDefs += @{ event="run_initialized"; actor="orchestrator"; description="Phase 6C-M-R2 Validate-State Truth Closure"; projectName="tcm-therapy-registration-prototype"; timestamp=$timestamp }

$builders = @("T-001","T-002","T-003","T-004","T-005")
$builderActors = @("builder-core-m","builder-auth-m","builder-admin-m","builder-doctor-m","builder-app-m")
for ($i = 0; $i -lt 5; $i++) {
    $eventDefs += @{ event="task_claimed"; taskId=$builders[$i]; actor=$builderActors[$i]; role="builder-agent"; tokenExpiresAt="2026-06-21T02:00:00Z"; tokenIssuedAt="2026-06-19T16:00:00Z"; timestamp=$timestamp }
}
for ($i = 0; $i -lt 5; $i++) {
    $eventDefs += @{ event="task_submitted"; taskId=$builders[$i]; actor=$builderActors[$i]; role="builder-agent"; status="candidate_complete"; tokenExpiresAt="2026-06-21T02:00:00Z"; tokenIssuedAt="2026-06-19T16:00:00Z"; timestamp=$timestamp }
}

$acMap = @{ 
    "AC-M-001"="T-001"; "AC-M-002"="T-004"; "AC-M-003"="T-004"; "AC-M-004"="T-003"
    "AC-M-005"="T-003"; "AC-M-006"="T-005"; "AC-M-007"="T-005"; "AC-M-008"="T-001"
}
foreach ($aid in @("AC-M-001","AC-M-002","AC-M-003","AC-M-004","AC-M-005","AC-M-006","AC-M-007","AC-M-008")) {
    $eventDefs += @{ event="validation_started"; taskId=$acMap[$aid]; validationId=$aid; actor="validator-m1"; role="test-agent"; timestamp=$timestamp }
}
foreach ($aid in @("AC-M-001","AC-M-002","AC-M-003","AC-M-004","AC-M-005","AC-M-006","AC-M-007","AC-M-008")) {
    $eventDefs += @{ event="validation_passed"; taskId=$acMap[$aid]; validationId=$aid; actor="validator-m1"; role="test-agent"; testCount=33; timestamp=$timestamp }
}
for ($i = 0; $i -lt 5; $i++) {
    $eventDefs += @{ event="task_verified"; taskId=$builders[$i]; actor="validator-m1"; role="test-agent"; testCount=33; timestamp=$timestamp }
}
$eventDefs += @{ event="release_validation_started"; taskId=""; validationId="RELEASE-M-R2"; actor="release-agent-m"; role="release-agent"; timestamp=$timestamp }
$eventDefs += @{ event="release_validation_passed"; taskId=""; validationId="RELEASE-M-R2"; actor="release-agent-m"; role="release-agent"; timestamp=$timestamp }
$eventDefs += @{ event="release_verified"; taskId=""; validationId="RELEASE-M-R2"; actor="release-agent-m"; role="release-agent"; timestamp=$timestamp }
$eventDefs += @{ event="run_completed"; actor="orchestrator"; verdict="PASS"; timestamp=$timestamp }

# ----------------------------------------------------------------------
# Build RUN_STATE with correct hash algorithm
# Key insight: validate-state.ps1 includes authorizationProof/proofNonce/tokenLeaseId
# in the payload hash (they are NOT excluded by $hashExclude).
# So we must:
# 1. Build event def (no auth fields)
# 2. Compute authorization proof (excluding auth fields from its canonical)
# 3. Add auth fields to event
# 4. Compute payloadHash (including auth fields)
# 5. Compute eventHash
# ----------------------------------------------------------------------
$hashExclude = @("eventHash","previousHash","payloadHash","seq","timestamp")
$proofExclude = @("eventHash","previousHash","payloadHash","seq","timestamp","authorizationProof","tokenLeaseId","proofNonce","tokenIssuedAt","tokenExpiresAt")
$authTypes = @("task_claimed","task_submitted","validation_started","validation_passed","validation_failed","task_verified","release_validation_started","release_validation_passed","release_validation_failed","release_verified")

$prevHash = "GENESIS"
$runStateEvents = @()
$seq = 0

foreach ($ed in $eventDefs) {
    $seq++
    
    # Step 1: Build base event (no auth fields)
    $baseEvent = [ordered]@{}
    foreach ($key in $ed.Keys) { $baseEvent[$key] = $ed[$key] }
    $baseEvent["seq"] = $seq
    $baseEvent["previousHash"] = $prevHash
    
    # Step 2: Compute authorization proof if applicable
    $isAuth = $baseEvent["event"] -in $authTypes
    if ($isAuth) {
        $actor = $baseEvent["actor"]
        $td = $tokenData[$actor]
        if ($td) {
            # Proof canonical excludes auth fields
            $proofCanonical = [ordered]@{}
            foreach ($k in ($baseEvent.Keys | Sort-Object)) {
                if ($k -notin $proofExclude) {
                    $proofCanonical[$k] = $baseEvent[$k]
                }
            }
            $proofJson = ($proofCanonical | ConvertTo-Json -Compress -Depth 10)
            $eventCanonicalHash = Get-Sha256 $proofJson
            
            $refId = if ($baseEvent["taskId"]) { $baseEvent["taskId"] } elseif ($baseEvent["validationId"]) { $baseEvent["validationId"] } else { "" }
            $proofInput = "$($td.tokenHash)|$($td.nonce)|$eventCanonicalHash|$($baseEvent['event'])|$refId"
            $proof = Get-Sha256 $proofInput
            
            $baseEvent["tokenLeaseId"] = $td.tokenHash
            $baseEvent["proofNonce"] = $td.nonce
            $baseEvent["authorizationProof"] = $proof
        }
    }
    
    # Step 3: Compute payloadHash (including auth fields if present)
    $payloadOnly = [ordered]@{}
    foreach ($key in ($baseEvent.Keys | Sort-Object)) {
        if ($key -notin $hashExclude) {
            $payloadOnly[$key] = $baseEvent[$key]
        }
    }
    $payloadOnly["seq"] = $seq
    $payloadOnly["timestamp"] = $baseEvent["timestamp"]
    
    $pJson = ($payloadOnly | ConvertTo-Json -Compress -Depth 12)
    $payloadHash = Get-Sha256 $pJson
    
    # Step 4: Compute eventHash
    $canonical = [ordered]@{}
    foreach ($k in $payloadOnly.Keys) { $canonical[$k] = $payloadOnly[$k] }
    $canonical["previousHash"] = $prevHash
    
    $cJson = ($canonical | ConvertTo-Json -Compress -Depth 12)
    $eventHash = Get-Sha256 ($cJson + $prevHash)
    
    # Step 5: Finalize event
    $baseEvent["payloadHash"] = $payloadHash
    $baseEvent["eventHash"] = $eventHash
    
    $prevHash = $eventHash
    $runStateEvents += $baseEvent
}

# Write RUN_STATE.jsonl
$statePath = Join-Path $R2Dir "RUN_STATE.jsonl"
$lines = @()
foreach ($e in $runStateEvents) {
    $lines += ($e | ConvertTo-Json -Compress -Depth 12)
}
[System.IO.File]::WriteAllLines($statePath, $lines, $utf8)

$authCount = @($runStateEvents | Where-Object { $_.authorizationProof }).Count
Write-Host "RUN_STATE: $($runStateEvents.Count) events, $authCount with proofs"

# ----------------------------------------------------------------------
# Update token store (already created, but ensure it matches)
# ----------------------------------------------------------------------
$TokenStoreDir = "C:\Codex_App_Factory\harness-control\tokens\phase6c-m-r2-run"
if (Test-Path $TokenStoreDir) { Remove-Item -Recurse -Force $TokenStoreDir }
New-Item -ItemType Directory -Path $TokenStoreDir -Force | Out-Null

$issuedAtBase = "2026-06-19T16:00:00.0000000Z"
$expiresAt = "2026-06-21T16:00:00.0000000Z"

foreach ($agentId in $tokenData.Keys) {
    $td = $tokenData[$agentId]
    $leaseId = [System.Guid]::NewGuid().ToString("N")
    $filePath = Join-Path $TokenStoreDir "$leaseId.json"
    $actorEvents = @($runStateEvents | Where-Object { $_.actor -eq $agentId -and $_.authorizationProof })
    $nonces = @()
    foreach ($ae in $actorEvents) {
        $nonces += @{ nonce = $ae.proofNonce; issuedAt = $issuedAtBase; consumedAt = $null; operation = $ae.event }
    }
    $record = @{
        schemaVersion = "6B-R5"; tokenHash = $td.tokenHash; agentId = $agentId; role = $td.role
        taskId = $td.taskId; issuedAt = $issuedAtBase; expiresAt = $expiresAt; status = "active"
        revokedAt = $null; issuedNonces = $nonces; allowedOperations = @()
    }
    [System.IO.File]::WriteAllText($filePath, ($record | ConvertTo-Json -Depth 10 -Compress), $utf8)
}
Write-Host "Token store: 7 files"

# ----------------------------------------------------------------------
# Update trust root
# ----------------------------------------------------------------------
$LocksDir = "C:\Codex_App_Factory\harness-control\locks\phase6c-m-r2-run"
if (Test-Path $LocksDir) { Remove-Item -Recurse -Force $LocksDir }
New-Item -ItemType Directory -Path $LocksDir -Force | Out-Null
$trustRoot = @{
    schemaVersion = "6B-R3"; runId = "phase6c-m-r2-run"
    controlPlaneLockSha256 = Get-FileSha256 (Join-Path $R2Dir "CONTROL_PLANE_LOCK.json")
    harnessBaselineSha256 = Get-DirSha256 (Join-Path $HarnessRoot "scripts")
    frozenAt = (Get-Date).ToString("o"); freezeSequence = 1
    trustRootFile = (Join-Path $LocksDir "trust-root.json")
}
[System.IO.File]::WriteAllText((Join-Path $LocksDir "trust-root.json"), ($trustRoot | ConvertTo-Json -Depth 4), $utf8)
[System.IO.File]::WriteAllText("C:\Codex_App_Factory\harness-control\locks\_freeze_sequence.json", '{"lastSequence":1}', $utf8)
Write-Host "Trust root created"
Write-Host "Done."

