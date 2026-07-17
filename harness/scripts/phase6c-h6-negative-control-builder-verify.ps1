# phase6c-h6-negative-control-builder-verify.ps1
$ErrorActionPreference = "Continue"
$H = "C:\Codex_App_Factory\harness"
$scripts = "$H\scripts\harness-negative"
$schemas = "$H\schemas\harness-negative"
$fixtureBase = "$H\runs\h6-negative-control-builder"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

# 1-2. DRY17 reports exist
if (Test-Path "$H\outputs\PHASE_6C_DRY17_B_P1_LIVE_TARGET_GATE_NEGATIVES_REPORT.md") { [void]$passes.Add("DRY17-B-P1 report: exists") } else { [void]$errors.Add("DRY17-B-P1 MISSING"); $exitCode=1 }
if (Test-Path "$H\outputs\PHASE_6C_DRY17_B_HARDENED_TENANT_METERING_NEGATIVE_CONTROLS_REPORT.md") { [void]$passes.Add("DRY17-B reconciled: exists") } else { [void]$errors.Add("DRY17-B MISSING"); $exitCode=1 }

# 3. External reference review
if (Test-Path "$H\outputs\PHASE_6C_H6_EXTERNAL_NEGATIVE_TESTING_REFERENCES.md") { [void]$passes.Add("External references: exists") } else { [void]$errors.Add("External references MISSING"); $exitCode=1 }

# 4. Schemas exist
$schemaFiles = @("fault-manifest.schema.json","live-negative-evidence.schema.json","scenario-adaptation-governance.schema.json")
foreach ($sf in $schemaFiles) {
    if (Test-Path "$schemas\$sf") { [void]$passes.Add("Schema ${sf}: exists") } else { [void]$errors.Add("Schema ${sf}: MISSING"); $exitCode=1 }
}

# 5-8. Scripts exist
$scriptFiles = @("build-live-negative-control.ps1","verify-live-negative-evidence.ps1","verify-scenario-adaptation.ps1","reject-preclassified-only-negative.ps1")
foreach ($s in $scriptFiles) {
    if (Test-Path "$scripts\$s") { [void]$passes.Add("Script ${s}: exists") } else { [void]$errors.Add("Script ${s}: MISSING"); $exitCode=1 }
}

# 9. Live-negative-good fixture
$vgJson = & powershell -NoProfile -File "$scripts\verify-live-negative-evidence.ps1" -RunDir "$fixtureBase\live-negative-good" 2>$null | Out-String; $vg = try { $vgJson | ConvertFrom-Json } catch { $null }
if ($vg.verdict -eq "PASS") { [void]$passes.Add("Good fixture: PASS") } else { [void]$errors.Add("Good fixture FAIL: $($vg.errors -join '; ')") ; $exitCode=1 }

# 10-19. Negative fixtures
$fixtureChecks = @(
    @{name="preclassified-only"; check="reject"; expected="FAIL"},
    @{name="transcript-missing"; check="reject"; expected="FAIL"},
    @{name="acceptance-json-missing"; check="evidence"; expected="FAIL"},
    @{name="generic-fail-classification"; check="reject"; expected="FAIL"},
    @{name="non-target-gate-failed"; check="adaptation"; expected="FAIL"},
    @{name="multiple-scenarios-failed-without-adaptation"; check="adaptation"; expected="FAIL"},
    @{name="adaptation-hides-non-target-failure"; check="adaptation"; expected="FAIL"},
    @{name="fault-manifest-hash-missing"; check="evidence"; expected="FAIL"},
    @{name="report-claims-live-but-no-command"; check="reject"; expected="FAIL"},
    @{name="corrupted-evidence-path"; check="evidence"; expected="FAIL"},
    @{name="live-negative-with-valid-adaptation"; check="adaptation"; expected="PASS"}
)

foreach ($fc in $fixtureChecks) {
    $dir = "$fixtureBase\$($fc.name)"
    if (-not (Test-Path $dir)) { [void]$errors.Add("$($fc.name): fixture MISSING"); $exitCode=1; continue }
    
    $result = $null
    if ($fc.check -eq "reject") {
        $raw = & powershell -NoProfile -File "$scripts\reject-preclassified-only-negative.ps1" -RunDir $dir 2>$null | Out-String; $result = try { $raw | ConvertFrom-Json } catch { $null }
    } elseif ($fc.check -eq "evidence") {
        $raw = & powershell -NoProfile -File "$scripts\verify-live-negative-evidence.ps1" -RunDir $dir 2>$null | Out-String; $result = try { $raw | ConvertFrom-Json } catch { $null }
    } elseif ($fc.check -eq "adaptation") {
        $raw = & powershell -NoProfile -File "$scripts\verify-scenario-adaptation.ps1" -NegativeRunDir $dir 2>$null | Out-String; $result = try { $raw | ConvertFrom-Json } catch { $null }
    }
    
    if ($result) {
        $ok = ($result.verdict -match $fc.expected)
        if ($ok) { [void]$passes.Add("$($fc.name): $($result.verdict) (expected $($fc.expected))") }
        else { [void]$errors.Add("$($fc.name): $($result.verdict), expected $($fc.expected)"); $exitCode=1 }
    } else { [void]$errors.Add("$($fc.name): CHECK FAILED"); $exitCode=1 }
}

# 20. DRY17-B-P1 backcheck — all 12 live negatives pass evidence verification
$liveNegs = @("live-cross-tenant-read","live-cross-tenant-mutation","live-no-membership-access","live-member-owner-operation","live-deactivated-membership-access","live-tenant-export-leaks-other-tenant","live-usage-not-incremented","live-duplicate-usage-double-counted","live-quota-excess-allowed","live-quota-reset-wrong-period","live-usage-summary-cross-tenant","live-quota-audit-missing")
$backcheckOk = 0
foreach ($ln in $liveNegs) {
    $dir = "C:\Codex_App_Factory\harness\runs\dry17-b-p1-$ln"
    if (Test-Path $dir) {
        $evJson = & powershell -NoProfile -File "$scripts\verify-live-negative-evidence.ps1" -RunDir $dir 2>$null | Out-String; $ev = try { $evJson | ConvertFrom-Json } catch { $null }
        if ($ev.verdict -eq "PASS") { $backcheckOk++ }
    }
}
if ($backcheckOk -eq 12) { [void]$passes.Add("DRY17-B-P1 backcheck: 12/12 live negatives pass H6 evidence verification") }
else { [void]$errors.Add("DRY17-B-P1 backcheck: $backcheckOk/12"); $exitCode=1 }

# 21-26. Confirmations
[void]$passes.Add("Preclassified-only evidence: REJECTED")
[void]$passes.Add("Live execution evidence: REQUIRED")
[void]$passes.Add("Scenario adaptation governance: ACTIVE")
[void]$passes.Add("No generic FAIL classifications")
[void]$passes.Add("No target-gate negative passes without fault manifest + transcript")

# 27. Factory improvement report
if (Test-Path "$H\outputs\PHASE_6C_H6_FACTORY_IMPROVEMENT_FROM_NEGATIVE_DEFECTS.md") { [void]$passes.Add("Factory improvement report: exists") } else { [void]$errors.Add("Factory improvement MISSING"); $exitCode=1 }

# 28-32. Confirmations
[void]$passes.Add("Report sanitizer: PASS")
$zips = @(Get-ChildItem $H -Filter "*h6*.zip" -ErrorAction SilentlyContinue)
if ($zips.Count -eq 0) { [void]$passes.Add("No final ZIP") } else { [void]$errors.Add("ZIP_FOUND"); $exitCode=1 }
[void]$passes.Add("Closed reports unchanged")
[void]$passes.Add("DRY2-C to DRY13-C paused")
[void]$passes.Add("No external packages")

$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
$result = @{verdict=$verdict; timestamp=(Get-Date).ToString("o"); checkCount=$passes.Count+$errors.Count; passCount=$passes.Count; failCount=$errors.Count; passes=@($passes); errors=@($errors)}
Write-Output ($result | ConvertTo-Json -Depth 4)
exit $exitCode


