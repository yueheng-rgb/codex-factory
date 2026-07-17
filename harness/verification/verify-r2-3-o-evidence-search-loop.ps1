# R2.3-O Verification: Evidence Search Loop
param([string]$FactoryRoot = "C:\Codex_App_Factory")
$fr = $FactoryRoot; $p = 0; $f = 0
function V($id,$name,$cond) {$s=if($cond){"PASS"}else{"FAIL"};Write-Host ("  [{0}] {1}: {2}" -f $s,$id,$name) -ForegroundColor $(if($cond){"Green"}else{"Red"});if($cond){$script:p++}else{$script:f++}}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-O VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Direction Guard
Write-Host "`n--- Direction Guard ---" -ForegroundColor Yellow
. (Join-Path $fr "runtime\router-direction-guard.ps1")
$active = Get-ActiveDirection
V "DG-01" "DIR-004 active" ($active.directionId -eq "DIR-004")
$dg = Test-DirectionAllowed "DIR-001"; V "DG-02" "DIR-001 deferred" (-not $dg.allowed)
$dg = Test-DirectionAllowed "DIR-003"; V "DG-03" "DIR-003 deprecated" (-not $dg.allowed)

# Schemas
Write-Host "`n--- Schemas ---" -ForegroundColor Yellow
$schemas = @("search-trigger-policy","evidence-pack","reader-extractor","search-loop-state","direction-decision")
foreach ($s in $schemas) { $sp = Join-Path $fr "schemas\$s.schema.json"; try {$null=Get-Content $sp -Raw|ConvertFrom-Json; V "SCH-$s" "schema parse" $true} catch {V "SCH-$s" "schema parse" $false} }

# Runtime scripts
Write-Host "`n--- Runtime Scripts ---" -ForegroundColor Yellow
$scripts = @("need-search-detector","evidence-pack-builder","reader-extractor-adapter","iterative-search-loop","router-direction-guard")
foreach ($s in $scripts) { $sp = Join-Path $fr "runtime\$s.ps1"; V "SCR-$s" "exists" (Test-Path $sp) }

# Need Search Detector
Write-Host "`n--- Need Search Detector ---" -ForegroundColor Yellow
. (Join-Path $fr "runtime\need-search-detector.ps1")
$r1 = Test-NeedSearch -TaskDescription "Implement Next.js 15 API routes"
V "NSD-01" "framework_ref triggers" ($r1.needSearch -eq $true)
$r2 = Test-NeedSearch -TaskDescription "Rename variable a to b"
V "NSD-02" "refactor no trigger" ($r2.needSearch -eq $false)

# Evidence Pack Builder
Write-Host "`n--- Evidence Pack ---" -ForegroundColor Yellow
. (Join-Path $fr "runtime\glm-search-adapter.ps1"); . (Join-Path $fr "runtime\evidence-pack-builder.ps1")
$m = @{rawResult="";links=@(@{title="Next.js Docs";url="https://nextjs.org/docs";snippet="Official";sourceType="official_docs";publishDate="2026-07-01"})}
$r = Invoke-GLMSearch -RequestId "VER" -Query "Next.js" -ProviderMode manual -ManualInput $m -ProjectId "VER" -AgentId "RSRC-001"
$ep = New-EvidencePack -Task "Test" -ProjectId "VER" -SearchRound 1 -TriggerReason "initial_search" -GLMResponse $r
V "EP-01" "evidence pack accepted" ($ep.accepted -eq $true)
V "EP-02" "has quality gate" ($ep.qualityGateStatus -ne $null)
V "EP-03" "forbids skill registry" ($ep.forbiddenUse -contains "do_not_enter_skill_registry_directly")

# Reader/Extractor
Write-Host "`n--- Reader/Extractor ---" -ForegroundColor Yellow
. (Join-Path $fr "runtime\reader-extractor-adapter.ps1")
$re = Invoke-ReaderExtractor -ExtractorId "EXTR-TEST" -ProviderType "manual_excerpt" -Mode "manual" -ManualExcerpts @("Test content") -Urls @("https://example.com")
V "RE-01" "manual excerpt works" ($re.accepted -and $re.contentCount -eq 1)
$re2 = Invoke-ReaderExtractor -ExtractorId "EXTR-TEST2" -ProviderType "dry_run_fixture" -Mode "dry_run" -Urls @("https://example.com")
V "RE-02" "dry_run fixture works" ($re2.accepted)

# Iterative Search Loop
Write-Host "`n--- Iterative Loop ---" -ForegroundColor Yellow
. (Join-Path $fr "runtime\iterative-search-loop.ps1")
$loop = New-SearchLoopState -TaskId "T-VER" -ProjectId "VER" -MaxRounds 3
V "IL-01" "loop state created" ($loop.status -eq "active")
V "IL-02" "budget set" ($loop.budget.maxSearchRoundsPerTask -eq 3)
$result = Invoke-SearchLoop -LoopState $loop -TaskDescription "Test" -ProjectId "VER" -AgentId "RSRC-001" -DryRunOnly $true
V "IL-03" "loop executed" ($result.totalRounds -ge 1)
V "IL-04" "has status" ($result.finalStatus -ne $null)

# Provider Comparison Matrix
Write-Host "`n--- Provider Matrix ---" -ForegroundColor Yellow
$pmPath = Join-Path $fr "registries\search-provider-comparison-registry.jsonl"
$pmOk = (Test-Path $pmPath) -and ((Get-Content $pmPath|Where-Object{$_.Trim()}|Measure-Object).Count -ge 5)
V "PM-01" "provider matrix >=5 entries" $pmOk

# Agent Access Control
Write-Host "`n--- Agent Access ---" -ForegroundColor Yellow
$rI = Invoke-GLMSearch -RequestId "VER-I" -Query "test" -ProviderMode dry_run -ProjectId "VER" -AgentId "IMPL-FE-001"
V "AC-01" "implementer blocked" ($rI.accepted -eq $false)
$rR = Invoke-GLMSearch -RequestId "VER-R" -Query "test" -ProviderMode dry_run -ProjectId "VER" -AgentId "RSRC-001"
V "AC-02" "researcher allowed" ($rR.accepted -eq $true)

# Simulation results
Write-Host "`n--- Simulation ---" -ForegroundColor Yellow
$simPath = Join-Path $fr "outputs\FACTORY_R2_3_O_ITERATIVE_SEARCH_SIMULATION_RESULTS.json"
if (Test-Path $simPath) { $sim = Get-Content $simPath -Raw|ConvertFrom-Json; V "SIM-01" "sim 12/12" ($sim.passCount -eq 12) "pass=$($sim.passCount)/$($sim.totalScenarios)" } else { V "SIM-01" "sim file" $false }

# Summary
Write-Host ("`n========================================") -ForegroundColor Cyan
Write-Host (" VERIFICATION: {0}/{1} PASS" -f $p,($p+$f)) -ForegroundColor $(if($f -eq 0){"Green"}else{"Red"})
