param([string]$FactoryRoot = "C:\Codex_App_Factory")
$fr = $FactoryRoot; $total=0; $passed=0; $failed=0
function V($id,$desc,$result) { $script:total++; if($result){$script:passed++;$m="PASS"}else{$script:failed++;$m="FAIL"}; $c=if($result){"Green"}else{"Red"}; Write-Host ("  [{0}] {1}: {2}" -f $m,$id,$desc) -ForegroundColor $c }
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-J VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n--- Schemas ---" -ForegroundColor Yellow
V "SCH-001" "tool-capability.schema.json exists" (Test-Path "$fr\schemas\tool-capability.schema.json")
V "SCH-002" "tool-capability parses" (try{Get-Content "$fr\schemas\tool-capability.schema.json" -Raw|ConvertFrom-Json;$true}catch{$false})
V "SCH-003" "mcp-server-manifest exists" (Test-Path "$fr\schemas\mcp-server-manifest.schema.json")
V "SCH-004" "tool-invocation schema exists" (Test-Path "$fr\schemas\tool-invocation.schema.json")
V "SCH-005" "tool-permission-packet exists" (Test-Path "$fr\schemas\tool-permission-packet.schema.json")

Write-Host "`n--- Registry ---" -ForegroundColor Yellow
V "REG-001" "Registry file exists" (Test-Path "$fr\registries\tool-candidate-registry.jsonl")
. "$fr\runtime\tool-registry-loader.ps1"; Initialize-ToolCache
V "REG-002" "10+ tools loaded" ($script:ToolCache.Count -ge 10)

Write-Host "`n--- Gate ---" -ForegroundColor Yellow
V "GATE-001" "Gate script exists" (Test-Path "$fr\runtime\tool-permission-gate.ps1")
. "$fr\runtime\tool-permission-gate.ps1"
$r1=Test-ToolPermission -ProjectId "T" -AgentId "VER-001" -ToolId "TOOL-CLI-VER-001" -ProjectType "fullstack-admin"
V "GATE-002" "CLI verifier ALLOW" ($r1.Decision -like "ALLOW*")
$r2=Test-ToolPermission -ProjectId "T" -AgentId "VER-001" -ToolId "TOOL-UNKNOWN-999"
V "GATE-003" "Unknown REJECT" ($r2.Decision -eq "REJECT")
$r3=Test-ToolPermission -ProjectId "T" -AgentId "VER-001" -ToolId "TOOL-MAL-AUTOUPDATE-001"
V "GATE-004" "Quarantine REJECT" ($r3.Decision -eq "REJECT")
$r4=Test-ToolPermission -ProjectId "T" -AgentId "IMPL-FE-001" -ToolId "TOOL-STITCH-MCP-001" -SandboxAvailable $false
V "GATE-005" "Stitch PENDING_SANDBOX" ($r4.Decision -eq "PENDING_SANDBOX")

Write-Host "`n--- Ledger ---" -ForegroundColor Yellow
. "$fr\runtime\tool-invocation-logger.ps1"
V "LED-001" "Logger exists" (Test-Path "$fr\runtime\tool-invocation-logger.ps1")
V "LED-002" "Ledger file" (Test-Path "$fr\governance\tool-invocations\tool-invocation-index.jsonl")

Write-Host "`n--- TPP ---" -ForegroundColor Yellow
V "TPP-001" "TPP dir" (Test-Path "$fr\examples\tool-permission-packets")
V "TPP-002" "TPP IMPL-FE" (Test-Path "$fr\examples\tool-permission-packets\tpp-impl-fe-fullstack.json")
V "TPP-003" "TPP VER" (Test-Path "$fr\examples\tool-permission-packets\tpp-ver-fullstack.json")

Write-Host "`n--- Simulation ---" -ForegroundColor Yellow
$sim=Get-Content "$fr\outputs\FACTORY_R2_3_J_TOOL_PERMISSION_GATE_RESULTS.json" -Raw|ConvertFrom-Json
$sp=($sim|Where-Object{$_.passed}).Count
V "SIM-001" "Results exist" ($sim.Count -gt 0)
V "SIM-002" ">=90% pass" ($sp/$sim.Count -ge 0.90)

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host (" VERIFICATION: {0} / {1} PASS" -f $passed,$total) -ForegroundColor $(if($failed -eq 0){"Green"}else{"Red"})
Write-Host "========================================" -ForegroundColor Cyan

