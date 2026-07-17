param([Parameter(Mandatory=$true)][string]$ManifestPath,[string]$ProtocolPackRoot,[string]$ResultsDir)
if(-not$ProtocolPackRoot){$ProtocolPackRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}
if(-not$ResultsDir){$ResultsDir="$ProtocolPackRoot\runtime\results"}
ni -Force -ItemType Directory $ResultsDir|Out-Null
$rs="$ProtocolPackRoot\runtime\scripts"
$all=@();$bk=0;$wn=0;$er=0;$pk=0
try{$m=gc $ManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 2}

function Inv($sn){
  $sp="$rs\$sn"
  $j=& powershell -NoProfile -File $sp @args 2>$null|Out-String
  if(!$j.Trim()){return [PSCustomObject]@{script=$sn;overall="ERROR";error="Empty output"}}
  try{$r=$j|ConvertFrom-Json;return [PSCustomObject]@{script=$sn;overall=$r.overall;tc=$r.totalChecks;pc=$r.passedChecks;fc=$r.failedChecks}}catch{return [PSCustomObject]@{script=$sn;overall="ERROR";error=$_.Exception.Message}}
}
function A($r){$script:all+=$r;switch($r.overall){"PASS"{$script:pk++}"FAIL"{$script:bk++}"WARNING"{$script:wn++}default{$script:er++}}}

$P=$m.PSObject.Properties.Name
if($P -contains "capsules"){foreach($c in $m.capsules){A (Inv "validate-worker-capsule.ps1" -CapsulePath $c -ProtocolPackRoot $ProtocolPackRoot)}}
if($P -contains "progressReports"){foreach($c in $m.progressReports){A (Inv "validate-progress-report.ps1" -InputPath $c)}}
if($P -contains "statusReports"){foreach($c in $m.statusReports){A (Inv "validate-worker-status-report.ps1" -InputPath $c)}}
if($P -contains "handoffs"){foreach($c in $m.handoffs){A (Inv "validate-worker-handoff.ps1" -InputPath $c)}}
if($P -contains "closeReceipts"){foreach($c in $m.closeReceipts){A (Inv "validate-agent-close-receipt.ps1" -InputPath $c)}}
if($P -contains "scopeDefs"){foreach($c in $m.scopeDefs){A (Inv "check-scope-isolation.ps1" -ScopeDefPath $c)}}
if($P -contains "evidenceManifests"){foreach($c in $m.evidenceManifests){$bd=Split-Path -Parent $c;A (Inv "check-evidence-integrity.ps1" -ManifestPath $c -BasePath $bd)}}

if($er -gt 0){$vd="AGENT_PROTOCOL_ERROR";$ec=2}
elseif($bk -gt 0){$vd="AGENT_PROTOCOL_BLOCKED";$ec=1}
elseif($wn -gt 0){$vd="AGENT_PROTOCOL_WARNING";$ec=0}
else{$vd="AGENT_PROTOCOL_VALID";$ec=0}

$o=[PSCustomObject]@{manifestPath=$ManifestPath;suiteEnd=(Get-Date -Format "o");overall=if($ec -eq 0){"PASS"}else{"FAIL"};verdict=$vd;artifactsChecked=$all.Count;blockingCount=$bk;warningCount=$wn;errorCount=$er;passCount=$pk;results=$all}
$o|ConvertTo-Json -Depth 5
$rp="$ResultsDir\agent-protocol-integrity-result.json"
$o|ConvertTo-Json -Depth 5|Out-File $rp -Encoding utf8
exit $ec
