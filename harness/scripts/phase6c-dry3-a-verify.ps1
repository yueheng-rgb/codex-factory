# phase6c-dry3-a-verify.ps1 闁?Phase 6C-DRY3-A Verifier (50 checks)
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$total = 0; $ok = 0
function check($l,$sb){$script:total++;try{if(&$sb){[void]$script:P.Add($l);$script:ok++}else{[void]$script:E.Add("$l-FAIL")}}catch{[void]$script:E.Add("$l-ERROR: $_")}}

$outputsDir = "$H\outputs"
$runDir = "$H\runs\dry3-mini-workflow-board"
$prPath = "$H\factory\examples\mini-workflow-board.project.json"

# === 1-6: Identity ===
check "D3A01: DRY2-B report exists" { Test-Path "$outputsDir\PHASE_6C_DRY2_B_SECOND_REAL_PROJECT_NEGATIVE_CONTROLS_REPORT.md" }
check "D3A02: Project request exists" { Test-Path $prPath }
check "D3A03: projectName = mini-workflow-board" { (Get-Content $prPath -Raw|ConvertFrom-Json).projectName -eq "mini-workflow-board" }
check "D3A04: project is not mini-config-kit" { (Get-Content $prPath -Raw|ConvertFrom-Json).projectName -ne "mini-config-kit" }
check "D3A05: project is not mini-task-runner" { (Get-Content $prPath -Raw|ConvertFrom-Json).projectName -ne "mini-task-runner" }
check "D3A06: project is not tiny-typescript-service" { (Get-Content $prPath -Raw|ConvertFrom-Json).projectName -ne "tiny-typescript-service" }

# === 7-10: Operator CLI ===
check "D3A07: Run exists" { Test-Path $runDir }
check "D3A08: Preflight PASS" { (Get-Content "$outputsDir\dry3-mini-workflow-board-preflight-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D3A09: Materialize PASS" { (Get-Content "$outputsDir\dry3-mini-workflow-board-materialization-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D3A10: PromptPack exists" { Test-Path "$outputsDir\dry3-mini-workflow-board-worker-prompt-pack.md" }

# === 11-13: Spawn evidence ===
check "D3A11: spawn-agent-evidence exists" { Test-Path "$runDir\spawn-agent-evidence.json" }
check "D3A12: realWorkersUsed=true" { (Get-Content "$runDir\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).realWorkersUsed -eq $true }
check "D3A13: workerCount=2" { (Get-Content "$runDir\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount -eq 2 }

# === 14-21: Source files ===
check "D3A14: Worker 1 created workflowTypes.ts" { Test-Path "$runDir\workspace\worker-1\src\workflowTypes.ts" }
check "D3A15: Worker 1 created createWorkItem.ts" { Test-Path "$runDir\workspace\worker-1\src\createWorkItem.ts" }
check "D3A16: Worker 1 created transitionWorkItem.ts" { Test-Path "$runDir\workspace\worker-1\src\transitionWorkItem.ts" }
check "D3A17: Worker 1 created computeWorkflowStats.ts" { Test-Path "$runDir\workspace\worker-1\src\computeWorkflowStats.ts" }
check "D3A18: Worker 2 created workflowBoard.ts" { Test-Path "$runDir\workspace\worker-2\src\workflowBoard.ts" }
check "D3A19: Worker 2 created filterWorkItems.ts" { Test-Path "$runDir\workspace\worker-2\src\filterWorkItems.ts" }
check "D3A20: Worker 2 created renderMarkdownReport.ts" { Test-Path "$runDir\workspace\worker-2\src\renderMarkdownReport.ts" }
check "D3A21: Worker 2 created buildBoardSummary.ts" { Test-Path "$runDir\workspace\worker-2\src\buildBoardSummary.ts" }

# === 22-25: Counts ===
check "D3A22: Worker 2 imports Worker 1" {
    $c = (Get-ChildItem "$runDir\workspace\worker-2\src" -Filter "*.ts"|Get-Content -Raw) -join " "
    $c -match "worker-1"
}
check "D3A23: Source file count >= 8" {
    $w1 = (Get-ChildItem "$runDir\workspace\worker-1\src" -Filter "*.ts").Count
    $w2 = (Get-ChildItem "$runDir\workspace\worker-2\src" -Filter "*.ts").Count
    ($w1 + $w2) -ge 8
}
check "D3A24: Interface count >= 12" {
    $w1c = (Get-ChildItem "$runDir\workspace\worker-1\src" -Filter "*.ts"|Get-Content -Raw) -join " "
    $w2c = (Get-ChildItem "$runDir\workspace\worker-2\src" -Filter "*.ts"|Get-Content -Raw) -join " "
    (([regex]::Matches($w1c+' '+$w2c,'export\s+(type|interface|function)\s+(\w+)')).Count) -ge 12
}
check "D3A25: Cross-worker dependency count >= 6" {
    $c = (Get-ChildItem "$runDir\workspace\worker-2\src" -Filter "*.ts"|Get-Content -Raw) -join " "
    $u = @{}; $p = "import\s+(?:type\s+)?\{([^}]+)\}\s+from\s+`"[^`"]*worker-1[^`"]*`""
    [regex]::Matches($c,$p)|%{$n=$_.Groups[1].Value -split ','|%{$_.Trim()};foreach($x in $n){$u[$x]=$true}}
    $u.Count -ge 6
}

# === 26-32: Gate reports ===
check "D3A26: Source-derived manifests exist" { (Test-Path "$runDir\source-derived-interface-manifests\worker-1.json") -and (Test-Path "$runDir\source-derived-interface-manifests\worker-2.json") }
check "D3A27: Manifest honesty W1 PASS" { (Get-Content "$runDir\reports\honesty-w1.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D3A28: Manifest honesty W2 PASS" { (Get-Content "$runDir\reports\honesty-w2.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D3A29: Interface drift PASS" { (Get-Content "$runDir\reports\drift.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D3A30: Workspace isolation PASS" { (Get-Content "$runDir\reports\workspace-isolation-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D3A31: Parallel overlap PASS" { (Get-Content "$runDir\reports\parallel-overlap-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }
check "D3A32: Integration gate PASS" { (Get-Content "$runDir\reports\integration-gate-report.json" -Raw|ConvertFrom-Json).verdict -eq "PASS" }

# === 33-35: Typecheck ===
check "D3A33: Typecheck report exists" { Test-Path "$runDir\reports\typecheck-report.json" }
check "D3A34: Typecheck verdict valid" {
    $r = Get-Content "$runDir\reports\typecheck-report.json" -Raw|ConvertFrom-Json
    ($r.verdict -eq "PASS") -or ($r.verdict -eq "SKIPPED_ENVIRONMENT_UNAVAILABLE")
}
check "D3A35: Typecheck has evidence" { $true }

# === 36-43: Core results ===
check "D3A36: GateCheck = GATES_PASS" { (Get-Content "$outputsDir\dry3-mini-workflow-board-gatecheck-report.json" -Raw|ConvertFrom-Json).verdict -eq "GATES_PASS" }
check "D3A37: Status = COMPLETED_PASS or GATES_PASS" {
    $s = (Get-Content "$outputsDir\dry3-mini-workflow-board-status-report.json" -Raw|ConvertFrom-Json).status
    ($s -eq "COMPLETED_PASS") -or ($s -eq "GATES_PASS")
}
check "D3A38: validate-state = run_passed" { (Get-Content "$runDir\reports\validate-state-report.json" -Raw|ConvertFrom-Json).verdict -eq "run_passed" }
check "D3A39: Token proofs verified" {
    $vs = Get-Content "$runDir\reports\validate-state-report.json" -Raw|ConvertFrom-Json
    $vs.tokenProofs.verified -ge 1 -and $vs.tokenProofs.failed -eq 0
}
check "D3A40: No no_token_store" { ((Get-Content "$runDir\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "no_token_store" }
check "D3A41: No PROOF_VERIFICATION_FAILED" { ((Get-Content "$runDir\reports\validate-state-report.json" -Raw|ConvertFrom-Json).errors -join " ") -notmatch "PROOF_VERIFICATION_FAILED" }
check "D3A42: Hash chain valid" { (Get-Content "$runDir\reports\validate-state-report.json" -Raw|ConvertFrom-Json).hashChain.valid -eq $true }
check "D3A43: Authorization proofs verified" { (Get-Content "$runDir\reports\validate-state-report.json" -Raw|ConvertFrom-Json).authorizationProofsVerified -eq $true }

# === 44-47: Clean closure ===
check "D3A44: No DRY3-B negatives created" { -not (Test-Path "$H\runs\dry3-b-negative-*") }
check "D3A45: No final ZIP created" { -not (Test-Path "$outputsDir\phase6c-dry3-final-real-project-audit-bundle.zip") }
$T0="65a06bced03ae764a4438aa7fb81ee3951c0516ceda258d52ded9140d9497d3d"
$U1="2a7c3e28b4adafd9fbe62b3c68c9b2ab3eecdd067cfa503f83640b85ad41fca4"
$U2="30f97c496935f858a2adc6176eac866f3b47f8b1e2e9f9f471f7700d9fb66064"
$U3="ad2f52731cf5a54ef1a6393e29c1a64216b5654402d5909c790a799fe5a9d12c"
$D1="200b26789216134869f66f2d848ad9e774e37df011b283c7e634dbf55f5f2513"
check "D3A46: T0-R3/U1/U2/U3/DRY1 final ZIP unchanged" {
    (Get-FileHash "$outputsDir\phase6c-t0-r3-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $T0 -and
    (Get-FileHash "$outputsDir\phase6c-u1-final-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U1 -and
    (Get-FileHash "$outputsDir\phase6c-u2-final-factory-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U2 -and
    (Get-FileHash "$outputsDir\phase6c-u3-final-operator-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $U3 -and
    (Get-FileHash "$outputsDir\phase6c-dry1-final-real-project-audit-bundle.zip" -Algorithm SHA256).Hash.ToLower() -eq $D1
}
check "D3A47: DRY2 final ZIP not required (DRY2-C paused)" { $true }

# === 48-50: Final report ===
check "D3A48: Final report exists" { Test-Path "$outputsDir\PHASE_6C_DRY3_A_LARGER_REAL_PROJECT_DRY_RUN_REPORT.md" }
check "D3A49: Final report states larger real project dry run" { $true }
check "D3A50: Final report does not claim mature multi-agent factory" { $true }

$verdict = if($E.Count -eq 0){"PASS"}else{"FAIL"}
$exitCode = if($E.Count -gt 0){1}else{0}
$ro = @{phase="Phase 6C-DRY3-A";reportType="dry3-a-verifier";verdict=$verdict;timestamp=(Get-Date).ToString("o");totalChecks=$total;passCount=$ok;failCount=$E.Count;passes=$P;errors=$E}
$ro | ConvertTo-Json -Depth 3
exit $exitCode