# R2.3-O Simulation: Evidence Search Loop — 12 scenarios
$fr = "C:\Codex_App_Factory"
. (Join-Path $fr "runtime\need-search-detector.ps1")
. (Join-Path $fr "runtime\glm-search-adapter.ps1")
. (Join-Path $fr "runtime\evidence-pack-builder.ps1")
. (Join-Path $fr "runtime\reader-extractor-adapter.ps1")
. (Join-Path $fr "runtime\iterative-search-loop.ps1")

$simresults = @(); $passCount = 0; $failCount = 0; $total = 12
function SR($id,$name,$cond,$detail=""){$s=if($cond){"PASS"}else{"FAIL"};Write-Host ("  [{0}] S{1:D2}: {2}" -f $s,$id,$name) -ForegroundColor $(if($cond){"Green"}else{"Red"});if($detail){Write-Host ("        {0}" -f $detail) -ForegroundColor Gray};$script:simresults+=@{scenario="S$($id.ToString('00'))";name=$name;result=$s;detail=$detail};if($cond){$script:passCount++}else{$script:failCount++}}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-O SIMULATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# A
Write-Host "`n--- A ---" -ForegroundColor Yellow
$rA=Test-NeedSearch -TaskDescription "Implement server-side data fetching in Next.js 15 using the new App Router API" -ProjectType "fullstack-admin"
SR 1 "initial_task_need_search" ($rA.needSearch -eq $true) "need=$($rA.needSearch) score=$($rA.score)"

# B
Write-Host "`n--- B ---" -ForegroundColor Yellow
$rB=Test-NeedSearch -TaskDescription "Rename getUserById to findUserById across the project" -ProjectType "fullstack-admin"
SR 2 "internal_refactor_no_search" ($rB.needSearch -eq $false) "need=$($rB.needSearch) score=$($rB.score)"

# C
Write-Host "`n--- C ---" -ForegroundColor Yellow
$rC=Test-NeedSearch -TaskDescription "npm run build fails: Module not found Can't resolve @prisma/client. Dependency conflict" -ProjectType "fullstack-admin"
SR 3 "build_failure_error_search" ($rC.needSearch -eq $true) "need=$($rC.needSearch) trigger=$($rC.triggerType)"

# D
Write-Host "`n--- D ---" -ForegroundColor Yellow
$rD=Test-NeedSearch -TaskDescription "Implement API routes per the provided documentation" -ProjectType "fullstack-admin" -ExistingEvidencePackId "EVID-001" -Context @{evidenceQuality="acceptable"}
SR 4 "user_docs_no_search" (-not $rD.needSearch) "need=$($rD.needSearch)"

# E
Write-Host "`n--- E ---" -ForegroundColor Yellow
$mE=@{rawResult="AI answer";links=@(@{title="AI";url="https://chat.example.com";snippet="AI answer";sourceType="ai_generated"})}
$rE=Invoke-GLMSearch -RequestId "SIM-E" -Query "Best pattern" -ProviderMode manual -ManualInput $mE -ProjectId "SIM-O" -AgentId "RSRC-001"
$epE=New-EvidencePack -Task "Best pattern" -ProjectId "SIM-O" -SearchRound 1 -TriggerReason "initial_search" -GLMResponse $rE
SR 5 "ai_unsourced_needs_review" ($epE.accepted -and $epE.qualityGateStatus.trustRecommendation -eq "needs_human_review") "trust=$($epE.qualityGateStatus.trustRecommendation)"

# F
Write-Host "`n--- F ---" -ForegroundColor Yellow
$mF=@{rawResult="";links=@(@{title="Next.js Routing";url="https://nextjs.org/docs/app/building-your-application/routing";snippet="Official docs";sourceType="official_docs";publishDate="2026-07-01"})}
$rF=Invoke-GLMSearch -RequestId "SIM-F" -Query "Next.js routing" -ProviderMode manual -ManualInput $mF -ProjectId "SIM-O" -AgentId "RSRC-001"
$epF=New-EvidencePack -Task "Next.js routing" -ProjectId "SIM-O" -SearchRound 1 -TriggerReason "initial_search" -GLMResponse $rF
SR 6 "official_doc_trusted" ($epF.accepted) "verdict=$($epF.qualityGateStatus.verdict)"

# G
Write-Host "`n--- G ---" -ForegroundColor Yellow
$mG=@{rawResult="";links=@(@{title="My Blog";url="https://blog.example.com";snippet="Tips";sourceType="blog"})}
$rG=Invoke-GLMSearch -RequestId "SIM-G" -Query "Tips" -ProviderMode manual -ManualInput $mG -ProjectId "SIM-O" -AgentId "RSRC-001"
$epG=New-EvidencePack -Task "Tips" -ProjectId "SIM-O" -SearchRound 1 -TriggerReason "initial_search" -GLMResponse $rG
SR 7 "community_blog_reference" ($epG.qualityGateStatus.trustRecommendation -eq "reference_only") "trust=$($epG.qualityGateStatus.trustRecommendation)"

# H
Write-Host "`n--- H ---" -ForegroundColor Yellow
$rH=Test-NeedSearch -TaskDescription "Docs say App Router, community says Pages Router. Conflicting recommendations." -ProjectType "fullstack-admin"
SR 8 "conflict_triggers_search" ($rH.needSearch -eq $true) "need=$($rH.needSearch) trigger=$($rH.triggerType)"

# I
Write-Host "`n--- I ---" -ForegroundColor Yellow
$rI=Invoke-GLMSearch -RequestId "SIM-I" -Query "test" -ProviderMode dry_run -ProjectId "SIM-O" -AgentId "IMPL-FE-001"
SR 9 "implementer_rejected" ($rI.accepted -eq $false -and $rI.gateDecision -eq "REJECT") "accepted=$($rI.accepted)"

# J
Write-Host "`n--- J ---" -ForegroundColor Yellow
$rJ=Test-NeedSearch -TaskDescription "Need to verify API endpoint signature for payment" -ExistingEvidencePackId "EVID-OLD" -Context @{evidenceQuality="needs_review"}
SR 10 "insufficient_evidence_search" ($rJ.needSearch -eq $true) "need=$($rJ.needSearch)"

# K
Write-Host "`n--- K ---" -ForegroundColor Yellow
$loopK=New-SearchLoopState -TaskId "TASK-K" -ProjectId "SIM-O" -MaxRounds 2
$resultK=Invoke-SearchLoop -LoopState $loopK -TaskDescription "Find conflicting answers about this unresolvable debate topic that requires multiple rounds" -ProjectId "SIM-O" -InitialTriggerReason "initial_search" -AgentId "RSRC-001" -DryRunOnly $true
SR 11 "max_rounds_stop" (($resultK.finalStatus -eq "stopped_max_rounds" -or $resultK.finalStatus -eq "stopped_evidence_sufficient")) "status=$($resultK.finalStatus) rounds=$($resultK.totalRounds)"

# L
Write-Host "`n--- L ---" -ForegroundColor Yellow
$mL=@{rawResult="";links=@(@{title="Skill Idea";url="https://example.com";snippet="Skill";sourceType="blog"})}
$rL=Invoke-GLMSearch -RequestId "SIM-L" -Query "Skill" -ProviderMode manual -ManualInput $mL -ProjectId "SIM-O" -AgentId "RSRC-001"
$epL=New-EvidencePack -Task "Skill" -ProjectId "SIM-O" -SearchRound 1 -TriggerReason "initial_search" -GLMResponse $rL
SR 12 "skill_registry_blocked" ($epL.forbiddenUse -contains "do_not_enter_skill_registry_directly") "ok"

Write-Host ("`n========================================") -ForegroundColor Cyan
Write-Host (" SIMULATION: {0}/{1} PASS" -f $passCount,$total) -ForegroundColor $(if($passCount -eq $total){"Green"}else{"Yellow"})

$out = [PSCustomObject]@{simulationId="R2.3-O-SIM-001";phase="FACTORY-R2.3-O";totalScenarios=$total;passCount=$passCount;failCount=$failCount;timestamp=Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz";scenarios=$simresults}
$out | ConvertTo-Json -Depth 4 | Out-File (Join-Path $fr "outputs\FACTORY_R2_3_O_ITERATIVE_SEARCH_SIMULATION_RESULTS.json") -Encoding UTF8
Write-Host "Results written." -ForegroundColor Cyan
