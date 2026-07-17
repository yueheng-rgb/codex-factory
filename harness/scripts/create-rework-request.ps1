# create-rework-request.ps1 -- Phase 6C-U0-F
# Reads gate failure reports and generates machine-readable rework requests.
param(
    [Parameter(Mandatory=$true)][string]$RunDir,
    [Parameter(Mandatory=$true)][string]$RunId,
    [string]$Phase="Phase 6C-U0-F"
)
$ErrorActionPreference="Continue"
$H=(Resolve-Path (Join-Path $PSScriptRoot ".."))
$reqDir=Join-Path $RunDir "rework-requests"
if(-not (Test-Path $reqDir)){New-Item -ItemType Directory -Path $reqDir -Force|Out-Null}

$requests=@()
$reqId=1

# Check honesty reports for failures
$honDir=Join-Path $RunDir "reports"
$honFiles=Get-ChildItem "$honDir\manifest-honesty-report-*.json" -ErrorAction SilentlyContinue
foreach($hf in $honFiles){
    $h=Get-Content $hf.FullName -Raw|ConvertFrom-Json
    if($h.verdict -eq "FAIL"){
        $issues=@()
        foreach($m in $h.mismatches){
            $issues+=@{
                issueId="ISSUE-$($reqId.ToString('D3'))"
                type=$m.type
                file=if($m.workerClaimedFile){$m.workerClaimedFile}else{""}
                interfaceId=""
                expected=""
                actual=if($m.workerClaimed){$m.workerClaimed}else{""}
                requiredAction="Fix mismatch in worker manifest or source code"
            }
            $reqId++
        }
        if($issues.Count -gt 0){
            $requests+=@{
                phase=$Phase; requestId="RW-001"; createdAtUtc=(Get-Date).ToUniversalTime().ToString("o"); status="open"
                targetWorkerId=$h.workerId; targetTaskId=$h.taskId
                failureSource="manifest-honesty"
                failureReports=@($hf.Name)
                issues=$issues; blocking=$true
            }
        }
    }
}

# Check drift report
$driftPath=Join-Path $RunDir "reports/interface-drift-report.json"
if(Test-Path $driftPath){
    $dr=Get-Content $driftPath -Raw|ConvertFrom-Json
    if($dr.verdict -eq "FAIL"){
        $issues=@()
        foreach($d in $dr.drifts){
            $issues+=@{
                issueId="ISSUE-$($reqId.ToString('D3'))"
                type=$d.type
                file=""
                interfaceId=if($d.interfaceId){$d.interfaceId}else{""}
                expected=if($d.expectedName){$d.expectedName}else{""}
                actual=if($d.actualName){$d.actualName}else{""}
                requiredAction="Fix drift: align worker manifest with contract lock"
            }
            $reqId++
        }
        $targetW=if($dr.drifts[0].workerId){$dr.drifts[0].workerId}else{"unknown"}
        if($issues.Count -gt 0){
            $requests+=@{
                phase=$Phase; requestId="RW-002"; createdAtUtc=(Get-Date).ToUniversalTime().ToString("o"); status="open"
                targetWorkerId=$targetW; targetTaskId=""; failureSource="interface-drift"
                failureReports=@("reports/interface-drift-report.json")
                issues=$issues; blocking=$true
            }
        }
    }
}

# Write requests
foreach($r in $requests){
    $rp=Join-Path $reqDir "$($r.requestId).json"
    $r|ConvertTo-Json -Depth 6|Out-File $rp -Encoding UTF8
    Write-Output "Created: $rp ($($r.issues.Count) issues)"
}
if($requests.Count -eq 0){Write-Output "No rework requests needed (all gates PASS)"}
exit 0