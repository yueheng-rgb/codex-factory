# Harness Evidence Validator — Phase 6A.1
# Checks: timestamp monotonicity, event sequence, hash chain, no backfill, no tampering
param(
    [Parameter(Mandatory=$true)][string]$RunDir
)

$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

$stateFile = Join-Path $RunDir "RUN_STATE.jsonl"

if (-not (Test-Path $stateFile)) {
    [void]$errors.Add("MISSING: RUN_STATE.jsonl")
    Write-Output (@{ status="FAIL"; errors=$errors } | ConvertTo-Json -Depth 4)
    exit 1
}

$rawLines = Get-Content $stateFile -Encoding UTF8
$stateLines = @($rawLines | Where-Object { $_.Trim().Length -gt 0 })

if ($stateLines.Count -eq 0) {
    [void]$errors.Add("EMPTY: RUN_STATE.jsonl")
    Write-Output (@{ status="FAIL"; errors=$errors } | ConvertTo-Json -Depth 4)
    exit 1
}

$events = @()
$lineNum = 0
foreach ($line in $stateLines) {
    $lineNum++
    try { $events += ($line | ConvertFrom-Json) }
    catch { [void]$errors.Add("INVALID_JSON at line $lineNum : $($_.Exception.Message)"); $exitCode = 1 }
}

[void]$passes.Add("Events: $($events.Count)")

# ============================================================
# 1. First event check
# ============================================================
if ($events.Count -gt 0 -and $events[0].event -notin @("run_initialized","run_started")) {
    [void]$errors.Add("FIRST_EVENT_NOT_INIT: $($events[0].event)")
    $exitCode = 1
} else { [void]$passes.Add("First event valid") }

# ============================================================
# 2. Timestamp strictly monotonic
# ============================================================
$prevTime = [DateTime]::MinValue
$monotonic = $true
foreach ($evt in $events) {
    try {
        $t = [DateTime]::Parse($evt.timestamp)
        if ($t -le $prevTime) {
            [void]$errors.Add("TIMESTAMP_NOT_MONOTONIC: $($evt.timestamp) <= prev")
            $monotonic = $false; $exitCode = 1; break
        }
        $prevTime = $t
    } catch {
        [void]$errors.Add("INVALID_TIMESTAMP at seq=$($evt.seq): $($evt.timestamp)")
        $exitCode = 1; break
    }
}
if ($monotonic) { [void]$passes.Add("Timestamps strictly monotonic") }

# ============================================================
# 3. Sequence continuity
# ============================================================
$numericSeqs = @($events | Where-Object { $_.seq -is [int] -and $_.seq -gt 0 } | ForEach-Object { $_.seq } | Sort-Object)
if ($numericSeqs.Count -gt 0) {
    if ($numericSeqs[0] -ne 1) { [void]$errors.Add("SEQUENCE_NOT_START_AT_1: starts at $($numericSeqs[0])"); $exitCode = 1 }
    for ($i = 1; $i -lt $numericSeqs.Count; $i++) {
        if ($numericSeqs[$i] -ne $numericSeqs[$i-1] + 1) {
            [void]$errors.Add("SEQUENCE_GAP: $($numericSeqs[$i-1]) -> $($numericSeqs[$i])")
            $exitCode = 1; break
        }
    }
    if ($exitCode -eq 0) { [void]$passes.Add("Sequence continuous 1..$($numericSeqs[-1])") }
}

# ============================================================
# 4. Duplicate seq detection
# ============================================================
$seqDupes = $numericSeqs | Group-Object | Where-Object { $_.Count -gt 1 }
if ($seqDupes) {
    [void]$errors.Add("DUPLICATE_SEQ: $($seqDupes.Name -join ', ') (each x$($seqDupes[0].Count))")
    $exitCode = 1
} else { [void]$passes.Add("No duplicate sequences") }

# ============================================================
# 5. [RECONSTRUCTED] marker rejection (literal match, escaped brackets)
# ============================================================
$reconstructed = @($stateLines | Where-Object { $_ -match '\[RECONSTRUCTED\]' })
if ($reconstructed.Count -gt 0) {
    [void]$errors.Add("RECONSTRUCTED_EVENTS: $($reconstructed.Count) lines contain [RECONSTRUCTED]")
    $exitCode = 1
} else { [void]$passes.Add("No [RECONSTRUCTED] markers") }

# ============================================================
# 6. Hash chain validation (if present)
# ============================================================
$hasHashChain = ($events | Where-Object { $_.eventHash }).Count -gt 0
if ($hasHashChain) {
    $prevHash = "GENESIS"
    $chainOk = $true
    for ($i = 0; $i -lt $events.Count; $i++) {
        $evt = $events[$i]
        if (-not $evt.eventHash) {
            [void]$warnings.Add("Event seq=$($evt.seq) missing eventHash"); continue
        }
        if ($evt.previousHash -ne $prevHash) {
            [void]$errors.Add("HASH_CHAIN_BREAK at seq=$($evt.seq): expected previousHash=$prevHash, got $($evt.previousHash)")
            $chainOk = $false; $exitCode = 1
        }
        # Recompute hash: canonical JSON without eventHash/seq/timestamp fields
        $canonical = @{}
        foreach ($key in $evt.PSObject.Properties.Name) {
            if ($key -notin @("eventHash","previousHash","payloadHash","seq","timestamp")) {
                $canonical[$key] = $evt.$key
            }
        }
        $canonicalJson = ($canonical | ConvertTo-Json -Compress -Depth 6)
        $computedHash = [System.BitConverter]::ToString(
            [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                [System.Text.Encoding]::UTF8.GetBytes($canonicalJson + $prevHash)
            )
        ).Replace("-","").ToLower()
        if ($computedHash -ne $evt.eventHash) {
            [void]$errors.Add("HASH_MISMATCH at seq=$($evt.seq): computed=$computedHash, recorded=$($evt.eventHash)")
            $chainOk = $false; $exitCode = 1
        }
        $prevHash = $evt.eventHash
    }
    if ($chainOk) { [void]$passes.Add("Hash chain valid ($($events.Count) events)") }
} else {
    [void]$passes.Add("Hash chain not present (pre-6A.1 run)")
}

# ============================================================
# 7. Validation event pairing
# ============================================================
$startedValidations = @{}
foreach ($evt in $events) {
    if ($evt.event -eq "validation_started") {
        if ($startedValidations.ContainsKey($evt.validationId)) {
            [void]$errors.Add("DUPLICATE_VALIDATION_START: $($evt.validationId)")
            $exitCode = 1
        }
        $startedValidations[$evt.validationId] = $evt
    }
    if ($evt.event -in @("validation_passed","validation_failed")) {
        if (-not $startedValidations.ContainsKey($evt.validationId)) {
            [void]$errors.Add("ORPHAN_VALIDATION_RESULT: $($evt.validationId) has result without start")
            $exitCode = 1
        } else {
            $startedValidations.Remove($evt.validationId)
        }
    }
}
if ($startedValidations.Count -gt 0) {
    [void]$errors.Add("UNCLOSED_VALIDATIONS: $($startedValidations.Keys -join ', ')")
    $exitCode = 1
} else { [void]$passes.Add("All validations properly paired") }

# ============================================================
# 8. Evidence file mtime vs event timestamp
# ============================================================
$evtWithEvidence = @($events | Where-Object { $_.evidencePaths -and @($_.evidencePaths).Count -gt 0 })
foreach ($evt in $evtWithEvidence) {
    foreach ($ep in $evt.evidencePaths) {
        $fp = Join-Path $RunDir $ep
        if (Test-Path $fp) {
            $mtime = (Get-Item $fp).LastWriteTimeUtc
            $evtTime = [DateTime]::Parse($evt.timestamp)
            if ($mtime -gt $evtTime.AddMinutes(1)) {
                [void]$warnings.Add("EVIDENCE_MTIME_AFTER_EVENT: $ep")
            }
        }
    }
}

$result = @{
    status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
    errors = $errors
    warnings = $warnings
    passes = $passes
    eventCount = $events.Count
    hasHashChain = $hasHashChain
} | ConvertTo-Json -Depth 4

Write-Output $result
exit $exitCode
