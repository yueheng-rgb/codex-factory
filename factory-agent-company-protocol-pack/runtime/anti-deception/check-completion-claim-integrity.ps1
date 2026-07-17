<# .SYNOPSIS Checks that agent completion claims are backed by verifier confirmation and evidence. #>
param([Parameter(Mandatory=$true)][string]$ClaimPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$cl=Get-Content $ClaimPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$cl.PSObject.Properties.Name
C "agentId" ($pp -contains "agentId") "agentId=$($cl.agentId)"
C "completionClaim" ($pp -contains "completionPercent" -and $cl.completionPercent -eq 100) "completionPercent=100"  
C "verifierConfirmed" ($pp -contains "verifierConfirmed" -and $cl.verifierConfirmed -eq $true) "verifierConfirmed"
C "integrityPassed" ($pp -contains "integrityCheckPassed" -and $cl.integrityCheckPassed -eq $true) "integrityCheckPassed"
C "evidencePaths" ($pp -contains "evidencePaths" -and $cl.evidencePaths -is [array] -and $cl.evidencePaths.Count -gt 0) "evidencePaths=$($cl.evidencePaths.Count)"
C "hasCloseReceipt" ($pp -contains "closeReceiptRef") "closeReceiptRef=$($cl.closeReceiptRef)"
C "noProductClaim" (-not (($cl|ConvertTo-Json -Depth 4) -match '(?i)\bproduct\s+(is\s+)?(correct|ready|complete)\b')) "No product correctness"
$out=[PSCustomObject]@{claimPath=$ClaimPath;overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
