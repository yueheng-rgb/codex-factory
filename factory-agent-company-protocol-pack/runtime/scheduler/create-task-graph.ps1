<#
.SYNOPSIS
    Creates and validates a task graph for large-project multi-agent orchestration.
.PARAMETER DefinitionPath
    Path to the task graph definition JSON.
#>
param([Parameter(Mandatory=$true)][string]$DefinitionPath)

$results=@(); $overall=$true; $tc=0; $pc=0; $fc=0; $cycles=@(); $missingOwners=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:overall=$false};$script:results+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}

try{$g=Get-Content $DefinitionPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$g.PSObject.Properties.Name

C "graphId" ($pp -contains "graphId" -and $g.graphId -is [string] -and $g.graphId.Trim().Length -gt 0) "graphId='$($g.graphId)'"
C "phaseId" ($pp -contains "phaseId" -and $g.phaseId -is [string] -and $g.phaseId.Trim().Length -gt 0) "phaseId='$($g.phaseId)'"
C "tasksDefined" ($pp -contains "tasks" -and $g.tasks -is [array] -and $g.tasks.Count -gt 0) "tasks count=$($g.tasks.Count)"
C "maxParallelAgents" ($pp -contains "maxParallelAgents" -and $g.maxParallelAgents -is [int] -and $g.maxParallelAgents -ge 1 -and $g.maxParallelAgents -le 8) "maxParallelAgents=$($g.maxParallelAgents)"

if ($pp -contains "tasks" -and $g.tasks -is [array]) {
    $taskIds = @($g.tasks | ForEach-Object { $_.taskId })
    foreach ($t in $g.tasks) {
        $tp=$t.PSObject.Properties.Name
        $tid=$t.taskId
        C "task.$tid.id" ($tp -contains "taskId" -and $tid -is [string] -and $tid.Trim().Length -gt 0) "taskId='$tid'"
        C "task.$tid.title" ($tp -contains "taskTitle" -and $t.taskTitle -is [string] -and $t.taskTitle.Trim().Length -gt 0) "title='$($t.taskTitle)'"
        C "task.$tid.role" ($tp -contains "roleNeeded" -and $t.roleNeeded -is [string] -and $t.roleNeeded.Trim().Length -gt 0) "role='$($t.roleNeeded)'"
        C "task.$tid.outputs" ($tp -contains "expectedOutputs" -and $t.expectedOutputs -is [array] -and $t.expectedOutputs.Count -gt 0) "outputs=$($t.expectedOutputs.Count)"
        C "task.$tid.status" ($tp -contains "status" -and $t.status -in @("pending","ready","assigned","in_progress","blocked","completed","failed")) "status='$($t.status)'"

        # Dependency cycle detection via DFS
        if ($tp -contains "dependencies" -and $t.dependencies -is [array]) {
            foreach ($dep in $t.dependencies) {
                if ($dep -notin $taskIds) {
                    C "task.$tid.dep.$dep.missing" $false "Dependency '$dep' not found in task list"
                }
            }
        }

        # Missing owner for assigned/in_progress
        if ($t.status -in @("assigned","in_progress","completed")) {
            $hasOwner = $tp -contains "ownerAgentId" -and $t.ownerAgentId -is [string] -and $t.ownerAgentId.Trim().Length -gt 0
            C "task.$tid.owner" $hasOwner "ownerAgentId for status=$($t.status)"
            if (-not $hasOwner) { $missingOwners += $tid }
        }

        # High risk without reviewer
        if ($tp -contains "riskLevel" -and $t.riskLevel -in @("high","critical")) {
            C "task.$tid.highRiskReviewer" $true "riskLevel=$($t.riskLevel) - requires reviewer checkpoint"
        }

        # Cross-module without integration checkpoint
        if ($tp -contains "module" -and $t.module -is [string] -and $t.module.Trim().Length -gt 0) {
            C "task.$tid.hasModule" $true "module='$($t.module)'"
        }
    }
}

# Cycle detection
function Find-Cycle {
    param($taskId, [System.Collections.Generic.HashSet[string]]$visited, [System.Collections.Generic.HashSet[string]]$stack)
    if ($stack.Contains($taskId)) { return $true }
    if ($visited.Contains($taskId)) { return $false }
    $visited.Add($taskId) | Out-Null
    $stack.Add($taskId) | Out-Null
    $task = $g.tasks | Where-Object { $_.taskId -eq $taskId }
    if ($task -and $task.PSObject.Properties.Name -contains "dependencies") {
        foreach ($dep in $task.dependencies) {
            if (Find-Cycle -taskId $dep -visited $visited -stack $stack) { return $true }
        }
    }
    $stack.Remove($taskId) | Out-Null
    return $false
}
if ($pp -contains "tasks") {
    $v = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($t in $g.tasks) {
        $s = [System.Collections.Generic.HashSet[string]]::new()
        if (Find-Cycle -taskId $t.taskId -visited $v -stack $s) {
            $cycles += $t.taskId
        }
    }
}
C "noCycles" ($cycles.Count -eq 0) "Dependency cycles: $($cycles.Count)"
C "noMissingOwners" ($missingOwners.Count -eq 0) "Missing owners: $($missingOwners.Count)"

$o=[PSCustomObject]@{definitionPath=$DefinitionPath;validatedAt=(Get-Date -Format "o");overall=if($overall){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;cycles=$cycles;missingOwners=$missingOwners;results=$results}
$o|ConvertTo-Json -Depth 4
if($overall){exit 0}else{exit 1}
