param([string]$FactoryRoot="C:\Codex_App_Factory")
$fr=$FactoryRoot;$t=0;$p=0;$f=0
function V($id,$desc,$ok){$script:t++;if($ok){$script:p++;$m="PASS"}else{$script:f++;$m="FAIL"};Write-Host ("  [{0}] {1}: {2}" -f $m,$id,$desc) -ForegroundColor $(if($ok){"Green"}else{"Red"})}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " R2.3-L VERIFICATION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Schemas
V "SCH-001" "Network boundary schema" (Test-Path "$fr\schemas\network-boundary.schema.json")
V "SCH-002" "Network boundary parses" (try{Get-Content "$fr\schemas\network-boundary.schema.json" -Raw|ConvertFrom-Json;$true}catch{$false})

# Registry
Write-Host "`n--- Registry ---" -ForegroundColor Yellow
. "$fr\runtime\tool-registry-loader.ps1"
$pw=Get-ToolById -ToolId "TOOL-PLAYWRIGHT-VER-001"
V "REG-001" "Playwright has networkBoundary" ($pw.networkBoundary -ne $null)
V "REG-002" "Playwright boundary=loopback_only" ($pw.networkBoundary -eq "loopback_only")
V "REG-003" "CLI verifier boundary=no_network" ((Get-ToolById "TOOL-CLI-VER-001").networkBoundary -eq "no_network")
V "REG-004" "Stitch MCP boundary=external_api" ((Get-ToolById "TOOL-STITCH-MCP-001").networkBoundary -eq "external_api")

# Gate
Write-Host "`n--- Gate ---" -ForegroundColor Yellow
. "$fr\runtime\tool-permission-gate.ps1"
$g1=Test-ToolPermission -ProjectId "T" -AgentId "VER-001" -ToolId "TOOL-PLAYWRIGHT-VER-001" -IsLocalFirst $true -HumanApproved $true -SandboxAvailable $true -RequestedHosts @("127.0.0.1")
V "GATE-001" "Playwright loopback ALLOW in local-first" ($g1.Decision -like "ALLOW*")
$g2=Test-ToolPermission -ProjectId "T" -AgentId "IMPL-FE-001" -ToolId "TOOL-STITCH-MCP-001" -IsLocalFirst $true
V "GATE-002" "Stitch external_api REJECT in local-first" ($g2.Decision -eq "REJECT")
$g3=Test-ToolPermission -ProjectId "T" -AgentId "VER-001" -ToolId "TOOL-PLAYWRIGHT-VER-001" -IsLocalFirst $true -HumanApproved $true -RequestedHosts @("https://evil.com")
V "GATE-003" "Playwright external host REJECT" ($g3.Decision -eq "REJECT")

# Sandbox lifecycle
Write-Host "`n--- Sandbox ---" -ForegroundColor Yellow
. "$fr\runtime\sandbox-lifecycle.ps1"
V "SBOX-001" "Sandbox lifecycle script" (Test-Path "$fr\runtime\sandbox-lifecycle.ps1")
V "SBOX-002" "Sandbox ledger exists" (Test-Path "$fr\governance\sandbox-sessions\sandbox-session-index.jsonl")
$s=New-SandboxSession -ProjectId "T" -ToolId "TOOL-CLI-VER-001" -AgentId "VER-001" -NetworkBoundary "no_network"
V "SBOX-003" "Session created" ($s.sessionId -ne $null)
$s=Start-SandboxSession $s; $s=Stop-SandboxSession $s; $s=Invoke-CleanupSandbox $s
V "SBOX-004" "Full lifecycle completed" ($s.status -eq "completed")

# Playwright loopback trial
Write-Host "`n--- Loopback Trial ---" -ForegroundColor Yellow
$lt=Get-Content "$fr\outputs\FACTORY_R2_3_L_PLAYWRIGHT_LOOPBACK_TRIAL_RESULTS.json" -Raw|ConvertFrom-Json
V "LT-001" "Loopback trial gate=ALLOW_WITH_CONTROLS" ($lt.gateDecision -eq "ALLOW_WITH_CONTROLS")
V "LT-002" "6/6 assertions passed" $lt.allPass
V "LT-003" "Network boundary=loopback_only" ($lt.networkBoundary -eq "loopback_only")

# Negative controls
Write-Host "`n--- Negative Controls ---" -ForegroundColor Yellow
$nc=Get-Content "$fr\outputs\FACTORY_R2_3_L_NETWORK_NEGATIVE_CONTROLS.json" -Raw|ConvertFrom-Json
$npc=($nc|Where-Object{$_.passed}).Count
V "NC-001" "8 negative controls exist" ($nc.Count -eq 8)
V "NC-002" "8/8 PASS" ($npc -eq 8)

# TPP
Write-Host "`n--- TPP ---" -ForegroundColor Yellow
V "TPP-001" "Loopback TPP generated" (Test-Path "$fr\examples\tool-permission-packets\tpp-loopback-playwright.json")
$tpp=Get-Content "$fr\examples\tool-permission-packets\tpp-loopback-playwright.json" -Raw|ConvertFrom-Json
V "TPP-002" "TPP has networkBoundary" ($tpp.networkBoundary -eq "loopback_only")
V "TPP-003" "TPP has sandboxSessionId" ($tpp.sandboxSessionId -ne $null)

Write-Host ("`n========================================") -ForegroundColor Cyan
Write-Host (" VERIFICATION: {0} / {1} PASS" -f $p,$t) -ForegroundColor $(if($f -eq 0){"Green"}else{"Red"})
Write-Host ("========================================") -ForegroundColor Cyan
