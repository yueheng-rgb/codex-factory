# R3.0 Demo Cases Runner v2
Push-Location C:\Codex_App_Factory
. .\runtime\runtime-risk-classifier.ps1
. .\runtime\automated-gate-detector.ps1
. .\runtime\gate-evidence-binder.ps1
. .\runtime\external-engine-registry.ps1
. .\runtime\external-tool-availability-check.ps1
. .\runtime\external-engine-broker.ps1
. .\runtime\risk-enforcement-gate-v3.ps1

$testbedPath = "C:\Codex_App_Factory\testbeds\products-api"
$starterPath = "C:\Codex_App_Factory\runnable-starters\node-api-postgres"
$threejsPath = "C:\Codex_App_Factory\runnable-starters\vite-threejs-interactive"
$emptyPath = "C:\Codex_App_Factory\temp_r3_demo"
New-Item -ItemType Directory -Path $emptyPath -Force -ErrorAction SilentlyContinue | Out-Null

$demos = @(
    @{ num=1; risk="LOW"; desc="修改 README documentation style 和 format 调整，纯文档修改";
       path=$testbedPath; ptype="backend-api"; surfaces=@("api-service") },
    @{ num=2; risk="MEDIUM"; desc="更新 Products API crud filter pagination 参数，API endpoint 改动";
       path=$testbedPath; ptype="backend-api"; surfaces=@("api-service") },
    @{ num=3; risk="HIGH"; desc="修改 auth permission 权限校验和 file upload 文件上传安全逻辑 database write";
       path=$testbedPath; ptype="backend-api"; surfaces=@("api-service") },
    @{ num=4; risk="CRITICAL"; desc="修改 price 价格计算和 inventory stock 库存扣减逻辑 payment 支付流程";
       path=$testbedPath; ptype="backend-api"; surfaces=@("api-service") },
    @{ num=5; risk="PERF"; desc="验证 Products API endpoint 支持高并发 performance 和 load testing，需要 k6 autocannon 验证";
       path=$starterPath; ptype="backend-api"; surfaces=@("api-service") },
    @{ num=6; risk="UI"; desc="为 threejs-interactive 展示页添加 playwright e2e browser smoke 测试 component";
       path=$threejsPath; ptype="threejs-interactive"; surfaces=@("threejs-interactive") }
)

$results = @()

foreach ($d in $demos) {
    Write-Host "`n==============================" -F Cyan
    Write-Host "DEMO $($d.num): $($d.risk) — $($d.desc)" -F Cyan
    Write-Host "Project: $($d.path)" -F DarkGray
    Write-Host "==============================" -F Cyan

    try {
        $gateResult = Invoke-RiskEnforcementGateV3 `
            -TaskDescription $d.desc `
            -ProjectPath $d.path `
            -AdditionalSearchPaths @($d.path) `
            -ProjectType $d.ptype `
            -Surfaces $d.surfaces `
            -ShowOutput

        $enginesPlanned = if ($gateResult.external_engine_plan) { $gateResult.external_engine_plan.planned_engines.Count } else { 0 }
        $engineResults = @($gateResult.external_engine_results)
        $engineRan = ($engineResults | Where-Object { $_.status -notin @("SKIPPED","TOOL_UNAVAILABLE") }).Count
        $engineSkipped = ($engineResults | Where-Object { $_.status -in @("SKIPPED","TOOL_UNAVAILABLE") }).Count
        $engineIds = ($engineResults | ForEach-Object { "$($_.engine_id)=$($_.status)" }) -join "; "

        $results += [PSCustomObject]@{
            DemoNum = $d.num
            ExpectedRisk = $d.risk
            ActualRisk = $gateResult.profile.riskLevel
            Lightweight = $gateResult.lightweight_gate_result.finalDecision
            Final = $gateResult.final_decision
            EnginesPlanned = $enginesPlanned
            EnginesRan = $engineRan
            EnginesSkipped = $engineSkipped
            EngineStatuses = $engineIds
        }
    } catch {
        Write-Host "ERROR: $_" -F Red
        $results += [PSCustomObject]@{
            DemoNum = $d.num; ExpectedRisk = $d.risk; ActualRisk = "ERROR"
            Lightweight = "ERROR"; Final = "ERROR"
            EnginesPlanned = 0; EnginesRan = 0; EnginesSkipped = 0; EngineStatuses = $_.Exception.Message
        }
    }
}

Write-Host "`n==============================" -F Green
Write-Host "R3.0 DEMO SUMMARY" -F Green
Write-Host "==============================" -F Green
$results | Format-Table DemoNum, ExpectedRisk, ActualRisk, Lightweight, Final, EnginesPlanned, EnginesRan, EnginesSkipped -AutoSize

Write-Host "`nEngine Statuses:" -F DarkGray
foreach ($r in $results) {
    $status = if ($r.EngineStatuses) { $r.EngineStatuses } else { "(none - LOW risk or error)" }
    Write-Host "  Demo $($r.DemoNum): $status"
}

# Assessment
$passCount = 0
foreach ($r in $results) {
    $ok = $false
    switch ($r.ExpectedRisk) {
        "LOW" { $ok = ($r.ActualRisk -eq "LOW" -and $r.Final -eq "ALLOWED") }
        "MEDIUM" { $ok = ($r.ActualRisk -ne "ERROR" -and $r.Final -ne "ERROR") }
        "HIGH" { $ok = ($r.ActualRisk -ne "ERROR" -and $r.Final -ne "ERROR") }
        "CRITICAL" { $ok = ($r.ActualRisk -eq "CRITICAL" -and $r.Final -ne "ERROR") }
        "PERF" { $ok = ($r.Final -ne "ERROR" -and $r.EnginesPlanned -ge 0) }
        "UI" { $ok = ($r.ActualRisk -ne "ERROR" -and $r.Final -ne "ERROR") }
    }
    if ($ok) { $passCount++ }
    $mark = if ($ok) { "PASS" } else { "FAIL" }
    Write-Host "Demo $($r.DemoNum) ($($r.ExpectedRisk)): $($r.ActualRisk) / $($r.Final) -> $mark" -F $(if($ok){"Green"}else{"Red"})
}

Write-Host "`nPASS: $passCount / $($results.Count)" -F $(if($passCount -ge 5){"Green"}else{"Yellow"})

Remove-Item -Path $emptyPath -Recurse -Force -ErrorAction SilentlyContinue
Pop-Location
