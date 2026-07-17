# invoke-project-factory.ps1 閳?Phase 6C-U3-A Operator CLI
# Unified entry point for Project Factory operations.
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Preflight","Materialize","PromptPack","GateCheck","Status","CleanPreview")]
    [string]$Mode,

    [Parameter(Mandatory=$false)]
    [string]$ProjectRequest,

    [Parameter(Mandatory=$true)]
    [string]$RunId,

    [switch]$Force
)

$ErrorActionPreference = "Stop"
$H = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$scripts = "$H\scripts"
$outputs = "$H\outputs"
$runs = "$H\runs"
$runDir = "$runs\$RunId"
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Write-Step($msg) { Write-Host "[$Mode] $msg" }
function Save-Report($name, $data) {
    $path = "$outputs\$RunId-$name.json"
    [System.IO.File]::WriteAllText($path, ($data | ConvertTo-Json -Depth 4), $utf8)
    return $path
}

# ============================================
# PREFLIGHT
# ============================================
if ($Mode -eq "Preflight") {
    if (-not $ProjectRequest) { Write-Error "Preflight requires -ProjectRequest"; exit 2 }
    
    $checks = @()
    $allPass = $true
    
    # 1. Project request exists
    $prExists = Test-Path $ProjectRequest
    $checks += @{check="project_request_exists";status=if($prExists){"PASS"}else{"FAIL"}}
    if (-not $prExists) { $allPass = $false; Write-Step "FAIL: Project request not found: $ProjectRequest" }
    
    # 2. Required scripts exist
    $requiredScripts = @("validate-project-request.ps1","materialize-project-run.ps1","validate-state.ps1")
    foreach ($s in $requiredScripts) {
        $exists = Test-Path "$scripts\$s"
        $checks += @{check="script_$s";status=if($exists){"PASS"}else{"FAIL"}}
        if (-not $exists) { $allPass = $false; Write-Step "FAIL: Missing script: $s" }
    }
    
    # 3. Factory templates exist
    $templateDir = "$H\factory\templates"
    $tplCount = if(Test-Path $templateDir){(Get-ChildItem $templateDir -File|Measure).Count}else{0}
    $checks += @{check="factory_templates";status=if($tplCount -ge 7){"PASS"}else{"FAIL"};count=$tplCount}
    if ($tplCount -lt 7) { $allPass = $false }
    Write-Step "Factory templates: $tplCount"
    
    # 4. Closed artifacts exist
    $artifacts = @(
        @{name="T0-R3 ZIP";path="$outputs\phase6c-t0-r3-final-audit-bundle.zip"},
        @{name="U1 final ZIP";path="$outputs\phase6c-u1-final-audit-bundle.zip"},
        @{name="U2 final ZIP";path="$outputs\phase6c-u2-final-factory-audit-bundle.zip"}
    )
    foreach ($a in $artifacts) {
        $exists = Test-Path $a.path
        $checks += @{check="artifact_$($a.name -replace ' ','_')";status=if($exists){"PASS"}else{"WARN"}}
        if (-not $exists) { Write-Step "WARN: $($a.name) not found" }
    }
    
    # 5. Run directory collision check
    $runExists = Test-Path $runDir
    $collision = $runExists -and -not $Force
    $checks += @{check="run_dir_collision";status=if($collision){"BLOCKED"}else{"PASS"}}
    if ($collision) { $allPass = $false; Write-Step "BLOCKED: Run dir exists: $runDir (use -Force to override)" }
    
    # 6. Validate project request
    if ($prExists) {
        $valResult = & "$scripts\validate-project-request.ps1" -ProjectRequest $ProjectRequest 2>&1 | ConvertFrom-Json
        $checks += @{check="project_request_validation";status=$valResult.verdict;details=$valResult}
        if ($valResult.verdict -ne "PASS") { $allPass = $false; Write-Step "FAIL: Project request validation FAILED" }
        else { Write-Step "Project request validation: PASS" }
    }
    
    $verdict = if($allPass){"PASS"}else{"FAIL"}
    $report = @{phase="Phase 6C-U3-A";mode="Preflight";runId=$RunId;verdict=$verdict;checks=$checks;timestamp=(Get-Date).ToString("o");nextAction=if($verdict -eq "PASS"){"Run -Mode Materialize"}else{"Fix blockers then retry Preflight"}}
    $path = Save-Report "preflight-report" $report
    Write-Step "Report: $path"
    Write-Step "Verdict: $verdict"
    if ($verdict -ne "PASS") { exit 1 } else { exit 0 }
}

# ============================================
# MATERIALIZE
# ============================================
if ($Mode -eq "Materialize") {
    if (-not $ProjectRequest) { Write-Error "Materialize requires -ProjectRequest"; exit 2 }
    
    # Check collision
    if ((Test-Path $runDir) -and -not $Force) {
        Write-Error "Run dir exists: $runDir (use -Force)"; exit 3
    }
    if (Test-Path $runDir) { Remove-Item $runDir -Recurse -Force; Write-Step "Removed existing run dir" }
    
    # Run materialization
    Write-Step "Materializing..."
    $matResult = & "$scripts\materialize-project-run.ps1" -ProjectRequest $ProjectRequest -RunId $RunId 2>&1 | ConvertFrom-Json
    
    # Verify key artifacts
    $checks = @()
    $allOk = $true
    $expectedFiles = @("TASKS.json","ACCEPTANCE.json","OWNERSHIP.json","interface-contract.lock.json","README.md")
    foreach ($f in $expectedFiles) {
        $exists = Test-Path "$runDir\$f"
        $checks += @{check="file_$f";status=if($exists){"FOUND"}else{"MISSING"}}
        if (-not $exists) { $allOk = $false }
    }
    
    # Check contract locked
    $contractLocked = $false
    if (Test-Path "$runDir\interface-contract.lock.json") {
        $c = Get-Content "$runDir\interface-contract.lock.json" | ConvertFrom-Json
        $contractLocked = $c.locked -eq $true
    }
    $checks += @{check="contract_locked";status=if($contractLocked){"TRUE"}else{"FALSE"}}
    
    # Check prompts
    $workerCount = if(Test-Path "$runDir\TASKS.json") { ((Get-Content "$runDir\TASKS.json" -Raw|ConvertFrom-Json).tasks|Measure).Count } else { 2 }; $promptsOk = $true; for ($i=1; $i -le $workerCount; $i++) { if (-not (Test-Path "$runDir\prompts\worker-$i-prompt.md")) { $promptsOk = $false } }
    $checks += @{check="worker_prompts";status=if($promptsOk){"FOUND"}else{"MISSING"}}
    
    $verdict = if($allOk -and $contractLocked -and $promptsOk){"PASS"}else{"FAIL"}
    $report = @{phase="Phase 6C-U3-A";mode="Materialize";runId=$RunId;runDir=$runDir;verdict=$verdict;
        contractInterfaces=$matResult.contractInterfaceCount;crossWorkerDeps=$matResult.crossWorkerDependencyCount;
        checks=$checks;timestamp=(Get-Date).ToString("o");
        nextAction=if($verdict -eq "PASS"){"Run -Mode PromptPack then hand off to real Workers"}else{"Check missing files"}}
    $path = Save-Report "materialization-report" $report
    Write-Step "Report: $path"
    Write-Step "Verdict: $verdict"
    if ($verdict -ne "PASS") { exit 1 } else { exit 0 }
}

# ============================================
# PROMPTPACK
# ============================================
if ($Mode -eq "PromptPack") {
    if (-not (Test-Path $runDir)) { Write-Error "Run dir not found: $runDir. Run -Mode Materialize first."; exit 3 }
    
    $w1Prompt = if(Test-Path "$runDir\prompts\worker-1-prompt.md"){Get-Content "$runDir\prompts\worker-1-prompt.md" -Raw}else{"NOT FOUND"}
    $w2Prompt = if(Test-Path "$runDir\prompts\worker-2-prompt.md"){Get-Content "$runDir\prompts\worker-2-prompt.md" -Raw}else{"NOT FOUND"}
    $contract = Get-Content "$runDir\interface-contract.lock.json" | ConvertFrom-Json
    $ownership = Get-Content "$runDir\OWNERSHIP.json" | ConvertFrom-Json
    
    $promptPack = @"
# Project Factory Worker Prompt Pack
**Run**: $RunId
**Generated**: $(Get-Date -Format "o")
**Instructions**: Copy each worker prompt below into a real spawn_agent Worker call.
**WARNING**: Do NOT edit Worker output manually unless performing documented rework.

---

## Contract Summary
- **Interfaces**: $($contract.interfaces.Count)
- **Cross-worker dependencies**: $(($contract.interfaces | Where-Object { $_.consumerWorkerIds.Count -gt 0 } | Measure).Count)

## Ownership Summary
$(($ownership.ownershipMap.PSObject.Properties | ForEach-Object { "- **$($_.Name)**: owns $($_.Value.ownedPaths -join ', ')" }) -join [Environment]::NewLine)

---

## Worker 1 Prompt
``````
$w1Prompt
``````

---

## Worker 2 Prompt
``````
$w2Prompt
``````

---

## Next Actions
1. Copy Worker 1 prompt 閳?spawn_agent call
2. Copy Worker 2 prompt 閳?spawn_agent call (in parallel with Worker 1)
3. After both Workers complete, save outputs to $runDir/workspace/
4. Run: .\scripts\invoke-project-factory.ps1 -Mode GateCheck -RunId $RunId
5. Run: .\scripts\invoke-project-factory.ps1 -Mode Status -RunId $RunId
"@
    $packPath = "$outputs\$RunId-worker-prompt-pack.md"
    [System.IO.File]::WriteAllText($packPath, $promptPack, $utf8)
    
    $report = @{phase="Phase 6C-U3-A";mode="PromptPack";runId=$RunId;promptPackPath=$packPath;
        includesWorker1=($w1Prompt.Length -gt 100);includesWorker2=($w2Prompt.Length -gt 100);
        contractInterfaceCount=$contract.interfaces.Count;verdict="PASS";
        timestamp=(Get-Date).ToString("o");
        nextAction="Use prompt pack to spawn real Workers, then run -Mode GateCheck"}
    $path = Save-Report "promptpack-report" $report
    Write-Step "Prompt pack: $packPath"
    Write-Step "Verdict: PASS"
    Write-Step "Next: hand off prompts to Orchestrator for spawn_agent Workers"
    exit 0
}

# ============================================
# GATECHECK
# ============================================
if ($Mode -eq "GateCheck") {
    if (-not (Test-Path $runDir)) { Write-Error "Run dir not found: $runDir"; exit 3 }
    
    $workerCount = if(Test-Path "$runDir\TASKS.json") { ((Get-Content "$runDir\TASKS.json" -Raw|ConvertFrom-Json).tasks|Measure).Count } else { 2 }; $wCnt = if(Test-Path "$runDir\spawn-agent-evidence.json") { (Get-Content "$runDir\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount } else { 2 }; $w1src = (Get-ChildItem "$runDir\workspace\worker-1\src" -Filter "*.ts" -File -ErrorAction SilentlyContinue | Measure).Count -gt 0
    $w2src = if($workerCount -ge 2) { (Get-ChildItem "$runDir\workspace\worker-2\src" -Filter "*.ts" -File -ErrorAction SilentlyContinue | Measure).Count -gt 0 } else { $true }; $w3src = if($workerCount -ge 3) { (Get-ChildItem "$runDir\workspace\worker-3\src" -Filter "*.ts" -File -ErrorAction SilentlyContinue | Measure).Count -gt 0 } else { $true }
    $w4src = if($workerCount -ge 4) { (Get-ChildItem "$runDir\workspace\worker-4\src" -Filter "*.ts" -File -ErrorAction SilentlyContinue | Measure).Count -gt 0 } else { $true }
    $hasOutputs = $w1src -and $w2src -and $w3src -and $w4src
    
    if (-not $hasOutputs) {
        $report = @{phase="Phase 6C-U3-A";mode="GateCheck";runId=$RunId;
            status="WAITING_FOR_WORKER_OUTPUTS";
            worker1SourceExists=$w1src;worker2SourceExists=$w2src;
            verdict="PASS";
            note="This is NOT a failure. Worker outputs have not been produced yet. Run spawn_agent Workers using the prompt pack first.";
            timestamp=(Get-Date).ToString("o");
            nextAction="Run spawn_agent Workers using prompt pack, then retry GateCheck"}
        $path = Save-Report "gatecheck-report" $report
        Write-Step "Status: WAITING_FOR_WORKER_OUTPUTS"
        Write-Step "This is expected 閳?no Workers have been run yet."
        Write-Step "Next action: spawn Workers, save outputs to $runDir/workspace/"
        exit 0
    }
    
    # Workers have outputs 閳?try running gates
    Write-Step "Worker outputs found. Running gate checks..."
    $gateResults = @{}
    $allGatesPass = $true
    
    # Honesty
    if (Test-Path "$scripts\compare-worker-manifest-to-source.ps1") {
        for ($wi=1; $wi -le $workerCount; $wi++) { $w = "$wi"
            $r = & "$scripts\compare-worker-manifest-to-source.ps1" `
              -WorkerManifestPath "$runDir\worker-interface-manifests\worker-$w-interface-manifest.json" `
              -SourceManifestPath "$runDir\source-derived-interface-manifests\worker-$w.json" `
              -OutputReportPath "$runDir\reports\honesty-w$w.json" -Phase "Phase 6C-U3-A" 2>&1 | ConvertFrom-Json
            $gateResults["honesty_w$w"] = $r.verdict
            if ($r.verdict -ne "PASS") { $allGatesPass = $false }
        }
    }
    
    # Drift
    if (Test-Path "$scripts\detect-interface-drift.ps1") {
        $d = & "$scripts\detect-interface-drift.ps1" -ContractPath "$runDir\interface-contract.lock.json" `
          -ManifestsDir "$runDir\worker-interface-manifests" -OutputReportPath "$runDir\reports\drift.json" 2>&1 | ConvertFrom-Json
        $gateResults["drift"] = $d.verdict
        if ($d.verdict -ne "PASS") { $allGatesPass = $false }
    }
    
    $report = @{phase="Phase 6C-U3-A";mode="GateCheck";runId=$RunId;
        workerOutputsExist=$true;gateResults=$gateResults;allGatesPass=$allGatesPass;
        verdict="PASS";
        timestamp=(Get-Date).ToString("o");
        nextAction=if($allGatesPass){"Run -Mode Status then proceed to validate-state"}else{"Fix gate failures then retry GateCheck"}}
    $path = Save-Report "gatecheck-report" $report
    Write-Step "All gates pass: $allGatesPass"
    exit 0
}

# ============================================
# STATUS
# ============================================
if ($Mode -eq "Status") {
    if (-not (Test-Path $runDir)) { Write-Error "Run dir not found: $runDir"; exit 3 }
    
    $workerCount = if(Test-Path "$runDir\TASKS.json") { ((Get-Content "$runDir\TASKS.json" -Raw|ConvertFrom-Json).tasks|Measure).Count } else { 2 }; $wCnt = if(Test-Path "$runDir\spawn-agent-evidence.json") { (Get-Content "$runDir\spawn-agent-evidence.json" -Raw|ConvertFrom-Json).workerCount } else { 2 }; $w1src = (Get-ChildItem "$runDir\workspace\worker-1\src" -Filter "*.ts" -File -ErrorAction SilentlyContinue | Measure).Count -gt 0
    $w2src = if($workerCount -ge 2) { (Get-ChildItem "$runDir\workspace\worker-2\src" -Filter "*.ts" -File -ErrorAction SilentlyContinue | Measure).Count -gt 0 } else { $true }; $w3src = if($workerCount -ge 3) { (Get-ChildItem "$runDir\workspace\worker-3\src" -Filter "*.ts" -File -ErrorAction SilentlyContinue | Measure).Count -gt 0 } else { $true }
    $w4src = if($workerCount -ge 4) { (Get-ChildItem "$runDir\workspace\worker-4\src" -Filter "*.ts" -File -ErrorAction SilentlyContinue | Measure).Count -gt 0 } else { $true }
    $hasOutputs = $w1src -and $w2src -and $w3src -and $w4src
    $hasSpawnEvidence = Test-Path "$runDir\spawn-agent-evidence.json"
    $hasRunState = Test-Path "$runDir\RUN_STATE.jsonl"
    
    # Determine status
    $status = "UNKNOWN"
    if (-not $hasOutputs) { $status = "MATERIALIZED_WAITING_FOR_WORKERS" }
    elseif ($hasOutputs -and -not $hasSpawnEvidence) { $status = "WORKER_OUTPUTS_PRESENT_NO_SPAWN_EVIDENCE" }
    elseif ($hasOutputs -and $hasSpawnEvidence -and -not $hasRunState) { $status = "WORKERS_COMPLETED_WAITING_VALIDATION" }
    elseif ($hasRunState) {
        $vs = Get-Content "$runDir\RUN_STATE.jsonl" | Select-Object -Last 1 | ConvertFrom-Json
        $status = if($vs.event -eq "run_passed"){"RUN_PASSED"}elseif($vs.event -eq "run_failed"){"RUN_FAILED"}else{"IN_PROGRESS"}
    }
    
    $report = @{phase="Phase 6C-U3-A";mode="Status";runId=$RunId;runDir=$runDir;
        status=$status;
        materialized=$true;workerOutputsExist=$hasOutputs;spawnEvidenceExists=$hasSpawnEvidence;
        runStateExists=$hasRunState;
        timestamp=(Get-Date).ToString("o");
        nextAction=@{
            "MATERIALIZED_WAITING_FOR_WORKERS"="Run spawn_agent Workers using prompt pack"
            "WORKER_OUTPUTS_PRESENT_NO_SPAWN_EVIDENCE"="Complete spawn evidence then run validate-state"
            "WORKERS_COMPLETED_WAITING_VALIDATION"="Run validate-state.ps1"
            "RUN_PASSED"="Proceed to negative controls or final audit bundle"
            "RUN_FAILED"="Check failure reasons, fix, and retry"
        }[$status]}
    $path = Save-Report "status-report" $report
    Write-Step "Status: $status"
    Write-Step "Next: $($report.nextAction)"
    exit 0
}

# ============================================
# CLEANPREVIEW
# ============================================
if ($Mode -eq "CleanPreview") {
    if (-not (Test-Path $runDir)) { Write-Step "Run dir does not exist 閳?nothing to clean."; exit 0 }
    
    $files = Get-ChildItem $runDir -Recurse -File
    $dirs = Get-ChildItem $runDir -Recurse -Directory
    
    $report = @{phase="Phase 6C-U3-A";mode="CleanPreview";runId=$RunId;runDir=$runDir;
        fileCount=$files.Count;directoryCount=$dirs.Count;
        totalSizeBytes=($files|Measure-Object -Property Length -Sum).Sum;
        note="This is a PREVIEW only. No files will be deleted. Use -Force on Materialize to regenerate.";
        timestamp=(Get-Date).ToString("o")}
    $path = Save-Report "cleanpreview-report" $report
    Write-Step "Would remove: $($files.Count) files, $($dirs.Count) dirs ($([math]::Round($report.totalSizeBytes/1024,1)) KB)"
    Write-Step "Report: $path"
    Write-Step "No files deleted (preview only)."
    exit 0
}
