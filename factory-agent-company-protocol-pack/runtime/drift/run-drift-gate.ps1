<# .SYNOPSIS Combined drift/quality gate. #>
param([Parameter(Mandatory=$true)][string]$ManifestPath,[string]$ProtocolPackRoot)
if(-not$ProtocolPackRoot){$ProtocolPackRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}
$dr="$ProtocolPackRoot\runtime\drift";$all=@();$bk=0;$pk=0
try{$m=Get-Content $ManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 2}
function Inv($spath){$j=& powershell -NoProfile -File $spath @args *>"$env:TEMP\ag4-dr.json";$raw=Get-Content "$env:TEMP\ag4-dr.json" -Raw;try{return $raw|ConvertFrom-Json}catch{return[PSCustomObject]@{overall="ERROR"}}}
$P=$m.PSObject.Properties.Name
if($P -contains "driftManifests"){foreach($x in $m.driftManifests){$v=Inv "$dr\check-architecture-drift.ps1" -DriftManifestPath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
if($P -contains "styleManifests"){foreach($x in $m.styleManifests){$v=Inv "$dr\check-style-drift.ps1" -StyleManifestPath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
if($P -contains "qualityManifests"){foreach($x in $m.qualityManifests){$v=Inv "$dr\check-quality-gap-triggers.ps1" -QualityManifestPath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
$vd=if($bk -gt 0){"DRIFT_BLOCKED"}else{"DRIFT_CLEAN"}
$out=[PSCustomObject]@{manifestPath=$ManifestPath;verdict=$vd;artifactsChecked=$all.Count;passCount=$pk;blockCount=$bk;results=$all}
$out|ConvertTo-Json -Depth 5; exit $(if($bk -gt 0){1}else{0})
