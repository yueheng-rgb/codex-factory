# phase6c-u0-f-verify.ps1 -- Phase 6C-U0-F Rework Loop Verifier v2
param([switch]$Quick)
$ErrorActionPreference = "Continue"
$utf8 = New-Object System.Text.UTF8Encoding($false)
$H = Resolve-Path (Join-Path $PSScriptRoot "..")
$posDir = Join-Path $H "runs\phase6c-u0-f-rework"
$negDir = Join-Path $H "runs\phase6c-u0-f-negative-no-rework"
$VS = Join-Path $H "scripts\validate-state.ps1"
$P = [System.Collections.ArrayList]@()
$E = [System.Collections.ArrayList]@()
$W = [System.Collections.ArrayList]@()
$total = 0; $ok = 0

function check($label, $scriptBlock) {
    $script:total++
    try {
        if (& $scriptBlock) { [void]$script:P.Add($label); $script:ok++ }
        else { [void]$script:E.Add("$label-FAIL") }
    } catch { [void]$script:E.Add("$label-ERROR: $_") }
}

# Run validate-state on positive
$posVS = & $VS -RunDir $posDir 2>&1 | Out-String
$evts = @(Get-Content (Join-Path $posDir "RUN_STATE.jsonl") | ForEach-Object { $_ | ConvertFrom-Json })

check "POS-01: validate-state run_passed" { $posVS -match '"verdict":\s*"run_passed"' }
check "POS-02: 13 events" { $evts.Count -eq 13 }
check "POS-03: rework_request_created" { (@($evts | Where-Object { $_.event -eq "rework_request_created" })).Count -eq 1 }
check "POS-04: rework_resolved" { (@($evts | Where-Object { $_.event -eq "rework_resolved" })).Count -eq 1 }
check "POS-05: rework order" {
    $req = @($evts | Where-Object { $_.event -eq "rework_request_created" })
    $res = @($evts | Where-Object { $_.event -eq "rework_resolved" })
    $req.Count -gt 0 -and $res.Count -gt 0 -and $res[0].seq -gt $req[0].seq
}
check "POS-06: both tasks verified" { (@($evts | Where-Object { $_.event -eq "task_verified" })).Count -eq 2 }
check "POS-07: honesty both PASS" {
    $h1 = Get-Content (Join-Path $posDir "reports\manifest-honesty-report-worker-1.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $h2 = Get-Content (Join-Path $posDir "reports\manifest-honesty-report-worker-2.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $h1.verdict -eq "PASS" -and $h2.verdict -eq "PASS"
}
check "POS-08: drift PASS" {
    $drift = Get-Content (Join-Path $posDir "reports\interface-drift-report.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $drift.verdict -eq "PASS"
}
check "POS-09: integration gate PASS" {
    $gate = Get-Content (Join-Path $posDir "reports\integration-gate-report.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $gate.verdict -eq "PASS"
}
check "POS-10: RW-001.json exists" { Test-Path (Join-Path $posDir "rework-requests\RW-001.json") }
check "POS-11: resolution file exists" { Test-Path (Join-Path $posDir "rework-resolutions\RW-001-resolution.json") }
check "POS-12: resolution=resolved" {
    $res = Get-Content (Join-Path $posDir "rework-resolutions\RW-001-resolution.json") -Raw -Encoding UTF8 | ConvertFrom-Json
    $res.status -eq "resolved"
}
check "POS-13: source uses formatDate" {
    $s = [System.IO.File]::ReadAllText((Join-Path $posDir "workspace\worker-2\src\app.ts"), $utf8)
    $s -match "formatDate" -and $s -notmatch "format_date"
}
check "POS-14: canonical uses formatDate" {
    $s = [System.IO.File]::ReadAllText((Join-Path $posDir "canonical-integrated\src\app.ts"), $utf8)
    $s -match "formatDate" -and $s -notmatch "format_date"
}
check "POS-15: hash chain valid" { $posVS -match "Hash chain valid" }
check "POS-16: rework gate RESOLVED" { $posVS -match "Rework RW-001: RESOLVED" }

# Negative
$negVS = & $VS -RunDir $negDir 2>&1 | Out-String
$negEvts = @(Get-Content (Join-Path $negDir "RUN_STATE.jsonl") | ForEach-Object { $_ | ConvertFrom-Json })

check "NEG-17: negative dir exists" { Test-Path $negDir }
check "NEG-18: negative run_failed" { $negVS -match '"verdict":\s*"run_failed"' }
check "NEG-19: REWORK_NO_RESOLUTION" { $negVS -match "REWORK_NO_RESOLUTION" }
check "NEG-20: MANIFEST_HONESTY_FAIL" { $negVS -match "MANIFEST_HONESTY_FAIL" }
check "NEG-21: INTEGRATION_GATE_FAIL" { $negVS -match "INTEGRATION_GATE_FAIL" }
check "NEG-22: no resolutions dir" { -not (Test-Path (Join-Path $negDir "rework-resolutions")) }
check "NEG-23: negative uses format_date" {
    $s = [System.IO.File]::ReadAllText((Join-Path $negDir "workspace\worker-2\src\app.ts"), $utf8)
    $s -match "format_date" -and $s -notmatch "formatDate"
}
check "NEG-24: req yes res no" {
    (@($negEvts | Where-Object { $_.event -eq "rework_request_created" })).Count -eq 1 -and
    (@($negEvts | Where-Object { $_.event -eq "rework_resolved" })).Count -eq 0
}

$verdict = if ($E.Count -eq 0) { "PASS" } else { "FAIL" }
$exitCode = if ($E.Count -gt 0) { 1 } else { 0 }

@{
    phase="Phase 6C-U0-F"; reportType="u0-f-verifier"; verdict=$verdict
    timestamp=(Get-Date).ToString("o"); totalChecks=$total; passCount=$ok; failCount=$E.Count
    passes=$P; errors=$E; warnings=$W
} | ConvertTo-Json -Depth 3

exit $exitCode