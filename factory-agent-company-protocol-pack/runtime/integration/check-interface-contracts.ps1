<# .SYNOPSIS Checks that all cross-worker interface contracts match between producers and consumers. #>
param([Parameter(Mandatory=$true)][string]$ContractsPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0;$mismatches=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$c=Get-Content $ContractsPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$c.PSObject.Properties.Name
C "contractsDefined" ($pp -contains "contracts" -and $c.contracts -is [array] -and $c.contracts.Count -gt 0) "contracts=$($c.contracts.Count)"
if($pp -contains "contracts"){
    foreach($ct in $c.contracts){
        $ctp=$ct.PSObject.Properties.Name
        $id=$ct.contractId
        C "$id.producer" ($ctp -contains "producer" -and $ct.producer -is [string]) "producer=$($ct.producer)"
        C "$id.consumer" ($ctp -contains "consumer" -and $ct.consumer -is [string]) "consumer=$($ct.consumer)"
        C "$id.endpoint" ($ctp -contains "endpoint") "endpoint defined"
        $reqMatch = $ctp -contains "requestSchemaHash" -and $ctp -contains "consumerRequestSchemaHash" -and $ct.requestSchemaHash -eq $ct.consumerRequestSchemaHash
        C "$id.reqMatch" $reqMatch "request schema match"
        $resMatch = $ctp -contains "responseSchemaHash" -and $ctp -contains "consumerResponseSchemaHash" -and $ct.responseSchemaHash -eq $ct.consumerResponseSchemaHash
        C "$id.resMatch" $resMatch "response schema match"
        $errMatch = $ctp -contains "errorShapeHash" -and $ctp -contains "consumerErrorShapeHash" -and $ct.errorShapeHash -eq $ct.consumerErrorShapeHash
        C "$id.errMatch" $errMatch "error shape match"
        $authMatch = $ctp -contains "authAssumption" -and $ctp -contains "consumerAuthAssumption" -and $ct.authAssumption -eq $ct.consumerAuthAssumption
        C "$id.authMatch" $authMatch "auth assumption match"
        if(-not ($reqMatch -and $resMatch)){$mismatches+=$id}
    }
}
C "noMismatches" ($mismatches.Count -eq 0) "Contract mismatches: $($mismatches.Count)"
$out=[PSCustomObject]@{contractsPath=$ContractsPath;overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;mismatches=$mismatches;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
