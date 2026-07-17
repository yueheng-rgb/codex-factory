# apply-rework-resolution.ps1 -- Phase 6C-U0-F
# Reads a rework resolution and applies it to the workspace.
param(
    [Parameter(Mandatory=$true)][string]$ResolutionPath,
    [Parameter(Mandatory=$true)][string]$RunDir
)
$ErrorActionPreference="Continue"
if(-not (Test-Path $ResolutionPath)){Write-Error "Resolution not found: $ResolutionPath"; exit 1}
$res=Get-Content $ResolutionPath -Raw|ConvertFrom-Json
if($res.status -ne "resolved"){Write-Error "Resolution not in resolved status"; exit 1}

$resDir=Join-Path $RunDir "rework-resolutions"
if(-not (Test-Path $resDir)){New-Item -ItemType Directory -Path $resDir -Force|Out-Null}
$rp=Join-Path $resDir (Split-Path $ResolutionPath -Leaf)
Copy-Item $ResolutionPath $rp -Force

foreach($fix in $res.fixes){
    $fp=Join-Path $RunDir $fix.file
    if(Test-Path $fp){
        $content=[System.IO.File]::ReadAllText($fp,[System.Text.UTF8Encoding]::new($false))
        foreach($ch in $fix.changes){
            $content=$content.Replace($ch.old, $ch.new)
        }
        [System.IO.File]::WriteAllText($fp,$content,[System.Text.UTF8Encoding]::new($false))
        Write-Output "Applied: $($fix.file) ($($fix.changes.Count) changes)"
    }else{Write-Warning "File not found: $fp"}
}
# Update worker manifest if specified
if($res.manifestUpdates){
    foreach($mu in $res.manifestUpdates){
        $mp=Join-Path $RunDir $mu.manifestPath
        if(Test-Path $mp){
            $mc=[System.IO.File]::ReadAllText($mp,[System.Text.UTF8Encoding]::new($false))
            foreach($ch in $mu.changes){$mc=$mc.Replace($ch.old,$ch.new)}
            [System.IO.File]::WriteAllText($mp,$mc,[System.Text.UTF8Encoding]::new($false))
            Write-Output "Updated manifest: $($mu.manifestPath)"
        }
    }
}
Write-Output "Resolution applied. Request: $($res.requestId)"
exit 0