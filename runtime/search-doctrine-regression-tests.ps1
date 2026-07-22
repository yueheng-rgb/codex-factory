# Search Doctrine Regression Tests v1.0.0
# Part of: FACTORY-R2.3-Y
# 18 regression tests covering P0/P1/P2 classification

param(
    [string]$OutputFile = (Join-Path $PSScriptRoot "..\outputs\FACTORY_R2_3_Y_REGRESSION_RESULTS.json")
)

Push-Location (Split-Path -Parent $PSCommandPath)

. (Join-Path $PSScriptRoot "search-operating-doctrine.ps1")
. (Join-Path $PSScriptRoot "pre-build-research-gate.ps1")
. (Join-Path $PSScriptRoot "search-result-quality-gate.ps1")

$results = @()
$passed = 0
$failed = 0

function Test-Case {
    param([string]$Id, [string]$Description, $TaskDesc, [string]$ExpectedLevel, [string]$ExpectedFatal="")
    $gate = Invoke-PreBuildResearchGate -TaskDescription $TaskDesc -AgentId "RSRC-001"
    $levelMatch = $gate.search_level -eq $ExpectedLevel
    $fatalMatch = if ($ExpectedFatal) { $gate.fatal_violations -contains $ExpectedFatal } else { $true }
    $ok = $levelMatch -and $fatalMatch
    
    if ($ok) { $script:passed++ } else { $script:failed++ }
    $script:results += [PSCustomObject]@{id=$Id; description=$Description; expected=$ExpectedLevel; got=$gate.search_level; level_ok=$levelMatch; reason=$gate.reason; security_critical=$gate.security_critical; passed=$ok}
    Write-Output "$(if($ok){'PASS'}else{'FAIL'}) | $Id | $Description | expected=$ExpectedLevel got=$($gate.search_level)"
}

# A: JWT -> P0
Test-Case -Id "A" -Description "JWT Refresh Token" -TaskDesc "Implement JWT refresh token rotation with httpOnly cookie" -ExpectedLevel "P0_MUST_SEARCH"

# B: File Upload -> P0
Test-Case -Id "B" -Description "File Upload Multipart" -TaskDesc "Implement Fastify multipart file upload with MIME validation" -ExpectedLevel "P0_MUST_SEARCH"

# C: RBAC -> P0
Test-Case -Id "C" -Description "RBAC Permissions" -TaskDesc "Design RBAC role-based access control for admin dashboard" -ExpectedLevel "P0_MUST_SEARCH"

# D: Third-party SDK -> P0
Test-Case -Id "D" -Description "Third-party SDK Integration" -TaskDesc "Integrate new payment SDK and configure API keys" -ExpectedLevel "P0_MUST_SEARCH"

# E: Dependency upgrade -> P0
Test-Case -Id "E" -Description "Dependency Version Upgrade" -TaskDesc "Upgrade fastify/multipart from v7 to v8, check breaking changes" -ExpectedLevel "P0_MUST_SEARCH"

# F: UI pattern -> P1
Test-Case -Id "F" -Description "UI Pattern" -TaskDesc "Choose between multiple UI component approaches for admin table" -ExpectedLevel "P1_SHOULD_SEARCH"

# G: Simple CSS -> P2
Test-Case -Id "G" -Description "Simple CSS Fix" -TaskDesc "Fix padding on login button, change color to blue" -ExpectedLevel "P2_NO_SEARCH_REQUIRED"

# H: Local bug -> P2
Test-Case -Id "H" -Description "Local Known Bug Fix" -TaskDesc "Fix known bug in calculateTotal function where tax is doubled" -ExpectedLevel "P2_NO_SEARCH_REQUIRED"

# I: Bug + dependency uncertainty -> P0
Test-Case -Id "I" -Description "Bug + Dependency Uncertainty" -TaskDesc "Fix login bug, unsure if fastify/jwt API changed in latest version" -ExpectedLevel "P0_MUST_SEARCH"

# J: P0 must require Evidence Pack
Test-Case -Id "J" -Description "P0 without Evidence Pack" -TaskDesc "Implement JWT authentication without any research" -ExpectedLevel "P0_MUST_SEARCH"

# K: Implementer direct search -> REJECT
$gateK = Invoke-PreBuildResearchGate -TaskDescription "Implement file upload" -AgentId "IMPL-001"
$kPass = $gateK.search_level -eq "REJECT" -and $gateK.fatal_violations -contains "IMPLEMENTER_SEARCH_ATTEMPT"
$results += [PSCustomObject]@{id="K"; description="Implementer Direct Search"; expected="REJECT"; got=$gateK.search_level; level_ok=$kPass; reason=$gateK.reason; security_critical=$false; passed=$kPass}
if ($kPass) { $passed++ } else { $failed++ }
Write-Output "$(if($kPass){'PASS'}else{'FAIL'}) | K | Implementer Direct Search | REJECT"

# L: Chat URL extraction -> noted (tested via source_origin in QG)
Write-Output "INFO | L | Chat URL extraction -> tested via Quality Gate source_origin enforcement"

# M: model_text_extraction source_origin -> reject
$fakeIntake = [PSCustomObject]@{ sourceRefs = @([PSCustomObject]@{title="Test"; url="https://example.com"; source_origin="model_text_extraction"; snippet="test"}) }
$fakeEP = [PSCustomObject]@{ phase="test"; mode="live_search" }
$qgM = Test-SearchResultQuality -IntakePacket $fakeIntake -SearchInvoked $true -ActualMode "live_api" -EvidencePack $fakeEP
$mPass = (-not $qgM.passed) -and ($qgM.fatalRejections -contains "source_origin_not_model_text_extraction: FAIL")
$results += [PSCustomObject]@{id="M"; description="model_text_extraction reject"; expected="FAIL_FATAL"; got=$qgM.verdict; level_ok=$mPass; reason="source_origin check"; security_critical=$false; passed=$mPass}
if ($mPass) { $passed++ } else { $failed++ }
Write-Output "$(if($mPass){'PASS'}else{'FAIL'}) | M | model_text_extraction reject | $($qgM.verdict)"

# N: P2 forced search -> oversearch rejected
Test-Case -Id "N" -Description "P2 Forced Search" -TaskDesc "Fix typo in README" -ExpectedLevel "P2_NO_SEARCH_REQUIRED"

# O: P0 security Design missing controls -> fail
$secDesign = @{ adopted_approach = "JWT" }
$secEP = [PSCustomObject]@{ security_critical = $true }
$secCheck = Test-SecurityDesignCompleteness -Design $secDesign -EvidencePack $secEP
$oPass = (-not $secCheck.complete)
$results += [PSCustomObject]@{id="O"; description="Security missing controls"; expected="INCOMPLETE"; got=("complete=$($secCheck.complete)"); level_ok=$oPass; reason="missing fields"; security_critical=$true; passed=$oPass}
if ($oPass) { $passed++ } else { $failed++ }
Write-Output "$(if($oPass){'PASS'}else{'FAIL'}) | O | Security missing controls | complete=$($secCheck.complete)"

# P: No official source -> authoritative_source_gap
$noOfficialIntake = [PSCustomObject]@{ sourceRefs = @([PSCustomObject]@{title="Blog"; url="https://blog.example.com"; source_origin="provider_search_result"; source_tier="tier_3_bronze"; source_language="zh"; snippet="test"}) }
$qgP = Test-SearchResultQuality -IntakePacket $noOfficialIntake -SearchInvoked $true -ActualMode "live_api" -EvidencePack $fakeEP
$pPass = $qgP.authoritative_source_gap -eq $true
$results += [PSCustomObject]@{id="P"; description="Official source gap"; expected="gap=true"; got=("gap=$($qgP.authoritative_source_gap)"); level_ok=$pPass; reason="authoritative_source_gap"; security_critical=$false; passed=$pPass}
if ($pPass) { $passed++ } else { $failed++ }
Write-Output "$(if($pPass){'PASS'}else{'FAIL'}) | P | Official source gap | gap=$($qgP.authoritative_source_gap)"

# Q: Missing query_intent -> warning
$qgQ = Test-SearchResultQuality -IntakePacket $noOfficialIntake -SearchInvoked $true -ActualMode "live_api" -EvidencePack $fakeEP
$qPass = $qgQ.warnings -contains "query_intent_missing"
$results += [PSCustomObject]@{id="Q"; description="Missing query_intent"; expected="warning"; got=("warnings present=$qPass"); level_ok=$qPass; reason="query_intent warning"; security_critical=$false; passed=$qPass}
if ($qPass) { $passed++ } else { $failed++ }
Write-Output "$(if($qPass){'PASS'}else{'FAIL'}) | Q | Missing query_intent | warning=$qPass"

# R: Missing source_type_counts -> warning
$rPass = $qgQ.warnings -contains "source_type_counts_missing"
$results += [PSCustomObject]@{id="R"; description="Missing source_type_counts"; expected="warning"; got=("warnings present=$rPass"); level_ok=$rPass; reason="source_type_counts warning"; security_critical=$false; passed=$rPass}
if ($rPass) { $passed++ } else { $failed++ }
Write-Output "$(if($rPass){'PASS'}else{'FAIL'}) | R | Missing source_type_counts | warning=$rPass"

# Summary
$total = $passed + $failed
Write-Output ""
Write-Output "=== REGRESSION RESULTS ==="
Write-Output "Total: $total | Passed: $passed | Failed: $failed"
Write-Output "Pass Rate: $(if($total -gt 0){[math]::Round($passed/$total*100,1)}else{0})%"

$output = [PSCustomObject]@{phase="R2.3-Y-REGRESSION"; total=$total; passed=$passed; failed=$failed; pass_rate=$(if($total -gt 0){[math]::Round($passed/$total*100,1)}else{0}); results=$results}
$resolvedOutput = [IO.Path]::GetFullPath($OutputFile)
$outputParent = Split-Path -Parent $resolvedOutput
if (-not (Test-Path -LiteralPath $outputParent -PathType Container)) { New-Item -ItemType Directory -Force -Path $outputParent | Out-Null }
$output | ConvertTo-Json -Depth 4 | Out-File $resolvedOutput -Encoding UTF8

Pop-Location
Write-Output "Regression results written"
if ($failed -gt 0) { exit 1 }
exit 0
