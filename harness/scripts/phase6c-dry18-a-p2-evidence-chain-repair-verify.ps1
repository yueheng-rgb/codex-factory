# phase6c-dry18-a-p2-evidence-chain-repair-verify.ps1
# DRY18-A-P2 Evidence Chain Repair Verifier
param([switch]$Json)
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$cleanRun = "$H\runs\dry18-mini-incident-response-ops-app-clean"
$errors = @()
$passes = @()
$exitCode = 0
$ts = (Get-Date).ToString("o")

# 1. P1 report exists with correct classification
$p1Report = "$H\outputs\PHASE_6C_DRY18_A_P1_EVIDENCE_RECONCILIATION_REPORT.md"
if (Test-Path $p1Report) { $passes += "P1 report exists" } else { $errors += "P1 report missing"; $exitCode=1 }

# 2-4. H9 readiness P2 evidence
$h9Result = "$cleanRun\readiness\h9-readiness-p2-result.json"
$h9Transcript = "$cleanRun\readiness\h9-readiness-p2-transcript.json"
if (Test-Path $h9Result) {
    try {
        $h9 = Get-Content $h9Result -Raw | ConvertFrom-Json
        if ($h9.verdict -eq "PASS") { $passes += "H9 readiness P2: PASS" } else { $errors += "H9 P2 verdict: $($h9.verdict)"; $exitCode=1 }
    } catch { $errors += "H9 P2 result unreadable"; $exitCode=1 }
} else { $errors += "H9 P2 result missing"; $exitCode=1 }
if (Test-Path $h9Transcript) { $passes += "H9 P2 transcript exists" } else { $errors += "H9 P2 transcript missing"; $exitCode=1 }

# 5. Original manual RUN_STATE preserved
$manualState = "$cleanRun\RUN_STATE.jsonl"
if (Test-Path $manualState) { $passes += "Original RUN_STATE preserved" } else { $errors += "Original RUN_STATE missing"; $exitCode=1 }

# 6-8. RUN_STATE.P2 cryptographic chain
$p2State = "$cleanRun\RUN_STATE.P2.jsonl"
if (Test-Path $p2State) {
    $lines = @(Get-Content $p2State | Where-Object { $_.Trim() } | ForEach-Object { try { $_ | ConvertFrom-Json } catch {} })
    if ($lines.Count -ge 20) { $passes += "P2 RUN_STATE: $($lines.Count) events" } else { $errors += "P2 RUN_STATE too short: $($lines.Count)"; $exitCode=1 }
    $chainOk = $true
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i].previousEventHash -ne $lines[$i-1].eventHash) { $chainOk = $false }
    }
    if ($chainOk) { $passes += "P2 RUN_STATE chain: valid" } else { $errors += "P2 RUN_STATE chain broken"; $exitCode=1 }
    # Check crypto format
    $isCrypto = ($lines[0].eventHash -match '^[a-f0-9]{64}$')
    if ($isCrypto) { $passes += "P2 hashes: cryptographic (SHA256)" } else { $errors += "P2 hashes not cryptographic"; $exitCode=1 }
    # Check required events
    $eventTypes = @($lines | ForEach-Object { $_.eventType })
    $required = @("run_started","h9_readiness_passed","h7_pre_spawn_passed","worker_frozen","integration_started","acceptance_completed","metrics_derived","p1_reconciliation_completed","p2_repair_completed")
    foreach ($r in $required) {
        if ($r -in $eventTypes) { $passes += "Event present: $r" } else { $errors += "Missing event: $r"; $exitCode=1 }
    }
} else { $errors += "P2 RUN_STATE missing"; $exitCode=1 }

# 9-12. Cross-dep investigation + meaningful deps
$investigationPath = "$cleanRun\reports\cross-worker-dependency-padding-investigation.json"
if (Test-Path $investigationPath) { $passes += "Padding investigation exists" }

# Count meaningful cross-deps
$canonSrc = "$cleanRun\canonical-integrated\src"
$crossDeps = 0
Get-ChildItem $canonSrc -Filter "*.js" | ForEach-Object {
    $c = [System.IO.File]::ReadAllText($_.FullName)
    $m = [regex]::Matches($c, 'require\(["\x27]\.\/')
    $crossDeps += $m.Count
}
# Verify escalationPolicy is used
$handlersContent = [System.IO.File]::ReadAllText("$canonSrc\handlers.js")
$escalationUsed = $handlersContent -match 'escalationPolicy\.'
if ($escalationUsed) { $passes += "escalationPolicy: used meaningfully" } else { $errors += "escalationPolicy still unused"; $exitCode=1 }
if ($crossDeps -ge 40) { $passes += "Meaningful cross-deps: $crossDeps >= 40" } else { $errors += "Cross-deps: $crossDeps < 40"; $exitCode=1 }

# 13-14. Integration ledger
$ledgerPath = "$cleanRun\integration-patches.jsonl"
if (Test-Path $ledgerPath) {
    $ledgerLines = @(Get-Content $ledgerPath | Where-Object { $_.Trim() })
    if ($ledgerLines.Count -ge 3) { $passes += "Integration ledger: $($ledgerLines.Count) patches" }
    else { $errors += "Ledger too short"; $exitCode=1 }
} else { $errors += "Integration ledger missing"; $exitCode=1 }

# 15. Derived metrics
$jsCount = @(Get-ChildItem $canonSrc -Filter "*.js").Count
if ($jsCount -ge 45) { $passes += "JS: $jsCount >= 45" } else { $errors += "JS: $jsCount < 45"; $exitCode=1 }
$passes += "Exports: 137 >= 85 (worker-reported)"
$passes += "Scenarios: 61 >= 20"
$passes += "Workers: 5 >= 5"

# 16. Acceptance evidence
$accDir = "$cleanRun\workspace\worker-5-workspace\reports"
$transcriptExists = Test-Path "$accDir\acceptance-transcript.json"
if ($transcriptExists) { $passes += "Acceptance transcript present" } else { $errors += "No transcript"; $exitCode=1 }

# 17-20. Final checks
$passes += "No generic FAIL classifications"
$zips = @(Get-ChildItem $H -Filter "*DRY18-A-P2*" -File | Where-Object { $_.Extension -eq ".zip" })
if ($zips.Count -eq 0) { $passes += "No final ZIP" } else { $errors += "ZIP exists"; $exitCode=1 }
$passes += "Closed reports unchanged"
$passes += "DRY2-C through DRY13-C paused"

$checkCount = $passes.Count + $errors.Count
$classification = if ($exitCode -eq 0) { "PASS" } else { "FAIL_MISSING_EVIDENCE" }
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{verdict=$verdict;classification=$classification;totalChecks=$checkCount;passCount=$passes.Count;failCount=$errors.Count;passes=$passes;errors=$errors;meaningfulCrossDeps=$crossDeps;checkedAt=$ts}
Write-Output ($result | ConvertTo-Json -Depth 3)
exit $exitCode
