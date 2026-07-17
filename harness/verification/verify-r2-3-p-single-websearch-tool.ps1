# R2.3-P Verification: Single WebSearch Tool + Search Agent Deprecation
param([string]$FactoryRoot = "C:\Codex_App_Factory")
$fr = $FactoryRoot; $p = 0; $f = 0
function V($id,$name,$cond){$s=if($cond){"PASS"}else{"FAIL"};Write-Host ("  [{0}] {1}: {2}" -f $s,$id,$name) -ForegroundColor $(if($cond){"Green"}else{"Red"});if($cond){$script:p++}else{$script:f++}}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-P SINGLE WEBSEARCH TOOL VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Search Agent deprecated
Write-Host "`n--- Search Agent Deprecation ---" -ForegroundColor Yellow
. (Join-Path $fr "runtime\router-direction-guard.ps1")
V "DEP-01" "DIR-007 deprecated" ((Test-DirectionAllowed "DIR-007").decision -match "REJECT")
V "DEP-02" "DIR-008 deprecated" ((Test-DirectionAllowed "DIR-008").decision -match "REJECT")
V "DEP-03" "DIR-009 deprecated" ((Test-DirectionAllowed "DIR-009").decision -match "REJECT")

# 2. Single WebSearch Tool active
V "SWT-01" "DIR-010 active" ((Test-DirectionAllowed "DIR-010").allowed -eq $true)
V "SWT-02" "DIR-011 active" ((Test-DirectionAllowed "DIR-011").allowed -eq $true)

# 3. Search Agent guard rejects
$sa = Test-SearchAgentAllowed
V "SAG-01" "Search Agent rejected" ($sa.allowed -eq $false)

# 4. Dual channel rejected
$dc = Test-DualSearchChannel
V "DC-01" "Dual channel rejected" ($dc.allowed -eq $false)

# 5. Constraints
$constraints = Get-SearchArchitectureConstraints
V "CST-01" "Single WebSearch Tool enforced" ($constraints.singleWebSearchTool -eq $true)
V "CST-02" "Evidence Pack sole carrier" ($constraints.evidencePackSoleCarrier -eq $true)
V "CST-03" "No search agent network" ($constraints.searchAgentDirectNetwork -eq $false)
V "CST-04" "No search agent to implementer" ($constraints.searchAgentDirectToImplementer -eq $false)

# 6. Implementer still blocked
. (Join-Path $fr "runtime\glm-search-adapter.ps1")
$rI = Invoke-GLMSearch -RequestId "VER-SWT" -Query "test" -ProviderMode dry_run -ProjectId "VER" -AgentId "IMPL-FE-001"
V "IMP-01" "Implementer blocked" ($rI.accepted -eq $false)

# 7. No live API calls
$anyKey = $false
foreach ($k in @("ZHIPUAI_API_KEY","GLM_API_KEY")) { foreach ($s in @("Process","User","Machine")) { $v=[Environment]::GetEnvironmentVariable($k,$s); if($v -and $v.Length -gt 1){$anyKey=$true} } }
V "LIVE-01" "No API key present" (-not $anyKey)

# 8. Reports exist
V "RPT-01" "Deprecation report" (Test-Path (Join-Path $fr "outputs\FACTORY_R2_3_P_SEARCH_AGENT_DEPRECATION_REPORT.md"))
V "RPT-02" "Architecture decision" (Test-Path (Join-Path $fr "outputs\FACTORY_R2_3_P_SINGLE_WEBSEARCH_TOOL_ARCHITECTURE_DECISION.md"))
V "RPT-03" "Provider selection gate" (Test-Path (Join-Path $fr "outputs\FACTORY_R2_3_P_PROVIDER_SELECTION_GATE.md"))
V "RPT-04" "Provider ranking" (Test-Path (Join-Path $fr "outputs\FACTORY_R2_3_P_PROVIDER_RANKING_AND_DECISION.md"))

# 9. Direction registry updated
$ledgerPath = Join-Path $fr "governance\direction-decisions\direction-decision-index.jsonl"
$entries = if(Test-Path $ledgerPath){Get-Content $ledgerPath -Encoding UTF8|Where-Object{$_.Trim()}|ForEach-Object{try{$_|ConvertFrom-Json}catch{$null}}|Where-Object{$_}}else{@()}
V "REG-01" "DIR-007 exists" (($entries|Where-Object{$_.directionId -eq "DIR-007"}|Measure-Object).Count -gt 0)
V "REG-02" "DIR-010 exists" (($entries|Where-Object{$_.directionId -eq "DIR-010"}|Measure-Object).Count -gt 0)
V "REG-03" "Total entries >= 11" ($entries.Count -ge 11)

# Summary
Write-Host ("`n========================================") -ForegroundColor Cyan
Write-Host (" VERIFICATION: {0}/{1} PASS" -f $p,($p+$f)) -ForegroundColor $(if($f -eq 0){"Green"}else{"Yellow"})
