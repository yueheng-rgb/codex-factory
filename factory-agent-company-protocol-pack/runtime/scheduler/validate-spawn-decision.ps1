<#
.SYNOPSIS Validates a spawn decision before agent creation.
#>
param([Parameter(Mandatory=$true)][string]$DecisionPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$d=Get-Content $DecisionPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$d.PSObject.Properties.Name
C "decisionId" ($pp -contains "decisionId" -and $d.decisionId -is [string] -and $d.decisionId.Trim().Length -gt 0) "decisionId='$($d.decisionId)'"
C "agentId" ($pp -contains "agentId" -and $d.agentId -is [string] -and $d.agentId.Trim().Length -gt 0) "agentId='$($d.agentId)'"
C "role" ($pp -contains "role" -and $d.role -is [string] -and $d.role.Trim().Length -gt 0) "role='$($d.role)'"
C "complexityTrigger" ($pp -contains "complexityTrigger" -and $d.complexityTrigger -is [string] -and $d.complexityTrigger.Trim().Length -gt 0) "complexityTrigger='$($d.complexityTrigger)'"
C "isolationPlan" ($pp -contains "isolationPlan" -and $d.isolationPlan -is [string] -and $d.isolationPlan.Trim().Length -gt 0) "isolationPlan='$($d.isolationPlan)'"
C "capsuleRef" ($pp -contains "capsuleRef" -and $d.capsuleRef -is [string] -and $d.capsuleRef.Trim().Length -gt 0) "capsuleRef='$($d.capsuleRef)'"
C "forkContext" ($pp -contains "forkContext" -and $d.forkContext -eq $false) "forkContext=false"
C "capacityApproved" ($pp -contains "capacityApproved" -and $d.capacityApproved -eq $true) "capacityApproved=true"
C "decisionOutcome" ($pp -contains "decisionOutcome" -and $d.decisionOutcome -in @("APPROVED","DENIED","PENDING")) "outcome='$($d.decisionOutcome)'"
$out=[PSCustomObject]@{decisionPath=$DecisionPath;validatedAt=(Get-Date -Format "o");overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$r}
$out|ConvertTo-Json -Depth 4
if($o){exit 0}else{exit 1}
