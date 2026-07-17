<# .SYNOPSIS Checks that all builders have submitted handoffs and all dependency outputs exist. #>
param([Parameter(Mandatory=$true)][string]$ManifestPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0;$missing=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$m=Get-Content $ManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$m.PSObject.Properties.Name
C "expectedBuilders" ($pp -contains "expectedBuilders" -and $m.expectedBuilders -is [array] -and $m.expectedBuilders.Count -gt 0) "expectedBuilders=$($m.expectedBuilders.Count)"
C "submittedHandoffs" ($pp -contains "submittedHandoffs" -and $m.submittedHandoffs -is [array]) "submittedHandoffs=$($m.submittedHandoffs.Count)"
C "expectedOutputs" ($pp -contains "expectedOutputs" -and $m.expectedOutputs -is [array] -and $m.expectedOutputs.Count -gt 0) "expectedOutputs=$($m.expectedOutputs.Count)"
C "actualOutputs" ($pp -contains "actualOutputs" -and $m.actualOutputs -is [array]) "actualOutputs=$($m.actualOutputs.Count)"
if($pp -contains "expectedBuilders"){
    foreach($b in $m.expectedBuilders){
        $found = ($m.submittedHandoffs | Where-Object { $_ -eq $b }).Count -gt 0
        C "builder.$b.handoff" $found "Handoff from $b"
        if(-not $found){$missing+=$b}
    }
}
if($pp -contains "expectedOutputs"){
    foreach($eo in $m.expectedOutputs){
        $found = ($m.actualOutputs | Where-Object { $_ -eq $eo }).Count -gt 0
        C "output.$eo" $found "Expected output $eo"
        if(-not $found){$missing+="output:$eo"}
    }
}
C "readyForIntegration" ($pp -contains "readyForIntegration" -and $m.readyForIntegration -eq $true) "readyForIntegration=true"
C "noBlockers" ($pp -contains "blockers" -and $m.blockers -is [array] -and $m.blockers.Count -eq 0) "blockers=$($m.blockers.Count)"
C "allAgentsClosed" ($pp -contains "openAgents" -and $m.openAgents -is [array] -and $m.openAgents.Count -eq 0) "openAgents=$($m.openAgents.Count)"
$out=[PSCustomObject]@{manifestPath=$ManifestPath;checkedAt=(Get-Date -Format "o");overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;missing=$missing;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
