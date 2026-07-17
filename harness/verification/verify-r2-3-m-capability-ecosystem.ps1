param([string]$f="C:\Codex_App_Factory")
$t=0;$p=0;$fa=0
function V($id,$d,$ok){$script:t++;if($ok){$script:p++;$m="PASS"}else{$script:fa++;$m="FAIL"};Write-Host ("  [{0}] {1}: {2}" -f $m,$id,$d) -ForegroundColor $(if($ok){"Green"}else{"Red"})}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-M VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Consistency
V "C01" "Audit results exist" (Test-Path "$f\outputs\FACTORY_R2_3_M_CONSISTENCY_AUDIT.json")
$au=Get-Content "$f\outputs\FACTORY_R2_3_M_CONSISTENCY_AUDIT.json" -Raw|ConvertFrom-Json
V "C02" "0 blockers" ($au.block -eq 0)
V "C03" "Skill consistency report" (Test-Path "$f\outputs\FACTORY_R2_3_M_SKILL_ECOSYSTEM_CONSISTENCY_REPORT.md")
V "C04" "Tool consistency report" (Test-Path "$f\outputs\FACTORY_R2_3_M_TOOL_ECOSYSTEM_CONSISTENCY_REPORT.md")
V "C05" "Cross-registry report" (Test-Path "$f\outputs\FACTORY_R2_3_M_CROSS_REGISTRY_CONSISTENCY_REPORT.md")

# Promotion
V "P01" "Promotion trial report" (Test-Path "$f\outputs\FACTORY_R2_3_M_RUNTIME_PROMOTION_TRIAL_REPORT.md")
V "P02" "Promotion decisions doc" (Test-Path "$f\outputs\FACTORY_R2_3_M_PROMOTION_DECISIONS.md")
$sj13=Get-Content "$f\skills\CAP-SKILL-013\skill.json" -Raw|ConvertFrom-Json
V "P03" "CAP-SKILL-013 = factoryRuntimeVerified" ($sj13.status -eq "factoryRuntimeVerified")
$sj14=Get-Content "$f\skills\CAP-SKILL-014\skill.json" -Raw|ConvertFrom-Json
V "P04" "CAP-SKILL-014 = factoryRuntimeVerified" ($sj14.status -eq "factoryRuntimeVerified")

# Regression
V "R01" "Regression results exist" (Test-Path "$f\outputs\FACTORY_R2_3_M_PERMISSION_REGRESSION_RESULTS.json")
$rr=Get-Content "$f\outputs\FACTORY_R2_3_M_PERMISSION_REGRESSION_RESULTS.json" -Raw|ConvertFrom-Json
$rp=($rr|Where-Object{$_.passed}).Count
V "R02" "Regression 10/10" ($rp -eq 10)

# Key gates preserved
. "$f\runtime\tool-permission-gate.ps1"
$g=Test-ToolPermission -ProjectId "V" -AgentId "IMPL-FE-001" -ToolId "TOOL-STITCH-MCP-001" -IsLocalFirst $true
V "G01" "Stitch blocked post-R2.3-M" ($g.Decision -eq "REJECT")
$g=Test-ToolPermission -ProjectId "V" -AgentId "VER-001" -ToolId "TOOL-PLAYWRIGHT-VER-001" -IsLocalFirst $true -HumanApproved $true -SandboxAvailable $true -RequestedHosts @("127.0.0.1")
V "G02" "Playwright loopback allowed post-R2.3-M" ($g.Decision -like "ALLOW*")

# Readiness
V "RD01" "Readiness statement exists" (Test-Path "$f\outputs\FACTORY_R2_3_M_LOCAL_RUNTIME_READINESS_STATEMENT.md")
$rs=Get-Content "$f\outputs\FACTORY_R2_3_M_LOCAL_RUNTIME_READINESS_STATEMENT.md" -Raw
V "RD02" "States NOT production ready" ($rs -match "NOT.*production")
V "RD03" "States local runtime ready" ($rs -match "Local.*Runtime.*Ready")

# Reports
V "RP01" "Main report" (Test-Path "$f\outputs\FACTORY_R2_3_M_CAPABILITY_ECOSYSTEM_CONSISTENCY_AND_RUNTIME_PROMOTION_REPORT.md")
V "RP02" "Next phase" (Test-Path "$f\outputs\FACTORY_R2_3_M_NEXT_PHASE_RECOMMENDATION.md")

Write-Host ("`n========================================") -ForegroundColor Cyan
Write-Host (" VERIFICATION: {0} / {1} PASS" -f $p,$t) -ForegroundColor $(if($fa -eq 0){"Green"}else{"Red"})
Write-Host ("========================================") -ForegroundColor Cyan
