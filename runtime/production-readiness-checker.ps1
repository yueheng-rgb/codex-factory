# Production Readiness Checker v1.0.0
# Codex Factory R6.0 — evaluates project production readiness

param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [string]$ProjectType = "backend-api",
    [string[]]$Surfaces = @("api-service"),
    [string]$RiskProfile = "MEDIUM",
    [string]$ExpertPack = "",
    [string]$DeploymentTarget = "local",
    [switch]$IsUIType
)

$score = 0
$maxScore = 100
$checks = @{}
$missing = @()
$blocking = @()
$warnings = @()

function Check-Item($name, $weight, $condition, $detail) {
    $checks[$name] = @{ status = if ($condition) { "PASS" } else { "MISSING" }; details = $detail }
    if ($condition) { $script:score += $weight }
    else { $script:missing += $name; if ($weight -ge 10) { $script:blocking += $name } }
}

# 1. Env variables (weight: 8)
$hasEnv = Test-Path (Join-Path $ProjectPath ".env.example") -or Test-Path (Join-Path $ProjectPath ".env")
Check-Item "environment_variables" 8 $hasEnv "Expected: .env.example or .env file with documented variables"

# 2. Secrets handling (weight: 10)
$hasSecrets = $false
$srcFiles = @(Get-ChildItem -Path (Join-Path $ProjectPath "src") -Recurse -Include *.ts,*.js,*.json -File -ErrorAction SilentlyContinue)
foreach ($f in $srcFiles) {
    $content = Get-Content $f.FullName -ErrorAction SilentlyContinue | Out-String
    if ($content -match "(process\.env\.|import\.meta\.env\.)") { $hasSecrets = $true; break }
}
Check-Item "secrets_handling" 10 $hasSecrets "Expected: secrets via process.env, no hardcoded keys"

# 3. Database config (weight: 8)
$hasDbConfig = (Test-Path (Join-Path $ProjectPath "db")) -or (Test-Path (Join-Path $ProjectPath "src\db\config.ts"))
Check-Item "database_configuration" 8 $hasDbConfig "Expected: db/ directory or src/db/config.ts"

# 4. Migrations (weight: 8)
$hasMigrations = (Test-Path (Join-Path $ProjectPath "db\schema.sql")) -or (Test-Path (Join-Path $ProjectPath "migrations"))
Check-Item "migrations" 8 $hasMigrations "Expected: db/schema.sql or migrations/ directory"

# 5. Seed data (weight: 3)
$hasSeeds = (Test-Path (Join-Path $ProjectPath "db\seed.sql")) -or (Test-Path (Join-Path $ProjectPath "seeds"))
Check-Item "seed_data" 3 $hasSeeds "Expected: db/seed.sql or seeds/ directory"

# 6. Logging (weight: 5)
$hasLogging = $false
foreach ($f in $srcFiles) {
    $content = Get-Content $f.FullName -ErrorAction SilentlyContinue | Out-String
    if ($content -match "(pino|winston|bunyan|logger|console\.(log|error|warn|info))") { $hasLogging = $true; break }
}
Check-Item "logging" 5 $hasLogging "Expected: structured logging (pino, winston, etc.)"

# 7. Error handling (weight: 8)
$hasErrors = $false
foreach ($f in $srcFiles) {
    $content = Get-Content $f.FullName -ErrorAction SilentlyContinue | Out-String
    if ($content -match "(error|Error).*(code|CODE|status|Status).*\d{3}") { $hasErrors = $true; break }
}
Check-Item "error_handling" 8 $hasErrors "Expected: unified error format with status codes"

# 8. Health check (weight: 5)
$hasHealth = $false
foreach ($f in $srcFiles) {
    $content = Get-Content $f.FullName -ErrorAction SilentlyContinue | Out-String
    if ($content -match "health") { $hasHealth = $true; break }
}
Check-Item "health_check" 5 $hasHealth "Expected: /health endpoint"

# 9. Test command (weight: 10)
$pkg = $null; try { $pkg = Get-Content (Join-Path $ProjectPath "package.json") | ConvertFrom-Json } catch {}
$hasTestCmd = $pkg -and $pkg.scripts -and $pkg.scripts.test
Check-Item "test_command" 10 $hasTestCmd "Expected: `"test`" script in package.json"

# 10. Build command (weight: 6)
$hasBuildCmd = $pkg -and $pkg.scripts -and $pkg.scripts.build
Check-Item "build_command" 6 $hasBuildCmd "Expected: `"build`" script in package.json"

# 11. Start command (weight: 6)
$hasStartCmd = $pkg -and $pkg.scripts -and $pkg.scripts.start
Check-Item "start_command" 6 $hasStartCmd "Expected: `"start`" script in package.json"

# 12. Deployment target (weight: 5)
$hasDeploy = $DeploymentTarget -ne "" -and $DeploymentTarget -ne "unknown"
Check-Item "deployment_target" 5 $hasDeploy "Specified: $DeploymentTarget"

# 13. Security scan (weight: 8)
$hasSecurity = (semgrep --version 2>$null) -or (Test-Path (Join-Path $ProjectPath ".semgrepignore"))
$checks["security_scan"] = @{ status = if ($hasSecurity) { "AVAILABLE" } else { "TOOL_UNAVAILABLE" }; details = "semgrep available: $hasSecurity" }
if ($hasSecurity) { $score += 8 } else { $warnings += "security_scan: semgrep not available" }

# 14. Load smoke (weight: 5)
$hasAutocannon = (npx autocannon --version 2>$null) -or $true  # npx always somewhat available
$checks["load_smoke"] = @{ status = if ($hasAutocannon) { "AVAILABLE" } else { "TOOL_UNAVAILABLE" }; details = "autocannon available via npx" }
if ($hasAutocannon) { $score += 5 } else { $warnings += "load_smoke: autocannon not available" }

# 15. Rollback notes (weight: 3)
$hasRollback = (Test-Path (Join-Path $ProjectPath "ROLLBACK.md")) -or (Test-Path (Join-Path $ProjectPath "docs\rollback.md"))
Check-Item "rollback_notes" 3 $hasRollback "Expected: ROLLBACK.md or docs/rollback.md"

# Playwright handling
if ($IsUIType) {
    $pwAvailable = $false
    try { $pwResult = npx playwright --version 2>&1; $pwAvailable = $LASTEXITCODE -eq 0 } catch { $pwAvailable = $false }
    if (-not $pwAvailable) { $warnings += "playwright: TOOL_FAILED — browser version mismatch, UI smoke not verified" }
}

# Calculate level
$readinessLevel = switch ($true) {
    ($score -ge 85) { "READY_FOR_PRODUCTION_REVIEW" }
    ($score -ge 60) { "READY_FOR_STAGING" }
    ($score -ge 30) { "PARTIAL" }
    default { "NOT_READY" }
}

# Cap at READY_FOR_PRODUCTION_REVIEW — never auto-approve production
if ($readinessLevel -eq "READY_FOR_PRODUCTION_REVIEW") {
    $warnings += "READY_FOR_PRODUCTION_REVIEW means human review required — NOT automatically production-ready"
}

$result = [PSCustomObject]@{
    project_path = $ProjectPath
    project_type = $ProjectType
    surfaces = $Surfaces
    risk_profile = $RiskProfile
    expert_pack = $ExpertPack
    deployment_target = $DeploymentTarget
    score = $score
    max_score = $maxScore
    readiness_level = $readinessLevel
    checks = $checks
    missing_items = $missing
    blocking_items = $blocking
    warnings = $warnings
    required_human_review = ($readinessLevel -eq "READY_FOR_PRODUCTION_REVIEW" -or $blocking.Count -gt 0)
    non_claims = @(
        "Local load smoke does NOT prove production concurrency",
        "In-memory store is NOT a production database",
        "Semgrep CLEAN does NOT guarantee security",
        "This checker identifies gaps — it does NOT certify production readiness"
    )
}

$result | ConvertTo-Json -Depth 4
Write-Output ""
Write-Output "Readiness Level: $readinessLevel | Score: $score/$maxScore"
Write-Output "Missing: $($missing.Count) | Blocking: $($blocking.Count) | Warnings: $($warnings.Count)"
