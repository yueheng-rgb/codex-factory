# Skill Content Loader
# Part of: FACTORY-R2.3-F-SKILL-CONTENT-RUNTIME-VERIFICATION
# Loads skill package content for agent runtime.

param([string]$FactoryRoot = "C:\Codex_App_Factory")

. (Join-Path $FactoryRoot "runtime\agent-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-permission-gate.ps1")

$script:SkillsDir = Join-Path $FactoryRoot "skills"
$script:UsageLedger = Join-Path $FactoryRoot "governance\skill-usage\skill-usage-index.jsonl"

function Write-SkillUsage {
    param([string]$ProjId,[string]$PhsId,[string]$Aid,[string]$Sid,[string]$Dec,[string]$Rea,[string[]]$LS=@(),[string[]]$IR=@(),[string[]]$OR=@(),[string[]]$Cav=@())
    $ts = Get-Date -Format "yyyyMMddHHmmss"
    $rec = [PSCustomObject]@{recordId="SKILL-USE-$Sid-$Aid-$ts";timestamp=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz");projectId=$ProjId;phaseId=$PhsId;agentId=$Aid;skillId=$Sid;decision=$Dec;reason=$Rea;loadedSections=$LS;inputRefs=$IR;outputRefs=$OR;caveats=$Cav}
    $rec | ConvertTo-Json -Compress -Depth 3 | Add-Content -Path $script:UsageLedger -Encoding UTF8
    return $rec
}

function Get-SkillUsage {
    param([string]$Sid,[string]$Aid,[int]$Max=50)
    if (-not (Test-Path $script:UsageLedger)) { return @() }
    $lines = Get-Content $script:UsageLedger -Encoding UTF8 | Where-Object { $_.Trim() -ne "" }; $results = @()
    foreach ($l in $lines) { try { $o = $l | ConvertFrom-Json; if ($Sid -and $o.skillId -ne $Sid) { continue }; if ($Aid -and $o.agentId -ne $Aid) { continue }; $results += $o; if ($results.Count -ge $Max) { break } } catch {} }
    return $results
}

function Load-SkillContent {
    param(
        [Parameter(Mandatory=$true)][string]$SkillId,
        [Parameter(Mandatory=$true)][string]$AgentId,
        [string]$ProjectId = "PROJ-UNKNOWN",
        [string]$PhaseId = "PHASE-UNKNOWN",
        [string]$ProjectType = "fullstack-admin",
        [bool]$IsLocalFirst = $true
    )
    $result = [PSCustomObject]@{Loaded=$false;SkillId=$SkillId;AgentId=$AgentId;Reason="";SkillPackage=$null;SkillSummary=$null;Warnings=@();UsageRecord=$null}

    # 1: Skill dir exists
    $d = Join-Path $script:SkillsDir $SkillId
    if (-not (Test-Path $d)) { $result.Reason="REJECT: Skill dir not found: $d"; $null = Write-SkillUsage $ProjectId | Out-Null; $null = Write-SkillUsage $ProjectId $PhaseId $AgentId $SkillId "rejected" $result.Reason; return $result }

    # 2: skill.json
    $sj = Join-Path $d "skill.json"
    if (-not (Test-Path $sj)) { $result.Reason="REJECT: skill.json not found"; $null = Write-SkillUsage $ProjectId | Out-Null; $null = Write-SkillUsage $ProjectId $PhaseId $AgentId $SkillId "rejected" $result.Reason; return $result }
    try { $pkg = Get-Content $sj -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop } catch { $result.Reason="REJECT: JSON parse error: $($_.Exception.Message)"; $null = Write-SkillUsage $ProjectId | Out-Null; $null = Write-SkillUsage $ProjectId $PhaseId $AgentId $SkillId "rejected" $result.Reason; return $result }

    # 3: Required fields
    $rf = @("skillId","name","version","status","trustLevel","allowedTools","forbiddenActions")
    $miss = @(); foreach ($f in $rf) { if (-not (Get-Member -InputObject $pkg -Name $f)) { $miss += $f } }
    if ($miss.Count -gt 0) { $result.Reason="REJECT: Missing fields: $($miss -join ', ')"; $null = Write-SkillUsage $ProjectId | Out-Null; $null = Write-SkillUsage $ProjectId $PhaseId $AgentId $SkillId "rejected" $result.Reason; return $result }

    # 4: Status gate
    if ($pkg.status -eq "deprecated") { $result.Reason="REJECT: Skill is DEPRECATED"; $null = Write-SkillUsage $ProjectId | Out-Null; $null = Write-SkillUsage $ProjectId $PhaseId $AgentId $SkillId "rejected" $result.Reason; return $result }
    if ($pkg.status -eq "quarantine") { $result.Reason="REJECT: Skill is QUARANTINE"; $null = Write-SkillUsage $ProjectId | Out-Null; $null = Write-SkillUsage $ProjectId $PhaseId $AgentId $SkillId "rejected" $result.Reason; return $result }

    # 5: Permission gate
    $perm = Test-CapabilityPermission -AgentId $AgentId -CapabilityId $SkillId -ProjectId $ProjectId -ProjectType $ProjectType -HasHumanConfirmation $true -HasWriteScope $true
    if ($perm.Decision -eq "REJECT") { $result.Reason="REJECT: Gate denied: $($perm.Reason)"; $null = Write-SkillUsage $ProjectId | Out-Null; $null = Write-SkillUsage $ProjectId $PhaseId $AgentId $SkillId "rejected" $result.Reason; return $result }

    # 6: Agent applicability
    if ($pkg.applicableAgents -is [array] -and $pkg.applicableAgents.Count -gt 0 -and $AgentId -notin $pkg.applicableAgents) {
        $result.Reason="REJECT: Agent not in applicableAgents: $($pkg.applicableAgents -join ', ')"; $null = Write-SkillUsage $ProjectId | Out-Null; $null = Write-SkillUsage $ProjectId $PhaseId $AgentId $SkillId "rejected" $result.Reason; return $result
    }

    # 7: Load instructions from SKILL.md (primary) or skill.json (fallback)
    $smd = Join-Path $d "SKILL.md"
    $instructions = if (Test-Path $smd) { Get-Content $smd -Raw -Encoding UTF8 } elseif (Get-Member -InputObject $pkg -Name "instructions") { $pkg.instructions } else { "" }
    if (-not $instructions) { $result.Reason="REJECT: No instructions in SKILL.md or skill.json"; $null = Write-SkillUsage $ProjectId | Out-Null; $null = Write-SkillUsage $ProjectId $PhaseId $AgentId $SkillId "rejected" $result.Reason; return $result }

    # 8: Build summary (truncate if needed)
    $il = $instructions.Length
    $summ = if ($il -gt 1000) { $instructions.Substring(0, 1000) + "..." } else { $instructions }

    # 9: Build skill summary
    $summary = [PSCustomObject]@{
        skillId=$pkg.skillId; name=$pkg.name; version=$pkg.version; status=$pkg.status; trustLevel=$pkg.trustLevel
        allowedTools=$pkg.allowedTools; forbiddenActions=$pkg.forbiddenActions
        triggerConditions = if ($pkg.triggerConditions) { $pkg.triggerConditions } else { @() }
        instructionsSummary = $summ; instructionsFullPath = $smd; instructionsLength = $il
        verificationMethod = if ($pkg.verificationMethod) { $pkg.verificationMethod } else { $null }
        failureModes = if ($pkg.failureModes) { $pkg.failureModes } else { @() }
        rollbackPolicy = if ($pkg.rollbackPolicy) { $pkg.rollbackPolicy } else { $null }
        loadedSections = @("instructions","allowedTools","forbiddenActions","triggerConditions","failureModes")
        inputRefs = @($sj, $smd)
    }

    $result.Loaded=$true; $result.Reason="LOADED: $SkillId ($($pkg.name)) loaded for $AgentId"
    $result.SkillPackage=$pkg; $result.SkillSummary=$summary
    $null = Write-SkillUsage $ProjectId | Out-Null; $null = Write-SkillUsage $ProjectId $PhaseId $AgentId $SkillId "loaded" $result.Reason -LS $summary.loadedSections -IR $summary.inputRefs -Cav $result.Warnings
    return $result
}

function Invoke-SkillRollback {
    param([Parameter(Mandatory=$true)][string]$SkillId,[string]$Reason="Manual rollback",[string]$TargetStatus="deprecated")
    $r = Write-SkillUsage "ROLLBACK" "ROLLBACK" "INTG-001" $SkillId "rollback" $Reason
    Write-Host "ROLLBACK: $SkillId -> $TargetStatus. $Reason" -ForegroundColor Yellow
    return $r
}

Write-Verbose "Skill Content Loader initialized."
