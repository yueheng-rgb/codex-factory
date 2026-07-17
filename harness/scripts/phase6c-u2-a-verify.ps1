# phase6c-u2-a-verify.ps1 — Phase 6C-U2-A Verifier (24 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l, $sb) { $script:total++; try { if (& $sb) { [void]$script:P.Add($l); $script:ok++ } else { [void]$script:E.Add("$l-FAIL") } } catch { [void]$script:E.Add("$l-ERROR: $_") } }

$factoryDir = "$H\factory"
$templatesDir = "$factoryDir\templates"
$examplesDir = "$factoryDir\examples"

# 1-5: Factory files exist
$templates = @("project-request.template.json","task.template.json","acceptance.template.json","interface-contract.template.json","ownership.template.json","worker-prompt.template.md","final-report.template.md")
foreach ($t in $templates) { check "V01-TPL-$t" { Test-Path "$templatesDir\$t" } }
check "V02: Example project request exists" { Test-Path "$examplesDir\tiny-typescript-service.project.json" }
check "V03: validate-project-request.ps1 exists" { Test-Path "$H\scripts\validate-project-request.ps1" }
check "V04: materialize-project-run.ps1 exists" { Test-Path "$H\scripts\materialize-project-run.ps1" }
check "V05: new-project-run.ps1 exists" { Test-Path "$H\scripts\new-project-run.ps1" }
check "V06: Project factory guide exists" { Test-Path "$H\docs\HARNESS_PROJECT_FACTORY_GUIDE.md" }

# 7: Validate example project request
check "V07: Example project request validation PASS" {
    $valJson = & "$H\scripts\validate-project-request.ps1" -ProjectRequest "$examplesDir\tiny-typescript-service.project.json" 2>&1 | ConvertFrom-Json
    $valJson.verdict -eq "PASS"
}

# 8-19: Generated run skeleton checks
$exampleRun = "$H\runs\u2-a-example-run"
check "V08: Generated run skeleton exists" { Test-Path $exampleRun }
check "V09: TASKS.json exists" { Test-Path "$exampleRun\TASKS.json" }
check "V10: ACCEPTANCE.json exists" { Test-Path "$exampleRun\ACCEPTANCE.json" }
check "V11: OWNERSHIP.json non-empty" {
    if (Test-Path "$exampleRun\OWNERSHIP.json") {
        $o = Get-Content "$exampleRun\OWNERSHIP.json" | ConvertFrom-Json
        ($o.ownershipMap.PSObject.Properties | Measure-Object).Count -gt 0
    } else { $false }
}
check "V12: interface-contract.lock.json locked=true" {
    if (Test-Path "$exampleRun\interface-contract.lock.json") {
        $c = Get-Content "$exampleRun\interface-contract.lock.json" | ConvertFrom-Json
        $c.locked -eq $true
    } else { $false }
}
check "V13: Contract has >= 3 interfaces" {
    $c = Get-Content "$exampleRun\interface-contract.lock.json" | ConvertFrom-Json
    $c.interfaces.Count -ge 3
}
check "V14: Contract has >= 1 cross-worker dependency" {
    $c = Get-Content "$exampleRun\interface-contract.lock.json" | ConvertFrom-Json
    ($c.interfaces | ? { $_.consumerWorkerIds.Count -gt 0 } | Measure).Count -ge 1
}
check "V15: Worker-1 prompt generated" { Test-Path "$exampleRun\prompts\worker-1-prompt.md" }
check "V16: Worker-2 prompt generated" { Test-Path "$exampleRun\prompts\worker-2-prompt.md" }
check "V17: Workspace dirs generated" { (Test-Path "$exampleRun\workspace\worker-1") -and (Test-Path "$exampleRun\workspace\worker-2") }
check "V18: No Worker source outputs" {
    $src = Get-ChildItem "$exampleRun\workspace\worker-*\src\*.ts" -ErrorAction SilentlyContinue
    ($src | Measure).Count -eq 0
}
check "V19: No spawn-agent-evidence.json" { -not (Test-Path "$exampleRun\spawn-agent-evidence.json") }
check "V20: No runtime reports" { -not (Test-Path "$exampleRun\reports\run-report.md") }

# 21-22: Report checks
$reportPath = "$H\outputs\PHASE_6C_U2_A_REUSABLE_FACTORY_REPORT.md"
check "V21: Final report exists" { Test-Path $reportPath }

# 23-24: Boundary checks
$t0r3zip = "$H\outputs\phase6c-t0-r3-final-audit-bundle.zip"
check "V22: T0-R3 ZIP unchanged" {
    if (Test-Path $t0r3zip) {
        (Get-FileHash $t0r3zip -Algorithm SHA256).Hash.ToLower() -eq "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
    } else { $false }
}
$u1zip = "$H\outputs\phase6c-u1-final-audit-bundle.zip"
check "V23: U1 final ZIP unchanged" {
    if (Test-Path $u1zip) {
        (Get-FileHash $u1zip -Algorithm SHA256).Hash.ToLower() -eq "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
    } else { $false }
}

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$exitCode = if ($E.Count -gt 0) { 1 } else { 0 }
@{ phase="Phase 6C-U2-A"; reportType="u2-a-verifier"; verdict=$verdict; timestamp=(Get-Date).ToString("o"); totalChecks=$total; passCount=$ok; failCount=$E.Count; passes=$P; errors=$E } | ConvertTo-Json -Depth 3
exit $exitCode
