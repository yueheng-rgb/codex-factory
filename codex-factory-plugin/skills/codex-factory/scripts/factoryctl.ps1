<#
.SYNOPSIS Codex App Factory control plane CLI
.DESCRIPTION Repo-local entrypoint. Commands: status, agents, progress, watch, verify
#>
param(
    [Parameter(Position=0)]
    [ValidateSet("status","agents","progress","watch","verify")]
    [string]$Command = "status",
    [string]$VerifyPhase = "latest",
    [switch]$Json
)

$ErrorActionPreference = "Stop"
$Script:BaseDir = $PSScriptRoot | Split-Path -Parent
$GovDir = Join-Path $Script:BaseDir "governance\factory-state"

function Get-FactoryState {
    $path = Join-Path $GovDir "current-factory-state.json"
    if (-not (Test-Path $path)) { Write-Error "current-factory-state.json not found at $path"; exit 2 }
    Get-Content $path -Raw | ConvertFrom-Json
}

function Invoke-Status {
    $state = Get-FactoryState
    $handoffPath = Join-Path $GovDir "session-rotation-handoff.json"
    $handoff = if (Test-Path $handoffPath) { Get-Content $handoffPath -Raw | ConvertFrom-Json } else { $null }
    $result = [ordered]@{
        command = "status"; factoryVersion = $state.factoryVersion; currentTrustedPhase = $state.currentTrustedPhase
        dry20Status = if ($state.PSObject.Properties.Name -contains "dry20Status") { $state.dry20Status } else { "N/A" }
        dry21Status = if ($state.PSObject.Properties.Name -contains "dry21Status") { $state.dry21Status } else { "NOT_STARTED" }
        dry22Status = if ($state.PSObject.Properties.Name -contains "dry22Status") { $state.dry22Status } else { "NOT_STARTED" }
        h14Status = if ($state.PSObject.Properties.Name -contains "h14Status") { $state.h14Status } else { "NOT_STARTED" }
        h15Status = if ($state.PSObject.Properties.Name -contains "h15Status") { $state.h15Status } else { "NOT_STARTED" }
        h16Status = if ($state.PSObject.Properties.Name -contains "h16Status") { $state.h16Status } else { "NOT_STARTED" }; h16DiagnosisChecks = if ($state.PSObject.Properties.Name -contains "h16DiagnosisChecks") { $state.h16DiagnosisChecks } else { 0 }
        allowedNextPhase = $state.allowedNextPhase; finalZipExists = $state.finalZipExists
        closedPhasesCount = $state.closedPhases.Count; pausedPhasesCount = $state.pausedPhases.Count
        agentRegistryExists = (Test-Path (Join-Path $GovDir "AGENT_REGISTRY.json"))
        agentProgressExists = (Test-Path (Join-Path $GovDir "AGENT_PROGRESS.jsonl"))
        handoffNativeGenerated = if ($handoff -and $handoff.PSObject.Properties.Name -contains "nativeGenerated") { $handoff.nativeGenerated } else { $false }
        checkedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    }; $result | ConvertTo-Json -Depth 3
}

function Invoke-Agents {
    $rgPath = Join-Path $GovDir "AGENT_REGISTRY.json"
    if (-not (Test-Path $rgPath)) { Write-Output '{ "command": "agents", "error": "AGENT_REGISTRY.json not found", "agents": [], "totalAgents": 0 }'; return }
    $registry = Get-Content $rgPath -Raw | ConvertFrom-Json
    [ordered]@{command="agents"; totalAgents=$registry.agents.Count; agents=@($registry.agents|%{[ordered]@{agentId=$_.agentId;phase=$_.phase;role=$_.role;verdict=$_.verdict;nativeGenerated=if($_.PSObject.Properties.Name -contains "nativeGenerated"){$_.nativeGenerated}else{$false}}}); phasesCovered=$registry.phasesCovered; rolesUsed=$registry.rolesUsed; checkedAt=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")} | ConvertTo-Json -Depth 4
}

function Invoke-Progress {
    $prPath = Join-Path $GovDir "AGENT_PROGRESS.jsonl"
    if (-not (Test-Path $prPath)) { Write-Output '{ "command": "progress", "totalEvents": 0 }'; return }
    $events = @(); Get-Content $prPath | %{ if([string]::IsNullOrWhiteSpace($_)){return}; try{$events+=$_|ConvertFrom-Json}catch{} }
    $nat=0;$rec=0;$phs=@{}
    foreach($e in $events){
        if($e.PSObject.Properties.Name -contains "nativeGenerated" -and $e.nativeGenerated){$nat++}
        elseif($e.PSObject.Properties.Name -contains "reconstructedFromEvidence" -and $e.reconstructedFromEvidence){$rec++}
        if($e.PSObject.Properties.Name -contains "phase"){if(-not $phs.ContainsKey($e.phase)){$phs[$e.phase]=0};$phs[$e.phase]++}
    }
    $pb=@();foreach($k in $phs.Keys|Sort){$pb+="$k=$($phs[$k])"}
    [ordered]@{command="progress"; currentTrustedPhase=(Get-FactoryState).currentTrustedPhase; totalEvents=$events.Count; nativeGenerated=$nat; reconstructedFromEvidence=$rec; phases=$pb; checkedAt=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")} | ConvertTo-Json -Depth 4
}

function Invoke-Watch {
    $status = Invoke-Status | ConvertFrom-Json; $agents = Invoke-Agents | ConvertFrom-Json; $progress = Invoke-Progress | ConvertFrom-Json
    [ordered]@{command="watch"; snapshotType="on-demand"; status=$status; agents=$agents; progress=$progress; timestamp=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")} | ConvertTo-Json -Depth 6
}

function Invoke-Verify {
    param($Phase, [switch]$AsJson)
    $diagScripts = @(
        "scripts\diagnosis\run-factory-diagnosis.ps1",
        "scripts\diagnosis\check-complexity-preservation.ps1",
        "scripts\diagnosis\check-contract-first.ps1",
        "scripts\diagnosis\check-worker-boundaries.ps1",
        "scripts\diagnosis\check-negative-control-integrity.ps1",
        "scripts\diagnosis\check-handoff-integrity.ps1"
    )
    $results = @(); $totalChecks = 0
    foreach ($s in $diagScripts) {
        $sp = Join-Path $Script:BaseDir $s
        if (-not (Test-Path $sp)) { $results += @{verdict="ERROR"; checks=@(); error="Script not found: $s"}; continue }
        try {
            $out = & powershell -NoProfile -ExecutionPolicy Bypass -File $sp -Json 2>&1 | Out-String
            $r = $out | ConvertFrom-Json
            $results += $r
            $totalChecks += $r.checks.Count
        } catch {
            $results += @{verdict="ERROR"; checks=@(); error=$_.Exception.Message}
        }
    }
    $allPassed = ($results | Where-Object { $_.verdict -eq "FAIL" -or $_.verdict -eq "ERROR" }).Count -eq 0
    $summary = [ordered]@{ command="verify"; phase=$Phase; verdict=if($allPassed){"PASS"}else{"FAIL"}; totalChecks=$totalChecks; modules=@($results|%{[ordered]@{verdict=$_.verdict;checks=$_.checks.Count}}); checkedAt=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz") }
    if ($AsJson) { $summary | ConvertTo-Json -Depth 5 } else {
        Write-Output "=== factoryctl verify ($Phase) ==="; Write-Output "Verdict: $($summary.verdict) ($totalChecks checks)"
        $i=1; foreach($m in $summary.modules){Write-Output "  Module $i`: $($m.verdict) ($($m.checks) checks)";$i++}
    }
    exit $(if($allPassed){0}else{1})
}

switch ($Command) {
    "status"   { Invoke-Status }
    "agents"   { Invoke-Agents }
    "progress" { Invoke-Progress }
    "watch"    { Invoke-Watch }
    "verify"   { Invoke-Verify -Phase $VerifyPhase -AsJson:$Json }
}

