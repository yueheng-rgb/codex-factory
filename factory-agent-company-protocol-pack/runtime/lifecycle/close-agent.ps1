<#
.SYNOPSIS Closes an agent with a close receipt reference.
#>
param([Parameter(Mandatory=$true)][string]$RegistryPath,[Parameter(Mandatory=$true)][string]$AgentId,[Parameter(Mandatory=$true)][string]$CloseReason,[string]$CloseReceiptRef)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$reg=@(Get-Content $RegistryPath -Raw -ea Stop|ConvertFrom-Json)}catch{exit 1}
$idx=-1;for($i=0;$i -lt $reg.Count;$i++){if($reg[$i].agentId -eq $AgentId){$idx=$i;break}}
C "agentFound" ($idx -ge 0) "AgentId=$AgentId found at index $idx"
C "notAlreadyClosed" ($reg[$idx].status -ne "COMPLETED") "Current status=$($reg[$idx].status)"
C "closeReasonValid" ($CloseReason -in @("COMPLETED","FAILED","STALE","REPLACED")) "closeReason=$CloseReason"
C "hasCloseReceipt" ([string]::IsNullOrWhiteSpace($CloseReceiptRef) -eq $false) "closeReceiptRef=$CloseReceiptRef"
$reg[$idx].status = if($CloseReason -eq "COMPLETED"){"COMPLETED"}else{"FAILED"}
if($CloseReceiptRef){$reg[$idx]|Add-Member -NotePropertyName closeReceiptRef -NotePropertyValue $CloseReceiptRef -Force}
$reg[$idx]|Add-Member -NotePropertyName closedAt -NotePropertyValue (Get-Date -Format "o") -Force
$reg|ConvertTo-Json -Depth 4|Out-File $RegistryPath -Encoding utf8
$out=[PSCustomObject]@{agentId=$AgentId;closeReason=$CloseReason;closedAt=(Get-Date -Format "o");overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$r}
$out|ConvertTo-Json -Depth 4
if($o){exit 0}else{exit 1}
