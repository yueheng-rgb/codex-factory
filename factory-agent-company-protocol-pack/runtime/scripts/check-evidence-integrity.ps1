<#
.SYNOPSIS
    Checks evidence integrity: SHA256 matching, phantom file detection, evidence path validity.
.PARAMETER ManifestPath
    Path to evidence manifest JSON with files array (path, sha256, size).
.PARAMETER BasePath
    Base directory for resolving relative file paths. Defaults to current directory.
#>
param([Parameter(Mandatory=$true)][string]$ManifestPath, [string]$BasePath, [switch]$WhatIf)

if (-not $BasePath) { $BasePath = Get-Location }
$results=@(); $overall=$true; $tc=0; $pc=0; $fc=0; $mismatches=@(); $phantoms=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:overall=$false};$script:results+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}

try{$m=Get-Content $ManifestPath -Raw -ErrorAction Stop|ConvertFrom-Json}catch{$o=[PSCustomObject]@{manifestPath=$ManifestPath;checkedAt=(Get-Date -Format "o");parseError=$_.Exception.Message;overall="FAIL";totalChecks=0;passedChecks=0;failedChecks=0;mismatches=@();phantoms=@();results=@()};$o|ConvertTo-Json -Depth 4;exit 1}
$p=$m.PSObject.Properties.Name

C "filesDefined" ($p -contains "files" -and $m.files -is [array] -and $m.files.Count -gt 0) "files array has $($m.files.Count) entries"

if ($p -contains "files" -and $m.files -is [array]) {
    foreach ($fileObj in $m.files) {
        $filePath = $fileObj.path
        if ([string]::IsNullOrWhiteSpace($filePath)) {
            $phantoms += [PSCustomObject]@{path="<null>"; issue="NULL_PATH"}
            C "file.nullPath" $false "File path is null or whitespace"
            continue
        }
        $filePath = $filePath.ToString()
        $fp = if ([System.IO.Path]::IsPathRooted($filePath)) { $filePath } else { Join-Path $BasePath $filePath }
        if (-not (Test-Path $fp -PathType Leaf)) {
            $phantoms += [PSCustomObject]@{path=$filePath; issue="FILE_NOT_FOUND"}
            C "file.$filePath.exists" $false "File not found: $fp"
            continue
        }
        C "file.$filePath.exists" $true "File exists: $fp"
        try {
            $actualSha = (Get-FileHash -Path $fp -Algorithm SHA256).Hash
            $expectedSha = $fileObj.sha256
            if (-not [string]::IsNullOrWhiteSpace($expectedSha) -and $expectedSha -match '^[a-f0-9]{64}$') {
                if ($actualSha -eq $expectedSha) {
                    C "file.$filePath.sha256" $true "SHA256 matches: $actualSha"
                } else {
                    $mismatches += [PSCustomObject]@{path=$filePath; expected=$expectedSha; actual=$actualSha}
                    C "file.$filePath.sha256" $false "SHA256 MISMATCH: expected $expectedSha, got $actualSha"
                }
            } else {
                C "file.$filePath.sha256" $false "No valid SHA256 in manifest for $filePath"
            }
        } catch {
            C "file.$filePath.hashError" $false "Hash computation error: $($_.Exception.Message)"
        }
    }
}

C "noPhantomFiles" ($phantoms.Count -eq 0) "$($phantoms.Count) phantom file(s)"
C "noShaMismatches" ($mismatches.Count -eq 0) "$($mismatches.Count) SHA256 mismatch(es)"

$o=[PSCustomObject]@{manifestPath=$ManifestPath;checkedAt=(Get-Date -Format "o");overall=if($overall){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;mismatches=$mismatches;phantoms=$phantoms;results=$results}
$o|ConvertTo-Json -Depth 4
if($overall){exit 0}else{exit 1}
