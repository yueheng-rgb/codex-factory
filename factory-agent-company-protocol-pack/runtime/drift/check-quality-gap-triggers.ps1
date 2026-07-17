<# .SYNOPSIS Detects quality gaps: missing README, superficial tests, UI-depth, security, API completeness. #>
param([Parameter(Mandatory=$true)][string]$QualityManifestPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0;$gaps=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$q=Get-Content $QualityManifestPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$q.PSObject.Properties.Name
C "hasReadme" ($pp -contains "hasReadme" -and $q.hasReadme -eq $true) "hasReadme"
C "testDepth" ($pp -contains "testDepth" -and $q.testDepth -in @("unit","integration","e2e")) "testDepth=$($q.testDepth)"
C "uiDepth" ($pp -contains "uiDepth" -and $q.uiDepth -in @("basic","interactive","responsive","accessible")) "uiDepth=$($q.uiDepth)"
C "securityReviewed" ($pp -contains "securityReviewed" -and $q.securityReviewed -eq $true) "securityReviewed"
C "apiComplete" ($pp -contains "apiComplete" -and $q.apiComplete -eq $true) "apiComplete"
foreach($check in @("hasReadme","testDepth","uiDepth","securityReviewed","apiComplete")){
    $v=$q.$check
    if($check -eq "hasReadme" -and -not $v){$gaps+="no-readme"}
    if($check -eq "testDepth" -and $v -eq "unit"){$gaps+="superficial-tests"}
    if($check -eq "uiDepth" -and $v -eq "basic"){$gaps+="ui-depth-gap"}
    if($check -eq "securityReviewed" -and -not $v){$gaps+="security-unreviewed"}
    if($check -eq "apiComplete" -and -not $v){$gaps+="api-incomplete"}
}
C "qualityGapsTriggered" ($gaps.Count -eq 0) "Quality gaps: $($gaps.Count) [$($gaps -join ',')]"
$out=[PSCustomObject]@{qualityManifestPath=$QualityManifestPath;overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;gaps=$gaps;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
