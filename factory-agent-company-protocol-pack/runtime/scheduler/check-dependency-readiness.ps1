<#
.SYNOPSIS Checks if all upstream dependencies are completed before allowing a task to proceed.
#>
param([Parameter(Mandatory=$true)][string]$TaskGraphPath,[Parameter(Mandatory=$true)][string]$TaskId)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0;$blockedDeps=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$g=Get-Content $TaskGraphPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$task=$g.tasks|Where-Object{$_.taskId -eq $TaskId}
C "taskFound" ($task -ne $null) "TaskId=$TaskId"
if($task -and $task.PSObject.Properties.Name -contains "dependencies"){
    foreach($dep in $task.dependencies){
        $dt=$g.tasks|Where-Object{$_.taskId -eq $dep}
        if($dt -eq $null){$blockedDeps+="$dep(MISSING)";C "dep.$dep" $false "Dependency not found"}
        elseif($dt.status -ne "completed"){$blockedDeps+="$dep($($dt.status))";C "dep.$dep" $false "Status=$($dt.status), not completed"}
        else{C "dep.$dep" $true "Completed"}
    }
}
C "allDepsReady" ($blockedDeps.Count -eq 0) "Blocked deps: $($blockedDeps.Count) [$($blockedDeps -join ',')]"
$out=[PSCustomObject]@{taskGraphPath=$TaskGraphPath;taskId=$TaskId;checkedAt=(Get-Date -Format "o");overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;blockedDeps=$blockedDeps;results=$r}
$out|ConvertTo-Json -Depth 4
if($o){exit 0}else{exit 1}
