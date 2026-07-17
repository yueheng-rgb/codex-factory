<#
.SYNOPSIS
    Checks scope isolation compliance: workers must not write outside ownedScope or into forbiddenScope.
.DESCRIPTION
    Accepts a scope definition JSON and checks file writes against owned/forbidden scopes.
    Outputs machine-readable JSON. Non-zero exit on cross-scope violation.
.PARAMETER ScopeDefPath
    Path to scope definition JSON with ownedScope, forbiddenScope, and actualWrites arrays.
.PARAMETER ProtocolPackRoot
    Root of the protocol pack.
#>
param([Parameter(Mandatory=$true)][string]$ScopeDefPath, [string]$ProtocolPackRoot, [switch]$WhatIf)

$results=@(); $overall=$true; $tc=0; $pc=0; $fc=0; $violations=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:overall=$false};$script:results+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}

try{$s=Get-Content $ScopeDefPath -Raw -ErrorAction Stop|ConvertFrom-Json}catch{$o=[PSCustomObject]@{scopeDefPath=$ScopeDefPath;checkedAt=(Get-Date -Format "o");parseError=$_.Exception.Message;overall="FAIL";totalChecks=0;passedChecks=0;failedChecks=0;violations=@();results=@()};$o|ConvertTo-Json -Depth 4;exit 1}
$p=$s.PSObject.Properties.Name

C "ownedScopeDefined" ($p -contains "ownedScope" -and $s.ownedScope -is [array] -and $s.ownedScope.Count -gt 0) "ownedScope has $($s.ownedScope.Count) entries"
C "forbiddenScopeDefined" ($p -contains "forbiddenScope" -and $s.forbiddenScope -is [array]) "forbiddenScope has $($s.forbiddenScope.Count) entries"
C "actualWritesDefined" ($p -contains "actualWrites" -and $s.actualWrites -is [array]) "actualWrites has $($s.actualWrites.Count) entries"

# Match function: checks if path is inside a scope pattern
function Test-InScope {
    param([string]$Path, [string[]]$Patterns)
    foreach ($pat in $Patterns) {
        $normalized = $pat -replace '\\','/' -replace '/+','/'
        $testPath = $Path -replace '\\','/'
        if ($normalized -eq '*' -or $normalized -eq '**') { return $true }
        if ($normalized.EndsWith('/') -and $testPath.StartsWith($normalized)) { return $true }
        if ($normalized.EndsWith('/*') -and $testPath.StartsWith($normalized.Substring(0,$normalized.Length-1))) { return $true }
        if ($testPath -eq $normalized) { return $true }
        if ($normalized.Contains('*') -and $testPath -like $normalized) { return $true }
    }
    return $false
}

if ($p -contains "actualWrites" -and $p -contains "ownedScope") {
    foreach ($w in $s.actualWrites) {
        $inOwned = Test-InScope -Path $w -Patterns $s.ownedScope
        $inForbidden = if ($p -contains "forbiddenScope") { Test-InScope -Path $w -Patterns $s.forbiddenScope } else { $false }
        if (-not $inOwned) {
            $violations += [PSCustomObject]@{path=$w; violation="OUTSIDE_OWNED_SCOPE"; detail="Not in ownedScope patterns"}
            C "write.$w.outsideOwned" $false "Write '$w' is outside ownedScope"
        } elseif ($inForbidden) {
            $violations += [PSCustomObject]@{path=$w; violation="FORBIDDEN_SCOPE_WRITE"; detail="In forbiddenScope"}
            C "write.$w.forbidden" $false "Write '$w' is in forbiddenScope"
        } else {
            C "write.$w.clean" $true "Write '$w' is within ownedScope and not forbidden"
        }
    }
}

C "noCrossScopeViolations" ($violations.Count -eq 0) "$($violations.Count) scope violation(s) found"

$o=[PSCustomObject]@{scopeDefPath=$ScopeDefPath;checkedAt=(Get-Date -Format "o");overall=if($overall){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;violations=$violations;results=$results}
$o|ConvertTo-Json -Depth 4
if($overall){exit 0}else{exit 1}
