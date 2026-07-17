# Validate State — READ-ONLY Gate — Phase 6B-R3
# This script COMPUTES the verdict but NEVER modifies RUN_STATE, TASKS, ACCEPTANCE, token store, locks, or trust root.
# Only finalize-run.ps1 may write terminal events.
param(
    [Parameter(Mandatory=$true)][string]$RunDir
)
$ErrorActionPreference = "Continue"
$ScriptsDir = $PSScriptRoot
$HarnessRoot = Resolve-Path (Join-Path $ScriptsDir "..")
$errors = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

$stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
$tasksFile = Join-Path $RunDir "TASKS.json"
$acceptFile = Join-Path $RunDir "ACCEPTANCE.json"

# --- 1. File existence ---
foreach ($f in @($tasksFile, $acceptFile, $stateFile)) {
    if (Test-Path $f) { [void]$passes.Add("Found: $(Split-Path $f -Leaf)") }
    else { [void]$errors.Add("MISSING: $(Split-Path $f -Leaf)"); $exitCode = 1 }
}
if ($exitCode -ne 0) { Write-Output (@{ status="FAIL"; errors=$errors; passes=$passes } | ConvertTo-Json -Depth 4); exit $exitCode }

# --- 2. Parse events ---
$rawLines = Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 }
$events = @()
foreach ($line in $rawLines) {
    try { $events += ($line | ConvertFrom-Json) } catch { [void]$errors.Add("INVALID_JSON in RUN_STATE"); $exitCode = 1 }
}
[void]$passes.Add("Events: $($events.Count)")

# --- 3. Hash chain validation ---
$hasHashChain = ($events | Where-Object { $_.eventHash }).Count -gt 0
if (-not $hasHashChain) {
    [void]$errors.Add("NO_HASH_CHAIN: All events must be hash-chained via append-hash-event.ps1")
    $exitCode = 1
} else {
    $prevHash = "GENESIS"
    $chainOk = $true
    for ($i = 0; $i -lt $events.Count; $i++) {
        $evt = $events[$i]
        if (-not $evt.eventHash) { [void]$errors.Add("MISSING_EVENT_HASH at seq=$($evt.seq)"); $chainOk = $false; $exitCode = 1; continue }
        if (-not $evt.previousHash) { [void]$errors.Add("MISSING_PREVIOUS_HASH at seq=$($evt.seq)"); $chainOk = $false; $exitCode = 1; continue }
        if (-not $evt.payloadHash) { [void]$errors.Add("MISSING_PAYLOAD_HASH at seq=$($evt.seq)"); $chainOk = $false; $exitCode = 1; continue }
        if ($evt.previousHash -ne $prevHash) { [void]$errors.Add("HASH_CHAIN_BREAK at seq=$($evt.seq)"); $chainOk = $false; $exitCode = 1 }
        
        # Recompute
        $canonical = [ordered]@{}
        foreach ($key in ($evt.PSObject.Properties.Name | Sort-Object)) {
            if ($key -notin @("eventHash","previousHash","payloadHash","seq","timestamp")) {
                $canonical[$key] = $evt.$key
            }
        }
        $canonical["seq"] = $evt.seq
        $canonical["timestamp"] = $evt.timestamp
        $canonical["previousHash"] = $evt.previousHash
        $payloadOnly = [ordered]@{}
        foreach ($k in $canonical.Keys) { if ($k -ne "previousHash") { $payloadOnly[$k] = $canonical[$k] } }
        $pJson = ($payloadOnly | ConvertTo-Json -Compress -Depth 6)
        $computedPayload = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($pJson))).Replace("-","").ToLower()
        if ($computedPayload -ne $evt.payloadHash) { [void]$errors.Add("PAYLOAD_HASH_MISMATCH at seq=$($evt.seq)"); $chainOk = $false; $exitCode = 1 }
        $fJson = ($canonical | ConvertTo-Json -Compress -Depth 6)
        $computedEvent = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($fJson + $prevHash))).Replace("-","").ToLower()
        if ($computedEvent -ne $evt.eventHash) { [void]$errors.Add("EVENT_HASH_MISMATCH at seq=$($evt.seq)"); $chainOk = $false; $exitCode = 1 }
        $prevHash = $evt.eventHash
    }
    if ($chainOk) { [void]$passes.Add("Hash chain valid ($($events.Count) events)") }
}

# --- 3b. Check for un-hashed events ---
$noHash = @($events | Where-Object { -not $_.eventHash })
if ($noHash.Count -gt 0) { [void]$errors.Add("UNHASHED_EVENTS: $($noHash.Count) events without hash fields"); $exitCode = 1 }

# --- 4. Authorization proof verification ---
$authorizedEventTypes = @("task_claimed","task_submitted","validation_started","validation_passed","validation_failed","task_verified","release_validation_started","release_validation_passed","release_validation_failed","release_verified")
$authEvents = @($events | Where-Object { $_.event -in $authorizedEventTypes })
$proofVerified = 0; $proofFailed = 0

foreach ($aevt in $authEvents) {
    if (-not $aevt.authorizationProof) {
        [void]$errors.Add("MISSING_AUTHORIZATION_PROOF: event=$($aevt.event) seq=$($aevt.seq) taskId=$($aevt.taskId) validationId=$($aevt.validationId)")
        $proofFailed++; $exitCode = 1
        continue
    }
    if (-not $aevt.tokenLeaseId) {
        [void]$errors.Add("MISSING_TOKEN_LEASE_ID: seq=$($aevt.seq)")
        $proofFailed++; $exitCode = 1
        continue
    }
    if (-not $aevt.proofNonce) {
        [void]$errors.Add("MISSING_PROOF_NONCE: seq=$($aevt.seq)")
        $proofFailed++; $exitCode = 1
        continue
    }
    
    # Build canonical event content
    $canonicalContent = [ordered]@{}
    foreach ($key in ($aevt.PSObject.Properties.Name | Sort-Object)) {
        if ($key -notin @("eventHash","previousHash","payloadHash","seq","timestamp","authorizationProof","tokenLeaseId","proofNonce","tokenIssuedAt","tokenExpiresAt")) {
            $canonicalContent[$key] = $aevt.$key
        }
    }
    $canonicalJson = ($canonicalContent | ConvertTo-Json -Compress -Depth 6)
    
    $refId = if ($aevt.taskId) { $aevt.taskId } elseif ($aevt.validationId) { $aevt.validationId } else { "" }
    if (-not $refId) {
        [void]$errors.Add("PROOF_NO_REF_ID: seq=$($aevt.seq)")
        $proofFailed++; $exitCode = 1
        continue
    }
    
    $verifyResult = & (Join-Path $ScriptsDir "token-lease.ps1") -Action verify-proof `
        -RunId (Split-Path $RunDir -Leaf) `
        -TaskId $refId `
        -Operation $aevt.event `
        -EventTimestamp $aevt.timestamp `
        -EventCanonicalJson $canonicalJson `
        -AuthorizationProof $aevt.authorizationProof `
        -ProofNonce $aevt.proofNonce `
        -TokenLeaseId $aevt.tokenLeaseId 2>&1 | ConvertFrom-Json
    
    if (-not $verifyResult -or $verifyResult.status -ne "verified") {
        [void]$errors.Add("PROOF_VERIFICATION_FAILED: event=$($aevt.event) seq=$($aevt.seq) reason=$($verifyResult.reason)")
        $proofFailed++; $exitCode = 1
    } else {
        $proofVerified++
    }
}
[void]$passes.Add("Authorization proofs: $proofVerified verified, $proofFailed failed")

$builderVerified = @($events | Where-Object { $_.event -eq "task_verified" -and $_.role -eq "builder" })
if ($builderVerified.Count -gt 0) { [void]$errors.Add("BUILDER_ROLE_VERIFIED: $($builderVerified.Count)"); $exitCode = 1 }

# --- 5. Required acceptance items pass ---
$acceptance = Get-Content $acceptFile -Raw -Encoding UTF8 | ConvertFrom-Json
$required = @($acceptance.acceptanceItems | Where-Object { $_.required -eq $true })
if ($required.Count -eq 0) { [void]$warnings.Add("No required acceptance items") }

function Read-TestResults {
    param([string]$EvidencePath)
    $fullPath = if ([System.IO.Path]::IsPathRooted($EvidencePath)) { $EvidencePath } else { Join-Path $RunDir $EvidencePath }
    if (-not (Test-Path $fullPath)) { return $null }
    try { $json = Get-Content $fullPath -Raw -Encoding UTF8 | ConvertFrom-Json; return $json } catch { return $null }
}

foreach ($item in $required) {
    $valStarted = @($events | Where-Object { $_.event -eq "validation_started" -and $_.validationId -eq $item.id })
    $valPassed = @($events | Where-Object { $_.event -eq "validation_passed" -and $_.validationId -eq $item.id })
    
    if ($valStarted.Count -eq 0) {
        [void]$errors.Add("NO_VALIDATION_START: $($item.id)"); $exitCode = 1
        continue
    }
    if ($valPassed.Count -eq 0) {
        [void]$errors.Add("ACCEPTANCE_NOT_PASSED: $($item.id)"); $exitCode = 1
        continue
    }
    
    $vpEvent = $valPassed[-1]
    $evidenceOk = $true
    
    # For playwright: check actual test results
    if ($item.verificationType -eq "playwright" -or $vpEvent.testResultsPath) {
        $testResultsPath = $vpEvent.testResultsPath
        if (-not $testResultsPath -and $vpEvent.evidencePaths) {
            $testResultsPath = @($vpEvent.evidencePaths | Where-Object { $_ -match 'results\.json' } | Select-Object -First 1)
        }
        
        if ($testResultsPath) {
            $testResults = Read-TestResults -EvidencePath $testResultsPath
            if ($testResults) {
                $failedCount = 0
                if ($testResults.suites) {
                    foreach ($suite in $testResults.suites) {
                        if ($suite.suites) {
                            foreach ($sub in $suite.suites) {
                                foreach ($spec in $sub.specs) {
                                    foreach ($t in $spec.tests) {
                                        if ($t.status -ne "pass" -and $t.status -ne "expected") {
                                            $failedCount++
                                        }
                                    }
                                }
                            }
                        }
                    }
                } elseif ($testResults.testResults) {
                    foreach ($t in $testResults.testResults) {
                        if ($t.status -ne "pass" -and $t.status -ne "passed") {
                            $failedCount++
                        }
                    }
                } elseif ($testResults.numFailedTests) {
                    $failedCount = [int]$testResults.numFailedTests
                } elseif ($testResults.failures) {
                    $failedCount = [int]$testResults.failures
                }
                
                if ($failedCount -gt 0) {
                    [void]$errors.Add("ACCEPTANCE_FAILED_TESTS: $($item.id) has $failedCount failing tests (evidence: $testResultsPath)")
                    $exitCode = 1
                    $evidenceOk = $false
                }
            }
        }
    }
    
    # Check failedCount from validation_passed event
    if ($vpEvent.failedCount -and [int]$vpEvent.failedCount -gt 0) {
        [void]$errors.Add("ACCEPTANCE_FAILED_COUNT: $($item.id) failedCount=$($vpEvent.failedCount)")
        $exitCode = 1
        $evidenceOk = $false
    }
    
    # For command: check exitCode
    if ($item.verificationType -eq "command") {
        if ($vpEvent.exitCode -and [int]$vpEvent.exitCode -ne 0) {
            [void]$errors.Add("ACCEPTANCE_NONZERO_EXIT: $($item.id) exitCode=$($vpEvent.exitCode)")
            $exitCode = 1
            $evidenceOk = $false
        }
    }
    
    if ($evidenceOk) {
        [void]$passes.Add("Acceptance passed: $($item.id)")
    }
}

# --- 6. All tasks verified ---
$tasks = Get-Content $tasksFile -Raw -Encoding UTF8 | ConvertFrom-Json
$notVerified = @($tasks.tasks | Where-Object { $_.status -ne "verified" })
if ($notVerified.Count -gt 0) { [void]$errors.Add("TASKS_NOT_VERIFIED: $($notVerified.Count)"); $exitCode = 1 }
else { [void]$passes.Add("All tasks verified ($($tasks.tasks.Count))") }

# --- 7. Evidence content hash verification ---
$evtWithEvidence = @($events | Where-Object { $_.evidencePaths -or $_.stdoutSha256 })
foreach ($evt in $evtWithEvidence) {
    if ($evt.stdoutSha256) {
        $sp = $evt.stdoutPath
        if (-not $sp) { continue }
        $fp = if ([System.IO.Path]::IsPathRooted($sp)) { $sp } else { Join-Path $RunDir $sp }
        if (Test-Path $fp) {
            $actual = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.IO.File]::ReadAllBytes($fp))).Replace("-","").ToLower()
            if ($actual -ne $evt.stdoutSha256) { [void]$errors.Add("EVIDENCE_HASH_MISMATCH: $sp"); $exitCode = 1 }
        } else { [void]$errors.Add("EVIDENCE_FILE_MISSING: $sp"); $exitCode = 1 }
    }
}

# --- 8. Control plane + trust root ---
$cpLockFile = Join-Path $RunDir "CONTROL_PLANE_LOCK.json"
$trDirFile = Join-Path $RunDir "external-trust-root"
if (-not (Test-Path $cpLockFile)) {
    [void]$errors.Add("MISSING_CONTROL_PLANE_LOCK"); $exitCode = 1
} else {
    $trResult = & (Join-Path $ScriptsDir "external-trust-root.ps1") -RunDir $RunDir -Action validate 2>&1 | Out-String
    if ($trResult -notmatch '"status":\s*"VALID"') {
        [void]$errors.Add("EXTERNAL_TRUST_ROOT_FAILED: trust root missing or tampered")
        $exitCode = 1
    } else {
        $cpResult = & (Join-Path $ScriptsDir "validate-control-plane.ps1") -RunDir $RunDir 2>&1 | Out-String
        if ($cpResult -notmatch '"status":\s*"PASS"') {
            [void]$errors.Add("CONTROL_PLANE_TAMPERED: governance file hash mismatch")
            $exitCode = 1
        } else {
            [void]$passes.Add("Control plane + trust root: PASS")
        }
    }
}

# --- 8.5 Harness integrity ---
$harnessBaselineFile = Join-Path $RunDir "HARNESS_BASELINE.json"
if (-not (Test-Path $harnessBaselineFile)) {
    [void]$errors.Add("MISSING_HARNESS_BASELINE: HARNESS_BASELINE.json not found")
    $exitCode = 1
} else {
    $baseline = Get-Content $harnessBaselineFile -Raw -Encoding UTF8 | ConvertFrom-Json
    $modifiedFiles = [System.Collections.ArrayList]::new()
    foreach ($bf in $baseline.files) {
        $fp = Join-Path $HarnessRoot $bf.path
        if (Test-Path $fp) {
            $currentSha = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.IO.File]::ReadAllBytes($fp))).Replace("-","").ToLower()
            if ($currentSha -ne $bf.sha256) { [void]$modifiedFiles.Add("$($bf.path) (modified)"); $exitCode = 1 }
        } else { [void]$modifiedFiles.Add("$($bf.path) (added during run)"); $exitCode = 1 }
    }
    if ($modifiedFiles.Count -gt 0) {
        [void]$errors.Add("HARNESS_MODIFIED_DURING_RUN: $($modifiedFiles -join '; ')")
    } else {
        [void]$passes.Add("Harness integrity: PASS (no modifications during run)")
    }
}

# --- 9. Manual remediation detection ---
$manualRemEvents = @($events | Where-Object { $_.event -eq "manual_remediation" })
if ($manualRemEvents.Count -gt 0) { [void]$errors.Add("MANUAL_REMEDIATION: $($manualRemEvents.Count) events"); $exitCode = 1 }
else { [void]$passes.Add("No manual remediation") }

# --- 10. Release validation ---
$releaseFile = Join-Path $RunDir "RELEASE_MANIFEST.json"
if (Test-Path $releaseFile) {
    $rel = Get-Content $releaseFile -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $rel.status) { [void]$errors.Add("RELEASE_NOT_COMPLETE: status=$($rel.status)"); $exitCode = 1 }
    elseif ($rel.roundTrip.build -ne "pass") { [void]$errors.Add("RELEASE_BUILD_FAILED"); $exitCode = 1 }
    else {
        if ($rel.zipPath) {
            $zipFull = if ([System.IO.Path]::IsPathRooted($rel.zipPath)) { $rel.zipPath } else { Join-Path $RunDir $rel.zipPath }
            if (-not (Test-Path $zipFull)) { [void]$errors.Add("ZIP_NOT_FOUND: $($rel.zipPath)"); $exitCode = 1 }
            else {
                try {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    $za = [System.IO.Compression.ZipFile]::OpenRead($zipFull)
                    $entries = $za.Entries | ForEach-Object { $_.FullName }
                    $za.Dispose()
                    $rootOnly = ($entries | Where-Object { $_ -notmatch '/' }).Count
                    if ($rootOnly -eq $entries.Count -and $entries.Count -gt 2) {
                        [void]$errors.Add("ZIP_FLATTENED: all entries at root"); $exitCode = 1
                    } elseif (-not ($entries -match 'package\.json')) {
                        [void]$errors.Add("ZIP_MISSING_PACKAGE_JSON"); $exitCode = 1
                    } else { [void]$passes.Add("Release: OK (ZIP verified)") }
                } catch { [void]$errors.Add("ZIP_READ_ERROR: $_"); $exitCode = 1 }
            }
        } else { [void]$passes.Add("Release: OK (no ZIP path)") }
    }
} else { [void]$errors.Add("MISSING: RELEASE_MANIFEST.json"); $exitCode = 1 }

# --- TERMINAL VERDICT MULTIPLICITY ---
$terminalEvents = @($events | Where-Object { $_.event -in @("run_passed","run_failed") })
$runPassedCount = @($terminalEvents | Where-Object { $_.event -eq "run_passed" }).Count
$runFailedCount = @($terminalEvents | Where-Object { $_.event -eq "run_failed" }).Count

if ($runPassedCount -gt 0 -and $runFailedCount -gt 0) {
    [void]$errors.Add("TERMINAL_VERDICT_REVERSAL"); $exitCode = 1
} elseif (($runPassedCount + $runFailedCount) -gt 1) {
    [void]$errors.Add("MULTIPLE_TERMINAL_VERDICTS"); $exitCode = 1
}

# --- RUN_SEALED CHECK ---
$sealedEvents = @($events | Where-Object { $_.event -eq "run_sealed" })
if ($sealedEvents.Count -gt 0) {
    $lastSealedSeq = ($sealedEvents | Sort-Object seq -Descending)[0].seq
    $postSealBad = @($events | Where-Object { 
        $_.seq -gt $lastSealedSeq -and $_.event -in @("control_plane_refrozen","baseline_rebuilt","trust_root_refrozen","harness_script_modified")
    })
    if ($postSealBad.Count -gt 0) { [void]$errors.Add("POST_SEAL_TAMPERING"); $exitCode = 1 }
}

# --- REPORT FIELDS ---
$applicationManualRemediation = (@($events | Where-Object { $_.event -eq "manual_remediation" }).Count -gt 0)
$harnessModifiedDuringRun = $false
if ($modifiedFiles.Count -gt 0) { $harnessModifiedDuringRun = $true }
$harnessStateRebuiltDuringRun = (@($events | Where-Object { 
    $_.event -in @("baseline_rebuilt","control_plane_refrozen","trust_root_refrozen") 
}).Count -gt 0)
$trustRootRefrozenDuringRun = (@($events | Where-Object { $_.event -eq "trust_root_refrozen" }).Count -gt 0)
$independentRunValid = (-not $harnessModifiedDuringRun) -and (-not $harnessStateRebuiltDuringRun) -and (-not $applicationManualRemediation)

# --- FINAL VERDICT ---
$verdict = if ($exitCode -eq 0) { "run_passed" } else { "run_failed" }

$result = @{
    status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
    verdict = $verdict
    errors = $errors
    warnings = $warnings
    passes = $passes
    timestamp = (Get-Date).ToString("o")
    reportFields = @{
        applicationAutomaticRetryCount = (@($events | Where-Object { $_.event -eq "task_retry_created" }).Count)
        applicationManualRemediation = $applicationManualRemediation
        harnessModifiedDuringRun = $harnessModifiedDuringRun
        harnessStateRebuiltDuringRun = $harnessStateRebuiltDuringRun
        trustRootRefrozenDuringRun = $trustRootRefrozenDuringRun
        independentRunValid = $independentRunValid
        multipleTerminalVerdicts = (($runPassedCount + $runFailedCount) -gt 1)
        terminalVerdictReversal = ($runPassedCount -gt 0 -and $runFailedCount -gt 0)
    }
} | ConvertTo-Json -Depth 4

Write-Output $result
exit $exitCode
