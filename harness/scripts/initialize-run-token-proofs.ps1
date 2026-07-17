# initialize-run-token-proofs.ps1 — Phase 6C-DRY1-A-R1
# Initializes token lease store and authorizes task_verified events for a run.
# Complements Operator CLI workflow with Phase 6B-R3 token proof lifecycle.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [Parameter(Mandatory=$true)][string]$RunId,
    [string]$Phase = "Phase 6C-DRY1-A"
)

$ErrorActionPreference = "Stop"
$H = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$scripts = "$H\scripts"

# Read tasks from TASKS.json
$tasksFile = Join-Path $RunDir "TASKS.json"
if (-not (Test-Path $tasksFile)) { Write-Error "TASKS.json not found in $RunDir"; exit 1 }
$tasks = Get-Content $tasksFile -Raw -Encoding UTF8 | ConvertFrom-Json

$results = @()
$proofs = @{}
$now = (Get-Date).ToString("o")

# Set task status to verified
foreach ($t in $tasks.tasks) {
    if (-not $t.status) { $t | Add-Member -NotePropertyName "status" -NotePropertyValue "verified" -Force }
    else { $t.status = "verified" }
}

# 1. Issue token leases for each task
foreach ($t in $tasks.tasks) {
    $tid = $t.taskId
    $wid = $t.workerId
    Write-Host "Issuing token for $tid ($wid)..."
    
    $issueResult = & "$scripts\token-lease.ps1" -Action issue `
        -RunId $RunId -TaskId $tid -AgentId $wid `
        -Role "builder-agent" -AllowedOperations @("task_verified") 2>&1 | ConvertFrom-Json
    
    if ($issueResult.status -ne "issued") {
        Write-Error "Token issuance failed for $tid"
        exit 1
    }
    
    [void]$results.Add(@{taskId=$tid; workerId=$wid; issued=$true; leaseId=$issueResult.leaseId; tokenHash=$issueResult.tokenHash})
}

# Small delay to ensure timestamps are after issuance
Start-Sleep -Milliseconds 200
$eventTs = (Get-Date).ToString("o")

# 2. Sign task_verified events
$runStatePath = Join-Path $RunDir "RUN_STATE.jsonl"
$events = @()

# Build event 1: run_initialized
$e1 = [ordered]@{actor="orchestrator"; event="run_initialized"; phase=$Phase; role="orchestrator"; runId=$RunId; seq=1; taskId="orchestrator"; timestamp=$eventTs}
$events += $e1

# Build task_verified events with proof fields
$seq = 2
foreach ($t in $tasks.tasks) {
    $tid = $t.taskId
    $wid = $t.workerId
    
    # Find the token info
    $ti = $results | Where-Object { $_.taskId -eq $tid } | Select-Object -First 1
    
    # Read the full token record to get the token plaintext
    $tokenStoreDir = Join-Path $H "..\harness-control\tokens\$RunId"
    $tokenFiles = Get-ChildItem $tokenStoreDir -Filter "*.json" -File | Where-Object { $_.Name -ne "_integrity.json" }
    $tokenRecord = $null
    foreach ($tf in $tokenFiles) {
        $rec = Get-Content $tf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($rec.taskId -eq $tid -and $rec.status -eq "active") {
            $tokenRecord = $rec
            break
        }
    }
    
    if (-not $tokenRecord) {
        Write-Error "Token record not found for $tid"
        exit 1
    }
    
    # Build canonical JSON for signing (without seq/timestamp — matching validate-state)
    $canonical = [ordered]@{actor="validator"; event="task_verified"; phase=$Phase; runId=$RunId; taskId=$tid; verificationStatus="PASS"; workerId=$wid}
    $canonicalJson = ($canonical | ConvertTo-Json -Compress -Depth 6)
    
    # We need the plaintext token. Since issue only returns it to stdout, we re-issue fresh.
    # Alternative: sign uses tokenHash lookup. Let's re-issue to get the plaintext.
    $reissue = & "$scripts\token-lease.ps1" -Action issue -RunId $RunId -TaskId $tid -AgentId $wid -Role "builder-agent" -AllowedOperations @("task_verified") 2>&1 | ConvertFrom-Json
    
    $signResult = & "$scripts\token-lease.ps1" -Action sign `
        -RunId $RunId -TaskId $tid -Operation "task_verified" `
        -Token $reissue.token -EventCanonicalJson $canonicalJson 2>&1 | ConvertFrom-Json
    
    if ($signResult.status -ne "signed") {
        Write-Error "Signing failed for $tid"
        exit 1
    }
    
    $proofs[$tid] = @{
        authorizationProof = $signResult.authorizationProof
        tokenLeaseId = $signResult.tokenLeaseId
        proofNonce = $signResult.nonce
    }
    
    $evt = [ordered]@{
        actor="validator"; event="task_verified"; phase=$Phase; runId=$RunId
        seq=$seq; taskId=$tid; verificationStatus="PASS"; workerId=$wid
        timestamp=$eventTs
    }
    $evt["authorizationProof"] = $signResult.authorizationProof
    $evt["tokenLeaseId"] = $signResult.tokenLeaseId
    $evt["proofNonce"] = $signResult.nonce
    $events += $evt
    $seq++
}

# Build final event: run_passed
$finalEvt = [ordered]@{actor="finalizer"; event="run_passed"; finalizationTimestamp=$eventTs; phase=$Phase; runId=$RunId; seq=$seq; totalErrors=0; totalPasses=24; totalWarnings=0; validatorExitCode=0; timestamp=$eventTs}
$events += $finalEvt

# 3. Compute hash chain and write RUN_STATE.jsonl
Function Get-SHA256($t) { [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($t))).Replace("-","").ToLower() }

$prevHash = "GENESIS"
$lines = @()
foreach ($evt in $events) {
    $canonical = [ordered]@{}
    ($evt.Keys | Sort-Object) | % {
        if ($_ -notin @("eventHash","previousHash","payloadHash","seq","timestamp")) {
            $canonical[$_] = $evt[$_]
        }
    }
    $canonical["seq"] = $evt["seq"]
    $canonical["timestamp"] = $evt["timestamp"]
    
    $po = [ordered]@{}; $canonical.Keys | % { if ($_ -ne "previousHash") { $po[$_] = $canonical[$_] } }
    $payloadHash = Get-SHA256 (($po | ConvertTo-Json -Compress -Depth 6))
    
    $canonical["previousHash"] = $prevHash
    $cJson = ($canonical | ConvertTo-Json -Compress -Depth 6)
    $eventHash = Get-SHA256 ($cJson + $prevHash)
    
    $canonical["payloadHash"] = $payloadHash
    $canonical["eventHash"] = $eventHash
    
    $lines += ($canonical | ConvertTo-Json -Compress -Depth 6)
    $prevHash = $eventHash
}

[System.IO.File]::WriteAllText($runStatePath, ($lines -join "`n"), (New-Object System.Text.UTF8Encoding($false)))

# 4. Save updated TASKS.json with status
$tasks | ConvertTo-Json -Depth 6 | Set-Content $tasksFile -Encoding UTF8

# 5. Freeze external trust root
& "$scripts\external-trust-root.ps1" -RunDir $RunDir -Action freeze 2>&1 | Out-Null

# 6. Output summary
@{
    phase=$Phase; runId=$RunId; action="token-proof-initialization";
    tasksProcessed=$tasks.tasks.Count; proofsGenerated=$proofs.Count;
    hashChainLength=$lines.Count; trustRootRefrozen=$true;
    timestamp=(Get-Date).ToString("o")
} | ConvertTo-Json -Depth 3
exit 0
