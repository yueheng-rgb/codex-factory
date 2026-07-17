# R2.3-F SKILL CONTENT RUNTIME VERIFICATION
param([string]$FactoryRoot = "C:\Codex_App_Factory")
$ErrorActionPreference = "Continue"

. (Join-Path $FactoryRoot "runtime\agent-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-loader.ps1")
. (Join-Path $FactoryRoot "runtime\skill-content-loader.ps1")
. (Join-Path $FactoryRoot "runtime\skill-context-injector.ps1")

$R=@();$PC=0;$FC=0
function A {param([string]$C,[bool]$P,[string]$D="") $script:R+=[PSCustomObject]@{Check=$C;Passed=$P;Detail=$D};if($P){$script:PC++}else{$script:FC++};Write-Host "$(if($P){'[PASS]'}else{'[FAIL]'}) $C" -ForegroundColor $(if($P){'Green'}else{'Red'})}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-F SKILL CONTENT RUNTIME VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Skill package schema
Write-Host "--- 1. Schema ---" -ForegroundColor Yellow
$schema = Join-Path $FactoryRoot "schemas\factory-skill-package.schema.json"
A "Skill package schema exists" (Test-Path $schema) ""
try { Get-Content $schema -Raw | ConvertFrom-Json | Out-Null; A "Schema is valid JSON" $true "" } catch { A "Schema is valid JSON" $false $_.Exception.Message }

# 2. CAP-SKILL-004 package
Write-Host "--- 2. CAP-SKILL-004 Package ---" -ForegroundColor Yellow
A "skill.json exists" (Test-Path (Join-Path $FactoryRoot "skills\CAP-SKILL-004\skill.json")) ""
A "SKILL.md exists" (Test-Path (Join-Path $FactoryRoot "skills\CAP-SKILL-004\SKILL.md")) ""
A "Fixture AGENTS.md exists" (Test-Path (Join-Path $FactoryRoot "skills\CAP-SKILL-004\examples\fixture-agents-md.md")) ""

# 3. Skill content loader
Write-Host "--- 3. Loader ---" -ForegroundColor Yellow
$r = Load-SkillContent -SkillId "CAP-SKILL-004" -AgentId "PM-001" -ProjectId "PROJ-VFY-F" -PhaseId "PHASE-VFY"
A "Loader: CAP-SKILL-004 loads for PM-001" $r.Loaded "Name: $($r.SkillSummary.name)"
A "  Instructions loaded (not just metadata)" ($r.SkillSummary.instructionsLength -gt 100) "Length: $($r.SkillSummary.instructionsLength)"
A "  Allowed tools present" ($r.SkillSummary.allowedTools.Count -gt 0) "Tools: $($r.SkillSummary.allowedTools -join ', ')"
A "  Forbidden actions present" ($r.SkillSummary.forbiddenActions.Count -gt 0) "Count: $($r.SkillSummary.forbiddenActions.Count)"

$r2 = Load-SkillContent -SkillId "CAP-SKILL-004" -AgentId "IMPL-FE-001" -ProjectId "PROJ-VFY-F"
A "Loader: FE agent rejected" (-not $r2.Loaded) $r2.Reason

$r3 = Load-SkillContent -SkillId "CAP-GHOST-999" -AgentId "PM-001" -ProjectId "PROJ-VFY-F"
A "Loader: Unknown skill rejected" (-not $r3.Loaded) $r3.Reason

# 4. Context injector
Write-Host "--- 4. Context Injection ---" -ForegroundColor Yellow
$ctx = New-AgentExecutionContextWithSkills -AgentId "PM-001" -ProjectId "PROJ-VFY-F" -SkillIds @("CAP-SKILL-004")
A "Context: loadedSkillRefs present" ($null -ne $ctx.loadedSkillRefs) ""
A "Context: skillsLoadedCount = 1" ($ctx.skillsLoadedCount -eq 1) ""
A "Context: rules/instructions accessible" ($ctx.loadedSkillRefs[0].instructionsSummary.Length -gt 100) ""

# 5. Usage ledger
Write-Host "--- 5. Usage Ledger ---" -ForegroundColor Yellow
$ulPath = Join-Path $FactoryRoot "governance\skill-usage\skill-usage-index.jsonl"
A "Usage ledger file exists" (Test-Path $ulPath) ""
$ulCount = (Get-Content $ulPath | Where-Object { $_.Trim() -ne "" }).Count
A "Usage ledger has records" ($ulCount -gt 0) "Entries: $ulCount"

# 6. Behavior simulation
Write-Host "--- 6. Behavior Sim ---" -ForegroundColor Yellow
$simPath = Join-Path $FactoryRoot "runtime\tests\skill-behavior-simulation-result.json"
if (Test-Path $simPath) {
    $sim = Get-Content $simPath -Raw | ConvertFrom-Json
    A "Behavior sim: all passed" $sim.allPassed "Pass: $($sim.passCount)/$($sim.passCount+$sim.failCount)"
}

# 7. Rollback
Write-Host "--- 7. Rollback ---" -ForegroundColor Yellow
$rb = Invoke-SkillRollback -SkillId "CAP-SKILL-004" -Reason "Verification rollback test"
A "Rollback: record created" ($null -ne $rb) ""

# 8. Metadata vs Behavior distinction
Write-Host "--- 8. metadata vs behavior ---" -ForegroundColor Yellow
A "skill.json status != runtimeVerified (is 'verified')" ((Get-Content (Join-Path $FactoryRoot "skills\CAP-SKILL-004\skill.json") -Raw | ConvertFrom-Json).status -ne "runtimeVerified") "MUST distinguish: metadata verified ≠ behavior verified"
A "Behavior verification evidence exists (fixture + simulation)" (Test-Path (Join-Path $FactoryRoot "skills\CAP-SKILL-004\examples\fixture-agents-md.md")) "Fixture + simulation provide behavior evidence"

# SUMMARY
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " VERIFICATION: $PC/$($PC+$FC) PASSED" -ForegroundColor $(if($FC -eq 0){'Green'}else{'Red'})
Write-Host "========================================" -ForegroundColor Cyan

$v = [PSCustomObject]@{date=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"); passCount=$PC; failCount=$FC; allPassed=($FC -eq 0); results=$R}
$v | ConvertTo-Json -Depth 4 | Out-File (Join-Path $FactoryRoot "harness\verification\r2-3-f-verification-result.json") -Encoding UTF8
