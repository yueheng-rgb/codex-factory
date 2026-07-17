# R2.3-H Live Skill Runtime Trial Runner
# Simulates agent execution context with/without CAP-SKILL-004
# Verifies: loading, gate, extraction, contract inputs, usage ledger

param(
    [string]$FactoryRoot = "C:\Codex_App_Factory",
    [string]$TrialProjectRoot = "C:\Users\90961\Desktop\factory-skill-live-trial",
    [string]$ProjectId = "PROJ-LIVE-TRIAL-001",
    [string]$PhaseId = "PHASE-R2.3-H-TRIAL",
    [string]$ProjectType = "small-web-api-demo"
)

$script:FR = $FactoryRoot
$script:TR = $TrialProjectRoot

# Load runtime infrastructure
$loaders = @(
    "runtime\agent-loader.ps1",
    "runtime\capability-loader.ps1",
    "runtime\capability-permission-gate.ps1",
    "runtime\skill-content-loader.ps1"
)
foreach ($l in $loaders) {
    $lp = Join-Path $script:FR $l
    if (Test-Path $lp) { . $lp } else { Write-Host "MISSING: $l" -ForegroundColor Red; exit 1 }
}
Write-Host "Runtime infrastructure loaded." -ForegroundColor Green

# ============================================================================
# SECTION 1: Factory Bootstrap (without skill first, then with)
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " SECTION 1: FACTORY BOOTSTRAP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Simulate Router Agent (PM-001) context WITHOUT CAP-SKILL-004
$ctxNoSkill = [PSCustomObject]@{
    projectId = $ProjectId
    phaseId = $PhaseId
    agentId = "PM-001"
    role = "Router Agent"
    projectType = $ProjectType
    projectRoot = $script:TR
    allowedWriteScopes = @("$script:TR\outputs", "$script:TR\docs")
    allowedSkills = @()
    loadedSkillRefs = @()
    forbiddenActions = @("write_project_code", "modify_architecture")
    evidenceLevel = "standard"
    failurePolicy = "halt_and_report"
    hasHumanConfirmation = $true
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
}

Write-Host "`n--- 1A: Execution Context WITHOUT Skill ---"
Write-Host "  Agent: $($ctxNoSkill.agentId) | Project: $($ctxNoSkill.projectId) | Type: $($ctxNoSkill.projectType)"
Write-Host "  Loaded skills: $(if($ctxNoSkill.loadedSkillRefs.Count -eq 0){'none'}else{$ctxNoSkill.loadedSkillRefs -join ','})"

# Factory Bootstrap classification WITHOUT skill
$bsNoSkill = [PSCustomObject]@{
    projectId = $ProjectId
    projectType = $ProjectType
    recommendedArchitecture = "monolith-fastify"
    reasoning = "small-web-api-demo — single service, no database, minimal endpoints. Monolith is appropriate."
    agentsMdDetected = (Test-Path (Join-Path $script:TR "AGENTS.md"))
    agentsMdRulesExtracted = $false
    contractInputsGenerated = $false
    skillAssisted = $false
    agentsMdSummary = @{}
}
Write-Host "  Bootstrap: $($bsNoSkill.projectType) → $($bsNoSkill.recommendedArchitecture)"
Write-Host "  AGENTS.md detected: $($bsNoSkill.agentsMdDetected)"
Write-Host "  Rules extracted: $($bsNoSkill.agentsMdRulesExtracted)"
Write-Host "  Contract inputs: $($bsNoSkill.agentsMdContractInputsGenerated)"

# ============================================================================
# SECTION 2: Load CAP-SKILL-004 via Skill Content Loader
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " SECTION 2: CAP-SKILL-004 LOADING" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check permission gate first
Write-Host "`n--- 2A: Capability Permission Gate ---"
$permResult = Test-CapabilityPermission -AgentId "PM-001" -CapabilityId "CAP-SKILL-004" -ProjectId $ProjectId -ProjectType $ProjectType -HasHumanConfirmation $true -HasWriteScope $true
Write-Host "  Decision: $($permResult.Decision)"
Write-Host "  Reason: $($permResult.Reason)"
$permResult | ConvertTo-Json -Compress | Out-File -FilePath (Join-Path $script:FR "outputs\FACTORY_R2_3_H_PERMISSION_GATE_RESULT.json") -Encoding UTF8

# Check audit status
Write-Host "`n--- 2B: Audit Status Check ---"
$auditPath = Join-Path $script:FR "governance\skill-audits\CAP-SKILL-004-audit.json"
if (Test-Path $auditPath) {
    $audit = Get-Content $auditPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Write-Host "  Audit verdict: $($audit.verdict)"
    Write-Host "  Risk score: $($audit.riskScore)/100"
    $auditPassed = ($audit.verdict -eq "pass" -or $audit.verdict -eq "pass_with_controls")
    Write-Host "  Gate allowed: $auditPassed"
} else {
    Write-Host "  WARNING: No audit report found" -ForegroundColor Yellow
    $auditPassed = $false
}

# Load skill content
Write-Host "`n--- 2C: Skill Content Loader ---"
$loadResult = Load-SkillContent -SkillId "CAP-SKILL-004" -AgentId "PM-001" -ProjectId $ProjectId -PhaseId $PhaseId -ProjectType $ProjectType -IsLocalFirst $true
Write-Host "  Loaded: $($loadResult.Loaded)"
Write-Host "  Reason: $($loadResult.Reason)"
if ($loadResult.Loaded) {
    Write-Host "  Skill: $($loadResult.SkillSummary.name) v$($loadResult.SkillSummary.version)"
    Write-Host "  Trust: $($loadResult.SkillSummary.trustLevel)"
    Write-Host "  Sections loaded: $($loadResult.SkillSummary.loadedSections -join ', ')"
    if ($loadResult.Warnings.Count -gt 0) {
        Write-Host "  Warnings:" -ForegroundColor Yellow
        $loadResult.Warnings | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
    }
}

# Build execution context WITH skill
$ctxWithSkill = [PSCustomObject]@{
    projectId = $ProjectId
    phaseId = $PhaseId
    agentId = "PM-001"
    role = "Router Agent"
    projectType = $ProjectType
    projectRoot = $script:TR
    allowedWriteScopes = @("$script:TR\outputs", "$script:TR\docs")
    allowedSkills = @("CAP-SKILL-004")
    loadedSkillRefs = @(@{skillId="CAP-SKILL-004";name="agents-md-ecosystem";version="1.0.0";status="verified";trustLevel="VERIFIED";loadedSections=$loadResult.SkillSummary.loadedSections})
    forbiddenActions = @("write_project_code", "modify_architecture")
    evidenceLevel = "standard"
    failurePolicy = "halt_and_report"
    hasHumanConfirmation = $true
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
}

Write-Host "`n--- 2D: Execution Context WITH Skill ---"
Write-Host "  Agent: $($ctxWithSkill.agentId) | Project: $($ctxWithSkill.projectId)"
Write-Host "  Loaded skills: $($ctxWithSkill.loadedSkillRefs.Count) — $($ctxWithSkill.loadedSkillRefs[0].name)"
Write-Host "  Loaded sections: $($ctxWithSkill.loadedSkillRefs[0].loadedSections -join ', ')"

# Check skill usage ledger
Write-Host "`n--- 2E: Skill Usage Ledger Check ---"
$usage = Get-SkillUsage -Sid "CAP-SKILL-004" -Max 5
Write-Host "  Recent CAP-SKILL-004 usage records: $($usage.Count)"
foreach ($u in $usage) {
    Write-Host "    [$($u.decision)] agent=$($u.agentId) at $($u.timestamp)"
}

# ============================================================================
# SECTION 3: AGENTS.md Extraction Simulation
# ============================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " SECTION 3: AGENTS.md EXTRACTION (with CAP-SKILL-004)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Simulate CAP-SKILL-004 extracting rules from AGENTS.md
function Invoke-AgentsMdExtraction {
    param([string]$Root)
    $result = [PSCustomObject]@{
        filesFound = @()
        buildCommands = @()
        testCommands = @()
        lintCommands = @()
        securityBoundaries = @()
        directoryRules = @()
        conventions = @()
        forbiddenActions = @()
        handoffRequirements = @()
        userInstructionPriority = ""
        conflictWarnings = @()
        contractInputs = [PSCustomObject]@{pic=@();ac=@();fc=@();ngc=@()}
    }

    # Walk directory tree for AGENTS.md
    $agentsFiles = Get-ChildItem -Path $Root -Recurse -Filter "AGENTS.md" -ErrorAction SilentlyContinue
    foreach ($af in $agentsFiles) {
        $result.filesFound += $af.FullName.Replace($Root, ".")
        $content = Get-Content $af.FullName -Raw -Encoding UTF8
        $scope = $af.DirectoryName.Replace($Root, ".").Replace("\", "/")
        if ($scope -eq ".") { $scope = "/" }

        # Extract build commands
        if ($content -match 'npm run build') { $result.buildCommands += @{command="npm run build";source=$af.Name;scope=$scope} }
        if ($content -match 'npm start') { $result.buildCommands += @{command="npm start";source=$af.Name;scope=$scope} }

        # Extract test commands
        if ($content -match 'npm test') { $result.testCommands += @{command="npm test";source=$af.Name;scope=$scope} }

        # Extract lint commands
        if ($content -match 'npm run lint') { $result.lintCommands += @{command="npm run lint";source=$af.Name;scope=$scope} }

        # Extract security boundaries
        if ($content -match 'Do NOT commit \.env') { $result.securityBoundaries += @{rule="Do not commit .env files";source=$af.Name} }
        if ($content -match 'Do NOT hardcode secrets') { $result.securityBoundaries += @{rule="No hardcoded secrets/tokens/passwords";source=$af.Name} }
        if ($content -match 'bind.*127\.0\.0\.1') { $result.securityBoundaries += @{rule="Bind to 127.0.0.1 only";source=$af.Name} }
        if ($content -match 'no external network calls') { $result.securityBoundaries += @{rule="No external network calls without approval";source=$af.Name} }
        if ($content -match 'must wrap logic in try/catch') { $result.securityBoundaries += @{rule="Route handlers must use try/catch (src/ scope)";source=$af.Name} }

        # Extract directory rules
        $dirMatches = [regex]::Matches($content, '- `(\S+)` — (.+)')
        foreach ($m in $dirMatches) {
            $result.directoryRules += @{directory=$m.Groups[1].Value;rule=$m.Groups[2].Value;source=$af.Name}
        }

        # Extract conventions
        if ($content -match 'Use `const` and `let`') { $result.conventions += @{rule="const/let over var";source=$af.Name} }
        if ($content -match 'Async/await preferred') { $result.conventions += @{rule="Async/await preferred";source=$af.Name} }
        if ($content -match 'kebab-case') { $result.conventions += @{rule="kebab-case filenames, camelCase identifiers";source=$af.Name} }

        # Extract forbidden actions
        $forbiddenMatches = [regex]::Matches($content, '- Do NOT (.+)')
        foreach ($fm in $forbiddenMatches) {
            $result.forbiddenActions += @{action=$fm.Groups[1].Value;source=$af.Name}
        }

        # Extract handoff requirements
        if ($content -match 'handoff containing') {
            $handoffFields = [regex]::Matches($content, '\*\*(\w+)\*\* — (.+)')
            foreach ($hf in $handoffFields) {
                $result.handoffRequirements += @{field=$hf.Groups[1].Value;description=$hf.Groups[2].Value;source=$af.Name}
            }
        }

        # Extract user instruction priority
        if ($content -match 'ADVISORY') {
            $result.userInstructionPriority = "AGENTS.md rules are ADVISORY — user instructions take precedence"
        }
    }

    # Generate contract inputs
    if ($result.buildCommands.Count -gt 0) { $result.contractInputs.pic += "build: $($result.buildCommands[0].command)" }
    if ($result.testCommands.Count -gt 0) { $result.contractInputs.pic += "test: $($result.testCommands[0].command)" }
    if ($result.lintCommands.Count -gt 0) { $result.contractInputs.pic += "lint: $($result.lintCommands[0].command)" }
    if ($result.conventions.Count -gt 0) { $result.contractInputs.ac += "conventions detected: $($result.conventions.Count) rules" }
    if ($result.directoryRules.Count -gt 0) { $result.contractInputs.fc += "directory structure: $($result.directoryRules.Count) rules" }
    if ($result.securityBoundaries.Count -gt 0) { $result.contractInputs.ngc += "security boundaries: $($result.securityBoundaries.Count) rules" }

    # Check for conflicts
    if ($result.filesFound.Count -gt 1) {
        $result.conflictWarnings += "Multiple AGENTS.md files found — nested files override root for their scope"
    }

    return $result
}

Write-Host "Simulating CAP-SKILL-004 extraction from project AGENTS.md files..."
$extraction = Invoke-AgentsMdExtraction -Root $script:TR

Write-Host "`n--- Extraction Results ---"
Write-Host "  AGENTS.md files found: $($extraction.filesFound.Count)"
foreach ($f in $extraction.filesFound) { Write-Host "    - $f" }
Write-Host "  Build commands: $($extraction.buildCommands.Count)"
foreach ($c in $extraction.buildCommands) { Write-Host "    - $($c.command) (scope: $($c.scope))" }
Write-Host "  Test commands: $($extraction.testCommands.Count)"
foreach ($c in $extraction.testCommands) { Write-Host "    - $($c.command)" }
Write-Host "  Lint commands: $($extraction.lintCommands.Count)"
foreach ($c in $extraction.lintCommands) { Write-Host "    - $($c.command)" }
Write-Host "  Security boundaries: $($extraction.securityBoundaries.Count)"
foreach ($s in $extraction.securityBoundaries) { Write-Host "    - $($s.rule)" }
Write-Host "  Directory rules: $($extraction.directoryRules.Count)"
Write-Host "  Conventions: $($extraction.conventions.Count)"
Write-Host "  Forbidden actions: $($extraction.forbiddenActions.Count)"
Write-Host "  Handoff fields required: $($extraction.handoffRequirements.Count)"
Write-Host "  User instruction priority: $($extraction.userInstructionPriority)"
Write-Host "  Conflicts: $($extraction.conflictWarnings.Count)"
Write-Host "  Contract inputs:"
Write-Host "    PIC: $($extraction.contractInputs.pic -join '; ')"
Write-Host "    AC: $($extraction.contractInputs.ac -join '; ')"
Write-Host "    FC: $($extraction.contractInputs.fc -join '; ')"
Write-Host "    NGC: $($extraction.contractInputs.ngc -join '; ')"

# Save extraction result
$extraction | ConvertTo-Json -Depth 4 | Out-File -FilePath (Join-Path $script:FR "outputs\FACTORY_R2_3_H_AGENTS_MD_EXTRACTION.json") -Encoding UTF8
Write-Host "`n  Extraction saved: outputs\FACTORY_R2_3_H_AGENTS_MD_EXTRACTION.json"

Write-Host "`n=== SECTIONS 1-3 COMPLETE ===" -ForegroundColor Green
Write-Host "Proceeding to behavior difference, implementation, and verification..."
