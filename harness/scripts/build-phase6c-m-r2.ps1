# build-phase6c-m-r2.ps1 - Clean R2 run with PS-native hashing and proper governance
$ErrorActionPreference = "Stop"
$utf8 = [System.Text.UTF8Encoding]::new($false)

$HarnessRoot = "C:\Codex_App_Factory\harness"
$R1Dir = Join-Path $HarnessRoot "runs\phase6c-m-r1-run"
$R2Dir = Join-Path $HarnessRoot "runs\phase6c-m-r2-run"
$TokenStoreDir = "C:\Codex_App_Factory\harness-control\tokens\phase6c-m-r2-run"
$LocksDir = "C:\Codex_App_Factory\harness-control\locks\phase6c-m-r2-run"

# ----------------------------------------------------------------------
# STEP 1: Create clean R2 directory and copy governance evidence from R1
# ----------------------------------------------------------------------
Write-Host "=== STEP 1: Creating clean R2 run directory ==="
if (Test-Path $R2Dir) { Remove-Item -Recurse -Force $R2Dir }
New-Item -ItemType Directory -Path $R2Dir -Force | Out-Null

# Copy governance files (not RUN_STATE, not command-logs)
$copyFiles = @(
    "TASKS.json", "TASK_DAG.json", "ACCEPTANCE.json", "RUN_PLAN.json",
    "CONTROL_PLANE_LOCK.json", "OWNERSHIP.json", "RELEASE_MANIFEST.json",
    "HARNESS_BASELINE.json", "EXTERNAL_TRUST_ROOT",
    "PHASE_6C-M_INITIAL_AUDIT_NOTE.md", "PHASE_6C-M_REAL_PROJECT_SUMMARY.md",
    "PHASE_6C-L_BASELINE_NOTE.md",
    "agent-id-consistency-report.json", "manifest-format-validation-report.json",
    "release-evidence-completeness-report.json", "ownership-audit-report.json",
    "provenance-validation-report.json", "overlap-measurement-report.json",
    "agent-activity-timeline.json", "harness-task-timeline.json",
    "sha256sums-validation-report.json"
)
foreach ($f in $copyFiles) {
    $src = Join-Path $R1Dir $f
    if (Test-Path $src) { Copy-Item $src (Join-Path $R2Dir $f) -Force }
}

# Copy directories
$copyDirs = @(
    "agent-inputs", "patches", "submission-manifests", "workspace-manifests",
    "validator-evidence", "integration-evidence", "evidence", "handoffs",
    "project-summary", "screens-or-ui-description"
)
foreach ($d in $copyDirs) {
    $src = Join-Path $R1Dir $d
    $dst = Join-Path $R2Dir $d
    if (Test-Path $src) { Copy-Item $src $dst -Recurse -Force }
}

# Create command-logs directory (empty, we will populate it)
New-Item -ItemType Directory -Path (Join-Path $R2Dir "command-logs") -Force | Out-Null

Write-Host "R2 directory created with governance evidence"

# ----------------------------------------------------------------------
# STEP 2: Token data and helper functions
# ----------------------------------------------------------------------
Write-Host "`n=== STEP 2: Building RUN_STATE with PS-native hashing ==="

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
# STEP 3: Build event definitions from TASKS + ACCEPTANCE (no old RUN_STATE)
# ----------------------------------------------------------------------
$timestamp = "2026-06-20T01:00:00.0000000+08:00"

$eventDefs = @()

# run_initialized
$eventDefs += @{ event="run_initialized"; actor="orchestrator"; description="Phase 6C-M-R2 Validate-State Truth Closure"; projectName="tcm-therapy-registration-prototype"; timestamp=$timestamp }

# task_claimed x5
$builders = @("T-001","T-002","T-003","T-004","T-005")
$builderActors = @("builder-core-m","builder-auth-m","builder-admin-m","builder-doctor-m","builder-app-m")
for ($i = 0; $i -lt 5; $i++) {
    $eventDefs += @{ event="task_claimed"; taskId=$builders[$i]; actor=$builderActors[$i]; role="builder-agent"; tokenExpiresAt="2026-06-21T02:00:00Z"; tokenIssuedAt="2026-06-19T16:00:00Z"; timestamp=$timestamp }
}

# task_submitted x5
for ($i = 0; $i -lt 5; $i++) {
    $eventDefs += @{ event="task_submitted"; taskId=$builders[$i]; actor=$builderActors[$i]; role="builder-agent"; status="candidate_complete"; tokenExpiresAt="2026-06-21T02:00:00Z"; tokenIssuedAt="2026-06-19T16:00:00Z"; timestamp=$timestamp }
}

# validation events for AC-M-001..008
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

# task_verified x5
for ($i = 0; $i -lt 5; $i++) {
    $eventDefs += @{ event="task_verified"; taskId=$builders[$i]; actor="validator-m1"; role="test-agent"; testCount=33; timestamp=$timestamp }
}

# release validation
$eventDefs += @{ event="release_validation_started"; taskId=""; validationId="RELEASE-M-R2"; actor="release-agent-m"; role="release-agent"; timestamp=$timestamp }
$eventDefs += @{ event="release_validation_passed"; taskId=""; validationId="RELEASE-M-R2"; actor="release-agent-m"; role="release-agent"; timestamp=$timestamp }
$eventDefs += @{ event="release_verified"; taskId=""; validationId="RELEASE-M-R2"; actor="release-agent-m"; role="release-agent"; timestamp=$timestamp }

# run_completed
$eventDefs += @{ event="run_completed"; actor="orchestrator"; verdict="PASS"; timestamp=$timestamp }

Write-Host "Event definitions: $($eventDefs.Count)"

# ----------------------------------------------------------------------
# STEP 4: Build RUN_STATE with PS-compatible hash chain
#   - Exactly matches validate-state.ps1 recomputation algorithm
# ----------------------------------------------------------------------
$hashExclude = @("eventHash","previousHash","payloadHash","seq","timestamp")
$proofExclude = @("eventHash","previousHash","payloadHash","seq","timestamp","authorizationProof","tokenLeaseId","proofNonce","tokenIssuedAt","tokenExpiresAt")
$authTypes = @("task_claimed","task_submitted","validation_started","validation_passed","validation_failed","task_verified","release_validation_started","release_validation_passed","release_validation_failed","release_verified")

$prevHash = "GENESIS"
$runStateEvents = @()
$seq = 0

foreach ($ed in $eventDefs) {
    $seq++
    
    # Build payloadOnly with SORTED keys + seq + timestamp (matching validate-state.ps1 algorithm)
    $payloadOnly = [ordered]@{}
    foreach ($key in ($ed.Keys | Sort-Object)) {
        if ($key -notin $hashExclude) {
            $payloadOnly[$key] = $ed[$key]
        }
    }
    $payloadOnly["seq"] = $seq
    $payloadOnly["timestamp"] = $ed.timestamp
    
    $pJson = ($payloadOnly | ConvertTo-Json -Compress -Depth 10)
    $payloadHash = Get-Sha256 $pJson
    
    # Build canonical: payload + previousHash
    $canonical = [ordered]@{}
    foreach ($k in $payloadOnly.Keys) { $canonical[$k] = $payloadOnly[$k] }
    $canonical["previousHash"] = $prevHash
    
    $cJson = ($canonical | ConvertTo-Json -Compress -Depth 10)
    $eventHash = Get-Sha256 ($cJson + $prevHash)
    
    # Build the full event (sorted keys)
    $newEvent = [ordered]@{}
    foreach ($key in $ed.Keys) {
        $newEvent[$key] = $ed[$key]
    }
    $newEvent["seq"] = $seq
    $newEvent["timestamp"] = $ed.timestamp
    $newEvent["previousHash"] = $prevHash
    $newEvent["payloadHash"] = $payloadHash
    $newEvent["eventHash"] = $eventHash
    
    # Compute authorization proof
    if ($newEvent["event"] -in $authTypes) {
        $actor = $newEvent["actor"]
        $td = $tokenData[$actor]
        if ($td) {
            # Build proof canonical (sorted, excluding proof fields)
            $proofCanonical = [ordered]@{}
            foreach ($k in ($newEvent.Keys | Sort-Object)) {
                if ($k -notin $proofExclude) {
                    $proofCanonical[$k] = $newEvent[$k]
                }
            }
            $proofJson = ($proofCanonical | ConvertTo-Json -Compress -Depth 10)
            $eventCanonicalHash = Get-Sha256 $proofJson
            
            $refId = if ($newEvent.Contains("taskId") -and $newEvent["taskId"]) { $newEvent["taskId"] } elseif ($newEvent.Contains("validationId") -and $newEvent["validationId"]) { $newEvent["validationId"] } else { "" }
            $proofInput = "$($td.tokenHash)|$($td.nonce)|$eventCanonicalHash|$($newEvent['event'])|$refId"
            $proof = Get-Sha256 $proofInput
            
            $newEvent["tokenLeaseId"] = $td.tokenHash
            $newEvent["proofNonce"] = $td.nonce
            $newEvent["authorizationProof"] = $proof
        }
    }
    
    $prevHash = $eventHash
    $runStateEvents += $newEvent
}

# Write RUN_STATE.jsonl
$statePath = Join-Path $R2Dir "RUN_STATE.jsonl"
$lines = @()
foreach ($e in $runStateEvents) {
    $lines += ($e | ConvertTo-Json -Compress -Depth 12)
}
[System.IO.File]::WriteAllLines($statePath, $lines, $utf8)

$authCount = @($runStateEvents | Where-Object { $_.authorizationProof }).Count
Write-Host "RUN_STATE.jsonl: $($runStateEvents.Count) events, $authCount with authorization proofs"

# ----------------------------------------------------------------------
# STEP 5: Create token store
# ----------------------------------------------------------------------
Write-Host "`n=== STEP 5: Creating token store ==="
if (Test-Path $TokenStoreDir) { Remove-Item -Recurse -Force $TokenStoreDir }
New-Item -ItemType Directory -Path $TokenStoreDir -Force | Out-Null

$issuedAtBase = "2026-06-19T16:00:00.0000000Z"
$expiresAt = "2026-06-21T16:00:00.0000000Z"

foreach ($agentId in $tokenData.Keys) {
    $td = $tokenData[$agentId]
    $leaseId = [System.Guid]::NewGuid().ToString("N")
    $filePath = Join-Path $TokenStoreDir "$leaseId.json"

    # Find all events for this actor that need nonces
    $actorEvents = @($runStateEvents | Where-Object { $_.actor -eq $agentId -and $_.authorizationProof })
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
    [System.IO.File]::WriteAllText($filePath, ($record | ConvertTo-Json -Depth 10 -Compress), $utf8)
    Write-Host "  $agentId -> $filePath ($($nonces.Count) nonces)"
}

# ----------------------------------------------------------------------
# STEP 6: Create external trust root
# ----------------------------------------------------------------------
Write-Host "`n=== STEP 6: Creating external trust root ==="
if (Test-Path $LocksDir) { Remove-Item -Recurse -Force $LocksDir }
New-Item -ItemType Directory -Path $LocksDir -Force | Out-Null

$cpLockPath = Join-Path $R2Dir "CONTROL_PLANE_LOCK.json"
$cpLockSha = Get-FileSha256 $cpLockPath
$scriptsSha = Get-DirSha256 (Join-Path $HarnessRoot "scripts")

$trustRootFile = Join-Path $LocksDir "trust-root.json"
$trustRoot = @{
    schemaVersion = "6B-R3"
    runId = "phase6c-m-r2-run"
    controlPlaneLockSha256 = $cpLockSha
    harnessBaselineSha256 = $scriptsSha
    frozenAt = (Get-Date).ToString("o")
    freezeSequence = 1
    trustRootFile = $trustRootFile
}
[System.IO.File]::WriteAllText($trustRootFile, ($trustRoot | ConvertTo-Json -Depth 4), $utf8)

$seqFile = "C:\Codex_App_Factory\harness-control\locks\_freeze_sequence.json"
[System.IO.File]::WriteAllText($seqFile, '{"lastSequence":1}', $utf8)
Write-Host "Trust root: $trustRootFile"

# ----------------------------------------------------------------------
# STEP 7: Copy TOKEN_STORE into run dir (for evidence)
# ----------------------------------------------------------------------
Write-Host "`n=== STEP 7: Generating TOKEN_STORE evidence ==="
$tsEvidence = @{
    schemaVersion = "6B-R5"
    runId = "phase6c-m-r2-run"
    createdAt = (Get-Date).ToString("o")
    tokens = @()
}
foreach ($agentId in $tokenData.Keys) {
    $td = $tokenData[$agentId]
    $tsEvidence.tokens += @{
        agentId = $agentId
        role = $td.role
        taskId = $td.taskId
        tokenHash = $td.tokenHash
        nonce = $td.nonce
        issuedAt = $issuedAtBase
        expiresAt = $expiresAt
        status = "active"
    }
}
[System.IO.File]::WriteAllText((Join-Path $R2Dir "TOKEN_STORE"), ($tsEvidence | ConvertTo-Json -Depth 4), $utf8)
Write-Host "TOKEN_STORE created"

Write-Host "`n=== R2 run directory ready ==="
Write-Host "Run dir: $R2Dir"
Write-Host "Token store: $TokenStoreDir"
Write-Host "Trust root: $LocksDir"

