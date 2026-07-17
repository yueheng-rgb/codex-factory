<# .SYNOPSIS Combined anti-deception gate. #>
param([Parameter(Mandatory=$true)][string]$ManifestPath,[string]$ProtocolPackRoot)
if(-not$ProtocolPackRoot){$ProtocolPackRoot=Split-Path -Parent (Split-Path -Parent $PSScriptRoot)}
$ad="$ProtocolPackRoot\runtime\anti-deception";$all=@();$bk=0;$pk=0
try{$m=Get-Content $ManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 2}
function Inv($spath){$j=& powershell -NoProfile -File $spath @args *>"$env:TEMP\ag4-ad.json";$raw=Get-Content "$env:TEMP\ag4-ad.json" -Raw;try{return $raw|ConvertFrom-Json}catch{return[PSCustomObject]@{overall="ERROR"}}}
$P=$m.PSObject.Properties.Name
if($P -contains "scopeDefs"){foreach($x in $m.scopeDefs){$v=Inv "$ad\check-hidden-fallback.ps1" -ScopeDefPath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
if($P -contains "selfReports"){foreach($x in $m.selfReports){$v=Inv "$ad\check-self-report-vs-evidence.ps1" -ReportPath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
if($P -contains "completionClaims"){foreach($x in $m.completionClaims){$v=Inv "$ad\check-completion-claim-integrity.ps1" -ClaimPath $x;$all+=$v;if($v.overall -eq "PASS"){$pk++}else{$bk++}}}
$vd=if($bk -gt 0){"DECEPTION_BLOCKED"}else{"ANTI_DECEPTION_CLEAN"}
$out=[PSCustomObject]@{manifestPath=$ManifestPath;verdict=$vd;artifactsChecked=$all.Count;passCount=$pk;blockCount=$bk;results=$all}
$out|ConvertTo-Json -Depth 5; exit $(if($bk -gt 0){1}else{0})
