<#
.SYNOPSIS
    Validates a worker progress report JSON against the worker-reporting schema.
.DESCRIPTION
    Checks all required fields for a PROGRESS-type report. Outputs machine-readable JSON.
.PARAMETER InputPath
    Path to the progress report JSON file.
.EXAMPLE
    powershell -File validate-progress-report.ps1 -InputPath ./report.json
#>
param([Parameter(Mandatory=$true)][string]$InputPath, [switch]$WhatIf)

$results=@(); $overall=$true; $tc=0; $pc=0; $fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:overall=$false};$script:results+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}

try{$r=Get-Content $InputPath -Raw -ErrorAction Stop|ConvertFrom-Json}catch{$o=[PSCustomObject]@{inputPath=$InputPath;validatedAt=(Get-Date -Format "o");parseError=$_.Exception.Message;overall="FAIL";totalChecks=0;passedChecks=0;failedChecks=0;results=@()};$o|ConvertTo-Json -Depth 4;exit 1}
$p=$r.PSObject.Properties.Name

C "reportId" ($p -contains "reportId" -and $r.reportId -is [string] -and $r.reportId.Trim().Length -gt 0) "reportId='$($r.reportId)'"
C "agentId" ($p -contains "agentId" -and $r.agentId -is [string] -and $r.agentId.Trim().Length -gt 0) "agentId='$($r.agentId)'"
C "capsuleId" ($p -contains "capsuleId" -and $r.capsuleId -is [string] -and $r.capsuleId.Trim().Length -gt 0) "capsuleId='$($r.capsuleId)'"
C "phase" ($p -contains "phase" -and $r.phase -is [string] -and $r.phase.Trim().Length -gt 0) "phase='$($r.phase)'"
C "reportType" ($p -contains "reportType" -and $r.reportType -in @("PROGRESS","BLOCKER","STATUS")) "reportType='$($r.reportType)'"
C "timestamp" {try{$d=[DateTime]::Parse($r.timestamp);$true}catch{$false}} "timestamp='$($r.timestamp)'"
C "detail" ($p -contains "detail" -and $r.detail -is [string] -and $r.detail.Trim().Length -gt 10) "detail length=$($r.detail.Length)"
C "completionPercent" ($p -contains "completionPercent" -and $r.completionPercent -is [int] -and $r.completionPercent -ge 0 -and $r.completionPercent -le 100) "completionPercent=$($r.completionPercent)"
C "filesCreated" ($p -contains "filesCreated" -and $r.filesCreated -is [array]) "filesCreated count=$($r.filesCreated.Count)"
C "blockersDetected" ($p -contains "blockersDetected" -and $r.blockersDetected -is [array]) "blockersDetected count=$($r.blockersDetected.Count)"
C "nextExpectedMilestone" ($p -contains "nextExpectedMilestone" -and $r.nextExpectedMilestone -is [string] -and $r.nextExpectedMilestone.Trim().Length -gt 0) "nextExpectedMilestone='$($r.nextExpectedMilestone)'"
C "nativeGenerated" ($p -contains "nativeGenerated" -and $r.nativeGenerated -eq $true) "nativeGenerated=true"
C "noMarkdownOnly" ($r.detail -is [string] -and $r.detail.Trim().Length -gt 20) "detail is substantive (length=$($r.detail.Length))"

$o=[PSCustomObject]@{inputPath=$InputPath;validatedAt=(Get-Date -Format "o");overall=if($overall){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$results}
$o|ConvertTo-Json -Depth 4
if($overall){exit 0}else{exit 1}
