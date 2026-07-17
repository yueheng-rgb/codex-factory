param([Parameter(Mandatory=$true)][string]$RegistryPath,[string]$FilterStatus,[string]$FilterAgentId)
$reg=@(Get-Content $RegistryPath -Raw|ConvertFrom-Json)
if($FilterStatus){$reg=$reg|Where-Object{$_.status -eq $FilterStatus}}
if($FilterAgentId){$reg=$reg|Where-Object{$_.agentId -eq $FilterAgentId}}
[PSCustomObject]@{registryPath=$RegistryPath;queriedAt=(Get-Date -Format "o");totalAgents=$reg.Count;filterStatus=$FilterStatus;agents=$reg}|ConvertTo-Json -Depth 5
