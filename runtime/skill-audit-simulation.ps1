# Skill Audit Simulation
# Part of: FACTORY-R2.3-G-SKILL-AUDIT-CAPABILITY-TRUST-PIPELINE
# Runs audit pipeline on CAP-SKILL-004 + 6 malicious fixtures, verifies verdicts

$script:FactoryRoot = "C:\Codex_App_Factory"

# Init pipeline
. (Join-Path $script:FactoryRoot "runtime\skill-audit-pipeline.ps1")

$ResultsDir = Join-Path $script:FactoryRoot "outputs"
$MalSkillsDir = Join-Path $script:FactoryRoot "runtime\tests\malicious-skills"

# Override SkillsDir for testing malicious skills
$origSkillsDir = $script:SkillsDir

function Write-SimulationResult {
    param($Result)
    $Result | ConvertTo-Json -Compress -Depth 3 | Add-Content -Path (Join-Path $ResultsDir "simulation-output.jsonl") -Encoding UTF8
}

$simResults = @()
$passCount = 0
$failCount = 0

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " SKILL AUDIT SIMULATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# --- TEST 1: CAP-SKILL-004 (legit) ---
Write-Host "`n>>> TEST 1: CAP-SKILL-004 (legit skill) <<<" -ForegroundColor Yellow
$script:SkillsDir = $origSkillsDir
$r = Invoke-SkillAudit -SkillId "CAP-SKILL-004" -AuditorAgent "SEC-001"
$expected = ($r.verdict -eq "pass" -or $r.verdict -eq "pass_with_controls")
$simResults += [PSCustomObject]@{testId="SIM-001";skillId="CAP-SKILL-004";expected="pass_or_pass_with_controls";actual=$r.verdict;passed=$expected;riskScore=$r.riskScore;notes=""}
if ($expected) { $passCount++ } else { $failCount++ }
Write-Host "  EXPECTED: pass/pass_with_controls | ACTUAL: $($r.verdict) | $(if($expected){'PASS'}else{'FAIL'})" -ForegroundColor $(if($expected){'Green'}else{'Red'})

# --- TEST 2: MAL-PROMPT-INJECTION ---
Write-Host "`n>>> TEST 2: MAL-PROMPT-INJECTION <<<" -ForegroundColor Yellow
$script:SkillsDir = $MalSkillsDir
$r = Invoke-SkillAudit -SkillId "MAL-PROMPT-INJECTION" -AuditorAgent "SEC-001"
$expected = ($r.verdict -eq "reject" -or $r.verdict -eq "quarantine")
$simResults += [PSCustomObject]@{testId="SIM-002";skillId="MAL-PROMPT-INJECTION";expected="reject_or_quarantine";actual=$r.verdict;passed=$expected;riskScore=$r.riskScore;notes=""}
if ($expected) { $passCount++ } else { $failCount++ }
Write-Host "  EXPECTED: reject/quarantine | ACTUAL: $($r.verdict) | $(if($expected){'PASS'}else{'FAIL'})" -ForegroundColor $(if($expected){'Green'}else{'Red'})

# --- TEST 3: MAL-DATA-EXFILTRATION ---
Write-Host "`n>>> TEST 3: MAL-DATA-EXFILTRATION <<<" -ForegroundColor Yellow
$script:SkillsDir = $MalSkillsDir
$r = Invoke-SkillAudit -SkillId "MAL-DATA-EXFILTRATION" -AuditorAgent "SEC-001"
$expected = ($r.verdict -eq "reject" -or $r.verdict -eq "quarantine")
$simResults += [PSCustomObject]@{testId="SIM-003";skillId="MAL-DATA-EXFILTRATION";expected="reject_or_quarantine";actual=$r.verdict;passed=$expected;riskScore=$r.riskScore;notes=""}
if ($expected) { $passCount++ } else { $failCount++ }
Write-Host "  EXPECTED: reject/quarantine | ACTUAL: $($r.verdict) | $(if($expected){'PASS'}else{'FAIL'})" -ForegroundColor $(if($expected){'Green'}else{'Red'})

# --- TEST 4: MAL-ARBITRARY-COMMAND ---
Write-Host "`n>>> TEST 4: MAL-ARBITRARY-COMMAND <<<" -ForegroundColor Yellow
$script:SkillsDir = $MalSkillsDir
$r = Invoke-SkillAudit -SkillId "MAL-ARBITRARY-COMMAND" -AuditorAgent "SEC-001"
$expected = ($r.verdict -eq "reject" -or $r.verdict -eq "quarantine")
$simResults += [PSCustomObject]@{testId="SIM-004";skillId="MAL-ARBITRARY-COMMAND";expected="reject_or_quarantine";actual=$r.verdict;passed=$expected;riskScore=$r.riskScore;notes=""}
if ($expected) { $passCount++ } else { $failCount++ }
Write-Host "  EXPECTED: reject/quarantine | ACTUAL: $($r.verdict) | $(if($expected){'PASS'}else{'FAIL'})" -ForegroundColor $(if($expected){'Green'}else{'Red'})

# --- TEST 5: MAL-OVERBROAD-TOOLS ---
Write-Host "`n>>> TEST 5: MAL-OVERBROAD-TOOLS <<<" -ForegroundColor Yellow
$script:SkillsDir = $MalSkillsDir
$r = Invoke-SkillAudit -SkillId "MAL-OVERBROAD-TOOLS" -AuditorAgent "SEC-001"
$expected = ($r.verdict -eq "reject" -or $r.verdict -eq "quarantine" -or $r.verdict -eq "pass_with_controls")
$simResults += [PSCustomObject]@{testId="SIM-005";skillId="MAL-OVERBROAD-TOOLS";expected="reject_or_quarantine_or_controls";actual=$r.verdict;passed=$expected;riskScore=$r.riskScore;notes=""}
if ($expected) { $passCount++ } else { $failCount++ }
Write-Host "  EXPECTED: reject/quarantine/pass_with_controls | ACTUAL: $($r.verdict) | $(if($expected){'PASS'}else{'FAIL'})" -ForegroundColor $(if($expected){'Green'}else{'Red'})

# --- TEST 6: MAL-AUTO-UPDATE ---
Write-Host "`n>>> TEST 6: MAL-AUTO-UPDATE <<<" -ForegroundColor Yellow
$script:SkillsDir = $MalSkillsDir
$r = Invoke-SkillAudit -SkillId "MAL-AUTO-UPDATE" -AuditorAgent "SEC-001"
$expected = ($r.verdict -eq "reject" -or $r.verdict -eq "quarantine")
$simResults += [PSCustomObject]@{testId="SIM-006";skillId="MAL-AUTO-UPDATE";expected="reject_or_quarantine";actual=$r.verdict;passed=$expected;riskScore=$r.riskScore;notes=""}
if ($expected) { $passCount++ } else { $failCount++ }
Write-Host "  EXPECTED: reject/quarantine | ACTUAL: $($r.verdict) | $(if($expected){'PASS'}else{'FAIL'})" -ForegroundColor $(if($expected){'Green'}else{'Red'})

# --- TEST 7: MAL-MISLEADING-TRIGGER ---
Write-Host "`n>>> TEST 7: MAL-MISLEADING-TRIGGER <<<" -ForegroundColor Yellow
$script:SkillsDir = $MalSkillsDir
$r = Invoke-SkillAudit -SkillId "MAL-MISLEADING-TRIGGER" -AuditorAgent "SEC-001"
$expected = ($r.verdict -eq "reject" -or $r.verdict -eq "quarantine" -or $r.verdict -eq "pass_with_controls")
$simResults += [PSCustomObject]@{testId="SIM-007";skillId="MAL-MISLEADING-TRIGGER";expected="reject_or_quarantine_or_controls";actual=$r.verdict;passed=$expected;riskScore=$r.riskScore;notes="Overbroad agents=11 triggers permission finding"}
if ($expected) { $passCount++ } else { $failCount++ }
Write-Host "  EXPECTED: reject/quarantine/pass_with_controls | ACTUAL: $($r.verdict) | $(if($expected){'PASS'}else{'FAIL'})" -ForegroundColor $(if($expected){'Green'}else{'Red'})

# --- SUMMARY ---
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " SIMULATION RESULTS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PASSED: $passCount / $($simResults.Count)" -ForegroundColor Green
if ($failCount -gt 0) { Write-Host "  FAILED: $failCount / $($simResults.Count)" -ForegroundColor Red }

# Save results
$ResultsPath = Join-Path $ResultsDir "FACTORY_R2_3_G_SKILL_AUDIT_SIMULATION_RESULTS.json"
$outObj = [PSCustomObject]@{
    simulationId = "R2.3-G-SIM-001"
    timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    totalTests = $simResults.Count
    passed = $passCount
    failed = $failCount
    results = $simResults
}
$outObj | ConvertTo-Json -Depth 4 | Out-File -FilePath $ResultsPath -Encoding UTF8
Write-Host "`nResults saved: $ResultsPath" -ForegroundColor Gray

# Restore
$script:SkillsDir = $origSkillsDir

# Return results as exit code (0 if all passed)
if ($failCount -gt 0) { exit 1 } else { exit 0 }
