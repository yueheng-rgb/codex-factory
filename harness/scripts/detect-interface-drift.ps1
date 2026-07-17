# detect-interface-drift.ps1 鈥?Phase 6C-U0-A
# Core interface drift detector. Compares worker interface manifests against
# the locked contract. Detects A/B mismatches: Agent1 exports A, Agent2 imports B.
# READ-ONLY: never modifies contract or manifests.
param(
    [Parameter(Mandatory=$true)][string]$ContractPath,
    [Parameter(Mandatory=$true)][string]$ManifestsDir,
    [Parameter(Mandatory=$true)][string]$OutputReportPath,
    [switch]$Json
)

$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$checks = [System.Collections.ArrayList]::new()
$drifts = [System.Collections.ArrayList]::new()
$exitCode = 0

# --- 1. Contract lock exists ---
if (-not (Test-Path $ContractPath)) {
    [void]$errors.Add("CONTRACT_NOT_FOUND: $ContractPath")
    $result = @{ verdict="FAIL"; errors=$errors; passes=$passes; timestamp=(Get-Date).ToString("o") }
    if ($Json) { Write-Output ($result | ConvertTo-Json -Depth 4) } else { Write-Output "FAIL: Contract not found" }
    exit 1
}
[void]$passes.Add("Contract lock found: $ContractPath")

# --- 2. Load contract ---
try {
    $contract = Get-Content $ContractPath -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    [void]$errors.Add("CONTRACT_INVALID_JSON: $_")
    exit 1
}

# --- 3. Contract locked = true ---
if ($contract.locked -eq $true) {
    [void]$checks.Add(@{check="contract_locked"; status="PASS"; detail="locked=true"})
    [void]$passes.Add("Contract locked = true")
} else {
    [void]$checks.Add(@{check="contract_locked"; status="FAIL"; detail="locked=$($contract.locked)"})
    [void]$errors.Add("CONTRACT_NOT_LOCKED")
    $exitCode = 1
}

# --- 4. Load all manifests ---
if (-not (Test-Path $ManifestsDir)) {
    [void]$errors.Add("MANIFESTS_DIR_NOT_FOUND: $ManifestsDir")
    exit 1
}

$manifestFiles = Get-ChildItem $ManifestsDir -Filter "*.json" -File
if ($manifestFiles.Count -eq 0) {
    [void]$errors.Add("NO_MANIFESTS_FOUND: $ManifestsDir")
    exit 1
}

$manifests = @()
foreach ($mf in $manifestFiles) {
    try {
        $m = Get-Content $mf.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
        $manifests += $m
        [void]$passes.Add("Manifest loaded: $($mf.Name) 鈫?workerId=$($m.workerId)")
    } catch {
        [void]$errors.Add("MANIFEST_INVALID_JSON: $($mf.Name): $_")
        $exitCode = 1
    }
}

[void]$checks.Add(@{check="manifests_loaded"; status=if($exitCode -eq 0){"PASS"}else{"FAIL"}; detail="$($manifests.Count) manifests"})

if ($exitCode -ne 0) {
    $result = @{ phase="Phase 6C-U0-A"; reportType="interface-drift-report"; verdict="FAIL"; checkedContractPath=$ContractPath; checkedManifestCount=$manifestFiles.Count; driftCount=0; errors=$errors; passes=$passes; checks=$checks; timestamp=(Get-Date).ToString("o") }
    [System.IO.File]::WriteAllText($OutputReportPath, ($result | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
    exit 1
}

# --- 5. Build contract index ---
$contractIndex = @{}
foreach ($iface in $contract.interfaces) {
    $contractIndex[$iface.interfaceId] = $iface
}

# --- 6. Check each manifest export against contract ---
foreach ($m in $manifests) {
    foreach ($exp in $m.exports) {
        $iid = $exp.interfaceId
        # Check interfaceId exists in contract
        if (-not $contractIndex.ContainsKey($iid)) {
            $drift = "EXPORT_INTERFACE_NOT_IN_CONTRACT: worker=$($m.workerId) interfaceId=$iid"
            [void]$drifts.Add(@{type="unknown_interface"; workerId=$m.workerId; interfaceId=$iid; detail=$drift})
            [void]$errors.Add($drift)
            [void]$checks.Add(@{check="export_interface_in_contract"; status="FAIL"; workerId=$m.workerId; interfaceId=$iid; detail=$drift})
            $exitCode = 1
            continue
        }

        $ciface = $contractIndex[$iid]

        # Check name matches
        if ($exp.name -ne $ciface.name) {
            $drift = "EXPORT_NAME_MISMATCH: worker=$($m.workerId) interfaceId=$iid expected='$($ciface.name)' actual='$($exp.name)'"
            [void]$drifts.Add(@{type="name_mismatch"; workerId=$m.workerId; interfaceId=$iid; expectedName=$ciface.name; actualName=$exp.name; detail=$drift})
            [void]$errors.Add($drift)
            [void]$checks.Add(@{check="export_name_match"; status="FAIL"; workerId=$m.workerId; interfaceId=$iid; expected=$ciface.name; actual=$exp.name; detail=$drift})
            $exitCode = 1
        } else {
            [void]$checks.Add(@{check="export_name_match"; status="PASS"; workerId=$m.workerId; interfaceId=$iid; detail="$($exp.name) matches"})
        }

        # Check file matches
        if ($exp.file -ne $ciface.file) {
            $drift = "EXPORT_FILE_MISMATCH: worker=$($m.workerId) interfaceId=$iid expected='$($ciface.file)' actual='$($exp.file)'"
            [void]$drifts.Add(@{type="file_mismatch"; workerId=$m.workerId; interfaceId=$iid; expectedFile=$ciface.file; actualFile=$exp.file; detail=$drift})
            [void]$errors.Add($drift)
            [void]$checks.Add(@{check="export_file_match"; status="FAIL"; workerId=$m.workerId; interfaceId=$iid; detail=$drift})
            $exitCode = 1
        } else {
            [void]$checks.Add(@{check="export_file_match"; status="PASS"; workerId=$m.workerId; interfaceId=$iid; detail="$($exp.file) matches"})
        }

        # Check owner worker actually exports this interface
        if ($ciface.owner -ne $m.workerId) {
            $drift = "OWNER_MISMATCH: interfaceId=$iid contract.owner='$($ciface.owner)' but exported by worker='$($m.workerId)'"
            [void]$drifts.Add(@{type="owner_mismatch"; workerId=$m.workerId; interfaceId=$iid; expectedOwner=$ciface.owner; detail=$drift})
            [void]$errors.Add($drift)
            [void]$checks.Add(@{check="owner_match"; status="FAIL"; workerId=$m.workerId; interfaceId=$iid; detail=$drift})
            $exitCode = 1
        } else {
            [void]$checks.Add(@{check="owner_match"; status="PASS"; workerId=$m.workerId; interfaceId=$iid; detail="owner matches contract"})
        }
    }
}

# --- 7. Check each manifest import against contract ---
foreach ($m in $manifests) {
    foreach ($imp in $m.imports) {
        $iid = $imp.interfaceId
        if (-not $contractIndex.ContainsKey($iid)) {
            $drift = "IMPORT_INTERFACE_NOT_IN_CONTRACT: worker=$($m.workerId) interfaceId=$iid"
            [void]$drifts.Add(@{type="unknown_import_interface"; workerId=$m.workerId; interfaceId=$iid; detail=$drift})
            [void]$errors.Add($drift)
            [void]$checks.Add(@{check="import_interface_in_contract"; status="FAIL"; workerId=$m.workerId; interfaceId=$iid; detail=$drift})
            $exitCode = 1
            continue
        }

        $ciface = $contractIndex[$iid]

        # Check name matches
        if ($imp.name -ne $ciface.name) {
            $drift = "IMPORT_NAME_MISMATCH: worker=$($m.workerId) interfaceId=$iid expected='$($ciface.name)' actual='$($imp.name)'"
            [void]$drifts.Add(@{type="import_name_mismatch"; workerId=$m.workerId; interfaceId=$iid; expectedName=$ciface.name; actualName=$imp.name; offendingManifestPath=$mf.FullName; detail=$drift})
            [void]$errors.Add($drift)
            [void]$checks.Add(@{check="import_name_match"; status="FAIL"; workerId=$m.workerId; interfaceId=$iid; expected=$ciface.name; actual=$imp.name; detail=$drift})
            $exitCode = 1
        } else {
            [void]$checks.Add(@{check="import_name_match"; status="PASS"; workerId=$m.workerId; interfaceId=$iid; detail="$($imp.name) matches"})
        }

        # Check file matches
        if ($imp.file -ne $ciface.file) {
            $drift = "IMPORT_FILE_MISMATCH: worker=$($m.workerId) interfaceId=$iid expected='$($ciface.file)' actual='$($imp.file)'"
            [void]$drifts.Add(@{type="import_file_mismatch"; workerId=$m.workerId; interfaceId=$iid; expectedFile=$ciface.file; actualFile=$imp.file; detail=$drift})
            [void]$errors.Add($drift)
            [void]$checks.Add(@{check="import_file_match"; status="FAIL"; workerId=$m.workerId; interfaceId=$iid; detail=$drift})
            $exitCode = 1
        } else {
            [void]$checks.Add(@{check="import_file_match"; status="PASS"; workerId=$m.workerId; interfaceId=$iid; detail="$($imp.file) matches"})
        }
    }
}

# --- 8. Check requiredBy: every worker in requiredBy must actually import ---
$contractKeys = @($contractIndex.Keys)
foreach ($iid in $contractKeys) {
    $ciface = $contractIndex[$iid]
    $iidStr = [string]$iid
    foreach ($rb in $ciface.requiredBy) {
        $rbStr = [string]$rb
        $importingWorker = $null
        foreach ($m in $manifests) {
            if ($m.workerId -eq $rbStr) { $importingWorker = $m; break }
        }
        if (-not $importingWorker) {
            [void]$errors.Add("REQUIRED_BY_WORKER_NOT_FOUND: interfaceId=$iidStr requiredBy=$rbStr (no manifest for this worker)")
            $exitCode = 1
            continue
        }
        $foundImport = $false
        foreach ($imp in $importingWorker.imports) {
            if ($imp.interfaceId -eq $iidStr) { $foundImport = $true; break }
        }
        if (-not $foundImport) {
            $driftMsg = "REQUIRED_IMPORT_MISSING: interfaceId=$iidStr requiredBy=$rbStr but worker $rbStr does not import it"
            [void]$drifts.Add(@{type="required_import_missing"; interfaceId=$iidStr; requiredBy=$rbStr; detail=$driftMsg})
            [void]$errors.Add($driftMsg)
            [void]$checks.Add(@{check="required_by_imports"; status="FAIL"; interfaceId=$iidStr; workerId=$rbStr; detail=$driftMsg})
            $exitCode = 1
        } else {
            [void]$checks.Add(@{check="required_by_imports"; status="PASS"; interfaceId=$iidStr; workerId=$rbStr; detail="worker imports as required"})
        }
    }
}

# --- 9. Check owner: every owner must actually export ---
foreach ($iid in $contractKeys) {
    $ciface = $contractIndex[$iid]
    $iidStr = [string]$iid
    $ownerStr = [string]$ciface.owner
    $ownerWorker = $null
    foreach ($m in $manifests) {
        if ($m.workerId -eq $ownerStr) { $ownerWorker = $m; break }
    }
    if (-not $ownerWorker) {
        [void]$errors.Add("OWNER_WORKER_NOT_FOUND: interfaceId=$iidStr owner=$ownerStr (no manifest)")
        $exitCode = 1
        continue
    }
    $foundExport = $false
    foreach ($exp in $ownerWorker.exports) {
        if ($exp.interfaceId -eq $iidStr) { $foundExport = $true; break }
    }
    if (-not $foundExport) {
        $driftMsg = "REQUIRED_EXPORT_MISSING: interfaceId=$iidStr owner=$ownerStr does not export it"
        [void]$drifts.Add(@{type="required_export_missing"; interfaceId=$iidStr; owner=$ownerStr; detail=$driftMsg})
        [void]$errors.Add($driftMsg)
        [void]$checks.Add(@{check="owner_exports"; status="FAIL"; interfaceId=$iidStr; owner=$ownerStr; detail=$driftMsg})
        $exitCode = 1
    } else {
        [void]$checks.Add(@{check="owner_exports"; status="PASS"; interfaceId=$iidStr; owner=$ownerStr; detail="owner exports as declared"})
    }
}

# --- VERDICT ---
$verdict = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

$result = @{
    phase = "Phase 6C-U0-A"
    reportType = "interface-drift-report"
    verdict = $verdict
    checkedContractPath = $ContractPath
    checkedManifestCount = $manifests.Count
    driftCount = $drifts.Count
    errors = $errors
    passes = $passes
    checks = $checks
    drifts = $drifts
    timestamp = (Get-Date).ToString("o")
}

$resultJson = $result | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText($OutputReportPath, $resultJson, (New-Object System.Text.UTF8Encoding($false)))

if ($Json) {
    Write-Output $resultJson
} else {
    Write-Output "=== Interface Drift Detector ==="
    Write-Output "Verdict: $verdict"
    Write-Output "Drifts: $($drifts.Count) | Errors: $($errors.Count) | Passes: $($passes.Count)"
    foreach ($d in $drifts) { Write-Output "  [DRIFT] $($d.detail)" }
}

exit $exitCode