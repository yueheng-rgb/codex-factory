<#
.SYNOPSIS
    Validates a worker status report JSON. Status reports must NOT claim phase/product PASS.
#>
param([Parameter(Mandatory=$true)][string]$InputPath, [switch]$WhatIf)

$results=@(); $overall=$true; $tc=0; $pc=0; $fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:overall=$false};$script:results+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}

try{$r=Get-Content $InputPath -Raw -ErrorAction Stop|ConvertFrom-Json}catch{$o=[PSCustomObject]@{inputPath=$InputPath;validatedAt=(Get-Date -Format "o");parseError=$_.Exception.Message;overall="FAIL";totalChecks=0;passedChecks=0;failedChecks=0;results=@()};$o|ConvertTo-Json -Depth 4;exit 1}
$p=$r.PSObject.Properties.Name

C "reportId" ($p -contains "reportId" -and $r.reportId -is [string] -and $r.reportId.Trim().Length -gt 0) "reportId='$($r.reportId)'"
C "agentId" ($p -contains "agentId" -and $r.agentId -is [string] -and $r.agentId.Trim().Length -gt 0) "agentId='$($r.agentId)'"
C "reportType" ($p -contains "reportType" -and $r.reportType -eq "STATUS") "reportType=STATUS"
C "detail" ($p -contains "detail" -and $r.detail -is [string] -and $r.detail.Trim().Length -gt 10) "detail length=$($r.detail.Length)"
C "completionPercent" ($p -contains "completionPercent" -and $r.completionPercent -is [int] -and $r.completionPercent -ge 0 -and $r.completionPercent -le 100) "completionPercent=$($r.completionPercent)"
C "nativeGenerated" ($p -contains "nativeGenerated" -and $r.nativeGenerated -eq $true) "nativeGenerated=true"

$hasPhasePass = ($r.detail -match '(?i)\bphase\s+PASS\b') -or ($r.detail -match '(?i)\bPASS\b.*\bphase\b')
C "noPhasePassClaim" (-not $hasPhasePass) "Phase PASS claim: $hasPhasePass"

$hasProductPass = ($r.detail -match '(?i)\bproduct\s+(is\s+)?(correct|PASS|ready|complete)\b')
C "noProductPassClaim" (-not $hasProductPass) "Product correctness claim: $hasProductPass"

C "hasEvidencePaths" ($p -contains "filesCreated" -and $r.filesCreated -is [array]) "filesCreated defined"
C "noMarkdownOnly" ($r.detail -is [string] -and $r.detail.Trim().Length -gt 20) "detail is substantive"

$o=[PSCustomObject]@{inputPath=$InputPath;validatedAt=(Get-Date -Format "o");overall=if($overall){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$results}
$o|ConvertTo-Json -Depth 4
if($overall){exit 0}else{exit 1}
