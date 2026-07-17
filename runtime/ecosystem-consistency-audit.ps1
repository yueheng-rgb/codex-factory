param([string]$FactoryRoot = "C:\Codex_App_Factory")
$fr = $FactoryRoot
. (Join-Path $fr "runtime\agent-loader.ps1")
. (Join-Path $fr "runtime\capability-loader.ps1")
. (Join-Path $fr "runtime\skill-content-loader.ps1")
. (Join-Path $fr "runtime\tool-registry-loader.ps1")
. (Join-Path $fr "runtime\tool-permission-gate.ps1")
$issues=@();$warns=@();$passes=@()
function A($c,$id,$d,$ok,$s="info"){$m="PASS";if(-not $ok){if($s -eq "blocker"){$script:issues+="$c/$id";$m="BLOCK"}else{$script:warns+="$c/$id";$m="WARN"}}else{$script:passes+="$c/$id"};Write-Host ("  [{0}] {1}/{2}: {3}" -f $m,$c,$id,$d) -ForegroundColor $(if($ok){"Green"}else{if($s -eq "blocker"){"Red"}else{"Yellow"}})}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " ECOSYSTEM CONSISTENCY AUDIT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`n--- 1. SKILLS ---" -ForegroundColor Yellow
$sids=@("CAP-SKILL-004","CAP-SKILL-013","CAP-SKILL-014","CAP-SKILL-015")
foreach($sid in $sids){$d=Join-Path $fr "skills\$sid";$sj=Join-Path $d "skill.json";$smd=Join-Path $d "SKILL.md";$au=Join-Path $fr "governance\skill-audits\$sid-audit.json"
A "SKILL" $sid "skill.json" (Test-Path $sj); A "SKILL" $sid "SKILL.md" (Test-Path $smd)
if(Test-Path $sj){try{$p=Get-Content $sj -Raw -Encoding UTF8|ConvertFrom-Json;A "SKILL" $sid ("status="+$p.status) ($p.status -in @("candidate","adapted","verified","auditPassed","factoryRuntimeVerified","realAgentVerified","quarantine","deprecated"));A "SKILL" $sid "allowedTools present" ($p.allowedTools -is [array]);A "SKILL" $sid "forbiddenActions present" ($p.forbiddenActions -is [array])}catch{A "SKILL" $sid "JSON error" $false "blocker"}}
A "SKILL" $sid "audit exists" (Test-Path $au) "warn";$lr=Load-SkillContent -SkillId $sid -AgentId "PM-001" -ProjectId "AUDIT" -PhaseId "AUDIT" -ProjectType "fullstack-admin" -IsLocalFirst $true;A "SKILL" $sid "loadable" $lr.Loaded}

Write-Host "`n--- 2. TOOLS ---" -ForegroundColor Yellow
Initialize-ToolCache;foreach($t in $script:ToolCache){$tid=$t.toolId;A "TOOL" $tid ("status="+$t.status) ($t.status -in @("candidate","monitor","sandboxReady","allowedWithControls","rejected","quarantine","deprecated"));A "TOOL" $tid "has networkBoundary" ($t.networkBoundary -ne $null);A "TOOL" $tid "has riskLevel" ($t.riskLevel -in @("none","low","medium","high","critical"))}

Write-Host "`n--- 3. KEY GATES ---" -ForegroundColor Yellow
$g=Test-ToolPermission -ProjectId "A" -AgentId "IMPL-FE-001" -ToolId "TOOL-STITCH-MCP-001" -IsLocalFirst $true;A "GATE" "Stitch" "local-first blocked" ($g.Decision -eq "REJECT") "blocker"
$g=Test-ToolPermission -ProjectId "A" -AgentId "RSRC-001" -ToolId "TOOL-GLM-SEARCH-001" -IsLocalFirst $true -SecretsAllowed $false;A "GATE" "GLM" "no-secrets blocked" ($g.Decision -eq "REJECT") "blocker"
$g=Test-ToolPermission -ProjectId "A" -AgentId "IMPL-DB-001" -ToolId "TOOL-DB-MCP-001" -IsLocalFirst $true;A "GATE" "DB-MCP" "local-first blocked" ($g.Decision -eq "REJECT") "blocker"
$g=Test-ToolPermission -ProjectId "A" -AgentId "VER-001" -ToolId "TOOL-PLAYWRIGHT-VER-001" -IsLocalFirst $true -HumanApproved $true -SandboxAvailable $true -RequestedHosts @("127.0.0.1");A "GATE" "Playwright" "loopback allowed" ($g.Decision -like "ALLOW*") "blocker"
$g=Test-ToolPermission -ProjectId "A" -AgentId "VER-001" -ToolId "TOOL-CLI-VER-001" -IsLocalFirst $true;A "GATE" "CLI-Ver" "no_net allowed" ($g.Decision -like "ALLOW*")

Write-Host "`n--- 4. CROSS-REGISTRY ---" -ForegroundColor Yellow
$caps=Get-CapabilitiesByType -Type "skill";foreach($c in $caps){$sj=Join-Path $fr "skills\$($c.capabilityId)\skill.json";A "XREG" $c.capabilityId "has skill package" (Test-Path $sj) "warn"}
$sl=Join-Path $fr "governance\sandbox-sessions\sandbox-session-index.jsonl";A "XREG" "SBOX" "sandbox ledger" (Test-Path $sl)
$ul=Join-Path $fr "governance\skill-usage\skill-usage-index.jsonl";A "XREG" "USAGE" "skill usage ledger" (Test-Path $ul)
$il=Join-Path $fr "governance\tool-invocations\tool-invocation-index.jsonl";A "XREG" "INVOKE" "tool invocation ledger" (Test-Path $il)

Write-Host ("`n========================================") -ForegroundColor Cyan
$bi=$issues.Count;$bw=$warns.Count;$bp=$passes.Count
Write-Host ("  PASS: {0}  WARN: {1}  BLOCK: {2}" -f $bp,$bw,$bi)
[PSCustomObject]@{auditId="ECO-AUDIT-001";pass=$bp;warn=$bw;block=$bi;warnings=$warns;blockers=$issues}|ConvertTo-Json -Depth 3|Out-File (Join-Path $fr "outputs\FACTORY_R2_3_M_CONSISTENCY_AUDIT.json") -Encoding UTF8

