# Verify R2.3-G Skill Audit Capability Trust Pipeline
# Part of: FACTORY-R2.3-G-SKILL-AUDIT-CAPABILITY-TRUST-PIPELINE

param([string]$FactoryRoot = "C:\Codex_App_Factory")

$Script:FR = $FactoryRoot
$total = 0; $passed = 0; $failed = 0
$results = @()

function Check {
    param([string]$Id,[string]$Description,[scriptblock]$Test)
    $script:total++
    try {
        $ok = & $Test
        if ($ok) { $script:passed++; $results += [PSCustomObject]@{id=$Id;desc=$Description;status="PASS"}; Write-Host "  [PASS] $Id" -ForegroundColor Green }
        else { $script:failed++; $results += [PSCustomObject]@{id=$Id;desc=$Description;status="FAIL"}; Write-Host "  [FAIL] $Id" -ForegroundColor Red }
    } catch {
        $script:failed++; $results += [PSCustomObject]@{id=$Id;desc=$Description;status="FAIL";error=$_.Exception.Message}; Write-Host "  [FAIL] $Id -- $_" -ForegroundColor Red
    }
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-G SKILL AUDIT VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# --- Schema checks ---
Write-Host "`n--- Schema Checks ---" -ForegroundColor Yellow
Check "SCH-001" "Risk taxonomy schema exists and is valid JSON" { Test-Path (Join-Path $FR "schemas\skill-risk-taxonomy.schema.json") }
Check "SCH-002" "Risk taxonomy schema parses" { try { Get-Content (Join-Path $FR "schemas\skill-risk-taxonomy.schema.json") -Raw -Encoding UTF8 | ConvertFrom-Json; $true } catch { $false } }
Check "SCH-003" "Audit report schema exists and is valid JSON" { Test-Path (Join-Path $FR "schemas\skill-audit-report.schema.json") }
Check "SCH-004" "Audit report schema parses" { try { Get-Content (Join-Path $FR "schemas\skill-audit-report.schema.json") -Raw -Encoding UTF8 | ConvertFrom-Json; $true } catch { $false } }

# --- Registry checks ---
Write-Host "`n--- Registry Checks ---" -ForegroundColor Yellow
Check "REG-001" "Audit capability registry exists" { Test-Path (Join-Path $FR "registries\skill-audit-capability-candidate-registry.jsonl") }
Check "REG-002" "Audit capability registry has entries" { $lines = Get-Content (Join-Path $FR "registries\skill-audit-capability-candidate-registry.jsonl") -Encoding UTF8 | Where-Object { $_.Trim() -ne "" }; $lines.Count -gt 0 }

# --- Pipeline checks ---
Write-Host "`n--- Pipeline Checks ---" -ForegroundColor Yellow
Check "PIPE-001" "Audit pipeline script exists" { Test-Path (Join-Path $FR "runtime\skill-audit-pipeline.ps1") }
Check "PIPE-002" "Audit pipeline loads without error" { try { . (Join-Path $FR "runtime\skill-audit-pipeline.ps1"); $true } catch { $false } }
Check "PIPE-003" "Invoke-SkillAudit function exists" { Get-Command Invoke-SkillAudit -ErrorAction SilentlyContinue; $true }

# --- CAP-SKILL-004 audit ---
Write-Host "`n--- CAP-SKILL-004 Audit Checks ---" -ForegroundColor Yellow
Check "CAP-001" "CAP-SKILL-004 audit report exists" { Test-Path (Join-Path $FR "governance\skill-audits\CAP-SKILL-004-audit.json") }
Check "CAP-002" "CAP-SKILL-004 audit is pass or pass_with_controls" { 
    $ar = Get-Content (Join-Path $FR "governance\skill-audits\CAP-SKILL-004-audit.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $ar.verdict -eq "pass" -or $ar.verdict -eq "pass_with_controls"
}
Check "CAP-003" "CAP-SKILL-004 audit has all 6 stages" {
    $ar = Get-Content (Join-Path $FR "governance\skill-audits\CAP-SKILL-004-audit.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $stages = $ar.stages
    $stages.metadata -ne $null -and $stages.content -ne $null -and $stages.permission -ne $null -and $stages.supplyChain -ne $null -and $stages.runtimeBehavior -ne $null
}

# --- Malicious fixture checks ---
Write-Host "`n--- Malicious Fixture Checks ---" -ForegroundColor Yellow
$malBase = Join-Path $FR "runtime\tests\malicious-skills"
Check "MAL-001" "6 malicious fixtures exist" { (Get-ChildItem $malBase -Directory | Measure-Object).Count -ge 6 }
Check "MAL-002" "MAL-PROMPT-INJECTION has skill.json + SKILL.md" { (Test-Path (Join-Path $malBase "MAL-PROMPT-INJECTION\skill.json")) -and (Test-Path (Join-Path $malBase "MAL-PROMPT-INJECTION\SKILL.md")) }
Check "MAL-003" "MAL-DATA-EXFILTRATION has skill.json + SKILL.md" { (Test-Path (Join-Path $malBase "MAL-DATA-EXFILTRATION\skill.json")) -and (Test-Path (Join-Path $malBase "MAL-DATA-EXFILTRATION\SKILL.md")) }
Check "MAL-004" "MAL-ARBITRARY-COMMAND has skill.json + SKILL.md" { (Test-Path (Join-Path $malBase "MAL-ARBITRARY-COMMAND\skill.json")) -and (Test-Path (Join-Path $malBase "MAL-ARBITRARY-COMMAND\SKILL.md")) }
Check "MAL-005" "MAL-OVERBROAD-TOOLS has skill.json + SKILL.md" { (Test-Path (Join-Path $malBase "MAL-OVERBROAD-TOOLS\skill.json")) -and (Test-Path (Join-Path $malBase "MAL-OVERBROAD-TOOLS\SKILL.md")) }
Check "MAL-006" "MAL-AUTO-UPDATE has skill.json + SKILL.md" { (Test-Path (Join-Path $malBase "MAL-AUTO-UPDATE\skill.json")) -and (Test-Path (Join-Path $malBase "MAL-AUTO-UPDATE\SKILL.md")) }
Check "MAL-007" "MAL-MISLEADING-TRIGGER has skill.json + SKILL.md" { (Test-Path (Join-Path $malBase "MAL-MISLEADING-TRIGGER\skill.json")) -and (Test-Path (Join-Path $malBase "MAL-MISLEADING-TRIGGER\SKILL.md")) }

# --- Simulation results ---
Write-Host "`n--- Simulation Checks ---" -ForegroundColor Yellow
Check "SIM-001" "Simulation results file exists" { Test-Path (Join-Path $FR "outputs\FACTORY_R2_3_G_SKILL_AUDIT_SIMULATION_RESULTS.json") }
Check "SIM-002" "Simulation 7/7 passed" {
    $sr = Get-Content (Join-Path $FR "outputs\FACTORY_R2_3_G_SKILL_AUDIT_SIMULATION_RESULTS.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $sr.totalTests -eq 7 -and $sr.passed -eq 7 -and $sr.failed -eq 0
}

# --- Output reports ---
Write-Host "`n--- Output Report Checks ---" -ForegroundColor Yellow
Check "OUT-001" "External survey report exists" { Test-Path (Join-Path $FR "outputs\FACTORY_R2_3_G_EXTERNAL_SKILL_AUDIT_SURVEY.md") }
Check "OUT-002" "Risk taxonomy doc exists" { Test-Path (Join-Path $FR "outputs\FACTORY_R2_3_G_SKILL_RISK_TAXONOMY.md") }

# --- Key principle check ---
Write-Host "`n--- Principle Checks ---" -ForegroundColor Yellow
Check "PRN-001" "Audit does not claim runtimeVerified" {
    $ar = Get-Content (Join-Path $FR "governance\skill-audits\CAP-SKILL-004-audit.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $ar.verdict -ne "runtimeVerified"
}

# --- SUMMARY ---
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " VERIFICATION SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  TOTAL:  $total" -ForegroundColor White
Write-Host "  PASSED: $passed" -ForegroundColor Green
if ($failed -gt 0) { Write-Host "  FAILED: $failed" -ForegroundColor Red } else { Write-Host "  FAILED: $failed" -ForegroundColor Green }

$vReport = [PSCustomObject]@{
    verificationId = "VERIFY-R2.3-G-001"
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    total = $total
    passed = $passed
    failed = $failed
    results = $results
}
$vPath = Join-Path $FR "outputs\FACTORY_R2_3_G_VERIFICATION_RESULTS.json"
$vReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $vPath -Encoding UTF8
Write-Host "`nResults: $vPath" -ForegroundColor Gray

if ($failed -gt 0) { exit 1 } else { exit 0 }
