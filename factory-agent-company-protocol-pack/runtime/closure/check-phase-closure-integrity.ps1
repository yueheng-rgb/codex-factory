<# .SYNOPSIS Checks that a phase can be safely closed: no open/stale agents, no blockers, all gates passed. #>
param([Parameter(Mandatory=$true)][string]$ClosurePath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0;$blockers=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$c=Get-Content $ClosurePath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$c.PSObject.Properties.Name
C "phaseId" ($pp -contains "phaseId" -and $c.phaseId -is [string] -and $c.phaseId.Trim().Length -gt 0) "phaseId=$($c.phaseId)"
C "noOpenAgents" ($pp -contains "openAgentCount" -and $c.openAgentCount -eq 0) "openAgents=0"
C "noStaleAgents" ($pp -contains "staleAgentCount" -and $c.staleAgentCount -eq 0) "staleAgents=0"
C "integrationPassed" ($pp -contains "integrationGatePassed" -and $c.integrationGatePassed -eq $true) "integrationGatePassed"
C "antiDeceptionPassed" ($pp -contains "antiDeceptionGatePassed" -and $c.antiDeceptionGatePassed -eq $true) "antiDeceptionGatePassed"
C "driftPassed" ($pp -contains "driftGatePassed" -and $c.driftGatePassed -eq $true) "driftGatePassed"
C "verifierPassed" ($pp -contains "verifierPassed" -and $c.verifierPassed -eq $true) "verifierPassed"
C "allCloseReceipts" ($pp -contains "allCloseReceiptsPresent" -and $c.allCloseReceiptsPresent -eq $true) "allCloseReceiptsPresent"
C "noBlockers" ($pp -contains "blockerCount" -and $c.blockerCount -eq 0) "blockerCount=0"
if($c.openAgentCount -gt 0){$blockers+="open-agents"}
if($c.staleAgentCount -gt 0){$blockers+="stale-agents"}
if(-not $c.integrationGatePassed){$blockers+="integration"}
if(-not $c.antiDeceptionGatePassed){$blockers+="anti-deception"}
if(-not $c.driftGatePassed){$blockers+="drift"}
if(-not $c.verifierPassed){$blockers+="verifier"}
if($c.blockerCount -gt 0){$blockers+="blockers"}
C "closureAllowed" ($blockers.Count -eq 0) "Blockers: $($blockers.Count) [$($blockers -join ',')]"
$out=[PSCustomObject]@{closurePath=$ClosurePath;overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;blockers=$blockers;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
