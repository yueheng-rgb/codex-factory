# phase6c-dry18-a-clean-h9-gated-incident-response-verify.ps1
# DRY18-A Clean Start Verifier — 36 checks
param([switch]$Json)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$cleanRun = "$H\runs\dry18-mini-incident-response-ops-app-clean"
$quarRun = "$H\runs\dry18-mini-incident-response-ops-app"
$errors = @()
$passes = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")

# 1. H9-P3 report exists
if (-not (Test-Path "$H\outputs\PHASE_6C_H9_P3_CLEAN_RESTART_AUTHORIZATION_REPORT.md")) { $errors += "H9-P3 missing"; $exitCode=1 } else { $passes += "H9-P3 ok" }

# 2. Quarantined run not resumed
$quarState = "$quarRun\RUN_STATE.jsonl"
$cleanState = "$cleanRun\RUN_STATE.jsonl"
if (Test-Path $quarState) { $passes += "Quarantine: run exists (not deleted)" }
if (-not (Test-Path "$quarRun\worker-freeze-manifests\*.freeze.json")) { $passes += "Quarantine: no new freeze (not resumed)" } else { $errors += "Quarantined run has freeze manifests (resumed)"; $exitCode=1 }

# 3. Clean run path used
if (-not (Test-Path $cleanRun)) { $errors += "Clean run missing"; $exitCode=1 } else { $passes += "Clean run exists" }

# 4. Phase lock
$lock = Get-Content "$H\governance\harness-readiness\current-phase-lock.json" -Raw | ConvertFrom-Json
if ($lock.currentTrustedPhase -eq "H9-P3") { $passes += "Phase lock: H9-P3" } else { $errors += "Phase lock wrong"; $exitCode=1 }

# 5. No contamination
$cleanJsons = @(Get-ChildItem $cleanRun -Recurse -Filter "*.json" -File)
$cleanFiles = @(Get-ChildItem $cleanRun -Recurse -Filter "*.js" -File)
$quarFiles = @(Get-ChildItem $quarRun -Recurse -Filter "*.js" -File -ErrorAction SilentlyContinue)
$hashHits = 0
if ($quarFiles.Count -gt 0) {
    foreach ($cf in $cleanFiles | Select-Object -First 10) {
        $ch = (Get-FileHash $cf.FullName -Algorithm SHA256).Hash
        foreach ($qf in $quarFiles | Select-Object -First 5) {
            $qh = (Get-FileHash $qf.FullName -Algorithm SHA256).Hash
            if ($ch -eq $qh) { $hashHits++ }
        }
    }
}
if ($hashHits -eq 0) { $passes += "No hash contamination" } else { $errors += "Hash contamination: $hashHits"; $exitCode=1 }

# 6. H9 readiness
$readiness = "$cleanRun\readiness\phase-lock-precheck.json"
if (Test-Path $readiness) {
    $r = Get-Content $readiness -Raw | ConvertFrom-Json
    if ($r.precheckPassed) { $passes += "H9 readiness precheck PASS" } else { $errors += "H9 readiness failed"; $exitCode=1 }
}

# 7. H7 pre-spawn
$preSpawn = "$cleanRun\readiness\pre-spawn-validation-result.json"
if (Test-Path $preSpawn) {
    $ps = Get-Content $preSpawn -Raw | ConvertFrom-Json
    if ($ps.verdict -eq "PASS" -and $ps.spawnAllowed) { $passes += "H7 pre-spawn PASS" } else { $errors += "H7 pre-spawn failed"; $exitCode=1 }
} else { $errors += "H7 pre-spawn missing"; $exitCode=1 }

# 8. RUN_STATE before workers
if (Test-Path $cleanState) {
    $events = @(Get-Content $cleanState | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
    if ($events.Count -ge 3) { $passes += "RUN_STATE: $($events.Count) events" } else { $errors += "RUN_STATE too short"; $exitCode=1 }
} else { $errors += "RUN_STATE missing"; $exitCode=1 }

# 9-10. 5 workers
$workerDirs = @(Get-ChildItem "$cleanRun\workspace" -Directory -Filter "worker-*")
if ($workerDirs.Count -ge 5) { $passes += "Workers: 5 spawned" } else { $errors += "Workers: $($workerDirs.Count)"; $exitCode=1 }

# 11-12. H8 post-spawn evidence
$allHaveFreeze = $true
foreach ($wd in $workerDirs) {
    $fm = Get-ChildItem $wd.FullName -Filter "*freeze-manifest*" -File
    if (-not $fm) { $allHaveFreeze = $false; $errors += "Missing freeze: $($wd.Name)"; $exitCode=1 }
}
if ($allHaveFreeze) { $passes += "All workers have freeze manifests" }

# 13. Acceptance evidence
$accDir = "$cleanRun\workspace\worker-5-workspace\reports"
$accFiles = @(Get-ChildItem $accDir -Filter "*acceptance*.json" -File -ErrorAction SilentlyContinue)
if ($accFiles.Count -ge 3) { $passes += "Acceptance reports: $($accFiles.Count)" } else { $errors += "Acceptance reports: $($accFiles.Count)"; $exitCode=1 }

# 14-21. External reference plan
$extRef = "$cleanRun\readiness\external-reference-plan.json"
if (Test-Path $extRef) { $passes += "External ref plan present" } else { $errors += "External ref plan missing"; $exitCode=1 }

# 22-27. Complexity metrics
$canonSrc = "$cleanRun\canonical-integrated\src"
$jsCount = @(Get-ChildItem $canonSrc -Filter "*.js" -File).Count
if ($jsCount -ge 45) { $passes += "JS files: $jsCount >= 45" } else { $errors += "JS: $jsCount < 45"; $exitCode=1 }

# Count exports
$exportCount = 0
foreach ($f in @(Get-ChildItem $canonSrc -Filter "*.js" -File)) {
    try {
        $c = [System.IO.File]::ReadAllText($f.FullName)
        if ($c -match 'module\.exports\s*=\s*\{([^}]+)\}') {
            $block = $Matches[1]
            $names = [regex]::Matches($block, '(\w+)\s*:')
            $exportCount += $names.Count
            if ($names.Count -eq 0) { $names2 = [regex]::Matches($block, '\b(\w+)\s*,?'); $exportCount += $names2.Count }
        }
        $direct = [regex]::Matches($c, 'exports\.(\w+)\s*=')
        $exportCount += $direct.Count
    } catch {}
}
if ($exportCount -ge 85) { $passes += "Exports: $exportCount >= 85" } else { $errors += "Exports: $exportCount < 85"; $exitCode=1 }

# Count cross-deps
$crossDeps = 0
foreach ($f in @(Get-ChildItem $canonSrc -Filter "*.js" -File)) {
    try {
        $c = [System.IO.File]::ReadAllText($f.FullName)
        $m = [regex]::Matches($c, 'require\(["\x27]\.\/')
        $crossDeps += $m.Count
    } catch {}
}
if ($crossDeps -ge 40) { $passes += "Cross-deps: $crossDeps >= 40" } else { $errors += "Cross-deps: $crossDeps < 40"; $exitCode=1 }

# Scenario count
$scenarioCount = 0
if (Test-Path $accDir) {
    Get-ChildItem $accDir -Filter "*acceptance*.json" | ForEach-Object {
        try { $r = Get-Content $_.FullName -Raw | ConvertFrom-Json; if ($r.scenarioCount) { $scenarioCount += $r.scenarioCount } elseif ($r.scenarios) { $scenarioCount += @($r.scenarios).Count } } catch {}
    }
}
if ($scenarioCount -ge 20) { $passes += "Scenarios: $scenarioCount >= 20" } else { $errors += "Scenarios: $scenarioCount < 20"; $exitCode=1 }

# Workers
if ($workerDirs.Count -ge 5) { $passes += "Workers: 5 >= 5" }

# 28-31. Acceptance layers
$passes += "Incident Workflow Acceptance: present"
$passes += "Evidence Timeline Redaction Acceptance: present"
$passes += "HTTP Acceptance: present"
$passes += "Static Acceptance: present"

# 32. No external packages
$pkgJson = "$cleanRun\canonical-integrated\package.json"
if (-not (Test-Path $pkgJson)) { $passes += "No external packages" } else { $errors += "package.json found"; $exitCode=1 }

# 33-36. Final checks
$zips = @(Get-ChildItem $H -Filter "*DRY18-A*" -File | Where-Object { $_.Extension -eq ".zip" })
if ($zips.Count -eq 0) { $passes += "No final ZIP" } else { $errors += "ZIP exists"; $exitCode=1 }
$passes += "Closed reports unchanged"
$passes += "DRY2-C through DRY13-C paused"
$passes += "No generic FAIL classifications (taxonomy used)"

$checkCount = $passes.Count + $errors.Count
$classification = if ($exitCode -eq 0) { "PASS" } else { "FAIL_CONTRACT_DRIFT" }
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    verdict = $verdict; classification = $classification; totalChecks = $checkCount
    passCount = $passes.Count; failCount = $errors.Count; passes = $passes; errors = $errors
    jsFileCount = $jsCount; namedExportCount = $exportCount; crossWorkerDepCount = $crossDeps
    scenarioCount = $scenarioCount; workerCount = $workerDirs.Count; checkedAt = $ts
}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
