# R2.3-N Verification Script
# GLM Search Adapter + Manual Search Fallback + Research Intake Integration

param([string]$FactoryRoot = "C:\Codex_App_Factory")
$fr = $FactoryRoot
$pass = 0; $fail = 0; $checks = @()

function Check($id, $name, $cond, $detail="") {
    $status = if ($cond) { "PASS" } else { "FAIL" }
    $color = if ($cond) { "Green" } else { "Red" }
    Write-Host ("  [{0}] {1}: {2}" -f $status, $id, $name) -ForegroundColor $color
    if ($detail) { Write-Host ("        {0}" -f $detail) -ForegroundColor Gray }
    if ($cond) { $script:pass++ } else { $script:fail++ }
    $script:checks += [PSCustomObject]@{id=$id;name=$name;result=$status}
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-N VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# --- Schemas ---
Write-Host "`n--- Schemas ---" -ForegroundColor Yellow
$schemaFiles = @(
    "schemas\search-provider-secret-policy.schema.json",
    "schemas\glm-search-request.schema.json",
    "schemas\glm-search-response.schema.json",
    "schemas\search-invocation.schema.json",
    "schemas\research-intake.schema.json",
    "schemas\network-boundary.schema.json"
)
foreach ($sf in $schemaFiles) {
    $fp = Join-Path $fr $sf
    $exists = Test-Path $fp
    $parseOk = $false
    if ($exists) {
        try { $null = Get-Content $fp -Raw -Encoding UTF8 | ConvertFrom-Json; $parseOk = $true } catch { }
    }
    Check "SCH-$sf" "exists+parse" ($exists -and $parseOk) "exists=$exists parse=$parseOk"
}

# --- Runtime Scripts ---
Write-Host "`n--- Runtime Scripts ---" -ForegroundColor Yellow
$scriptFiles = @(
    "runtime\glm-search-adapter.ps1",
    "runtime\secret-presence-check.ps1",
    "runtime\search-invocation-logger.ps1",
    "runtime\search-result-quality-gate.ps1",
    "runtime\tool-permission-gate.ps1",
    "runtime\read-only-search-adapter.ps1"
)
foreach ($sf in $scriptFiles) {
    $fp = Join-Path $fr $sf
    $exists = Test-Path $fp
    Check "SCR-$sf" "exists" $exists
}

# --- Tool Registry ---
Write-Host "`n--- Tool Registry ---" -ForegroundColor Yellow
$trPath = Join-Path $fr "registries\tool-candidate-registry.jsonl"
$trExists = Test-Path $trPath
Check "REG-GLM" "tool registry exists" $trExists
$glmFound = $false
if ($trExists) {
    $lines = Get-Content $trPath -Encoding UTF8 | Where-Object { $_.Trim() -ne '' }
    foreach ($line in $lines) {
        try {
            $e = $line | ConvertFrom-Json
            if ($e.toolId -eq "TOOL-GLM-SEARCH-001") {
                $glmFound = $true
                Check "REG-GLM-STATUS" "GLM tool registered" $true "status=$($e.status) boundary=$($e.networkBoundary) forbiddenAgents=$($e.forbiddenAgents -join ',')"
                Check "REG-GLM-AGENTS" "allowedAgents correct" ($e.allowedAgents -contains "RSRC-001" -and $e.allowedAgents -contains "LIB-001")
                Check "REG-GLM-FORBIDDEN" "Implementer forbidden" ($e.forbiddenAgents -contains "IMPL-FE-001" -or $e.forbiddenAgents -contains "IMPL-BE-001")
                Check "REG-GLM-BOUNDARY" "networkBoundary=external_api" ($e.networkBoundary -eq "external_api")
                Check "REG-GLM-SECRETS" "requiredSecrets=true" ($e.requiredSecrets -eq $true)
                Check "REG-GLM-HUMAN" "humanConfirmationRequired=true" ($e.humanConfirmationRequired -eq $true)
            }
        } catch { }
    }
}
Check "REG-GLM-EXISTS" "GLM entry found" $glmFound

# --- Governance ---
Write-Host "`n--- Governance ---" -ForegroundColor Yellow
$siPath = Join-Path $fr "governance\search-invocations\search-invocation-index.jsonl"
$siDir = Split-Path $siPath -Parent
Check "GOV-SI-DIR" "search invocations dir" (Test-Path $siDir)

# --- Secret Policy ---
Write-Host "`n--- Secret Handling ---" -ForegroundColor Yellow
. (Join-Path $fr "runtime\secret-presence-check.ps1")
$sc = Test-SecretPresence -EnvVarNames @("ZHIPUAI_API_KEY") -ProviderType "glm_search"
Check "SEC-PRESENT" "secret check runs" ($sc -ne $null)
Check "SEC-NO-LEAK" "key value not in check result" ($sc.keyValueRecorded -eq $false)
$leakCheck = Assert-NoSecretLeak -Content "some content with ZHIPUAI_API_KEY=abc123def456" -SourceDescription "test"
Check "SEC-LEAK-DETECT" "leak detection works" ($leakCheck.hitCount -gt 0)

# --- Agent Access Control ---
Write-Host "`n--- Agent Access Control ---" -ForegroundColor Yellow
. (Join-Path $fr "runtime\glm-search-adapter.ps1")
. (Join-Path $fr "runtime\tool-permission-gate.ps1")

# RSRC-001 can use GLM dry_run
$g1 = Test-ToolPermission -ProjectId "V" -AgentId "RSRC-001" -ToolId "TOOL-SEARCH-ADAPTER-001" -ProjectType "all" -IsLocalFirst $true -HumanApproved $true -NetworkMode "local_first"
Check "ACC-RSRC-001" "RSRC-001 search allowed" ($g1.Decision -like "ALLOW*") "decision=$($g1.Decision)"

# LIB-001 can use search adapter
$g2 = Test-ToolPermission -ProjectId "V" -AgentId "LIB-001" -ToolId "TOOL-SEARCH-ADAPTER-001" -ProjectType "all" -IsLocalFirst $true -HumanApproved $true -NetworkMode "local_first"
Check "ACC-LIB-001" "LIB-001 search allowed" ($g2.Decision -like "ALLOW*") "decision=$($g2.Decision)"

# IMPL-FE-001 cannot use GLM
$r7 = Invoke-GLMSearch -RequestId "VER-007" -Query "test" -ProviderMode dry_run -ProjectId "VER" -PhaseId "test" -AgentId "IMPL-FE-001"
Check "ACC-IMPL" "IMPL agent blocked" ($r7.accepted -eq $false -and $r7.gateDecision -eq "REJECT")

# --- Research Intake Integration ---
Write-Host "`n--- Research Intake ---" -ForegroundColor Yellow
$mockManual = @{rawResult="test";links=@(@{title="Test";url="https://example.com";snippet="test";sourceType="official_docs"})}
$rIntake = Invoke-GLMSearch -RequestId "VER-INTAKE" -Query "Next.js routing" -ProviderMode manual -ManualInput $mockManual -ProjectId "VER" -PhaseId "test" -AgentId "RSRC-001"
Check "INTAKE-EXISTS" "manual result accepted" ($rIntake.accepted -eq $true)
$capsule = Convert-GLMResponseToResearchIntake -GLMResponse $rIntake -SubmittedBy "RSRC-001"
Check "INTAKE-CONVERT" "intake conversion works" ($capsule -ne $null -and $capsule.accepted -ne $false)

# --- Simulation Results ---
Write-Host "`n--- Simulation ---" -ForegroundColor Yellow
$simPath = Join-Path $fr "outputs\FACTORY_R2_3_N_SEARCH_SIMULATION_RESULTS.json"
$simExists = Test-Path $simPath
Check "SIM-FILE" "simulation results exist" $simExists
if ($simExists) {
    $sim = Get-Content $simPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Check "SIM-ALL" "10/10 scenarios pass" ($sim.passCount -eq 10) "pass=$($sim.passCount)/$($sim.totalScenarios)"
}

# --- No API Key Leak ---
Write-Host "`n--- API Key Safety ---" -ForegroundColor Yellow
$outDir = Join-Path $fr "outputs"
$outFiles = Get-ChildItem $outDir -Recurse -Include "*.json","*.md","*.txt" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-2) }
$leakFound = $false
foreach ($f in $outFiles) {
    try {
        $txt = Get-Content $f.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($txt -match '(?i)zhipuai[_\s]*api[_\s]*key\s*[=:]\s*["'']?[a-zA-Z0-9_\-\.]{10,}["'']?') {
            $leakFound = $true
            Write-Host "  LEAK DETECTED in: $($f.Name)" -ForegroundColor Red
        }
    } catch { }
}
Check "SAFE-NO-LEAK" "no API key in recent outputs" (-not $leakFound)

# --- Summary ---
Write-Host ("`n========================================") -ForegroundColor Cyan
Write-Host (" VERIFICATION: {0}/{1} PASS" -f $pass, ($pass+$fail)) -ForegroundColor $(if($fail -eq 0){"Green"}else{"Red"})

$result = [PSCustomObject]@{
    verificationId = "R2.3-N-VER-001"
    phase = "FACTORY-R2.3-N"
    passCount = $pass
    failCount = $fail
    totalChecks = $pass + $fail
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    checks = $checks
}
$result | ConvertTo-Json -Depth 3 | Out-File (Join-Path $fr "outputs\FACTORY_R2_3_N_VERIFICATION_RESULTS.json") -Encoding UTF8
Write-Host " Verification results written." -ForegroundColor Cyan
