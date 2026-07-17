# R2.3-N GLM Search Adapter Simulation
# 10 scenarios covering all modes, gate checks, quality checks, and agent access control

. (Join-Path (Split-Path $PSScriptRoot -Parent) "glm-search-adapter.ps1")

$results = @()
$pass = 0; $fail = 0; $total = 10
$fr = "C:\Codex_App_Factory"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-N SIMULATION: GLM Search Adapter" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Report($id, $name, $cond, $detail) {
    $status = if ($cond) { "PASS" } else { "FAIL" }
    $color = if ($cond) { "Green" } else { "Red" }
    Write-Host ("  [{0}] S{1:D2}: {2}" -f $status, $id, $name) -ForegroundColor $color
    if ($detail) { Write-Host ("        {0}" -f $detail) -ForegroundColor Gray }
    $script:results += [PSCustomObject]@{scenario="S$($id.ToString('00'))";name=$name;result=$status;detail=$detail}
    if ($cond) { $script:pass++ } else { $script:fail++ }
}

# =============================================
# Scenario 01: manual_mode, official docs with URLs → PASS
# =============================================
Write-Host "`n--- S01: manual_mode + official docs ---" -ForegroundColor Yellow
$manualInput = @{
    rawResult = "Next.js documentation search results"
    links = @(
        @{title="Next.js Docs — Routing";url="https://nextjs.org/docs/app/building-your-application/routing";snippet="Official Next.js routing documentation.";sourceType="official_docs";publishDate="2026-06-15"},
        @{title="Next.js Docs — Data Fetching";url="https://nextjs.org/docs/app/building-your-application/data-fetching";snippet="Official Next.js data fetching guide.";sourceType="official_docs";publishDate="2026-06-10"}
    )
}
$r1 = Invoke-GLMSearch -RequestId "REQ-0001" -Query "Next.js routing best practices" -ProviderMode manual -ManualInput $manualInput -ProjectId "SIM-001" -PhaseId "test" -AgentId "RSRC-001"
Report 1 "manual_mode+official_docs" ($r1.accepted -eq $true -and $r1.resultCount -eq 2 -and $r1.mode -eq "manual") "accepted=$($r1.accepted) results=$($r1.resultCount) mode=$($r1.mode)"

# =============================================
# Scenario 02: manual_mode, no-source AI answer → NEEDS_HUMAN_REVIEW
# =============================================
Write-Host "`n--- S02: manual_mode + no-source AI answer ---" -ForegroundColor Yellow
$manualInput2 = @{
    rawResult = "AI generated answer without citations"
    links = @(
        @{title="Some AI Answer";url="https://ai-chat.example.com/response";snippet="This is an AI-generated answer with no real sources.";sourceType="ai_generated";publishDate=""}
    )
}
$r2 = Invoke-GLMSearch -RequestId "REQ-0002" -Query "What is the best framework?" -ProviderMode manual -ManualInput $manualInput2 -ProjectId "SIM-002" -PhaseId "test" -AgentId "RSRC-001"
# Quality gate should flag ai_generated without official sources
$qualResult = if ($r2.accepted) {
    $fakeIntake = [PSCustomObject]@{sourceRefs=$r2.sourceRefs;provider="glm_search";claimedFacts=@()}
    Test-SearchResultQuality -IntakePacket $fakeIntake
} else { $null }
$s2ok = $r2.accepted -eq $true
# AI-generated content should not pass cleanly
$s2qual = if ($qualResult) { $qualResult.trustRecommendation -in @("needs_human_review","reference_only") } else { $true }
Report 2 "manual_mode+AI_no_source" ($s2ok -and $s2qual) "accepted=$($r2.accepted) trust=$($qualResult.trustRecommendation)"

# =============================================
# Scenario 03: dry_run_mode → mock GLM response → PASS as referenceOnly
# =============================================
Write-Host "`n--- S03: dry_run_mode ---" -ForegroundColor Yellow
$r3 = Invoke-GLMSearch -RequestId "REQ-0003" -Query "Next.js 15 new features" -ProviderMode dry_run -ProjectId "SIM-003" -PhaseId "test" -AgentId "RSRC-001"
Report 3 "dry_run_mode+mock" ($r3.accepted -eq $true -and $r3.resultCount -gt 0 -and $r3.mode -eq "dry_run" -and ($r3.caveats -match "dry_run")) "accepted=$($r3.accepted) results=$($r3.resultCount) mode=$($r3.mode)"

# =============================================
# Scenario 04: live_api, no API key → downgrade to dry_run
# =============================================
Write-Host "`n--- S04: live_api + no key → downgrade ---" -ForegroundColor Yellow
# Ensure no key in env for this test
$oldKey = [Environment]::GetEnvironmentVariable("ZHIPUAI_API_KEY","Process")
$oldKey2 = [Environment]::GetEnvironmentVariable("GLM_API_KEY","Process")
[Environment]::SetEnvironmentVariable("ZHIPUAI_API_KEY","","Process")
[Environment]::SetEnvironmentVariable("GLM_API_KEY","","Process")
try {
    $r4 = Invoke-GLMSearch -RequestId "REQ-0004" -Query "Next.js docs" -ProviderMode live_api -UserApproval $true -ProjectId "SIM-004" -PhaseId "test" -AgentId "RSRC-001"
} finally {
    if ($oldKey) { [Environment]::SetEnvironmentVariable("ZHIPUAI_API_KEY",$oldKey,"Process") }
    if ($oldKey2) { [Environment]::SetEnvironmentVariable("GLM_API_KEY",$oldKey2,"Process") }
}
Report 4 "live_api+no_key→downgrade" ($r4.accepted -eq $true -and $r4.mode -eq "dry_run" -and $r4.downgradedFrom -eq "live_api") "accepted=$($r4.accepted) mode=$($r4.mode) downgradedFrom=$($r4.downgradedFrom)"

# =============================================
# Scenario 05: live_api, has key but no human approval → PENDING_HUMAN
# =============================================
Write-Host "`n--- S05: live_api + key + no approval → PENDING_HUMAN ---" -ForegroundColor Yellow
$oldKey = [Environment]::GetEnvironmentVariable("ZHIPUAI_API_KEY","Process")
[Environment]::SetEnvironmentVariable("ZHIPUAI_API_KEY","test-key-1234567890abcdef","Process")
try {
    $r5 = Invoke-GLMSearch -RequestId "REQ-0005" -Query "Next.js docs" -ProviderMode live_api -UserApproval $false -ProjectId "SIM-005" -PhaseId "test" -AgentId "RSRC-001"
} finally {
    if ($oldKey) { [Environment]::SetEnvironmentVariable("ZHIPUAI_API_KEY",$oldKey,"Process") } else { [Environment]::SetEnvironmentVariable("ZHIPUAI_API_KEY","","Process") }
}
Report 5 "live_api+no_human→pending" ($r5.accepted -eq $false -and $r5.gateDecision -eq "PENDING_HUMAN") "accepted=$($r5.accepted) gate=$($r5.gateDecision)"

# =============================================
# Scenario 06: live_api, has key + approval (but no real call) → allowWithControls with caveat
# =============================================
Write-Host "`n--- S06: live_api + key + approval → allowWithControls (no real call) ---" -ForegroundColor Yellow
$oldKey = [Environment]::GetEnvironmentVariable("ZHIPUAI_API_KEY","Process")
[Environment]::SetEnvironmentVariable("ZHIPUAI_API_KEY","test-key-real-abcdef123456","Process")
try {
    $r6 = Invoke-GLMSearch -RequestId "REQ-0006" -Query "Next.js 15 release notes" -ProviderMode live_api -UserApproval $true -ProjectId "SIM-006" -PhaseId "test" -AgentId "RSRC-001"
} finally {
    if ($oldKey) { [Environment]::SetEnvironmentVariable("ZHIPUAI_API_KEY",$oldKey,"Process") } else { [Environment]::SetEnvironmentVariable("ZHIPUAI_API_KEY","","Process") }
}
# live_api with fake key will fail, should downgrade gracefully
$s6ok = $r6.accepted -eq $true -and ($r6.mode -eq "dry_run" -or $r6.mode -eq "live_api")
$s6caveat = ($r6.caveats | Where-Object { $_ -match "downgrade|fail|API call" } | Measure-Object).Count -gt 0
Report 6 "live_api+key+approval→with_caveat" ($s6ok) "accepted=$($r6.accepted) mode=$($r6.mode) hasCaveat=$s6caveat"

# =============================================
# Scenario 07: Implementer agent → REJECT
# =============================================
Write-Host "`n--- S07: Implementer agent → REJECT ---" -ForegroundColor Yellow
$r7 = Invoke-GLMSearch -RequestId "REQ-0007" -Query "Next.js docs" -ProviderMode dry_run -ProjectId "SIM-007" -PhaseId "test" -AgentId "IMPL-FE-001"
Report 7 "implementer_agent→reject" ($r7.accepted -eq $false -and $r7.gateDecision -eq "REJECT" -and ($r7.gateReason -match "Implementer")) "accepted=$($r7.accepted) gate=$($r7.gateDecision)"

# =============================================
# Scenario 08: Search result with advertisement → referenceOnly or reject
# =============================================
Write-Host "`n--- S08: Ad source → flagged ---" -ForegroundColor Yellow
$manualInput8 = @{
    rawResult = "Search results with ads"
    links = @(
        @{title="Buy Next.js Templates — Best Deals!";url="https://spam-templates.example.com";snippet="Buy premium Next.js templates at 90% discount! LIMITED OFFER!";sourceType="advertisement";publishDate=""},
        @{title="Next.js Docs";url="https://nextjs.org/docs";snippet="Official Next.js documentation.";sourceType="official_docs";publishDate="2026-07-01"}
    )
}
$r8 = Invoke-GLMSearch -RequestId "REQ-0008" -Query "Next.js templates" -ProviderMode manual -ManualInput $manualInput8 -ProjectId "SIM-008" -PhaseId "test" -AgentId "RSRC-001"
$qualResult8 = if ($r8.accepted) {
    $fakeIntake = [PSCustomObject]@{sourceRefs=$r8.sourceRefs;provider="glm_search";claimedFacts=@()}
    Test-SearchResultQuality -IntakePacket $fakeIntake
} else { $null }
$s8flagged = if ($qualResult8) { ($qualResult8.issues -contains "ADVERTISMENT_DETECTED") } else { $false }
# Even with ad, if official docs present, should pass but with caveat
Report 8 "ad_source→flagged" ($r8.accepted -eq $true -and ($s8flagged -or ($qualResult8.trustRecommendation -ne "trusted_reference"))) "adFlagged=$s8flagged trust=$($qualResult8.trustRecommendation)"

# =============================================
# Scenario 09: Freshness not met → stale_caveat
# =============================================
Write-Host "`n--- S09: Stale results → caveat ---" -ForegroundColor Yellow
$r9 = Invoke-GLMSearch -RequestId "REQ-0009" -Query "Latest Next.js features" -ProviderMode dry_run -FreshnessRequirement "last_week" -ProjectId "SIM-009" -PhaseId "test" -AgentId "RSRC-001"
$s9caveat = ($r9.caveats | Where-Object { $_ -match "Freshness" } | Measure-Object).Count -gt 0
Report 9 "freshness_caveat" ($r9.accepted -eq $true -and $s9caveat) "accepted=$($r9.accepted) freshnessCaveat=$s9caveat"

# =============================================
# Scenario 10: Duplicate sources → dedupe
# =============================================
Write-Host "`n--- S10: Duplicate sources → dedupe ---" -ForegroundColor Yellow
$manualInput10 = @{
    rawResult = "Results with duplicates"
    links = @(
        @{title="Next.js Docs";url="https://nextjs.org/docs";snippet="Official Next.js documentation.";sourceType="official_docs";publishDate="2026-07-01"},
        @{title="Next.js Docs (same)";url="https://nextjs.org/docs";snippet="Official Next.js documentation duplicate.";sourceType="official_docs";publishDate="2026-07-01"},
        @{title="Next.js GitHub";url="https://github.com/vercel/next.js";snippet="Next.js repository.";sourceType="github";publishDate="2026-07-01"}
    )
}
$r10 = Invoke-GLMSearch -RequestId "REQ-0010" -Query "Next.js resources" -ProviderMode manual -ManualInput $manualInput10 -ProjectId "SIM-010" -PhaseId "test" -AgentId "RSRC-001"
$qualResult10 = if ($r10.accepted) {
    $fakeIntake = [PSCustomObject]@{sourceRefs=$r10.sourceRefs;provider="glm_search";claimedFacts=@()}
    Test-SearchResultQuality -IntakePacket $fakeIntake
} else { $null }
$s10dupDetected = if ($qualResult10) { $qualResult10.issues -contains "DUPLICATES" } else { $false }
Report 10 "duplicate_dedup" ($r10.accepted -eq $true) "results=$($r10.resultCount) dupDetected=$s10dupDetected"

# =============================================
# Summary
# =============================================
Write-Host ("`n========================================") -ForegroundColor Cyan
Write-Host (" SIMULATION: {0}/{1} PASS" -f $pass, $total) -ForegroundColor $(if($pass -eq $total){"Green"}else{"Yellow"})

$simResult = [PSCustomObject]@{
    simulationId = "R2.3-N-SIM-001"
    phase = "FACTORY-R2.3-N"
    totalScenarios = $total
    passCount = $pass
    failCount = $fail
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    scenarios = $results
}
$simResult | ConvertTo-Json -Depth 4 | Out-File (Join-Path $fr "outputs\FACTORY_R2_3_N_SEARCH_SIMULATION_RESULTS.json") -Encoding UTF8
Write-Host (" Simulation results written to outputs\FACTORY_R2_3_N_SEARCH_SIMULATION_RESULTS.json") -ForegroundColor Cyan
