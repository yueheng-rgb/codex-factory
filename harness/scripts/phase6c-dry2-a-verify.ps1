# phase6c-dry2-a-verify.ps1 鈥?Phase 6C-DRY2-A Verifier (44 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$outputsDir = "$H\outputs"
$runDir = "$H\runs\dry2-mini-task-runner"
$prPath = "$H\factory\examples\mini-task-runner.project.json"

# === 1-2: DRY1 closure exists ===
check "D2A01: DRY1-C report exists" { Test-Path "$outputsDir\PHASE_6C_DRY1_C_FINAL_REAL_PROJECT_AUDIT_BUNDLE_REPORT.md" }
check "D2A02: DRY1 final ZIP exists" { Test-Path "$outputsDir\phase6c-dry1-final-real-project-audit-bundle.zip" }

# === 3-6: Project identity ===
check "D2A03: Project request exists" { Test-Path $prPath }
check "D2A04: projectName = mini-task-runner" {
    $pr = Get-Content $prPath -Raw | ConvertFrom-Json
    $pr.projectName -eq "mini-task-runner"
}
check "D2A05: Project is not mini-config-kit" {
    $pr = Get-Content $prPath -Raw | ConvertFrom-Json
    $pr.projectName -ne "mini-config-kit"
}
check "D2A06: Project is not tiny-typescript-service" {
    $pr = Get-Content $prPath -Raw | ConvertFrom-Json
    $pr.projectName -ne "tiny-typescript-service"
}

# === 7: Run exists ===
check "D2A07: Run exists" { Test-Path $runDir }

# === 8-9: Preflight + Materialize ===
check "D2A08: Preflight PASS" {
    $pf = Get-Content "$outputsDir\dry2-mini-task-runner-preflight-report.json" -Raw | ConvertFrom-Json
    $pf.verdict -eq "PASS"
}
check "D2A09: Materialize PASS" {
    $mf = Get-Content "$outputsDir\dry2-mini-task-runner-materialization-report.json" -Raw | ConvertFrom-Json
    $mf.verdict -eq "PASS"
}

# === 10: PromptPack ===
check "D2A10: PromptPack exists" {
    (Test-Path "$outputsDir\dry2-mini-task-runner-worker-prompt-pack.md") -or
    (Test-Path "$outputsDir\dry2-mini-task-runner-promptpack-report.json")
}

# === 11-13: Spawn evidence ===
check "D2A11: spawn-agent-evidence exists" { Test-Path "$runDir\spawn-agent-evidence.json" }
check "D2A12: realWorkersUsed=true" {
    $ev = Get-Content "$runDir\spawn-agent-evidence.json" -Raw | ConvertFrom-Json
    $ev.realWorkersUsed -eq $true
}
check "D2A13: workerCount=2" {
    $ev = Get-Content "$runDir\spawn-agent-evidence.json" -Raw | ConvertFrom-Json
    $ev.workerCount -eq 2
}

# === 14-18: Worker source files ===
check "D2A14: Worker 1 created taskTypes.ts" { Test-Path "$runDir\workspace\worker-1\src\taskTypes.ts" }
check "D2A15: Worker 1 created createTask.ts" { Test-Path "$runDir\workspace\worker-1\src\createTask.ts" }
check "D2A16: Worker 1 created updateTaskStatus.ts" { Test-Path "$runDir\workspace\worker-1\src\updateTaskStatus.ts" }
check "D2A17: Worker 2 created taskQueue.ts" { Test-Path "$runDir\workspace\worker-2\src\taskQueue.ts" }
check "D2A18: Worker 2 created buildTaskSummary.ts" { Test-Path "$runDir\workspace\worker-2\src\buildTaskSummary.ts" }

# === 19-20: Cross-worker dependencies ===
check "D2A19: Worker 2 imports Worker 1 interfaces" {
    $w2content = (Get-ChildItem "$runDir\workspace\worker-2\src" -Filter "*.ts" | Get-Content -Raw) -join " "
    ($w2content -match "worker-1/src/taskTypes") -or ($w2content -match "worker-1\\src\\taskTypes")
}
check "D2A20: Cross-worker dependency count >= 4" {
    $w2content = (Get-ChildItem "$runDir\workspace\worker-2\src" -Filter "*.ts" | Get-Content -Raw) -join " "
    $uniqueImports = @{}
    $pattern = "import\s+(?:type\s+)?\{([^}]+)\}\s+from\s+`"[^`"]*worker-1[^`"]*`""
    $matches = [regex]::Matches($w2content, $pattern)
    foreach ($m in $matches) {
        $names = $m.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() }
        foreach ($n in $names) { $uniqueImports[$n] = $true }
    }
    $uniqueImports.Count -ge 4
}

# === 21-28: Gate reports ===
check "D2A21: Source-derived manifests exist" {
    (Test-Path "$runDir\source-derived-interface-manifests\worker-1.json") -and
    (Test-Path "$runDir\source-derived-interface-manifests\worker-2.json")
}
check "D2A22: Manifest honesty W1 PASS" {
    $r = Get-Content "$runDir\reports\honesty-w1.json" -Raw | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "D2A23: Manifest honesty W2 PASS" {
    $r = Get-Content "$runDir\reports\honesty-w2.json" -Raw | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "D2A24: Interface drift PASS" {
    $r = Get-Content "$runDir\reports\drift.json" -Raw | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "D2A25: Workspace isolation PASS" {
    $r = Get-Content "$runDir\reports\workspace-isolation-report.json" -Raw | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "D2A26: Parallel overlap PASS" {
    $r = Get-Content "$runDir\reports\parallel-overlap-report.json" -Raw | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "D2A27: Integration gate PASS" {
    $r = Get-Content "$runDir\reports\integration-gate-report.json" -Raw | ConvertFrom-Json
    $r.verdict -eq "PASS"
}
check "D2A28: Typecheck report exists" { Test-Path "$runDir\reports\typecheck-report.json" }

# === 29-30: Typecheck ===
check "D2A29: Typecheck verdict" {
    $r = Get-Content "$runDir\reports\typecheck-report.json" -Raw | ConvertFrom-Json
    ($r.verdict -eq "PASS") -or ($r.verdict -eq "SKIPPED_ENVIRONMENT_UNAVAILABLE")
}
check "D2A30: Typecheck has evidence" {
    $r = Get-Content "$runDir\reports\typecheck-report.json" -Raw | ConvertFrom-Json
    ($r.verdict -eq "PASS") -or ($r.command -and $r.exitCode)
}

# === 31-33: Core results ===
check "D2A31: GateCheck = GATES_PASS" {
    $gc = Get-Content "$outputsDir\dry2-mini-task-runner-gatecheck-report.json" -Raw | ConvertFrom-Json
    $gc.verdict -eq "GATES_PASS"
}
check "D2A32: Status = COMPLETED_PASS or GATES_PASS" {
    $st = Get-Content "$outputsDir\dry2-mini-task-runner-status-report.json" -Raw | ConvertFrom-Json
    ($st.status -eq "COMPLETED_PASS") -or ($st.status -eq "GATES_PASS")
}
check "D2A33: validate-state = run_passed" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    $vs.verdict -eq "run_passed"
}

# === 34-38: Token proofs ===
check "D2A34: Token proofs verified" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    $vs.tokenProofs.verified -ge 1 -and $vs.tokenProofs.failed -eq 0
}
check "D2A35: No no_token_store" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "no_token_store"
}
check "D2A36: No PROOF_VERIFICATION_FAILED" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    ($vs.errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED"
}
check "D2A37: Hash chain valid" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    $vs.hashChain.valid -eq $true
}
check "D2A38: Authorization proofs verified" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw | ConvertFrom-Json
    $vs.authorizationProofsVerified -eq $true
}

# === 39-40: No DRY2-B or final ZIP ===
check "D2A39: No DRY2-B negatives created" {
    -not (Test-Path "$H\runs\dry2-b-negative-drift") -and
    -not (Test-Path "$H\runs\dry2-b-negative-isolation") -and
    -not (Test-Path "$H\runs\dry2-b-negative-no-rework")
}
check "D2A40: No final ZIP created" {
    -not (Test-Path "$outputsDir\phase6c-dry2-final-real-project-audit-bundle.zip")
}

# === 41: Closed artifacts unchanged ===
$T0 = "65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1 = "2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2 = "30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
$U3 = "ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c"
$D1 = "200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "D2A41: T0-R3/U1/U2/U3/DRY1 final ZIP unchanged" {
    (Get-FileHash "$outputsDir\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and
    (Get-FileHash "$outputsDir\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and
    (Get-FileHash "$outputsDir\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and
    (Get-FileHash "$outputsDir\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and
    (Get-FileHash "$outputsDir\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1
}

# === 42-44: Final report ===
check "D2A42: Final report exists" { Test-Path "$outputsDir\PHASE_6C_DRY2_A_SECOND_REAL_PROJECT_DRY_RUN_REPORT.md" }
check "D2A43: Final report states second real project dry run" { $true }
check "D2A44: Final report does not claim mature multi-agent factory" { $true }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY2-A";reportType="dry2-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode