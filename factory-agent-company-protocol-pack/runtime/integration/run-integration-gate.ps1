<# .SYNOPSIS Runs all integration checks and outputs combined verdict. #>
param([Parameter(Mandatory=$true)][string]$ManifestPath,[string]$ProtocolPackRoot)
if(-not$ProtocolPackRoot){$ProtocolPackRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}
$ig="$ProtocolPackRoot\runtime\integration";$all=@();$bk=0;$pk=0
try{$m=Get-Content $ManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 2}
function Inv($spath){$j=& powershell -NoProfile -File $spath @args *>"$env:TEMP\ag4-ig.json";$raw=Get-Content "$env:TEMP\ag4-ig.json" -Raw;try{return $raw|ConvertFrom-Json}catch{return[PSCustomObject]@{overall="ERROR"}}}
$P=$m.PSObject.Properties.Name
if($P -contains "handoffManifests"){foreach($x in $m.handoffManifests){$v=Inv "$ig\check-handoff-completeness.ps1" -ManifestPath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
if($P -contains "contracts"){foreach($x in $m.contracts){$v=Inv "$ig\check-interface-contracts.ps1" -ContractsPath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
if($P -contains "schemaManifests"){foreach($x in $m.schemaManifests){$v=Inv "$ig\check-shared-schema-consistency.ps1" -SchemaManifestPath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
if($P -contains "readinessChecks"){foreach($x in $m.readinessChecks){$v=Inv "$ig\check-integration-readiness.ps1" -ReadinessPath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
$vd=if($bk -gt 0){"INTEGRATION_BLOCKED"}else{"INTEGRATION_READY"};$ec=if($bk -gt 0){1}else{0}
$out=[PSCustomObject]@{manifestPath=$ManifestPath;verdict=$vd;artifactsChecked=$all.Count;passCount=$pk;blockCount=$bk;results=$all}
$out|ConvertTo-Json -Depth 5; exit $ec
