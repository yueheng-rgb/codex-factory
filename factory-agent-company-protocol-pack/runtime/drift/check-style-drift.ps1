<# .SYNOPSIS Detects inconsistent error shapes and style drift across modules. #>
param([Parameter(Mandatory=$true)][string]$StyleManifestPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0;$drifts=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$s=Get-Content $StyleManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$s.PSObject.Properties.Name
C "modulesDefined" ($pp -contains "modules" -and $s.modules -is [array] -and $s.modules.Count -gt 0) "modules=$($s.modules.Count)"
if($pp -contains "modules"){
    $refErrorShape=$null
    foreach($mod in $s.modules){
        if($null -eq $refErrorShape -and $mod.PSObject.Properties.Name -contains "errorShape"){
            $refErrorShape=$mod.errorShape
        }
        if($mod.PSObject.Properties.Name -contains "errorShape" -and $refErrorShape -ne $null){
            if($mod.errorShape -ne $refErrorShape){$drifts+="$($mod.name):errorShape"}
        }
    }
}
C "consistentErrorShapes" ($drifts.Count -eq 0) "Error shape drifts: $($drifts.Count)"
$out=[PSCustomObject]@{styleManifestPath=$StyleManifestPath;overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;drifts=$drifts;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
