# R2.14 Demo Cases Runner v3 - L_CLASS uses empty temp dir
Push-Location C:\Codex_App_Factory
. .\runtime\runtime-risk-classifier.ps1
. .\runtime\automated-gate-detector.ps1
. .\runtime\gate-evidence-binder.ps1
. .\runtime\risk-enforcement-gate-v2.ps1

$testbedPath = "C:\Codex_App_Factory\testbeds\products-api"
$factoryPath = "C:\Codex_App_Factory"
$newProjPath = "C:\Codex_App_Factory\temp_lclass_demo"
New-Item -ItemType Directory -Path $newProjPath -Force -ErrorAction SilentlyContinue | Out-Null

$demos = @(
    @{ num=1; risk="LOW"; desc="修改 README documentation 中的说明文字和 style 样式"; path=$testbedPath; extra=@($testbedPath) },
    @{ num=2; risk="MEDIUM"; desc="更新 Products API crud filter pagination 参数，添加新的搜索和排序"; path=$testbedPath; extra=@($testbedPath) },
    @{ num=3; risk="HIGH"; desc="修改产品 status transition 流转规则 database write，新增从草稿到审核中的状态转换 lifecycle"; path=$testbedPath; extra=@($testbedPath) },
    @{ num=4; risk="CRITICAL+inv"; desc="修改商品 price 价格计算逻辑，调整 discount 折扣算法和支付金额"; path=$testbedPath; extra=@($testbedPath) },
    @{ num=5; risk="CRITICAL-inv"; desc="修改 inventory stock 库存扣减逻辑，引入新的 quantity 库存计算和处理方式"; path=$testbedPath; extra=@($testbedPath) },
    @{ num=6; risk="L_CLASS"; desc="做一个完整的小程序 miniapp 商城，带后台 admin dashboard 管理系统和 REST API payment 数据库 backend api"; path=$newProjPath; extra=@($newProjPath) }
)

$results = @()

foreach ($d in $demos) {
    Write-Host "`n==============================" -F Cyan
    Write-Host "DEMO $($d.num): $($d.risk) - $($d.desc)" -F Cyan
    Write-Host "Project: $($d.path)" -F DarkGray
    Write-Host "==============================" -F Cyan

    try {
        $binding = Invoke-RiskEnforcementGateV2 `
            -TaskDescription $d.desc `
            -ProjectPath $d.path `
            -AdditionalSearchPaths $d.extra `
            -ShowOutput

        $results += [PSCustomObject]@{
            DemoNum = $d.num
            ExpectedRisk = $d.risk
            ActualRisk = $binding.riskLevel
            Decision = $binding.finalDecision
            Satisfied = $binding.satisfiedCount
            Missing = $binding.missingCount
            Partial = $binding.partialCount
            NotApplicable = ($binding.gates | Where-Object { $_.status -eq "NOT_APPLICABLE" }).Count
        }
    } catch {
        Write-Host "ERROR: $_" -F Red
        $results += [PSCustomObject]@{
            DemoNum = $d.num; ExpectedRisk = $d.risk; ActualRisk = "ERROR"
            Decision = "ERROR"; Satisfied = 0; Missing = 0; Partial = 0; NotApplicable = 0
        }
    }
}

Write-Host "`n==============================" -F Green
Write-Host "DEMO SUMMARY" -F Green
Write-Host "==============================" -F Green
$results | Format-Table -AutoSize

$passCount = 0
foreach ($r in $results) {
    $expected = switch ($r.ExpectedRisk) {
        "LOW" { "ALLOWED" }
        "MEDIUM" { "ALLOWED" }
        "HIGH" { "ALLOWED" }
        "CRITICAL+inv" { "ALLOWED" }
        "CRITICAL-inv" { "BLOCKED" }
        "L_CLASS" { "BLOCKED" }
    }
    $match = if ($r.Decision -eq $expected) { "PASS" } else { "FAIL" }
    if ($match -eq "PASS") { $passCount++ }
    Write-Host "Demo $($r.DemoNum) ($($r.ExpectedRisk)): $($r.ActualRisk) -> $($r.Decision) (expected $expected) -> $match" -F $(if ($match -eq "PASS"){"Green"}else{"Red"})
}

Write-Host "`nPASS: $passCount / $($results.Count)" -F $(if ($passCount -eq 6){"Green"}else{"Yellow"})

Remove-Item -Path $newProjPath -Recurse -Force -ErrorAction SilentlyContinue
Pop-Location
