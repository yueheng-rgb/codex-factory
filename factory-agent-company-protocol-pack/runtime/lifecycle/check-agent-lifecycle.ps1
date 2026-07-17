<#
.SYNOPSIS Checks agent lifecycle status: detects stale, open, unclosed agents.
#>
param([Parameter(Mandatory=$true)][string]$RegistryPath,[int]$StaleThresholdMinutes=30)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0;$staleAgents=@();$openAgents=@();$unclosed=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$reg=@(Get-Content $RegistryPath -Raw -ea Stop|ConvertFrom-Json)}catch{exit 1}
$now=Get-Date
foreach($a in $reg){
    if($a.status -eq "ACTIVE"){
        $openAgents+=$a.agentId
        if($a.PSObject.Properties.Name -contains "lastProgressAt"){
            $last=[DateTime]::Parse($a.lastProgressAt)
            if(($now - $last).TotalMinutes -gt $StaleThresholdMinutes){$staleAgents+=$a.agentId}
        }
    }
    if($a.status -eq "COMPLETED"){
        if(-not ($a.PSObject.Properties.Name -contains "closeReceiptRef")){$unclosed+=$a.agentId}
    }
}
C "registryLoaded" ($reg.Count -gt 0) "Registry has $($reg.Count) agents"
C "noStaleAgents" ($staleAgents.Count -eq 0) "Stale agents: $($staleAgents.Count) [$($staleAgents -join ',')]"
C "noUnclosedAgents" ($unclosed.Count -eq 0) "Unclosed (completed without receipt): $($unclosed.Count)"
C "openAgentCount" ($openAgents.Count -le 8) "Open agents: $($openAgents.Count)"
$out=[PSCustomObject]@{registryPath=$RegistryPath;checkedAt=(Get-Date -Format "o");overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;staleAgents=$staleAgents;openAgents=$openAgents;unclosed=$unclosed;results=$r}
$out|ConvertTo-Json -Depth 4
if($o){exit 0}else{exit 1}
