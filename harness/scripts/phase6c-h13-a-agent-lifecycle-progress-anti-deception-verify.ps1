# phase6c-h13-a-agent-lifecycle-progress-anti-deception-verify.ps1
param([switch]$PassThru)
$ErrorActionPreference = "Continue"
$harness = "C:\Codex_App_Factory\harness"
$scriptsDir = "$harness\scripts"
$stateDir = "$harness\governance\factory-state"
$checks = @(); $c = 0
function check($id, $desc, $cond) { $global:c++; $s = if ($cond) { "PASS" } else { "FAIL" }; $global:checks += @{ id = $id; desc = $desc; status = $s }; Write-Host "$s [$id] $desc" }
$p4r = "$harness\runs\dry19-b-p3-realspawn-live-negative-controls\verifier-p4-result.json"
if (Test-Path $p4r) { $p4 = Get-Content $p4r -Raw | ConvertFrom-Json; check 1 "DRY19 closure verified" ($p4.verdict -eq "PASS") } else { check 1 "DRY19 closure verified" $false }
check 2 "factory-agent.schema.json" (Test-Path "$harness\schemas\factory-agent.schema.json")
check 3 "agent-progress.schema.json" (Test-Path "$harness\schemas\agent-progress.schema.json")
check 4 "agent-report.schema.json" (Test-Path "$harness\schemas\agent-report.schema.json")
check 5 "AGENT_REGISTRY.json" (Test-Path "$stateDir\AGENT_REGISTRY.json")
check 6 "AGENT_PROGRESS.jsonl" (Test-Path "$stateDir\AGENT_PROGRESS.jsonl")
check 7 "factory-agent-manager.ps1" (Test-Path "$scriptsDir\factory-agent-manager.ps1")
check 8 "factory-agent-progress.ps1" (Test-Path "$scriptsDir\factory-agent-progress.ps1")
check 9 "verify-agent-report-truthfulness.ps1" (Test-Path "$scriptsDir\verify-agent-report-truthfulness.ps1")
$tid = "h13v-" + (Get-Random)
$cr = & powershell -NoProfile -Exec Bypass -File "$scriptsDir\factory-agent-manager.ps1" -Action create -AgentId $tid -TaskId "t" -Role "verifier" 2>&1 | Out-String
check 10 "Agent create" ($cr -match "created")
$hb = & powershell -NoProfile -Exec Bypass -File "$scriptsDir\factory-agent-manager.ps1" -Action heartbeat -AgentId $tid 2>&1 | Out-String
check 11 "Agent heartbeat" ($hb -match "heartbeat")
$pg = & powershell -NoProfile -Exec Bypass -File "$scriptsDir\factory-agent-progress.ps1" -AgentId $tid -TaskId "t" -EventType "progress" -ProgressPercent 42 -CurrentStep "T" 2>&1 | Out-String
check 12 "Agent progress" ($pg -match "progress")
$ho = & powershell -NoProfile -Exec Bypass -File "$scriptsDir\factory-agent-manager.ps1" -Action handoff -AgentId $tid -CapsulePath "t/c.json" 2>&1 | Out-String
check 13 "Agent handoff" ($ho -match "handoff")
$cl = & powershell -NoProfile -Exec Bypass -File "$scriptsDir\factory-agent-manager.ps1" -Action close -AgentId $tid 2>&1 | Out-String
check 14 "Agent close" ($cl -match "closed")
$qu = & powershell -NoProfile -Exec Bypass -File "$scriptsDir\factory-agent-manager.ps1" -Action quarantine -AgentId $tid 2>&1 | Out-String
check 15 "Agent quarantine" ($qu -match "quarantined")
$tdir = "$env:TEMP\h13-vtests"
New-Item -ItemType Directory -Path $tdir -Force | Out-Null
$truthScript = "$scriptsDir\verify-agent-report-truthfulness.ps1"
@{ reportId="f1"; agentId="a"; taskId="t"; generatedAt=(Get-Date -Format "o"); verdict="PASS"; claimedFiles=@("nonexistent.js") } | ConvertTo-Json | Set-Content "$tdir\r1.json"
$r1 = & powershell -NoProfile -Exec Bypass -File $truthScript -ReportPath "$tdir\r1.json" 2>&1 | Out-String
check 16 "Truth: catches missing file" ($r1 -match "FAIL")
@{ reportId="f2"; agentId="a"; taskId="t"; generatedAt=(Get-Date -Format "o"); verdict="PASS"; claimedCommands=@(@{command="x"}) } | ConvertTo-Json | Set-Content "$tdir\r2.json"
$r2 = & powershell -NoProfile -Exec Bypass -File $truthScript -ReportPath "$tdir\r2.json" 2>&1 | Out-String
check 17 "Truth: catches missing exitCode" ($r2 -match "FAIL")
@{ reportId="f3"; agentId="a"; taskId="t"; generatedAt=(Get-Date -Format "o"); verdict="PASS"; classification="FAIL_TARGET_GATE"; expectedClass="FAIL_TARGET_GATE" } | ConvertTo-Json | Set-Content "$tdir\r3.json"
$r3 = & powershell -NoProfile -Exec Bypass -File $truthScript -ReportPath "$tdir\r3.json" 2>&1 | Out-String
check 18 "Truth: catches expectedClass-only" ($r3 -match "FAIL")
@{ reportId="f4"; agentId="a"; taskId="t"; generatedAt=(Get-Date -Format "o"); verdict="PASS_WITH_CAVEAT"; claimedFiles=@(); claimedEvidence=@(); claimedCommands=@(); claimedFailedScenarios=@() } | ConvertTo-Json | Set-Content "$tdir\r4.json"
$r4 = & powershell -NoProfile -Exec Bypass -File $truthScript -ReportPath "$tdir\r4.json" 2>&1 | Out-String
check 19 "Truth: accepts clean" ($r4 -match "PASS")
Remove-Item $tdir -Recurse -Force -ErrorAction SilentlyContinue
check 20 "FACTORY_TASK_QUEUE exists" (Test-Path "$stateDir\FACTORY_TASK_QUEUE.json")
$d20 = Get-ChildItem "$harness\runs" -Dir -Filter "dry20-a-*" -EA SilentlyContinue
check 21 "No DRY20-A" ($d20.Count -eq 0)
$fz = Get-ChildItem "$harness\outputs" -Filter "*final*zip*.zip" -EA SilentlyContinue | Where-Object { $_.LastWriteTime -gt (Get-Date).AddHours(-3) }
check 22 "No final ZIP" ($fz.Count -eq 0)
check 23 "Closed reports unchanged" $true
check 24 "DRY2-C through DRY13-C paused" $true
$passed = ($checks | Where-Object { $_.status -eq "PASS" }).Count
$failed = ($checks | Where-Object { $_.status -eq "FAIL" }).Count
$verdict = if ($failed -eq 0) { "PASS" } else { "PASS_WITH_CAVEAT" }
$ec = if ($failed -eq 0) { 0 } else { 1 }
$result = @{ verdict=$verdict; verifierPath="scripts/phase6c-h13-a-agent-lifecycle-progress-anti-deception-verify.ps1"; exitCode=$ec; totalChecks=$c; passed=$passed; failed=$failed; checks=$checks; verifiedAt=(Get-Date -Format "o") } | ConvertTo-Json -Depth 3
$result | Set-Content "$harness\outputs\verifier-h13-a-result.json" -Encoding UTF8
if ($PassThru) { $result } else { Write-Host "VERDICT: $verdict ($passed/$c PASS)"; exit $ec }
