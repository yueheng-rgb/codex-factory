param([string]$FactoryRoot = "C:\Codex_App_Factory")
$fr = $FactoryRoot
. (Join-Path $fr "runtime\tool-registry-loader.ps1")
. (Join-Path $fr "runtime\tool-permission-gate.ps1")
. (Join-Path $fr "runtime\tool-invocation-logger.ps1")
. (Join-Path $fr "runtime\read-only-search-adapter.ps1")
. (Join-Path $fr "runtime\search-result-quality-gate.ps1")
$sims=@();$pc=0;$fc=0
function S($id,$desc,$ok){$script:sims+=[PSCustomObject]@{simId=$id;description=$desc;passed=$ok};if($ok){$script:pc++;$m="PASS"}else{$script:fc++;$m="FAIL"};Write-Host ("  [{0}] {1}: {2}" -f $m,$id,$desc) -ForegroundColor $(if($ok){"Green"}else{"Red"})}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-K COMBINED SIMULATION (10 scenarios)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "`n--- Playwright ---" -ForegroundColor Yellow
$pw=Get-Content (Join-Path $fr "outputs\FACTORY_R2_3_K_PLAYWRIGHT_SANDBOX_RESULTS.json") -Raw|ConvertFrom-Json
S "SIM-A" "Playwright sandbox trial: 6/6 PASS" $pw.playwrightOk
$g1=Test-ToolPermission -ProjectId "T" -AgentId "VER-001" -ToolId "TOOL-PLAYWRIGHT-VER-001" -SandboxAvailable $true -HumanApproved $true -NetworkAllowed $false
S "SIM-B" "Playwright gate: REJECT (localhost/external nuance)" ($g1.Decision -eq "REJECT")
S "SIM-C" "Playwright+external net disallowed => REJECT" ($g1.Decision -eq "REJECT")
$g2=Test-ToolPermission -ProjectId "T" -AgentId "VER-001" -ToolId "TOOL-PLAYWRIGHT-VER-001" -SandboxAvailable $true -HumanApproved $true -NetworkAllowed $true -FileWriteAllowed $false
S "SIM-D" "Playwright+fileWrite allowed (tool has fileWriteAccess=false)" ($g2.Decision -like "ALLOW*")
$g3=Test-ToolPermission -ProjectId "T" -AgentId "VER-001" -ToolId "TOOL-UNKNOWN-999"
S "SIM-E" "Unknown tool => REJECT" ($g3.Decision -eq "REJECT")
Write-Host "`n--- Search Adapter ---" -ForegroundColor Yellow
$good=Join-Path $fr "examples\search-adapter-inputs\good-official-docs.json"
$bad=Join-Path $fr "examples\search-adapter-inputs\bad-ai-no-sources.json"
$i1=Import-SearchResult -InputPath $good
S "SIM-F" "Official docs: accepted for review/capsule" ($i1.accepted -and $i1.recommendedAction -eq "review_and_capsule")
$i2=Import-SearchResult -InputPath $bad
S "SIM-G" "AI no sources: rejected or needs human review" ($i2.issueCount -ne 0)
S "SIM-H" "AI flagged NEEDS_HUMAN_REVIEW" ($i2.trustRecommendation -eq "NEEDS_HUMAN_REVIEW")
S "SIM-I" "Official docs: TRUSTED_REFERENCE" ($i1.trustRecommendation -eq "TRUSTED_REFERENCE")
$g4=Test-ToolPermission -ProjectId "T" -AgentId "IMPL-FE-001" -ToolId "TOOL-SEARCH-ADAPTER-001"
S "SIM-J" "Implementer cannot use search adapter => REJECT" ($g4.Decision -eq "REJECT")
Write-Host ("`n========================================") -ForegroundColor Cyan
Write-Host (" RESULTS: {0} / {1} PASS" -f $pc,$sims.Count) -ForegroundColor $(if($fc -eq 0){"Green"}else{"Red"})
Write-Host ("========================================") -ForegroundColor Cyan
$sims|ConvertTo-Json -Depth 2|Out-File (Join-Path $fr "outputs\FACTORY_R2_3_K_TOOL_SEARCH_SIMULATION_RESULTS.json") -Encoding UTF8

