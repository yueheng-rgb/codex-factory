<# .SYNOPSIS Checks whether all conditions are met to begin integration. #>
param([Parameter(Mandatory=$true)][string]$ReadinessPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$rd=Get-Content $ReadinessPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$rd.PSObject.Properties.Name
C "handoffsComplete" ($pp -contains "handoffsComplete" -and $rd.handoffsComplete -eq $true) "handoffsComplete"
C "contractsMatch" ($pp -contains "contractsMatch" -and $rd.contractsMatch -eq $true) "contractsMatch"
C "schemasConsistent" ($pp -contains "schemasConsistent" -and $rd.schemasConsistent -eq $true) "schemasConsistent"
C "noOpenAgents" ($pp -contains "openAgentCount" -and $rd.openAgentCount -eq 0) "openAgentCount=0"
C "noStaleAgents" ($pp -contains "staleAgentCount" -and $rd.staleAgentCount -eq 0) "staleAgentCount=0"
C "noBlockers" ($pp -contains "blockerCount" -and $rd.blockerCount -eq 0) "blockerCount=0"
C "allCloseReceipts" ($pp -contains "closeReceiptCount" -and $rd.closeReceiptCount -gt 0) "closeReceiptCount=$($rd.closeReceiptCount)"
C "verifierPassed" ($pp -contains "verifierPassed" -and $rd.verifierPassed -eq $true) "verifierPassed"
$out=[PSCustomObject]@{readinessPath=$ReadinessPath;overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
