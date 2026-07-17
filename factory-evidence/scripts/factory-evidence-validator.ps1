# Factory Evidence Validator MVP
param($ClaimedLevel="E5_RAW_OUTPUT_EXECUTION",$EvidenceLevel="E4_LIVE_EXECUTED_FIXTURE",$ClaimText="",[switch]$Json)
$lv=@{"E0_UNSUPPORTED"=0;"E1_DESIGN_ANALYSIS"=1;"E2_POLICY_REVIEW"=2;"E3_LIVE_INSPECTED"=3;"E4_LIVE_EXECUTED_FIXTURE"=4;"E5_RAW_OUTPUT_EXECUTION"=5;"E6_REALWORLD_LOCAL"=6;"E7_PRODUCTION_VALIDATED"=7;"E8_REPLICATED_EVIDENCE"=8}
$np=@("SNAPSHOT_WORKING_CONTEXT","ATTACH_PACKET_WORKING_CONTEXT","DASHBOARD_DIAGNOSTIC_VIEW","USER_CHAT_SUMMARY","FOREIGN_CONTEXT","CORRUPT_OR_UNTRUSTED")
$bw=@("universal","always","guaranteed","proven universally","works everywhere")
$r=@{timestamp=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz");claimedLevel=$ClaimedLevel;evidenceLevel=$EvidenceLevel;valid=$false;verdict="FAIL";reason="";caveat=""}
Write-Host "=== Evidence Validator ===" -F Cyan
if($EvidenceLevel -in $np){$r.reason="NON_PRIMARY: $EvidenceLevel cannot support claims.";Write-Host "FAIL: $($r.reason)" -F Red}
elseif($EvidenceLevel -eq "CORRUPT_OR_UNTRUSTED"){$r.reason="CORRUPT: Cannot support any claim.";Write-Host "FAIL: $($r.reason)" -F Red}
elseif($EvidenceLevel -eq "FOREIGN_CONTEXT"){$r.reason="FOREIGN: Wrong projectId.";Write-Host "FAIL: $($r.reason)" -F Red}
else{$cn=$lv[$ClaimedLevel];$en=$lv[$EvidenceLevel]
if($cn -gt $en){$r.reason="OVERCLAIM: Claimed $ClaimedLevel exceeds evidence $EvidenceLevel.";Write-Host "FAIL: $($r.reason)" -F Red}
elseif($cn -eq $en){$cv="";if($EvidenceLevel -eq "E3_LIVE_INSPECTED"){$cv="Live-inspected, not full E2E"}
elseif($EvidenceLevel -eq "E4_LIVE_EXECUTED_FIXTURE"){$cv="Fixture, not real project"}
elseif($EvidenceLevel -eq "E6_REALWORLD_LOCAL"){$cv="Local, not production"}
if($cv){$r.caveat=$cv;$r.valid=$true;$r.verdict="CAVEAT";$r.reason="CAVEAT_REQUIRED";Write-Host "CAVEAT: $cv" -F Yellow}
else{$r.valid=$true;$r.verdict="PASS";$r.reason="Supported.";Write-Host "PASS" -F Green}}
else{$r.valid=$true;$r.verdict="PASS";$r.reason="Claim below evidence. Supported.";Write-Host "PASS" -F Green}}
if($ClaimText){foreach($w in $bw){if($ClaimText -match $w){$r.reason="BLOCKED: '$w' claim unsupported.";$r.valid=$false;$r.verdict="FAIL";Write-Host "FAIL: $($r.reason)" -F Red;break}}}
if($Json){$r|ConvertTo-Json -Depth 3}else{Write-Host "Verdict: $($r.verdict)"}
exit $(if($r.valid){0}else{1})
