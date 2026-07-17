<#
.SYNOPSIS Orchestrator Runtime Suite - runs all AGENT-3 scheduler/lifecycle/registry validators.
#>
param([Parameter(Mandatory=$true)][string]$ManifestPath,[string]$ProtocolPackRoot)
if(-not$ProtocolPackRoot){$ProtocolPackRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}
$rs="$ProtocolPackRoot\runtime";$sch="$rs\scheduler";$lcm="$rs\lifecycle";$reg="$rs\registry"
$all=@();$bk=0;$wn=0;$er=0;$pk=0
try{$m=Get-Content $ManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 2}
function Inv($spath){$j=& powershell -NoProfile -File $spath @args *>"$env:TEMP\ag3-inv.json";$raw=Get-Content "$env:TEMP\ag3-inv.json" -Raw;try{return $raw|ConvertFrom-Json}catch{return[PSCustomObject]@{overall="ERROR";error=$_.Exception.Message}}}
function A($r){$script:all+=$r;switch($r.overall){"PASS"{$script:pk++}"FAIL"{$script:bk++}"WARNING"{$script:wn++}default{$script:er++}}}
$P=$m.PSObject.Properties.Name
if($P -contains "taskGraphs"){foreach($x in $m.taskGraphs){A(Inv "$sch\create-task-graph.ps1" -DefinitionPath $x)}}
if($P -contains "capacityStates"){foreach($x in $m.capacityStates){A(Inv "$sch\check-capacity-preflight.ps1" -StatePath $x)}}
if($P -contains "spawnDecisions"){foreach($x in $m.spawnDecisions){A(Inv "$sch\validate-spawn-decision.ps1" -DecisionPath $x)}}
if($P -contains "dependencyChecks"){foreach($x in $m.dependencyChecks){$tid=Split-Path $x -Leaf;$tg="$sch\fixtures\valid-task-graph.json";A(Inv "$sch\check-dependency-readiness.ps1" -TaskGraphPath $tg -TaskId $tid)}}
if($P -contains "lifecycleChecks"){foreach($x in $m.lifecycleChecks){A(Inv "$lcm\check-agent-lifecycle.ps1" -RegistryPath $x)}}
if($P -contains "newAgents"){foreach($x in $m.newAgents){A(Inv "$reg\register-agent.ps1" -AgentPath $x -RegistryPath "$reg\fixtures\sim-registry.json")}}
if($er -gt 0){$vd="AGENT_PROTOCOL_ERROR";$ec=2}
elseif($bk -gt 0){$vd="AGENT_PROTOCOL_BLOCKED";$ec=1}
elseif($wn -gt 0){$vd="AGENT_PROTOCOL_WARNING";$ec=0}
else{$vd="AGENT_PROTOCOL_VALID";$ec=0}
$out=[PSCustomObject]@{manifestPath=$ManifestPath;suiteEnd=(Get-Date -Format "o");overall=if($ec -eq 0){"PASS"}else{"FAIL"};verdict=$vd;artifactsChecked=$all.Count;blockingCount=$bk;warningCount=$wn;errorCount=$er;passCount=$pk;results=$all}
$out|ConvertTo-Json -Depth 5
$out|ConvertTo-Json -Depth 5|Out-File "$rs\results\orchestrator-suite-result.json" -Encoding utf8
exit $ec
