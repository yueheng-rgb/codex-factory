# Iterative Search Loop
# Part of: FACTORY-R2.3-O
# Manages multi-round search with budget, state tracking, and anti-infinite-loop controls

. (Join-Path $PSScriptRoot "need-search-detector.ps1")
. (Join-Path $PSScriptRoot "glm-search-adapter.ps1")
. (Join-Path $PSScriptRoot "evidence-pack-builder.ps1")

function New-SearchLoopState {
    param([string]$TaskId, [string]$ProjectId, [int]$MaxRounds = 5, [int]$MaxSourcesPerRound = 10)
    return [PSCustomObject]@{
        loopId = "LOOP-$(Get-Date -Format 'yyyyMMdd')-$(Get-Random -Minimum 100 -Maximum 999)"
        taskId = $TaskId; projectId = $ProjectId
        currentRound = 0; maxRounds = $MaxRounds
        status = "active"
        budget = [PSCustomObject]@{
            maxSearchRoundsPerTask = $MaxRounds
            maxSourcesPerRound = $MaxSourcesPerRound
            maxOfficialDocsPreferred = $true
            stopCondition = "evidence_sufficient_or_max_rounds_or_human_escalation"
            humanEscalationCondition = "3_consecutive_rounds_without_new_evidence_or_conflicting_unresolved_or_security_concern"
        }
        rounds = @()
        escalationHistory = @()
        evidenceHistory = @()
    }
}

function Invoke-SearchLoop {
    param(
        [Parameter(Mandatory=$true)]$LoopState,
        [Parameter(Mandatory=$true)][string]$TaskDescription,
        [Parameter(Mandatory=$true)][string]$ProjectId,
        [string]$PhaseId = "implementation",
        [string]$InitialTriggerReason = "initial_search",
        [hashtable]$EvidencePackInput = @{},
        [string]$AgentId = "RSRC-001",
        [bool]$HumanApproved = $false,
        [bool]$DryRunOnly = $true
    )

    $state = $LoopState
    $results = @()

    while ($state.status -eq "active" -and $state.currentRound -lt $state.maxRounds) {
        $state.currentRound++
        $round = $state.currentRound
        Write-Host ("  Search Loop Round {0}/{1}" -f $round, $state.maxRounds) -ForegroundColor Yellow

        # Determine trigger reason for this round
        if ($round -eq 1) {
            $trigger = $InitialTriggerReason
        } elseif ($results.Count -gt 0) {
            $lastResult = $results[-1]
            if (-not $lastResult.accepted -or $lastResult.sourceCount -eq 0) {
                $trigger = "error_driven_search"
            } elseif ($lastResult.conflictsDetected) {
                $trigger = "conflicting_sources_search"
            } else {
                # Check if evidence sufficient
                $needCheck = Test-NeedSearch -TaskDescription $TaskDescription `
                    -ExistingEvidencePackId $lastResult.evidenceId `
                    -ProjectType "fullstack-admin" -PhaseId $PhaseId `
                    -Context @{evidenceQuality=$lastResult.qualityGateStatus.verdict}
                if (-not $needCheck.needSearch) {
                    Write-Host "    Evidence sufficient. Stopping loop." -ForegroundColor Green
                    $state.status = "stopped_evidence_sufficient"
                    break
                }
                $trigger = "verification_failure_search"
            }
        } else {
            $trigger = "initial_search"
        }

        # Run search
        $searchResult = if ($DryRunOnly) {
            Invoke-GLMSearch -RequestId "LOOP-$round" -Query $TaskDescription `
                -ProviderMode dry_run -SearchIntent "project_time" `
                -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
                -UserApproval $HumanApproved
        } else {
            Invoke-GLMSearch -RequestId "LOOP-$round" -Query $TaskDescription `
                -ProviderMode manual -SearchIntent "project_time" `
                -ProjectId $ProjectId -PhaseId $PhaseId -AgentId $AgentId `
                -UserApproval $HumanApproved -ManualInput $EvidencePackInput
        }

        if (-not $searchResult -or -not $searchResult.accepted) {
            Write-Host "    Search rejected. Stopping loop." -ForegroundColor Red
            $state.status = "stopped_error"
            break
        }

        # Build Evidence Pack
        $evidence = New-EvidencePack -Task $TaskDescription -ProjectId $ProjectId -PhaseId $PhaseId `
            -SearchRound $round -TriggerReason $trigger -GLMResponse $searchResult `
            -PreviousEvidenceIds ($state.evidenceHistory)

        $results += $evidence
        $state.evidenceHistory += $evidence.evidenceId

        # Record round
        $state.rounds += [PSCustomObject]@{
            round = $round; triggerReason = $trigger
            evidenceId = $evidence.evidenceId; sourceCount = $evidence.sourceCount
            newEvidenceCount = $evidence.sourceCount
            delta = "Round $round : $($evidence.sourceCount) sources, quality=$($evidence.qualityGateStatus.verdict)"
            qualityScore = $evidence.qualityGateStatus.score
            timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
        }

        # Check: 3 consecutive rounds without new evidence?
        if ($round -ge 3) {
            $last3 = $results | Select-Object -Last 3
            $allZeroNew = ($last3 | Where-Object { $_.sourceCount -eq 0 } | Measure-Object).Count -eq 3
            if ($allZeroNew) {
                Write-Host "    3 consecutive rounds without new evidence. Escalating." -ForegroundColor Yellow
                $state.escalationHistory += "Round $round : 3 consecutive rounds without new evidence"
                $state.status = "stopped_human_escalated"
                break
            }
        }

        # Check if evidence sufficient
        $lastEvidence = $results[-1]
        if ($lastEvidence.qualityGateStatus.verdict -eq "high_quality" -and $lastEvidence.sourceCount -ge 3) {
            Write-Host "    High quality evidence sufficient. Stopping loop." -ForegroundColor Green
            $state.status = "stopped_evidence_sufficient"
            break
        }
    }

    # Max rounds reached
    if ($state.status -eq "active") {
        $state.status = "stopped_max_rounds"
        Write-Host "  Max rounds reached. Stopping loop." -ForegroundColor Yellow
    }

    return [PSCustomObject]@{
        loopState = $state
        evidenceResults = $results
        totalRounds = $state.currentRound
        finalStatus = $state.status
        totalSources = ($results | ForEach-Object { $_.sourceCount } | Measure-Object -Sum).Sum
        allEvidenceIds = $state.evidenceHistory
    }
}

Write-Verbose "Iterative Search Loop loaded."
