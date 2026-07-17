# Skill Context Injector
# Part of: FACTORY-R2.3-F-SKILL-CONTENT-RUNTIME-VERIFICATION
# Extends agent execution context with loaded skill references.
# Usage: . .\runtime\skill-context-injector.ps1; $ctx = New-AgentExecutionContextWithSkills -AgentId "PM-001" -ProjectId "PROJ-001" -SkillIds @("CAP-SKILL-004")

param([string]$FactoryRoot = "C:\Codex_App_Factory")

. (Join-Path $FactoryRoot "runtime\execution-context.ps1")
. (Join-Path $FactoryRoot "runtime\skill-content-loader.ps1")

<#
.SYNOPSIS
Generates an agent execution context with loaded skill references injected.
#>
function New-AgentExecutionContextWithSkills {
    param(
        [Parameter(Mandatory=$true)][string]$AgentId,
        [Parameter(Mandatory=$true)][string]$ProjectId,
        [string]$PhaseId = "PHASE-001",
        [string]$ProjectType = "fullstack-admin",
        [string[]]$SkillIds = @(),
        [bool]$IsLocalFirst = $true
    )

    # Generate base context from R2.3-D execution-context
    $ctx = New-AgentExecutionContext -AgentId $AgentId -ProjectId $ProjectId -PhaseId $PhaseId `
        -ProjectType $ProjectType -IsLocalFirst $IsLocalFirst

    if (-not $ctx) { return $null }

    # Skill injection
    $loadedSkillRefs = @()
    $rejectedSkillRefs = @()
    $skillWarnings = @()

    foreach ($skillId in $SkillIds) {
        $loaded = Load-SkillContent -SkillId $skillId -AgentId $AgentId `
            -ProjectId $ProjectId -PhaseId $PhaseId -ProjectType $ProjectType -IsLocalFirst $IsLocalFirst

        if ($loaded.Loaded) {
            $loadedSkillRefs += [PSCustomObject]@{
                skillId = $loaded.SkillId
                name = $loaded.SkillPackage.name
                version = $loaded.SkillPackage.version
                status = $loaded.SkillPackage.status
                trustLevel = $loaded.SkillPackage.trustLevel
                loadedSections = $loaded.SkillSummary.loadedSections
                allowedTools = $loaded.SkillPackage.allowedTools
                forbiddenActions = $loaded.SkillPackage.forbiddenActions
                instructionsSummary = $loaded.SkillSummary.instructionsSummary
            }
        } else {
            $rejectedSkillRefs += [PSCustomObject]@{
                skillId = $loaded.SkillId
                reason = $loaded.Reason
            }
        }
        $skillWarnings += $loaded.Warnings
    }

    # Add skill fields to context
    $ctx | Add-Member -MemberType NoteProperty -Name "loadedSkillRefs" -Value $loadedSkillRefs -Force
    $ctx | Add-Member -MemberType NoteProperty -Name "rejectedSkillRefs" -Value $rejectedSkillRefs -Force
    $ctx | Add-Member -MemberType NoteProperty -Name "skillWarnings" -Value $skillWarnings -Force
    $ctx | Add-Member -MemberType NoteProperty -Name "skillsLoadedCount" -Value $loadedSkillRefs.Count -Force
    $ctx | Add-Member -MemberType NoteProperty -Name "skillsRejectedCount" -Value $rejectedSkillRefs.Count -Force

    return $ctx
}

Write-Verbose "Skill Context Injector loaded."
