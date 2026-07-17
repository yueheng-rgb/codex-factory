<# .SYNOPSIS Detects duplicate shared types and missing schema owners. #>
param([Parameter(Mandatory=$true)][string]$SchemaManifestPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0;$dupes=@();$orphans=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$s=Get-Content $SchemaManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$s.PSObject.Properties.Name
C "schemasDefined" ($pp -contains "schemas" -and $s.schemas -is [array] -and $s.schemas.Count -gt 0) "schemas=$($s.schemas.Count)"
if($pp -contains "schemas"){
    $signatures=@{}
    foreach($sc in $s.schemas){
        $sig = "$($sc.typeName)|$($sc.fields -join ',')"
        if($signatures.ContainsKey($sig)){$dupes+=$sc.schemaId}
        else{$signatures[$sig]=$sc.schemaId}
        C "$($sc.schemaId).owner" ($sc.PSObject.Properties.Name -contains "owner" -and $sc.owner -is [string] -and $sc.owner.Trim().Length -gt 0) "owner=$($sc.owner)"
        if(-not ($sc.PSObject.Properties.Name -contains "owner")){$orphans+=$sc.schemaId}
    }
}
C "noDuplicates" ($dupes.Count -eq 0) "Duplicate schemas: $($dupes.Count)"
C "noOrphanSchemas" ($orphans.Count -eq 0) "Orphan (no owner): $($orphans.Count)"
$out=[PSCustomObject]@{schemaManifestPath=$SchemaManifestPath;overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;duplicates=$dupes;orphans=$orphans;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
