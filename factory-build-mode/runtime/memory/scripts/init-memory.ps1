# init-memory.ps1 — Initialize .codex-factory/ external memory for a project
param([Parameter(Mandatory)]$ProjectPath, $ProjectName="", [switch]$Force)

$ErrorActionPreference = "Stop"
$cfDir = Join-Path $ProjectPath ".codex-factory"

if (Test-Path $cfDir) {
    if (-not $Force) {
        Write-Warning ".codex-factory/ already exists at $cfDir"
        Write-Warning "Use -Force to reinitialize (existing files will NOT be overwritten unless --force)"
        exit 2
    }
    Write-Host "Force mode: .codex-factory/ exists, will overwrite core files only."
} else {
    New-Item -ItemType Directory -Path $cfDir -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $cfDir "verifier-results") -Force | Out-Null
}

$projectId = if ($ProjectName) { $ProjectName -replace '[^a-zA-Z0-9_-]','-' } else { (Split-Path $ProjectPath -Leaf) -replace '[^a-zA-Z0-9_-]','-' }
$now = (Get-Date).ToString("o")
$version = "0.1.0"

# project-state.json
@{projectId=$projectId;version=$version;projectName=$ProjectName;currentStage="INTAKE";stages=@{INTAKE="PENDING";CLASSIFY="PENDING";ROUTE="PENDING";BLUEPRINT="PENDING";TASK_GRAPH="PENDING";BUILD="PENDING";DIAGNOSTIC_GATE="PENDING";REPAIR="PENDING";DELIVER="PENDING"};selectedMode="";complexityLevel="";agentCount=1;lastAction="memory-initialized";lastActionTimestamp=$now;sessionCount=1;updatedAt=$now;updatedBy="init-memory.ps1"} | ConvertTo-Json -Depth 4 | Out-File (Join-Path $cfDir "project-state.json") -Encoding UTF8 -Force:$Force

# decision-log.jsonl (empty, append-only)
if (-not (Test-Path (Join-Path $cfDir "decision-log.jsonl")) -or $Force) {
    "" | Out-File (Join-Path $cfDir "decision-log.jsonl") -Encoding UTF8
}

# task-graph.json
@{projectId=$projectId;version=$version;totalTasks=0;completedTasks=0;updatedAt=$now;tasks=@()} | ConvertTo-Json -Depth 6 | Out-File (Join-Path $cfDir "task-graph.json") -Encoding UTF8 -Force:$Force

# architecture-map.json
@{projectId=$projectId;version=$version;updatedAt=$now;pages=@();apiEndpoints=@();databaseTables=@();permissions=@{roles=@();rules=@()};techStack=@{};designDecisions=@()} | ConvertTo-Json -Depth 6 | Out-File (Join-Path $cfDir "architecture-map.json") -Encoding UTF8 -Force:$Force

# requirement-map.json
@{projectId=$projectId;version=$version;updatedAt=$now;originalRequirements=@();derivedRequirements=@()} | ConvertTo-Json -Depth 6 | Out-File (Join-Path $cfDir "requirement-map.json") -Encoding UTF8 -Force:$Force

# active-risks.json
@{projectId=$projectId;version=$version;updatedAt=$now;risks=@()} | ConvertTo-Json -Depth 6 | Out-File (Join-Path $cfDir "active-risks.json") -Encoding UTF8 -Force:$Force

# verifier-history.json
@{projectId=$projectId;version=$version;updatedAt=$now;entries=@()} | ConvertTo-Json -Depth 6 | Out-File (Join-Path $cfDir "verifier-history.json") -Encoding UTF8 -Force:$Force

# handoff-packet.json
@{projectId=$projectId;version=$version;generatedAt=$now;currentStage="INTAKE";selectedMode="";complexityLevel="";completedStages=@();keyDecisions=@();activeRisks=@();evidencePaths=@();forbiddenAssumptions=@("Conversation memory is trustworthy after rotation","Compressed summaries are evidence");rejectedClaims=@();continuationInstructions="Read project-state.json and task-graph.json. Resume from currentStage."} | ConvertTo-Json -Depth 6 | Out-File (Join-Path $cfDir "handoff-packet.json") -Encoding UTF8 -Force:$Force

Write-Host "Memory initialized: $cfDir"
Write-Host "  project-state.json, decision-log.jsonl, task-graph.json, architecture-map.json"
Write-Host "  requirement-map.json, active-risks.json, verifier-history.json, handoff-packet.json"
@{"status"="ok";"projectId"=$projectId;"cfDir"=$cfDir;"filesCreated"=8} | ConvertTo-Json
