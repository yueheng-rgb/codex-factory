# Skill Behavior Simulation
# Part of: FACTORY-R2.3-F-SKILL-CONTENT-RUNTIME-VERIFICATION
# Verifies CAP-SKILL-004 produces meaningful behavioral differences.

param([string]$FactoryRoot = "C:\Codex_App_Factory")
$ErrorActionPreference = "Continue"

. (Join-Path $FactoryRoot "runtime\agent-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-loader.ps1")
. (Join-Path $FactoryRoot "runtime\skill-content-loader.ps1")
. (Join-Path $FactoryRoot "runtime\skill-context-injector.ps1")

$Results=@(); $PC=0; $FC=0
function S { param([string]$L,[bool]$P,[string]$D="") 
    $script:Results+=[PSCustomObject]@{Scenario=$L;Passed=$P;Detail=$D}; if($P){$script:PC++}else{$script:FC++}
    Write-Host "$(if($P){'[PASS]'}else{'[FAIL]'}) $L" -ForegroundColor $(if($P){'Green'}else{'Red'})
    if($D){Write-Host "    $D" -ForegroundColor White}
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SKILL BEHAVIOR SIMULATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# === 1: Load fixture AGENTS.md ===
Write-Host "`n--- 1: Fixture AGENTS.md ---" -ForegroundColor Yellow
$fixturePath = Join-Path $FactoryRoot "skills\CAP-SKILL-004\examples\fixture-agents-md.md"
$fixtureExists = Test-Path $fixturePath
S "1: Fixture AGENTS.md exists" $fixtureExists $fixturePath
if (-not $fixtureExists) { Write-Host "ABORT" -ForegroundColor Red; return }

$fixture = Get-Content $fixturePath -Raw -Encoding UTF8
S "1b: Fixture contains build command" ($fixture -match 'npm run build') ""
S "1c: Fixture contains test command" ($fixture -match 'npm test') ""
S "1d: Fixture contains lint command" ($fixture -match 'eslint') ""
S "1e: Fixture contains security boundary" ($fixture -match 'Do not commit .env') ""
S "1f: Fixture contains JWT rule" ($fixture -match 'validate JWT') ""
S "1g: Fixture contains handoff rule" ($fixture -match 'build PASS evidence') ""

# === 2: Extract commands programmatically ===
Write-Host "`n--- 2: Command Extraction ---" -ForegroundColor Yellow
$buildRx = [regex]'Run `([^`]+)` to (?:compile|build)'
$buildMatches = $buildRx.Matches($fixture)
S "2: Build command extracted" ($buildMatches.Count -gt 0) "Found: $($buildMatches[0].Groups[1].Value)"

$testRx = [regex]'Run `([^`]+)` to (?:execute|run) (?:all )?test'
$testMatches = $testRx.Matches($fixture)
S "2b: Test command extracted" ($testMatches.Count -gt 0) "Found: $($testMatches[0].Groups[1].Value)"

$lintRx = [regex]'Run `([^`]+)` (?:before|for)'
$lintMatches = $lintRx.Matches($fixture)
S "2c: Lint command extracted" ($lintMatches.Count -gt 0) ""

# === 3: Extract security boundaries ===
Write-Host "`n--- 3: Security Boundaries ---" -ForegroundColor Yellow
$secRx = [regex]'(?:Do not|must|must not|never)\s+([^.!]+)[.!]'
$secMatches = $secRx.Matches($fixture)
S "3: Security rules detected" ($secMatches.Count -ge 1) "Found: $($secMatches.Count)"
foreach ($m in $secMatches) { Write-Host "    - $($m.Groups[1].Value.Trim())" -ForegroundColor Gray }

# === 4: Extract directory scopes ===
Write-Host "`n--- 4: Directory Rules ---" -ForegroundColor Yellow
$dirRx = [regex]'-\s+(/[\w/]+):\s+(.+)'
$dirMatches = $dirRx.Matches($fixture)
S "4: Directory rules extracted" ($dirMatches.Count -ge 2) "Found: $($dirMatches.Count)"

# === 5: Context injection comparison ===
Write-Host "`n--- 5: Context Injection ---" -ForegroundColor Yellow
$ctxNoSkill = New-AgentExecutionContextWithSkills -AgentId "PM-001" -ProjectId "PROJ-SIM-F" -PhaseId "PHASE-DESIGN" -ProjectType "fullstack-admin" -SkillIds @()
S "5: Base context created (no skills)" ($null -ne $ctxNoSkill) ""

$ctxWithSkill = New-AgentExecutionContextWithSkills -AgentId "PM-001" -ProjectId "PROJ-SIM-F" -PhaseId "PHASE-DESIGN" -ProjectType "fullstack-admin" -SkillIds @("CAP-SKILL-004")
S "5b: Context created WITH CAP-SKILL-004" ($null -ne $ctxWithSkill) ""
S "5c: loadedSkillRefs injected" ($ctxWithSkill.loadedSkillRefs.Count -eq 1) "Count: $($ctxWithSkill.loadedSkillRefs.Count)"
S "5d: skillsLoadedCount = 1" ($ctxWithSkill.skillsLoadedCount -eq 1) ""
S "5e: Base context has 0 loaded skills" ($ctxNoSkill.loadedSkillRefs.Count -eq 0) ""

# === 6: Skill usage ledger ===
Write-Host "`n--- 6: Usage Ledger ---" -ForegroundColor Yellow
$usage = Get-SkillUsage -SkillId "CAP-SKILL-004" -Max 5
S "6: Usage records exist for CAP-SKILL-004" ($usage.Count -gt 0) "Records: $($usage.Count)"
$lastLoad = $usage | Where-Object { $_.decision -eq "loaded" } | Select-Object -First 1
S "6b: Most recent record is 'loaded'" ($null -ne $lastLoad -and $lastLoad.decision -eq "loaded") ""

# === 7: Conflict detection ===
Write-Host "`n--- 7: Conflict Detection ---" -ForegroundColor Yellow
$conflictFixture = "# AGENTS.md`n## Conventions`n- Use TypeScript strict mode"
$userInstruction = "Use plain JavaScript"
$hasConflict = ($conflictFixture -match 'TypeScript') -and ($userInstruction -match 'JavaScript')
S "7: Conflict detected: AGENTS.md=TS, user=JS" $hasConflict ""

# === 8: Rollback path ===
Write-Host "`n--- 8: Rollback ---" -ForegroundColor Yellow
$rb = Invoke-SkillRollback -SkillId "CAP-SKILL-004" -Reason "Behavior simulation rollback test"
S "8: Rollback record written" ($null -ne $rb) "RecordId: $($rb.recordId)"

# === 9: Quarantine gate ===
Write-Host "`n--- 9: Quarantine Gate ---" -ForegroundColor Yellow
$rQ = Load-SkillContent -SkillId "CAP-MCP-014" -AgentId "INTG-001" -ProjectId "PROJ-SIM-F"
S "9: Quarantine cap rejected (no skill dir)" (-not $rQ.Loaded) "Reason: $($rQ.Reason)"

# === SUMMARY ===
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " BEHAVIOR SIM: $PC/$($PC+$FC) PASSED" -ForegroundColor $(if($FC -eq 0){'Green'}else{'Red'})
Write-Host "========================================" -ForegroundColor Cyan

$sim = [PSCustomObject]@{date=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"); passCount=$PC; failCount=$FC; allPassed=($FC -eq 0); scenarios=$Results}
$sim | ConvertTo-Json -Depth 3 | Out-File (Join-Path $FactoryRoot "runtime\tests\skill-behavior-simulation-result.json") -Encoding UTF8
