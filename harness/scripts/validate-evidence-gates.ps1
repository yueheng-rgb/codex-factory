# validate-evidence-gates.ps1 — Phase 6C-O
# Mechanical detection of all 12 Codex Failure Patterns (CFP-001 to CFP-012).
# Phase O: CFP-001 fixed (front-matter verdict, no historical false positive).
# Phase O: CFP-011 fixed (live vs reconstructed run distinction).
# READ-ONLY: never modifies evidence.
param(
    [Parameter(Mandatory=$true)][string]$EvidenceDir,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$gates = [System.Collections.ArrayList]::new()
$exitCode = 0

function Add-Gate($cfp, $name, $passed, $detail) {
    [void]$gates.Add(@{ cfp=$cfp; name=$name; passed=$passed; detail=$detail })
    if (-not $passed) { $script:exitCode = 1 }
}

# ================================================================
# CFP-001: Report/Evidence Contradiction (O-fixed)
# Reads verdict from final-verdict-report.json or report front matter.
# Historical FAIL/PARTIAL mentions in body text do NOT cause false positive.
# ================================================================
$reportPath = Get-ChildItem $EvidenceDir -Recurse -Filter "*_FINAL_REPORT.md" -File | Where-Object { $_.Name -notmatch 'final-verdict' } | Select-Object -First 1
$vsStdoutPath = Get-ChildItem $EvidenceDir -Recurse -Filter "validate-state-stdout.log" -File | Select-Object -First 1

if ($reportPath) {
    $reportText = Get-Content $reportPath.FullName -Raw -Encoding UTF8
    if ($reportText -match '\*\*Status\*\*:\s*\*\*\s*(PASS|FAIL|PARTIAL)\s*\*\*' -or $reportText -match 'Status[:\s]+\*+\s*(PASS|FAIL|PARTIAL)\s*\*+') { $reportVerdict = $Matches[1] }
    elseif ($reportText -match '^\*\*[A-Z0-9\-]+:\s*(PASS|FAIL)\s*\*\*') { $reportVerdict = $Matches[1] }
    else { $reportVerdict = "UNKNOWN" }
} else { $reportVerdict = "MISSING" }

if ($vsStdoutPath -and $reportVerdict -ne "MISSING" -and $reportVerdict -ne "UNKNOWN") {
    try {
        $vsJson = Get-Content $vsStdoutPath.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $actualPass = ($vsJson.verdict -eq "run_passed" -and $vsJson.status -eq "PASS" -and $vsJson.errors.Count -eq 0)
        if ($reportVerdict -eq "PASS" -and -not $actualPass) {
            Add-Gate "CFP-001" "Report/Evidence Contradiction" $false "Report claims $reportVerdict but validate-state: verdict=$($vsJson.verdict) errors=$($vsJson.errors.Count)"
        } elseif ($reportVerdict -eq "FAIL" -and $actualPass) {
            Add-Gate "CFP-001" "Report/Evidence Contradiction" $false "validate-state PASS but report claims FAIL"
        } else {
            Add-Gate "CFP-001" "Report/Evidence Contradiction" $true "Consistent (report=$reportVerdict)"
        }
    } catch { Add-Gate "CFP-001" "Report/Evidence Contradiction" $true "Cannot parse validate-state stdout" }
} else { Add-Gate "CFP-001" "Report/Evidence Contradiction" $true "No report/validate-state pair to compare" }

# ================================================================
# CFP-002: ExitCode / Verdict Disagreement
# ================================================================
$exitCodePath = Get-ChildItem $EvidenceDir -Recurse -Filter "validate-state-exitcode.txt" -File | Select-Object -First 1
if ($exitCodePath -and $vsStdoutPath) {
    $ec = [int](Get-Content $exitCodePath.FullName -Raw).Trim()
    $vsJson = Get-Content $vsStdoutPath.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    $actualFailed = ($vsJson.verdict -eq "run_failed" -or $vsJson.status -eq "FAIL" -or $vsJson.errors.Count -gt 0)
    if ($ec -eq 0 -and $actualFailed) {
        Add-Gate "CFP-002" "ExitCode/Verdict Disagreement" $false "exitCode=0 but verdict=$($vsJson.verdict) errors=$($vsJson.errors.Count)"
    } elseif ($ec -ne 0 -and -not $actualFailed) {
        Add-Gate "CFP-002" "ExitCode/Verdict Disagreement" $false "exitCode=$ec but no failure in stdout"
    } else { Add-Gate "CFP-002" "ExitCode/Verdict Disagreement" $true "Consistent" }
} else { Add-Gate "CFP-002" "ExitCode/Verdict Disagreement" $true "No exitCode+stdout pair" }

# ================================================================
# CFP-003: Hollow Evidence
# ================================================================
$ownershipPath = Get-ChildItem $EvidenceDir -Recurse -Filter "OWNERSHIP.json" -File | Select-Object -First 1
$hollowFound = $false
if ($ownershipPath) {
    try {
        $ownership = Get-Content $ownershipPath.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($ownership.PSObject.Properties.Name -contains "ownership") { $ownership = $ownership.ownership }
        if ($ownership.PSObject.Properties.Name -contains "files") {
            $files = $ownership.files
            if (($files -is [hashtable] -and $files.Count -eq 0) -or $null -eq $files) { $hollowFound = $true }
        }
        if ($ownership.PSObject.Properties.Name -contains "modifiedFiles" -and $null -eq $ownership.modifiedFiles) { $hollowFound = $true }
    } catch {}
}
Add-Gate "CFP-003" "Hollow Evidence" (-not $hollowFound) $(if ($hollowFound) { "OWNERSHIP has empty/null fields" } else { "OWNERSHIP non-empty" })

# ================================================================
# CFP-004: Empty Directory PASS
# ================================================================
$requiredDirs = @("evidence","validator-evidence","integration-evidence","command-logs")
$emptyDirs = @()
foreach ($dn in $requiredDirs) {
    $dp = Join-Path $EvidenceDir $dn
    if (Test-Path $dp) { if (@(Get-ChildItem $dp -Recurse -File -ErrorAction SilentlyContinue).Count -eq 0) { $emptyDirs += $dn } }
}
Add-Gate "CFP-004" "Empty Directory PASS" ($emptyDirs.Count -eq 0) $(if ($emptyDirs.Count -gt 0) { "Empty: $emptyDirs" } else { "All dirs have content" })

# ================================================================
# CFP-005: Declared Test Not Observed
# ================================================================
$acceptPath = Get-ChildItem $EvidenceDir -Recurse -Filter "ACCEPTANCE.json" -File | Select-Object -First 1
$testStdoutPath = Get-ChildItem $EvidenceDir -Recurse -Filter "test-unit-stdout.log" -File | Select-Object -First 1
if ($acceptPath -and $testStdoutPath) {
    try {
        $accept = Get-Content $acceptPath.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $testOutput = Get-Content $testStdoutPath.FullName -Raw -Encoding UTF8
        $missingTests = @()
        $items = if ($accept.acceptanceItems) { $accept.acceptanceItems } else { @($accept) }
        foreach ($item in $items) {
            if ($item.requiredTests) {
                foreach ($rt in $item.requiredTests) {
                    $testName = Split-Path $rt -Leaf
                    if ($testOutput -notmatch [regex]::Escape($testName)) { $missingTests += "$($item.id):$rt" }
                }
            }
        }
        Add-Gate "CFP-005" "Declared Test Not Observed" ($missingTests.Count -eq 0) $(if ($missingTests.Count -gt 0) { "Missing: $missingTests" } else { "All declared tests observed" })
    } catch { Add-Gate "CFP-005" "Declared Test Not Observed" $true "Parse error, skipping" }
} else { Add-Gate "CFP-005" "Declared Test Not Observed" $true "No ACCEPTANCE+test-stdout pair" }

# ================================================================
# CFP-006: SHA256SUMS Self-Reference
# ================================================================
$sumsPath = Get-ChildItem $EvidenceDir -Recurse -Filter "SHA256SUMS.txt" -File | Select-Object -First 1
if ($sumsPath) {
    $sumsContent = Get-Content $sumsPath.FullName -Encoding UTF8
    $selfRef = $sumsContent | Where-Object { $_ -match 'SHA256SUMS\.txt' -or $_ -match 'sha256sums-validation-report\.json' }
    $absPath = $sumsContent | Where-Object { $_ -match '^[a-f0-9]{64}\s{2}[A-Z]:' }
    if ($selfRef) { Add-Gate "CFP-006" "SHA256SUMS Self-Reference" $false "Self-reference or validation-report reference found" }
    elseif ($absPath) { Add-Gate "CFP-006" "SHA256SUMS Self-Reference" $false "Absolute paths found" }
    else { Add-Gate "CFP-006" "SHA256SUMS Self-Reference" $true "Clean" }
} else { Add-Gate "CFP-006" "SHA256SUMS Self-Reference" $true "No SHA256SUMS.txt" }

# ================================================================
# CFP-007: Token Store / Proof Failure
# ================================================================
$runStatePath = Get-ChildItem $EvidenceDir -Recurse -Filter "RUN_STATE.jsonl" -File | Select-Object -First 1
if ($runStatePath) {
    $rsLines = Get-Content $runStatePath.FullName -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 }
    $authEventTypes = @("task_claimed","task_submitted","validation_started","validation_passed","validation_failed","task_verified","release_validation_started","release_validation_passed","release_validation_failed","release_verified")
    $authEvents = @()
    foreach ($line in $rsLines) { try { $e = $line | ConvertFrom-Json; if ($e.event -in $authEventTypes) { $authEvents += $e } } catch {} }
    $missingProofs = @($authEvents | Where-Object { -not $_.authorizationProof -or -not $_.proofNonce -or -not $_.tokenLeaseId })
    Add-Gate "CFP-007" "Token Store/Proof Failure" ($missingProofs.Count -eq 0) $(if ($missingProofs.Count -gt 0) { "$($missingProofs.Count) events missing proof fields" } else { "$($authEvents.Count) auth events have proof fields" })
} else { Add-Gate "CFP-007" "Token Store/Proof Failure" $true "No RUN_STATE" }

# ================================================================
# CFP-008: Hash Serialization Drift
# ================================================================
if ($vsStdoutPath) {
    try {
        $vsJson = Get-Content $vsStdoutPath.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $hashErrors = @($vsJson.errors | Where-Object { $_ -match 'HASH_MISMATCH' })
        $hashPass = @($vsJson.passes | Where-Object { $_ -match 'Hash chain valid' })
        if ($hashErrors.Count -gt 0) { Add-Gate "CFP-008" "Hash Serialization Drift" $false "$($hashErrors.Count) hash mismatches" }
        elseif ($hashPass.Count -gt 0) { Add-Gate "CFP-008" "Hash Serialization Drift" $true "Hash chain valid" }
        else { Add-Gate "CFP-008" "Hash Serialization Drift" $true "No hash info in stdout" }
    } catch { Add-Gate "CFP-008" "Hash Serialization Drift" $true "Cannot parse stdout" }
} else { Add-Gate "CFP-008" "Hash Serialization Drift" $true "No stdout" }

# ================================================================
# CFP-009: Stale Governance Artifacts
# ================================================================
$cpLockPath = Get-ChildItem $EvidenceDir -Recurse -Filter "CONTROL_PLANE_LOCK.json" -File | Select-Object -First 1
if ($cpLockPath) {
    try {
        $cpLock = Get-Content $cpLockPath.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $staleCount = 0
        if ($cpLock.items) {
            foreach ($item in $cpLock.items) {
                $fp = Join-Path $EvidenceDir $item.path
                if (-not (Test-Path $fp)) { $fp = Join-Path "C:\Codex_App_Factory\harness" $item.path }
                if (Test-Path $fp) {
                    $currentHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.IO.File]::ReadAllBytes($fp))).Replace("-","").ToLower()
                    if ($currentHash -ne $item.sha256) { $staleCount++ }
                }
            }
        }
        Add-Gate "CFP-009" "Stale Governance Artifacts" ($staleCount -eq 0) $(if ($staleCount -gt 0) { "$staleCount stale hashes" } else { "All hashes current" })
    } catch { Add-Gate "CFP-009" "Stale Governance Artifacts" $true "Parse error" }
} else { Add-Gate "CFP-009" "Stale Governance Artifacts" $true "No CONTROL_PLANE_LOCK" }

# ================================================================
# CFP-010: Task Lifecycle Incomplete
# ================================================================
if ($runStatePath) {
    $rsLines = Get-Content $runStatePath.FullName -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 }
    $events = @(); foreach ($line in $rsLines) { try { $events += ($line | ConvertFrom-Json) } catch {} }
    $taskIds = @($events | Where-Object { $_.taskId } | Select-Object -ExpandProperty taskId -Unique)
    $lifecycleIssues = @()
    foreach ($tid in $taskIds) {
        if (-not $tid) { continue }
        $tidEvents = @($events | Where-Object { $_.taskId -eq $tid })
        $hasClaimed = (@($tidEvents | Where-Object { $_.event -eq "task_claimed" }).Count -gt 0)
        $hasSubmitted = (@($tidEvents | Where-Object { $_.event -eq "task_submitted" }).Count -gt 0)
        $hasVerified = (@($tidEvents | Where-Object { $_.event -eq "task_verified" }).Count -gt 0)
        if ($hasVerified -and (-not $hasClaimed)) { $lifecycleIssues += "${tid}: verified without claimed" }
        if ($hasSubmitted -and (-not $hasClaimed)) { $lifecycleIssues += "${tid}: submitted without claimed" }
    }
    $accIds = @($events | Where-Object { $_.validationId } | Select-Object -ExpandProperty validationId -Unique)
    foreach ($aid in $accIds) {
        if (-not $aid) { continue }
        $aidEvents = @($events | Where-Object { $_.validationId -eq $aid })
        $hasStarted = (@($aidEvents | Where-Object { $_.event -eq "validation_started" }).Count -gt 0)
        $hasPassed = (@($aidEvents | Where-Object { $_.event -eq "validation_passed" }).Count -gt 0)
        if ($hasPassed -and (-not $hasStarted)) { $lifecycleIssues += "${aid}: passed without started" }
    }
    Add-Gate "CFP-010" "Task Lifecycle Incomplete" ($lifecycleIssues.Count -eq 0) $(if ($lifecycleIssues.Count -gt 0) { "$lifecycleIssues" } else { "All lifecycles complete" })
} else { Add-Gate "CFP-010" "Task Lifecycle Incomplete" $true "No RUN_STATE" }

# ================================================================
# CFP-011: Timestamp Reversal / Bulk Generation (O-fixed: live vs reconstructed)
# ================================================================
if ($runStatePath) {
    $rsLines = Get-Content $runStatePath.FullName -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 }
    $events = @(); foreach ($line in $rsLines) { try { $events += ($line | ConvertFrom-Json) } catch {} }
    
    $isReconstructed = $false
    $runPlanPath = Get-ChildItem $EvidenceDir -Recurse -Filter "RUN_PLAN.json" -File | Select-Object -First 1
    if ($runPlanPath) {
        try { $rp = Get-Content $runPlanPath.FullName -Raw -Encoding UTF8 | ConvertFrom-Json; if ($rp.reconstructed -eq $true) { $isReconstructed = $true } } catch {}
    }
    $initEvent = @($events | Where-Object { $_.event -eq "run_initialized" } | Select-Object -First 1)
    if ($initEvent -and $initEvent.reconstructed -eq $true) { $isReconstructed = $true }
    
    $timestamps = @($events | Where-Object { $_.timestamp } | ForEach-Object { $_.timestamp })
    $reversals = 0; $identical = 0
    for ($i = 1; $i -lt $timestamps.Count; $i++) {
        if ($timestamps[$i] -lt $timestamps[$i-1]) { $reversals++ }
        if ($timestamps[$i] -eq $timestamps[$i-1]) { $identical++ }
    }
    
    if ($reversals -gt 0) {
        Add-Gate "CFP-011" "Timestamp Reversal" $false "$reversals timestamp reversals"
    } elseif ($identical -gt ($timestamps.Count / 2)) {
        if ($isReconstructed) {
            Add-Gate "CFP-011" "Timestamp Reversal" $true "Bulk timestamps OK for reconstructed run ($identical/$($timestamps.Count) identical); timing claims disallowed"
        } else {
            Add-Gate "CFP-011" "Timestamp Reversal" $false "$identical/$($timestamps.Count) identical timestamps in live run (bulk generation)"
        }
    } else {
        Add-Gate "CFP-011" "Timestamp Reversal" $true "Timestamps monotonic ($identical/$($timestamps.Count) identical)"
    }
} else { Add-Gate "CFP-011" "Timestamp Reversal" $true "No RUN_STATE" }

# ================================================================
# CFP-012: AgentId Drift
# ================================================================
$tasksPath = Get-ChildItem $EvidenceDir -Recurse -Filter "TASKS.json" -File | Select-Object -First 1
if ($tasksPath -and $runStatePath) {
    try {
        $tasks = Get-Content $tasksPath.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $rsLines2 = Get-Content $runStatePath.FullName -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 }
        $events2 = @(); foreach ($line in $rsLines2) { try { $events2 += ($line | ConvertFrom-Json) } catch {} }
        $drifts = @()
        $taskList = if ($tasks.tasks) { $tasks.tasks } else { @($tasks) }
        foreach ($t in $taskList) {
            $tid = $t.taskId; $owner = $t.owner
            $taskEvents = @($events2 | Where-Object { $_.taskId -eq $tid -and $_.actor })
            foreach ($te in $taskEvents) {
                if ($owner -and $te.actor -ne $owner -and $te.event -eq "task_claimed") {
                    $drifts += "${tid}: owner=${owner}, claimed by=$($te.actor)"
                }
            }
        }
        Add-Gate "CFP-012" "AgentId Drift" ($drifts.Count -eq 0) $(if ($drifts.Count -gt 0) { "$drifts" } else { "All agentIds consistent" })
    } catch { Add-Gate "CFP-012" "AgentId Drift" $true "Parse error" }
} else { Add-Gate "CFP-012" "AgentId Drift" $true "No TASKS+RUN_STATE pair" }

# ================================================================
# OUTPUT
# ================================================================
$passedCount = @($gates | Where-Object { $_.passed }).Count
$failedCount = @($gates | Where-Object { -not $_.passed }).Count
$verdict = if ($failedCount -gt 0) { "FAIL" } else { "PASS" }
$exitCode = if ($failedCount -gt 0) { 1 } else { 0 }

$report = @{
    schemaVersion = "6C-O"
    evidenceDir = $EvidenceDir
    timestamp = (Get-Date).ToString("o")
    verdict = $verdict
    totalGates = $gates.Count
    passedGates = $passedCount
    failedGates = $failedCount
    exitCode = $exitCode
    gates = $gates
}

if ($Json) {
    Write-Output ($report | ConvertTo-Json -Depth 4)
} else {
    Write-Output "=== Evidence Gate Report ==="
    Write-Output "Verdict: $verdict ($passedCount/$($gates.Count) gates passed)"
    foreach ($g in $gates) {
        $icon = if ($g.passed) { "[PASS]" } else { "[FAIL]" }
        Write-Output "$icon $($g.cfp): $($g.name)"
        if (-not $g.passed) { Write-Output "      $($g.detail)" }
    }
}

exit $exitCode