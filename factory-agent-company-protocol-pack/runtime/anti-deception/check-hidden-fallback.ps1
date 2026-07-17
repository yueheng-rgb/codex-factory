<# .SYNOPSIS Detects when Main Agent or another agent writes in a worker's ownedScope, indicating hidden fallback. #>
param([Parameter(Mandatory=$true)][string]$ScopeDefPath)
$r=@();$o=$true;$tc=0;$pc=0;$fc=0;$fallbacks=@()
function C($f,$p,$d){$script:tc++;if($p){$script:pc++}else{$script:fc++;$script:o=$false};$script:r+=[PSCustomObject]@{field=$f;result=if($p){"PASS"}else{"FAIL"};detail=$d}}
try{$s=Get-Content $ScopeDefPath -Raw -ea Stop|ConvertFrom-Json}catch{exit 1}
$pp=$s.PSObject.Properties.Name
C "workersDefined" ($pp -contains "workers" -and $s.workers -is [array] -and $s.workers.Count -gt 0) "workers=$($s.workers.Count)"
C "mainAgentDeclared" ($pp -contains "mainAgentScope" -and $s.mainAgentScope -is [array]) "mainAgent scope entries=$($s.mainAgentScope.Count)"
if($pp -contains "workers"){
    foreach($w in $s.workers){
        $wp=$w.PSObject.Properties.Name
        C "$($w.agentId).scope" ($wp -contains "ownedScope") "ownedScope defined"
        C "$($w.agentId).handoff" ($wp -contains "handoffRef") "handoffRef=$($w.handoffRef)"
        if($pp -contains "mainAgentWrites" -and $s.mainAgentWrites -is [array]){
            $violations = @($s.mainAgentWrites | Where-Object {
                $_ -is [string] -and ($w.ownedScope | Where-Object { $_ -is [string] -and ($_ -replace '\\','/') -eq ($args[0] -replace '\\','/') }).Count -gt 0
            })
            # Simplified: check if any mainAgentWrite path is under a worker's owned scope
            foreach($mw in $s.mainAgentWrites){
                foreach($os in $w.ownedScope){
                    if($mw -like "$os*"){
                        $fallbacks += [PSCustomObject]@{worker=$w.agentId;path=$mw;violation="MAIN_AGENT_WROTE_WORKER_SCOPE"}
                        C "fallback.$($w.agentId).$mw" $false "Main Agent wrote to worker scope: $mw"
                    }
                }
            }
        }
    }
}
C "noHiddenFallbacks" ($fallbacks.Count -eq 0) "Hidden fallbacks: $($fallbacks.Count)"
$out=[PSCustomObject]@{scopeDefPath=$ScopeDefPath;overall=if($o){"PASS"}else{"FAIL"};totalChecks=$tc;passedChecks=$pc;failedChecks=$fc;fallbacks=$fallbacks;results=$r}
$out|ConvertTo-Json -Depth 4; if($o){exit 0}else{exit 1}
