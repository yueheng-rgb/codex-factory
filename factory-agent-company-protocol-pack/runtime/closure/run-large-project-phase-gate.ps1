<# .SYNOPSIS Combined large-project phase gate: integration + anti-deception + drift + closure. #>
param([Parameter(Mandatory=$true)][string]$ManifestPath,[string]$ProtocolPackRoot)
if(-not$ProtocolPackRoot){$ProtocolPackRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}
$ig="$ProtocolPackRoot\runtime\integration";$ad="$ProtocolPackRoot\runtime\anti-deception";$dr="$ProtocolPackRoot\runtime\drift";$cl="$ProtocolPackRoot\runtime\closure"
$all=@();$bk=0;$pk=0
try{$m=Get-Content $ManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 2}
function Inv($spath){$j=& powershell -NoProfile -File $spath @args *>"$env:TEMP\ag4-ph.json";$raw=Get-Content "$env:TEMP\ag4-ph.json" -Raw;try{return $raw|ConvertFrom-Json}catch{return[PSCustomObject]@{overall="ERROR"}}}
$P=$m.PSObject.Properties.Name
if($P -contains "integrationGateManifest"){$v=Inv "$ig\run-integration-gate.ps1" -ManifestPath $m.integrationGateManifest -ProtocolPackRoot $ProtocolPackRoot;$all+=$v;if($v.verdict -eq "INTEGRATION_READY"){$pk++}else{$bk++}}
if($P -contains "antiDeceptionGateManifest"){$v=Inv "$ad\run-anti-deception-gate.ps1" -ManifestPath $m.antiDeceptionGateManifest -ProtocolPackRoot $ProtocolPackRoot;$all+=$v;if($v.verdict -eq "ANTI_DECEPTION_CLEAN"){$pk++}else{$bk++}}
if($P -contains "driftGateManifest"){$v=Inv "$dr\run-drift-gate.ps1" -ManifestPath $m.driftGateManifest -ProtocolPackRoot $ProtocolPackRoot;$all+=$v;if($v.verdict -eq "DRIFT_CLEAN"){$pk++}else{$bk++}}
if($P -contains "closureChecks"){foreach($x in $m.closureChecks){$v=Inv "$cl\check-phase-closure-integrity.ps1" -ClosurePath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
$vd=if($bk -gt 0){"PHASE_BLOCKED"}else{"PHASE_READY"}
$out=[PSCustomObject]@{manifestPath=$ManifestPath;verdict=$vd;artifactsChecked=$all.Count;passCount=$pk;blockCount=$bk;results=$all}
$out|ConvertTo-Json -Depth 5; exit $(if($bk -gt 0){1}else{0})
