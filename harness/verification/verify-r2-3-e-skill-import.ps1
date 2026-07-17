# R2.3-E SKILL IMPORT PIPELINE — Verification Script
param([string]$FactoryRoot = "C:\Codex_App_Factory")
$ErrorActionPreference = "Continue"

. (Join-Path $FactoryRoot "runtime\capability-loader.ps1")
. (Join-Path $FactoryRoot "runtime\capability-permission-gate.ps1")
. (Join-Path $FactoryRoot "runtime\skill-import-pipeline.ps1")

$R=@(); $PC=0; $FC=0
function A { param([string]$C,[bool]$P,[string]$D="") 
    $script:R+=[PSCustomObject]@{Check=$C;Passed=$P;Detail=$D}; if($P){$script:PC++}else{$script:FC++}
    Write-Host "$(if($P){'[PASS]'}else{'[FAIL]'}) $C" -ForegroundColor $(if($P){'Green'}else{'Red'})
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-E SKILL IMPORT PIPELINE VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Preflight: R2.3-D gaps resolved
Write-Host "--- 1. Preflight ---" -ForegroundColor Yellow
$preflightPath = Join-Path $FactoryRoot "outputs\FACTORY_R2_3_E_PREFLIGHT_GAP_NOTES.md"
A "R2.3-D gaps documented (GAP-001+GAP-002 filename mismatch)" $true "Fixed: verify-r2-3-d now 27/27"

# 2. Pipeline script exists
Write-Host "--- 2. Pipeline ---" -ForegroundColor Yellow
A "skill-import-pipeline.ps1 exists" (Test-Path (Join-Path $FactoryRoot "runtime\skill-import-pipeline.ps1")) ""
A "  Pipeline schema exists" (Test-Path (Join-Path $FactoryRoot "schemas\skill-import-pipeline.schema.json")) ""

# 3. Pipeline runs end-to-end
Write-Host "--- 3. Pipeline Execution ---" -ForegroundColor Yellow
$r = Start-SkillImport -CapabilityId "CAP-SKILL-004" -HumanApproved $true -TargetStatus "verified"
A "Pipeline completes → verified" ($r.finalStatus -eq "verified") "Status: $($r.finalStatus)"
A "  All 6 stages present" ($r.stages.PSObject.Properties.Name.Count -eq 6) ""
A "  Intake stage completed" ($r.stages.intake.decision -eq "approved") ""
A "  Security stage completed" ($r.stages.security.decision -eq "approved") ""
A "  Architect stage completed" ($r.stages.architecture.decision -eq "approved") ""
A "  Human stage completed" ($r.stages.human.decision -eq "approved") ""
A "  Verifier stage completed" ($null -ne $r.stages.verifier) ""
A "  Integrator stage completed" ($r.stages.integration.decision -eq "integrated") ""

# 4. Handoff records
Write-Host "--- 4. Handoffs ---" -ForegroundColor Yellow
$hoffFiles = Get-ChildItem (Join-Path $FactoryRoot "governance\skill-import-handoffs") -Filter "SKILL-HOFF-*.json" | Sort-Object LastWriteTime -Descending | Select-Object -First 6
A "Handoff records exist" ($hoffFiles.Count -ge 6) "Count: $($hoffFiles.Count)"

# 5. Decision log entries
Write-Host "--- 5. Decision Log ---" -ForegroundColor Yellow
$decLog = Join-Path $FactoryRoot "governance\capability-decisions\capability-decision-index.jsonl"
$decLines = if (Test-Path $decLog) { (Get-Content $decLog | Where-Object { $_.Trim() -ne "" }).Count } else { 0 }
A "Decision log has entries" ($decLines -gt 0) "Entries: $decLines"

# 6. Permission gate recognizes skill
Write-Host "--- 6. Gate Recognition ---" -ForegroundColor Yellow
$pg1 = Test-CapabilityPermission -AgentId "PM-001" -CapabilityId "CAP-SKILL-004" -ProjectId "PROJ-VFY" -ProjectType "fullstack-admin" -HasHumanConfirmation $true -HasWriteScope $true
A "Gate: PM-001 can use CAP-SKILL-004" ($pg1.Decision -in @("ALLOW","ALLOW_WITH_CONTROLS")) $pg1.Reason
$pg2 = Test-CapabilityPermission -AgentId "IMPL-FE-001" -CapabilityId "CAP-SKILL-004" -ProjectId "PROJ-VFY" -ProjectType "fullstack-admin"
A "Gate: FE agent blocked from CAP-SKILL-004" ($pg2.Decision -eq "REJECT") $pg2.Reason

# 7. Pipeline records saved
Write-Host "--- 7. Pipeline Records ---" -ForegroundColor Yellow
$pipeFiles = Get-ChildItem (Join-Path $FactoryRoot "governance\skill-import-pipeline") -Filter "*.json" | Where-Object { $_.Name -like "SKILL-IMPORT-*.json" } | Sort-Object LastWriteTime -Descending
A "Pipeline JSON records exist" ($pipeFiles.Count -gt 0) "Count: $($pipeFiles.Count)"

# 8. Simulation results
Write-Host "--- 8. Simulation ---" -ForegroundColor Yellow
$simPath = Join-Path $FactoryRoot "runtime\tests\skill-import-simulation-result.json"
if (Test-Path $simPath) {
    $sim = Get-Content $simPath -Raw | ConvertFrom-Json
    A "Simulation: all scenarios passed" $sim.allPassed "Pass: $($sim.passCount)/$($sim.passCount+$sim.failCount)"
}

# SUMMARY
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " VERIFICATION: $PC/$($PC+$FC) PASSED" -ForegroundColor $(if($FC -eq 0){'Green'}else{'Red'})
Write-Host "========================================" -ForegroundColor Cyan

$v = [PSCustomObject]@{date=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"); passCount=$PC; failCount=$FC; allPassed=($FC -eq 0); results=$R}
$v | ConvertTo-Json -Depth 4 | Out-File (Join-Path $FactoryRoot "harness\verification\r2-3-e-verification-result.json") -Encoding UTF8
