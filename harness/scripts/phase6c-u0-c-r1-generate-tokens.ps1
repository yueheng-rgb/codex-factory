# phase6c-u0-c-r1-generate-tokens.ps1 — Phase 6C-U0-C-R1 v5
# Sign first, then include proof fields in append-hash-event for correct hash chain.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [Parameter(Mandatory=$true)][string]$RunId
)

$ErrorActionPreference = "Stop"
$HarnessRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$TokenStoreDir = Join-Path $HarnessRoot "..\harness-control\tokens\$RunId"
$TokenScript = Join-Path $HarnessRoot "scripts\token-lease.ps1"
$AppendScript = Join-Path $HarnessRoot "scripts\append-hash-event.ps1"

if (-not (Test-Path $TokenScript)) { Write-Error "token-lease.ps1 not found"; exit 1 }
if (-not (Test-Path $AppendScript)) { Write-Error "append-hash-event.ps1 not found"; exit 1 }

if (Test-Path $TokenStoreDir) { Remove-Item -Recurse -Force $TokenStoreDir }
New-Item -ItemType Directory -Path $TokenStoreDir -Force | Out-Null

$runStatePath = Join-Path $RunDir "RUN_STATE.jsonl"
$events = Get-Content $runStatePath | ForEach-Object { $_ | ConvertFrom-Json }
Write-Host "Loaded $($events.Count) events"

$ttlSeconds = 86400
$plaintextTokens = @{}

Write-Host "Issuing tokens..."
$r = & $TokenScript -Action issue -RunId $RunId -TaskId "orchestrator" -AgentId "orchestrator" -Role "orchestrator" -TtlSeconds $ttlSeconds -AllowedOperations @("run_initialized","run_passed","rework_request_created","rework_resolved"); $i=$r|ConvertFrom-Json; $plaintextTokens["orchestrator|orchestrator"]=$i.token
$r = & $TokenScript -Action issue -RunId $RunId -TaskId "T-001" -AgentId "worker-1" -Role "builder-agent" -TtlSeconds $ttlSeconds -AllowedOperations @("task_claimed","task_submitted"); $i=$r|ConvertFrom-Json; $plaintextTokens["worker-1|T-001"]=$i.token
$r = & $TokenScript -Action issue -RunId $RunId -TaskId "T-002" -AgentId "worker-2" -Role "builder-agent" -TtlSeconds $ttlSeconds -AllowedOperations @("task_claimed","task_submitted"); $i=$r|ConvertFrom-Json; $plaintextTokens["worker-2|T-002"]=$i.token
$r = & $TokenScript -Action issue -RunId $RunId -TaskId "T-001" -AgentId "validator" -Role "test-agent" -TtlSeconds $ttlSeconds -AllowedOperations @("validation_started","validation_passed","task_verified"); $i=$r|ConvertFrom-Json; $plaintextTokens["validator|T-001"]=$i.token
$r = & $TokenScript -Action issue -RunId $RunId -TaskId "T-002" -AgentId "validator" -Role "test-agent" -TtlSeconds $ttlSeconds -AllowedOperations @("validation_started","validation_passed","task_verified"); $i=$r|ConvertFrom-Json; $plaintextTokens["validator|T-002"]=$i.token
Write-Host "Tokens issued"

$eventOps = @{ "run_initialized"="run_initialized"; "task_claimed"="task_claimed"; "task_submitted"="task_submitted"; "validation_started"="validation_started"; "validation_passed"="validation_passed"; "task_verified"="task_verified"; "rework_request_created"="rework_request_created"; "rework_resolved"="rework_resolved" }

function Get-AgentTask($evt) {
    $n = $evt.event
    if ($n -eq "run_initialized") { if ($n -in @("rework_request_created","rework_resolved")) { return @("orchestrator","orchestrator","orchestrator") }; return @("orchestrator","orchestrator","orchestrator") }
    if ($n -in @("task_claimed","task_submitted")) {
        $a = if ($evt.actor) { $evt.actor } else { $evt.agent_id }
        if ($a -eq "worker-1") { return @("worker-1","T-001","builder-agent") }
        if ($a -eq "worker-2") { return @("worker-2","T-002","builder-agent") }
    }
    if ($n -in @("validation_started","validation_passed","task_verified")) {
        $t = if ($evt.taskId) { $evt.taskId } else { if ($evt.seq -le 8) { "T-001" } else { "T-002" } }
        return @("validator",$t,"test-agent")
    }
    if ($n -in @("rework_request_created","rework_resolved")) { return @("orchestrator","orchestrator","orchestrator") }; return @("orchestrator","orchestrator","orchestrator")
}

# Clear RUN_STATE
Remove-Item $runStatePath -Force -ErrorAction SilentlyContinue
$seq = 0

foreach ($evt in $events) {
    $seq = $evt.seq
    $eventName = $evt.event
    $at = Get-AgentTask $evt; $agentId=$at[0]; $taskId=$at[1]; $role=$at[2]
    $op = if ($eventOps[$eventName]) { $eventOps[$eventName] } else { $eventName }

    # Build base event data
    $eventData = @{}
    if ($agentId)  { $eventData["actor"]   = $agentId }
    if ($eventName){ $eventData["event"]   = $eventName }
    if ($role)     { $eventData["role"]    = $role }
    if ($taskId)   { $eventData["taskId"]  = $taskId }
    foreach ($key in $evt.PSObject.Properties.Name) {
        if ($key -notin @("actor","event","role","taskId","status","seq","timestamp","previousHash","eventHash","payloadHash",
                         "authorizationProof","tokenLeaseId","proofNonce","tokenIssuedAt","tokenExpiresAt","agent_id")) {
            $eventData[$key] = $evt.$key
        }
    }
    if ($evt.status) { $eventData["status"] = $evt.status }

    # Sign proof
    $proofCanonical = [ordered]@{}
    foreach ($k in ($eventData.Keys | Sort-Object)) { $proofCanonical[$k] = $eventData[$k] }
    $proofJson = ($proofCanonical | ConvertTo-Json -Compress -Depth 6)

    $tokKey = "$agentId|$taskId"
    $plainTok = $script:plaintextTokens[$tokKey]
    $signResult = & $TokenScript -Action sign -RunId $RunId -TaskId $taskId -Operation $op -Role $role -AgentId $agentId -EventCanonicalJson $proofJson -Token $plainTok
    $signInfo = $signResult | ConvertFrom-Json
    if ($signInfo.status -ne "signed") {
        Write-Error "Sign failed: $eventName seq=$seq status=$($signInfo.status)"
        exit 1
    }

    # Include proof fields in eventData BEFORE append-hash-event computes hashes
    $eventData["authorizationProof"] = $signInfo.authorizationProof
    $eventData["proofNonce"] = $signInfo.nonce
    $eventData["tokenLeaseId"] = $signInfo.tokenLeaseId
    $eventData["tokenIssuedAt"] = $signInfo.issuedAt
    $eventData["tokenExpiresAt"] = $signInfo.expiresAt

    # Append with full data → hash chain includes proof fields
    $appendResult = & $AppendScript -RunDir $RunDir -EventData $eventData 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "append-hash-event failed: $appendResult"; exit 1 }
    Write-Host "  seq=$seq $eventName OK"
}

Write-Host "Done: $(@(Get-Content $runStatePath).Count) events written"
exit 0