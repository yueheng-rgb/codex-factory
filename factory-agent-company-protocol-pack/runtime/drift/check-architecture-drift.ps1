<# .SYNOPSIS Detects architecture boundary violations via prefix matching. #>
param([Parameter(Mandatory=$true)][string]$DriftManifestPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0;$violations=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$d=Get-Content $DriftManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$d.PSObject.Properties.Name
C "boundariesDefined" ($pp -contains "boundaries" -and $d.boundaries -is [array] -and $d.boundaries.Count -gt 0) "boundaries=$($d.boundaries.Count)"
if($pp -contains "boundaries"){
    foreach($b in $d.boundaries){
        $ok=$true
        if($b.PSObject.Properties.Name -contains "actualImports" -and $b.PSObject.Properties.Name -contains "forbiddenImports"){
            foreach($ai in $b.actualImports){
                foreach($fi in $b.forbiddenImports){
                    if($ai -like "$fi*"){
                        $violations+="$($b.module):$ai(vs $fi)";$ok=$false
                    }
                }
            }
        }
        C "boundary.$($b.module)" $ok "Module $($b.module) boundary check"
    }
}
C "noDriftViolations" ($violations.Count -eq 0) "Drift violations: $($violations.Count) [$($violations -join '; ')]"
$out=[PSCustomObject]@{driftManifestPath=$DriftManifestPath;overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;violations=$violations;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
