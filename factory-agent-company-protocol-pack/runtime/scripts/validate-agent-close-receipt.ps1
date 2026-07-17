<#
.SYNOPSIS
    Validates an agent close receipt JSON against the close-receipt schema.
#>
param([Parameter(Mandatory=$true)][string]$InputPath, [switch]$WhatIf)

$results=@(); $overall=$true; $tc=0; $pc=0; $fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:overall=$false};$script:results+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}

try{$r=Get-Content $InputPath -Raw -ErrorAction Stop|ConvertFrom-Json}catch{$o=[PSCustomObject]@{inputPath=$InputPath;validatedAt=(Get-Date -Format "o");parseError=$_.Exception.Message;overall="FAIL";totalChecks=0;passedChecks=0;failedChecks=0;results=@()};$o|ConvertTo-Json -Depth 4;exit 1}
$p=$r.PSObject.Properties.Name

C "receiptId" ($p -contains "receiptId" -and $r.receiptId -is [string] -and $r.receiptId.Trim().Length -gt 0) "receiptId='$($r.receiptId)'"
C "agentId" ($p -contains "agentId" -and $r.agentId -is [string] -and $r.agentId.Trim().Length -gt 0) "agentId='$($r.agentId)'"
C "phase" ($p -contains "phase" -and $r.phase -is [string] -and $r.phase.Trim().Length -gt 0) "phase='$($r.phase)'"
C "role" ($p -contains "role" -and $r.role -is [string] -and $r.role.Trim().Length -gt 0) "role='$($r.role)'"
C "closedAt" {try{$d=[DateTime]::Parse($r.closedAt);$true}catch{$false}} "closedAt='$($r.closedAt)'"
C "closeReason" ($p -contains "closeReason" -and $r.closeReason -in @("COMPLETED","FAILED","STALE","REPLACED")) "closeReason='$($r.closeReason)'"
C "outputSummary" ($p -contains "outputSummary" -and $r.outputSummary -is [string] -and $r.outputSummary.Trim().Length -gt 10) "outputSummary length=$($r.outputSummary.Length)"
C "evidencePaths" ($p -contains "evidencePaths" -and $r.evidencePaths -is [array] -and $r.evidencePaths.Count -gt 0) "evidencePaths count=$($r.evidencePaths.Count)"
C "verifierConfirmation" ($p -contains "verifierConfirmation") "verifierConfirmation defined: $($r.verifierConfirmation)"
C "integrityCheckPassed" ($p -contains "integrityCheckPassed") "integrityCheckPassed defined: $($r.integrityCheckPassed)"
C "nativeGenerated" ($p -contains "nativeGenerated" -and $r.nativeGenerated -eq $true) "nativeGenerated=true"

if ($r.closeReason -eq "REPLACED") {
    C "replacementAgentId" ($p -contains "replacementAgentId" -and $r.replacementAgentId -is [string] -and $r.replacementAgentId.Trim().Length -gt 0) "replacementAgentId='$($r.replacementAgentId)'"
}
if ($r.closeReason -eq "FAILED") {
    C "spawnFailureClassified" ($p -contains "spawnFailureClassified" -and $r.spawnFailureClassified -in @("TRANSIENT","CONFIGURATION","PERMANENT")) "spawnFailureClassified='$($r.spawnFailureClassified)'"
}

$productClaim = ($r|ConvertTo-Json -Depth 3) -match '(?i)\bproduct\s+(is\s+)?(correct|PASS|ready|complete)\b'
C "noProductPassClaim" (-not $productClaim) "Product correctness claim: $productClaim"

$manualPass = ($r|ConvertTo-Json -Depth 3) -match '(?i)\bmanual\s+PASS\b'
C "noManualPassOnly" (-not $manualPass) "Manual PASS-only: $manualPass"

$o=[PSCustomObject]@{inputPath=$InputPath;validatedAt=(Get-Date -Format "o");overall=if($overall){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$results}
$o|ConvertTo-Json -Depth 4
if($overall){exit 0}else{exit 1}
