param([Parameter(Mandatory=$true)][string]$RegistryPath,[Parameter(Mandatory=$true)][string]$AgentId,[Parameter(Mandatory=$true)][string]$HandoffPath)
$reg=@(Get-Content $RegistryPath -Raw|ConvertFrom-Json)
$idx=-1;for($i=0;$i -lt $reg.Count;$i++){if($reg[$i].agentId -eq $AgentId){$idx=$i;break}}
if($idx -ge 0){$reg[$idx]|Add-Member -NotePropertyName handoffRef -NotePropertyValue $HandoffPath -Force;$reg[$idx]|Add-Member -NotePropertyName handoffAt -NotePropertyValue (Get-Date -Format "o") -Force}
$reg|ConvertTo-Json -Depth 4|Out-File $RegistryPath -Encoding utf8
[PSCustomObject]@{agentId=$AgentId;handoffRecordedAt=(Get-Date -Format "o");handoffPath=$HandoffPath;overall="PASS"}|ConvertTo-Json -Depth 3
