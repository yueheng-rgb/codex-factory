<#
.SYNOPSIS
    Validates a worker handoff JSON against the worker-handoff schema.
    Checks SHA256 presence, contract checklist, transcript ref, and anti-deception gates.
#>
param([Parameter(Mandatory=$true)][string]$InputPath, [switch]$WhatIf)

$results=@(); $overall=$true; $tc=0; $pc=0; $fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:overall=$false};$script:results+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}

try{$r=Get-Content $InputPath -Raw -ErrorAction Stop|ConvertFrom-Json}catch{$o=[PSCustomObject]@{inputPath=$InputPath;validatedAt=(Get-Date -Format "o");parseError=$_.Exception.Message;overall="FAIL";totalChecks=0;passedChecks=0;failedChecks=0;results=@()};$o|ConvertTo-Json -Depth 4;exit 1}
$p=$r.PSObject.Properties.Name

C "handoffId" ($p -contains "handoffId" -and $r.handoffId -is [string] -and $r.handoffId.Trim().Length -gt 0) "handoffId='$($r.handoffId)'"
C "agentId" ($p -contains "agentId" -and $r.agentId -is [string] -and $r.agentId.Trim().Length -gt 0) "agentId='$($r.agentId)'"
C "capsuleId" ($p -contains "capsuleId" -and $r.capsuleId -is [string] -and $r.capsuleId.Trim().Length -gt 0) "capsuleId='$($r.capsuleId)'"
C "phase" ($p -contains "phase" -and $r.phase -is [string] -and $r.phase.Trim().Length -gt 0) "phase='$($r.phase)'"
C "timestamp" {try{$d=[DateTime]::Parse($r.timestamp);$true}catch{$false}} "timestamp='$($r.timestamp)'"
C "files" ($p -contains "files" -and $r.files -is [array] -and $r.files.Count -gt 0) "files count=$($r.files.Count)"

$shaOk=$true
if ($p -contains "files" -and $r.files -is [array]) {
    foreach ($f in $r.files) {
        if ($f.PSObject.Properties.Name -notcontains "sha256" -or $f.sha256 -notmatch '^[a-f0-9]{64}$') { $shaOk=$false; break }
    }
}
C "filesHaveSha256" $shaOk "All files have valid SHA256 hex digests"
C "contractChecklist" ($p -contains "contractChecklist" -and $r.contractChecklist -is [array] -and $r.contractChecklist.Count -gt 0) "contractChecklist count=$($r.contractChecklist.Count)"
C "transcriptRef" ($p -contains "transcriptRef" -and $r.transcriptRef -is [string] -and $r.transcriptRef.Trim().Length -gt 0) "transcriptRef='$($r.transcriptRef)'"
C "nativeGenerated" ($p -contains "nativeGenerated" -and $r.nativeGenerated -eq $true) "nativeGenerated=true"

$productClaim = ($r.PSObject.Properties.Name -contains "productCorrectness") -or (($r|ConvertTo-Json -Depth 3) -match '(?i)\bproduct\s+(is\s+)?(correct|PASS|ready|complete)\b')
C "noProductPassClaim" (-not $productClaim) "Product correctness claim: $productClaim"

C "knownIssues" ($p -contains "knownIssues" -and $r.knownIssues -is [array]) "knownIssues defined"
C "verifiedBy" ($p -contains "verifiedBy") "verifiedBy field present"

$o=[PSCustomObject]@{inputPath=$InputPath;validatedAt=(Get-Date -Format "o");overall=if($overall){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$results}
$o|ConvertTo-Json -Depth 4
if($overall){exit 0}else{exit 1}
