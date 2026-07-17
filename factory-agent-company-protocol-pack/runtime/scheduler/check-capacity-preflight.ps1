<#
.SYNOPSIS Checks capacity before spawning agents.
#>
param([Parameter(Mandatory=$true)][string]$StatePath)
$results=@(); $overall=$true; $tc=0; $pc=0; $fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:overall=$false};$script:results+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$s=Get-Content $StatePath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$s.PSObject.Properties.Name
C "maxAgentsDefined" ($pp -contains "maxAgents" -and $s.maxAgents -is [int] -and $s.maxAgents -ge 1) "maxAgents=$($s.maxAgents)"
C "openAgentsDefined" ($pp -contains "openAgents" -and $s.openAgents -is [array]) "openAgents=$($s.openAgents.Count)"
C "staleAgentsDefined" ($pp -contains "staleAgents" -and $s.staleAgents -is [array]) "staleAgents=$($s.staleAgents.Count)"
$staleOpen = @($s.openAgents | Where-Object { $_ -in $s.staleAgents })
C "noUnsafeStaleOpen" ($staleOpen.Count -eq 0) "Stale+open overlap=$($staleOpen.Count)"
C "underCapacity" ($s.openAgents.Count -lt $s.maxAgents) "openAgents($($s.openAgents.Count)) < maxAgents($($s.maxAgents))"
$o=[PSCustomObject]@{statePath=$StatePath;checkedAt=(Get-Date -Format "o");overall=if($overall){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$results}
$o|ConvertTo-Json -Depth 4
if($overall){exit 0}else{exit 1}
