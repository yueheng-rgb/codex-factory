<#
.SYNOPSIS Registers a new agent in the agent registry.
#>
param([Parameter(Mandatory=$true)][string]$AgentPath,[Parameter(Mandatory=$true)][string]$RegistryPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$a=Get-Content $AgentPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$reg=@()
if(Test-Path $RegistryPath){try{$reg=@(Get-Content $RegistryPath -Raw|ConvertFrom-Json)}catch{}}
C "agentIdPresent" ($a.PSObject.Properties.Name -contains "agentId" -and $a.agentId -is [string] -and $a.agentId.Trim().Length -gt 0) "agentId='$($a.agentId)'"
C "notDuplicate" (($reg | Where-Object {$_.agentId -eq $a.agentId}).Count -eq 0) "No duplicate agentId"
C "roleValid" ($a.PSObject.Properties.Name -contains "role" -and $a.role -in @("Orchestrator","Architect","Builder","Integration Lead","Reviewer","Verifier","Integrity Checker")) "role='$($a.role)'"
C "phaseValid" ($a.PSObject.Properties.Name -contains "phase" -and $a.phase -is [string] -and $a.phase.Trim().Length -gt 0) "phase='$($a.phase)'"
C "statusValid" ($a.PSObject.Properties.Name -contains "status" -and $a.status -in @("ACTIVE","COMPLETED","FAILED","STALE","QUARANTINED")) "status='$($a.status)'"
$reg += $a
$reg|ConvertTo-Json -Depth 4|Out-File $RegistryPath -Encoding utf8
$out=[PSCustomObject]@{agentPath=$AgentPath;registryPath=$RegistryPath;registeredAt=(Get-Date -Format "o");overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;registrySize=$reg.Count;results=$r}
$out|ConvertTo-Json -Depth 4
if($o){exit 0}else{exit 1}
