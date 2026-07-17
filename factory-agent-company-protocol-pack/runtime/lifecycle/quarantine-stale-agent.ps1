<#
.SYNOPSIS Quarantines a stale active agent.
#>
param([Parameter(Mandatory=$true)][string]$RegistryPath,[Parameter(Mandatory=$true)][string]$AgentId)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$reg=@(Get-Content $RegistryPath -Raw -ea Stop|ConvertFrom-Json)}catch{exit 1}
$idx=-1;for($i=0;$i -lt $reg.Count;$i++){if($reg[$i].agentId -eq $AgentId){$idx=$i;break}}
C "agentFound" ($idx -ge 0) "AgentId=$AgentId"
C "isActive" ($reg[$idx].status -eq "ACTIVE") "Status=$($reg[$idx].status)"
$reg[$idx].status="QUARANTINED"
$reg[$idx]|Add-Member -NotePropertyName quarantinedAt -NotePropertyValue (Get-Date -Format "o") -Force
$reg[$idx]|Add-Member -NotePropertyName quarantineReason -NotePropertyValue "STALE_THRESHOLD_EXCEEDED" -Force
$reg|ConvertTo-Json -Depth 4|Out-File $RegistryPath -Encoding utf8
$out=[PSCustomObject]@{agentId=$AgentId;quarantinedAt=(Get-Date -Format "o");overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$r}
$out|ConvertTo-Json -Depth 4
if($o){exit 0}else{exit 1}
