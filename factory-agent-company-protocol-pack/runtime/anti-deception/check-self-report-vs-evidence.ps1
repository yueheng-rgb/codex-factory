<# .SYNOPSIS Checks that worker self-reports have corresponding evidence artifacts. #>
param([Parameter(Mandatory=$true)][string]$ReportPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$rp=Get-Content $ReportPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$rp.PSObject.Properties.Name
C "reportExists" ($pp -contains "reportId") "reportId=$($rp.reportId)"
C "hasArtifacts" ($pp -contains "filesCreated" -and $rp.filesCreated -is [array] -and $rp.filesCreated.Count -gt 0) "filesCreated=$($rp.filesCreated.Count)"
C "hasTranscript" ($pp -contains "transcriptRef" -and $rp.transcriptRef -is [string] -and $rp.transcriptRef.Trim().Length -gt 0) "transcriptRef=$($rp.transcriptRef)"
C "notMarkdownOnly" ($pp -contains "detail" -and $rp.detail -is [string] -and $rp.detail.Trim().Length -gt 20) "detail length=$($rp.detail.Length)"
C "noManualPass" (-not (($rp|ConvertTo-Json -Depth 4) -match '(?i)\bmanual\s+PASS\b')) "No manual PASS"
C "noExpectedClassOnly" (-not (($rp|ConvertTo-Json -Depth 4) -match '(?i)\bexpectedClass\b')) "No expectedClass-only"
C "noGenericFail" (-not (($rp|ConvertTo-Json -Depth 4) -match '(?i)\bgeneric\s+FAIL\b')) "No generic FAIL"
C "nativeGenerated" ($pp -contains "nativeGenerated" -and $rp.nativeGenerated -eq $true) "nativeGenerated=true"
$out=[PSCustomObject]@{reportPath=$ReportPath;overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
