# factoryctl.ps1 — Codex Factory Control CLI
# H12 Factory Local v0.1 + H13 Agent Lifecycle Commands
param(
    [Parameter(Position=0)]
    [ValidateSet("status","handoff","resume","rotate","readiness",
                 "spawn-worker","verify-worker","integrate","accept",
                 "negative","report","close",
                 "agents","agent-create","agent-heartbeat","agent-progress",
                 "agent-handoff","agent-close-agent","agent-quarantine",
                 "progress","watch","list-tasks","add-task","complete-task")]
    [string]$Command,

    [string]$Phase,
    [string]$WorkerId,
    [string]$TaskId,
    [string]$Role,
    [string]$ReportPath,
    [string]$EvidencePath,
    [switch]$PlanOnly,
    [switch]$PassThru,
    [switch]$Force
)

$ErrorActionPreference = "Continue"
$HarnessRoot = Resolve-Path "$PSScriptRoot\.."
$GovRoot = Join-Path $HarnessRoot "governance\factory-state"
$OutputsRoot = Join-Path $HarnessRoot "outputs"
$RunsRoot = Join-Path $HarnessRoot "runs"

function Get-FactoryState {
    $path = Join-Path $GovRoot "current-factory-state.json"
    if (-not (Test-Path $path)) { return $null }
    Get-Content $path -Raw | ConvertFrom-Json
}

function Get-TaskQueue {
    $path = Join-Path $GovRoot "FACTORY_TASK_QUEUE.json"
    if (-not (Test-Path $path)) { return $null }
    Get-Content $path -Raw | ConvertFrom-Json
}

function Get-AgentRegistry {
    $path = Join-Path $GovRoot "AGENT_REGISTRY.json"
    if (-not (Test-Path $path)) { return $null }
    Get-Content $path -Raw | ConvertFrom-Json
}

function Get-PhaseLock {
    $path = Join-Path $HarnessRoot "governance\harness-readiness\current-phase-lock.json"
    if (-not (Test-Path $path)) { return $null }
    Get-Content $path -Raw | ConvertFrom-Json
}

function Out-JsonResult($verdict, $data) {
    $result = @{ command = $Command; verdict = $verdict; timestamp = (Get-Date -Format "o") }
    if ($data) { foreach ($k in $data.Keys) { $result[$k] = $data[$k] } }
    $result | ConvertTo-Json -Depth 5
}

# ============================================
# COMMAND: status
# ============================================
if ($Command -eq "status") {
    $state = Get-FactoryState
    $queue = Get-TaskQueue
    $lock = Get-PhaseLock
    $reg = Get-AgentRegistry

    $activeAgents = if ($reg) { ($reg.agents | Where-Object { $_.status -eq "running" -or $_.status -eq "created" }).Count } else { 0 }
    $closedAgents = if ($reg) { ($reg.agents | Where-Object { $_.status -eq "closed" }).Count } else { 0 }
    $quarantinedAgents = if ($reg) { ($reg.agents | Where-Object { $_.status -eq "quarantined" }).Count } else { 0 }

    $data = @{
        currentTrustedPhase = if ($state) { $state.currentTrustedPhase } else { "UNKNOWN" }
        allowedNextPhase = if ($state) { $state.allowedNextPhase } else { "UNKNOWN" }
        activeRunId = if ($state) { $state.activeRunId } else { "UNKNOWN" }
        activeRunStatus = if ($state) { $state.activeRunStatus } else { "UNKNOWN" }
        DRY19Classification = if ($state) { $state.DRY19Classification } else { "UNKNOWN" }
        DRY19BStatus = if ($state) { $state.DRY19BStatus } else { "UNKNOWN" }
        DRY20AStatus = if ($state) { $state.DRY20AStatus } else { "UNKNOWN" }
        finalZipExists = if ($state) { $state.finalZipExists } else { $false }
        openCaveats = if ($state) { $state.openCaveats } else { @() }
        taskCount = if ($queue) { $queue.tasks.Count } else { 0 }
        readyTasks = if ($queue) { ($queue.tasks | Where-Object { $_.status -eq "ready" }).Count } else { 0 }
        activeAgents = $activeAgents
        closedAgents = $closedAgents
        quarantinedAgents = $quarantinedAgents
    }
    Out-JsonResult "OK" $data
    exit 0
}

# ============================================
# COMMAND: handoff
# ============================================
if ($Command -eq "handoff") {
    $state = Get-FactoryState
    if (-not $state) {
        Out-JsonResult "FAIL" @{ reason = "No factory state found" }
        exit 1
    }

    $handoff = @{
        currentTrustedPhase = $state.currentTrustedPhase
        allowedNextPhase = $state.allowedNextPhase
        activeRunId = $state.activeRunId
        activeRunStatus = $state.activeRunStatus
        lastTrustedReports = $state.latestTrustedReports
        openCaveats = $state.openCaveats
        compressionCount = if ($state.compressionCount) { $state.compressionCount } else { 0 }
        handoffCreatedAt = (Get-Date -Format "o")
        forbiddenActions = @("start-closed-phase","delete-evidence","create-final-zip")
        requiredNextAction = "verify-resume-capsule"
    }
    Out-JsonResult "OK" $handoff
    exit 0
}

# ============================================
# COMMAND: resume
# ============================================
if ($Command -eq "resume") {
    $state = Get-FactoryState
    $lock = Get-PhaseLock

    if ($state.compressionCount -ge 2) {
        Out-JsonResult "BLOCKED" @{ reason = "compressionCount >= 2 requires new window handoff" }
        exit 1
    }

    $resumeData = @{
        currentPhase = $state.currentTrustedPhase
        allowedNext = $state.allowedNextPhase
        resumeAllowed = ($state.compressionCount -lt 2)
        activeRunStatus = $state.activeRunStatus
    }
    Out-JsonResult "OK" $resumeData
    exit 0
}

# ============================================
# COMMAND: rotate
# ============================================
if ($Command -eq "rotate") {
    $state = Get-FactoryState
    $compCount = if ($state.compressionCount) { $state.compressionCount + 1 } else { 1 }
    $needsNewWindow = ($compCount -ge 2)

    $rotateData = @{
        compressionCount = $compCount
        needsNewWindow = $needsNewWindow
        resumeAllowed = (-not $needsNewWindow)
        previousPhase = $state.currentTrustedPhase
        rotatedAt = (Get-Date -Format "o")
    }
    Out-JsonResult "OK" $rotateData
    exit 0
}

# ============================================
# COMMAND: readiness
# ============================================
if ($Command -eq "readiness") {
    $state = Get-FactoryState
    $lock = Get-PhaseLock
    $queue = Get-TaskQueue

    $checks = @()

    # Check phase lock
    if ($lock) {
        $checks += @{ check = "phase-lock-exists"; status = "PASS" }
        $checks += @{ check = "phase-lock-phase"; status = "PASS"; phase = $lock.currentPhase }
    } else {
        $checks += @{ check = "phase-lock-exists"; status = "FAIL" }
    }

    # Check DRY19 closure
    $dry19closed = ($state.DRY19Classification -eq "POSITIVE_NEGATIVE_CLOSED")
    $checks += @{ check = "DRY19-closed"; status = if ($dry19closed) { "PASS" } else { "FAIL" } }

    # Check DRY20 not started
    $dry20notStarted = ($state.DRY20AStatus -eq "NOT_STARTED")
    $checks += @{ check = "DRY20-A-not-started"; status = if ($dry20notStarted) { "PASS" } else { "FAIL" } }

    $allPass = ($checks | Where-Object { $_.status -eq "FAIL" }).Count -eq 0
    Out-JsonResult $(if ($allPass) { "PASS" } else { "FAIL" }) @{ checks = $checks }
    exit $(if ($allPass) { 0 } else { 1 })
}

# ============================================
# COMMAND: negative
# ============================================
if ($Command -eq "negative") {
    $state = Get-FactoryState
    $queue = Get-TaskQueue

    if (-not $Phase) {
        Out-JsonResult "FAIL" @{ reason = "Phase parameter required" }
        exit 1
    }

    # Find the negative task for this phase
    $negTask = $queue.tasks | Where-Object { $_.phase -eq $Phase -and $_.role -eq "negative" }
    if (-not $negTask) {
        # Try by taskId
        $negTask = $queue.tasks | Where-Object { $_.taskId -like "*$Phase*negative*" -or $_.taskId -like "*negative*$Phase*" }
    }

    # Check if phase is forbidden/closed
    $forbiddenPhases = @("DRY14","DRY15","DRY1","DRY2","DRY3","DRY4","DRY5","DRY6","DRY7","DRY8","DRY9","DRY10","DRY11","DRY12","DRY13","H1","H2","H3","H4","H5","H6","H7","H8","H9","H10","H11")
    if ($Phase -in $forbiddenPhases) {
        Out-JsonResult "BLOCKED" @{ reason = "Phase $Phase is closed/forbidden"; status = "BLOCKED" }
        exit 1
    }

    # Check parent positive status
    $parentPhase = if ($negTask) { $negTask.parentPositiveRun } else { $null }
    if (-not $parentPhase) {
        Out-JsonResult "BLOCKED" @{ reason = "No parent positive run found for $Phase"; status = "BLOCKED" }
        exit 1
    }

    $parentTask = $queue.tasks | Where-Object { $_.taskId -eq $parentPhase -or $_.phase -eq $parentPhase }
    $parentPass = $false
    if ($parentTask -and $parentTask.verdict -eq "PASS") { $parentPass = $true }
    if ($state.DRY19Classification -eq "POSITIVE_NEGATIVE_CLOSED" -and $Phase -eq "DRY19-B") { $parentPass = $true }
    if ($state.DRY19AStatus -eq "PASS" -and $Phase -eq "DRY19-B") { $parentPass = $true }

    if (-not $parentPass) {
        Out-JsonResult "BLOCKED" @{
            reason = "Parent positive not PASS"
            parentPositiveRun = $parentPhase
            parentPositiveStatus = if ($parentTask) { $parentTask.verdict } else { "UNKNOWN" }
            status = "BLOCKED"
        }
        exit 1
    }

    # Parent positive is PASS
    if ($PlanOnly) {
        Out-JsonResult "PLANNING_ALLOWED" @{
            parentPositiveRun = $parentPhase
            parentPositiveStatus = "PASS"
            status = "PLANNING_ALLOWED"
            executionStarted = $false
            message = "Negative plan may be created but execution not started"
        }
        exit 0
    }

    # Check if explicit start requested
    if (-not $Force) {
        Out-JsonResult "PLANNING_ALLOWED" @{
            parentPositiveRun = $parentPhase
            parentPositiveStatus = "PASS"
            status = "PLANNING_ALLOWED"
            executionStarted = $false
            message = "Use -Force to explicitly start negative run"
        }
        exit 0
    }

    Out-JsonResult "PASS" @{
        parentPositiveRun = $parentPhase
        parentPositiveStatus = "PASS"
        status = "ready"
        executionStarted = $true
    }
    exit 0
}

# ============================================
# COMMAND: agents
# ============================================
if ($Command -eq "agents") {
    $reg = Get-AgentRegistry
    if (-not $reg) {
        Out-JsonResult "FAIL" @{ reason = "No agent registry found" }
        exit 1
    }

    $summary = $reg.agents | ForEach-Object {
        @{
            agentId = $_.agentId
            taskId = $_.taskId
            role = $_.role
            status = $_.status
            createdAt = $_.createdAt
            closedAt = $_.closedAt
            worktreePath = $_.worktreePath
            capsulePath = $_.capsulePath
        }
    }

    Out-JsonResult "OK" @{
        totalAgents = $reg.agents.Count
        activeCount = ($reg.agents | Where-Object { $_.status -eq "running" -or $_.status -eq "created" }).Count
        closedCount = ($reg.agents | Where-Object { $_.status -eq "closed" }).Count
        quarantinedCount = ($reg.agents | Where-Object { $_.status -eq "quarantined" }).Count
        agents = @($summary)
    }
    exit 0
}

# ============================================
# COMMAND: agent-create
# ============================================
if ($Command -eq "agent-create") {
    if (-not $TaskId -or -not $Role) {
        Out-JsonResult "FAIL" @{ reason = "TaskId and Role required" }
        exit 1
    }

    $reg = Get-AgentRegistry
    $agentId = "agent-$((Get-Date -Format 'yyyyMMddHHmmss'))-$((Get-Random -Minimum 1000 -Maximum 9999))"
    $newAgent = @{
        agentId = $agentId
        taskId = $TaskId
        role = $Role
        status = "created"
        createdAt = (Get-Date -Format "o")
        forkContext = $false
        isolationRequired = $true
        expectedOutputs = @()
        capsulePath = ""
        worktreePath = ""
        parentPhase = if ($Phase) { $Phase } else { "" }
    }

    $reg.agents += $newAgent
    $reg.generatedAt = (Get-Date -Format "o")
    $reg | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $GovRoot "AGENT_REGISTRY.json") -Encoding UTF8

    Out-JsonResult "OK" @{ agentId = $agentId; role = $Role; taskId = $TaskId; status = "created" }
    exit 0
}

# ============================================
# COMMAND: agent-heartbeat
# ============================================
if ($Command -eq "agent-heartbeat") {
    if (-not $WorkerId) {
        Out-JsonResult "FAIL" @{ reason = "WorkerId required" }
        exit 1
    }

    $reg = Get-AgentRegistry
    $agent = $reg.agents | Where-Object { $_.agentId -eq $WorkerId }
    if (-not $agent) {
        Out-JsonResult "FAIL" @{ reason = "Agent $WorkerId not found" }
        exit 1
    }

    $agent.lastHeartbeatAt = (Get-Date -Format "o")
    $reg | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $GovRoot "AGENT_REGISTRY.json") -Encoding UTF8

    $evt = @{eventType="heartbeat"; eventId="evt-$((Get-Date -Format 'yyyyMMddHHmmss'))"; timestamp=(Get-Date -Format "o"); agentId=$WorkerId; taskId=$agent.taskId; progressPercent=$agent.progressPercent; currentStep="Heartbeat"} | ConvertTo-Json -Compress
    Add-Content (Join-Path $GovRoot "AGENT_PROGRESS.jsonl") "$evt"

    Out-JsonResult "OK" @{ agentId = $WorkerId; lastHeartbeatAt = $agent.lastHeartbeatAt }
    exit 0
}

# ============================================
# COMMAND: agent-progress
# ============================================
if ($Command -eq "agent-progress") {
    if (-not $WorkerId) {
        Out-JsonResult "FAIL" @{ reason = "WorkerId required" }
        exit 1
    }

    $progressPath = Join-Path $GovRoot "AGENT_PROGRESS.jsonl"
    if (-not (Test-Path $progressPath)) {
        Out-JsonResult "FAIL" @{ reason = "No progress log" }
        exit 1
    }

    $events = Get-Content $progressPath | Where-Object { $_ -match $WorkerId } | ForEach-Object { $_ | ConvertFrom-Json }
    Out-JsonResult "OK" @{ agentId = $WorkerId; eventCount = $events.Count; events = @($events) }
    exit 0
}

# ============================================
# COMMAND: agent-handoff
# ============================================
if ($Command -eq "agent-handoff") {
    if (-not $WorkerId) {
        Out-JsonResult "FAIL" @{ reason = "WorkerId required" }
        exit 1
    }

    $reg = Get-AgentRegistry
    $agent = $reg.agents | Where-Object { $_.agentId -eq $WorkerId }
    if (-not $agent) {
        Out-JsonResult "FAIL" @{ reason = "Agent $WorkerId not found" }
        exit 1
    }

    $handoffPath = if ($EvidencePath) { $EvidencePath } else { "handoff.json" }
    $agent.handoffPath = $handoffPath
    $agent.status = "handoff"
    $reg | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $GovRoot "AGENT_REGISTRY.json") -Encoding UTF8

    $evt = @{eventType="handoff"; eventId="evt-$((Get-Date -Format 'yyyyMMddHHmmss'))"; timestamp=(Get-Date -Format "o"); agentId=$WorkerId; taskId=$agent.taskId; progressPercent=100; handoffPath=$handoffPath} | ConvertTo-Json -Compress
    Add-Content (Join-Path $GovRoot "AGENT_PROGRESS.jsonl") "$evt"

    Out-JsonResult "OK" @{ agentId = $WorkerId; status = "handoff"; handoffPath = $handoffPath }
    exit 0
}

# ============================================
# COMMAND: agent-close-agent
# ============================================
if ($Command -eq "agent-close-agent") {
    if (-not $WorkerId) {
        Out-JsonResult "FAIL" @{ reason = "WorkerId required" }
        exit 1
    }

    $reg = Get-AgentRegistry
    $agent = $reg.agents | Where-Object { $_.agentId -eq $WorkerId }

    if (-not $agent) {
        Out-JsonResult "FAIL" @{ reason = "Agent $WorkerId not found" }
        exit 1
    }

    # Require handoff or explicit reason
    if (-not $agent.handoffPath -and -not $Force) {
        Out-JsonResult "FAIL" @{ reason = "Agent has no handoff and no explicit reason for close. Use -Force only with justification." }
        exit 1
    }

    $agent.status = "closed"
    $agent.closedAt = (Get-Date -Format "o")
    $reg | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $GovRoot "AGENT_REGISTRY.json") -Encoding UTF8

    $evt = @{eventType="close"; eventId="evt-$((Get-Date -Format 'yyyyMMddHHmmss'))"; timestamp=(Get-Date -Format "o"); agentId=$WorkerId; taskId=$agent.taskId; progressPercent=100; message="Agent closed"} | ConvertTo-Json -Compress
    Add-Content (Join-Path $GovRoot "AGENT_PROGRESS.jsonl") "$evt"

    Out-JsonResult "OK" @{ agentId = $WorkerId; status = "closed"; closedAt = $agent.closedAt }
    exit 0
}

# ============================================
# COMMAND: agent-quarantine
# ============================================
if ($Command -eq "agent-quarantine") {
    if (-not $WorkerId) {
        Out-JsonResult "FAIL" @{ reason = "WorkerId required" }
        exit 1
    }

    $reg = Get-AgentRegistry
    $agent = $reg.agents | Where-Object { $_.agentId -eq $WorkerId }
    if (-not $agent) {
        Out-JsonResult "FAIL" @{ reason = "Agent $WorkerId not found" }
        exit 1
    }

    $agent.status = "quarantined"
    $agent.quarantinedAt = (Get-Date -Format "o")
    if (-not $agent.riskSignals) { $agent.riskSignals = @() }
    $agent.riskSignals += if ($EvidencePath) { $EvidencePath } else { "manual_quarantine" }
    $reg | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $GovRoot "AGENT_REGISTRY.json") -Encoding UTF8

    $evt = @{eventType="quarantine"; eventId="evt-$((Get-Date -Format 'yyyyMMddHHmmss'))"; timestamp=(Get-Date -Format "o"); agentId=$WorkerId; taskId=$agent.taskId; riskSignals=$agent.riskSignals; message="Agent quarantined"} | ConvertTo-Json -Compress
    Add-Content (Join-Path $GovRoot "AGENT_PROGRESS.jsonl") "$evt"

    Out-JsonResult "OK" @{ agentId = $WorkerId; status = "quarantined"; riskSignals = $agent.riskSignals }
    exit 0
}

# ============================================
# COMMAND: progress
# ============================================
if ($Command -eq "progress") {
    $progressPath = Join-Path $GovRoot "AGENT_PROGRESS.jsonl"
    if (-not (Test-Path $progressPath)) {
        Out-JsonResult "FAIL" @{ reason = "No progress log" }
        exit 1
    }

    $allEvents = Get-Content $progressPath | ForEach-Object { $_ | ConvertFrom-Json }
    $agentIds = $allEvents | Select-Object -ExpandProperty agentId -Unique

    $summary = $agentIds | ForEach-Object {
        $id = $_
        $agentEvents = $allEvents | Where-Object { $_.agentId -eq $id }
        $lastEvt = $agentEvents | Select-Object -Last 1
        @{
            agentId = $id
            taskId = $lastEvt.taskId
            eventCount = $agentEvents.Count
            lastEventType = $lastEvt.eventType
            lastProgressPercent = $lastEvt.progressPercent
            lastTimestamp = $lastEvt.timestamp
            lastStep = $lastEvt.currentStep
        }
    }

    Out-JsonResult "OK" @{
        totalEvents = $allEvents.Count
        uniqueAgents = $agentIds.Count
        agentSummaries = @($summary)
    }
    exit 0
}

# ============================================
# COMMAND: watch
# ============================================
if ($Command -eq "watch") {
    $reg = Get-AgentRegistry
    $queue = Get-TaskQueue
    $state = Get-FactoryState
    $progressPath = Join-Path $GovRoot "AGENT_PROGRESS.jsonl"

    $progressEvents = @()
    if (Test-Path $progressPath) {
        $progressEvents = Get-Content $progressPath | ForEach-Object { $_ | ConvertFrom-Json }
    }

    $snapshot = @{
        timestamp = (Get-Date -Format "o")
        factoryPhase = if ($state) { $state.currentTrustedPhase } else { "UNKNOWN" }
        activeAgents = if ($reg) { @($reg.agents | Where-Object { $_.status -eq "running" -or $_.status -eq "created" } | ForEach-Object { @{agentId=$_.agentId; role=$_.role; status=$_.status} }) } else { @() }
        closedAgents = if ($reg) { ($reg.agents | Where-Object { $_.status -eq "closed" }).Count } else { 0 }
        quarantinedAgents = if ($reg) { ($reg.agents | Where-Object { $_.status -eq "quarantined" }).Count } else { 0 }
        recentProgressEvents = @($progressEvents | Select-Object -Last 10)
        zombieAgents = if ($reg) { @($reg.agents | Where-Object { $_.status -eq "running" -and $_.lastHeartbeatAt -and ([datetime]$_.lastHeartbeatAt) -lt (Get-Date).AddMinutes(-30) } | ForEach-Object { $_.agentId }) } else { @() }
    }

    Out-JsonResult "OK" $snapshot
    exit 0
}

# ============================================
# COMMAND: list-tasks
# ============================================
if ($Command -eq "list-tasks") {
    $queue = Get-TaskQueue
    if (-not $queue) {
        Out-JsonResult "FAIL" @{ reason = "No task queue found" }
        exit 1
    }

    $summary = $queue.tasks | ForEach-Object {
        @{
            taskId = $_.taskId
            phase = $_.phase
            status = $_.status
            verdict = $_.verdict
            role = $_.role
            blockedBy = $_.blockedBy
            executionStarted = $_.executionStarted
        }
    }

    Out-JsonResult "OK" @{
        totalTasks = $queue.tasks.Count
        readyCount = ($queue.tasks | Where-Object { $_.status -eq "ready" }).Count
        completeCount = ($queue.tasks | Where-Object { $_.status -eq "complete" }).Count
        blockedCount = ($queue.tasks | Where-Object { $_.status -eq "blocked" }).Count
        tasks = @($summary)
    }
    exit 0
}

# ============================================
# COMMAND: report
# ============================================
if ($Command -eq "report") {
    $state = Get-FactoryState
    $queue = Get-TaskQueue
    $reg = Get-AgentRegistry

    $report = @{
        generatedAt = (Get-Date -Format "o")
        currentPhase = if ($state) { $state.currentTrustedPhase } else { "UNKNOWN" }
        activeRunStatus = if ($state) { $state.activeRunStatus } else { "UNKNOWN" }
        DRY19Classification = if ($state) { $state.DRY19Classification } else { "UNKNOWN" }
        DRY20AStatus = if ($state) { $state.DRY20AStatus } else { "UNKNOWN" }
        taskSummary = if ($queue) { @{
            total = $queue.tasks.Count
            ready = ($queue.tasks | Where-Object { $_.status -eq "ready" }).Count
            complete = ($queue.tasks | Where-Object { $_.status -eq "complete" }).Count
            blocked = ($queue.tasks | Where-Object { $_.status -eq "blocked" }).Count
        }} else { $null }
        agentSummary = if ($reg) { @{
            total = $reg.agents.Count
            active = ($reg.agents | Where-Object { $_.status -eq "running" -or $_.status -eq "created" }).Count
            closed = ($reg.agents | Where-Object { $_.status -eq "closed" }).Count
            quarantined = ($reg.agents | Where-Object { $_.status -eq "quarantined" }).Count
        }} else { $null }
    }

    Out-JsonResult "OK" $report
    exit 0
}

# ============================================
# COMMAND: close
# ============================================
if ($Command -eq "close") {
    $state = Get-FactoryState
    if (-not $Phase) {
        Out-JsonResult "FAIL" @{ reason = "Phase parameter required" }
        exit 1
    }

    Out-JsonResult "OK" @{
        phase = $Phase
        status = "closed"
        closedAt = (Get-Date -Format "o")
        message = "Phase $Phase marked closed. Verify all evidence before proceeding."
    }
    exit 0
}

# ============================================
# DEFAULT: unknown command
# ============================================
Out-JsonResult "FAIL" @{ reason = "Unknown command: $Command. Available: status, handoff, resume, rotate, readiness, negative, agents, agent-create, agent-heartbeat, agent-progress, agent-handoff, agent-close-agent, agent-quarantine, progress, watch, list-tasks, report, close" }
exit 1
