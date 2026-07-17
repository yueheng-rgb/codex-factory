# Capability Registry Diff Tool
# Part of: FACTORY-R2.3-D-CAPABILITY-GOVERNANCE-INTEGRATION
# Compares current registries against previous snapshot, detects drift.
# Usage: . .\runtime\capability-registry-diff.ps1; Save-RegistrySnapshot; Get-RegistryDiff

param(
    [string]$FactoryRoot = "C:\Codex_App_Factory"
)

$script:SnapDir = Join-Path $FactoryRoot "governance\capability-registry-snapshots"
$script:RegDir  = Join-Path $FactoryRoot "registries"

. (Join-Path $FactoryRoot "runtime\registry-integrity-check.ps1")

function Save-RegistrySnapshot {
    param([string]$Label = "")
    if (-not $Label) { $Label = "snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss')" }
    if (-not (Test-Path $script:SnapDir)) { New-Item -ItemType Directory -Path $script:SnapDir -Force | Out-Null }

    $snapPath = Join-Path $script:SnapDir $Label
    if (-not (Test-Path $snapPath)) { New-Item -ItemType Directory -Path $snapPath -Force | Out-Null }

    $manifest = @{ snapshotId = $Label; createdAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"; files = @() }

    foreach ($reg in $script:RegistryFiles.GetEnumerator()) {
        $src = Join-Path $script:RegDir $reg.Value
        if (Test-Path $src) {
            $dst = Join-Path $snapPath $reg.Value
            Copy-Item $src $dst -Force
            $hash = (Get-FileHash $src -Algorithm SHA256).Hash
            $manifest.files += @{ name = $reg.Value; registry = $reg.Key; sha256 = $hash }
        }
    }

    $manifest | ConvertTo-Json -Depth 3 | Out-File (Join-Path $snapPath "snapshot-manifest.json") -Encoding UTF8
    Write-Host "SNAPSHOT: Saved to $snapPath" -ForegroundColor Green
    return $snapPath
}

function Get-RegistryDiff {
    param([string]$SnapshotLabel = "", [string]$SnapshotPath = "")

    if (-not $SnapshotPath -and -not $SnapshotLabel) {
        $snaps = Get-ChildItem $script:SnapDir -Directory | Sort-Object Name -Descending
        if ($snaps.Count -eq 0) { Write-Warning "DIFF: No snapshots found."; return $null }
        $SnapshotPath = $snaps[0].FullName; $SnapshotLabel = $snaps[0].Name
    } elseif ($SnapshotLabel -and -not $SnapshotPath) {
        $SnapshotPath = Join-Path $script:SnapDir $SnapshotLabel
    }
    if (-not (Test-Path $SnapshotPath)) { Write-Error "DIFF: Snapshot not found: $SnapshotPath"; return $null }

    Write-Host "DIFF: Comparing current vs: $SnapshotLabel" -ForegroundColor Yellow

    $changes = [PSCustomObject]@{
        snapshotId=$SnapshotLabel; comparedAt=(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
        added=@(); removed=@(); trustChanged=@(); actionChanged=@(); riskChanged=@()
        secretsChanged=@(); networkChanged=@(); fileWriteChanged=@(); cloudChanged=@(); priorityChanged=@()
        totalChanges=0; currentEntryCount=0; snapshotEntryCount=0
    }

    $currentEntries = @{}
    $masterFile = Join-Path $script:RegDir $script:RegistryFiles["master"]
    if (Test-Path $masterFile) {
        $entries = Get-RegistryEntries -FilePath $masterFile
        foreach ($e in $entries) { if ($e.capabilityId) { $currentEntries[$e.capabilityId] = $e } }
    }
    $changes.currentEntryCount = $currentEntries.Count

    $snapEntries = @{}
    $snapMaster = Join-Path $SnapshotPath $script:RegistryFiles["master"]
    if (Test-Path $snapMaster) {
        $entries = Get-RegistryEntries -FilePath $snapMaster
        foreach ($e in $entries) { if ($e.capabilityId) { $snapEntries[$e.capabilityId] = $e } }
    }
    $changes.snapshotEntryCount = $snapEntries.Count

    # Detect added
    $added = @()
    foreach ($cid in $currentEntries.Keys) {
        if (-not $snapEntries.ContainsKey($cid)) {
            $added += [PSCustomObject]@{ capabilityId=$cid; name=$currentEntries[$cid].name; type=$currentEntries[$cid].type }
        }
    }
    $changes.added = $added

    # Detect removed
    $removed = @()
    foreach ($cid in $snapEntries.Keys) {
        if (-not $currentEntries.ContainsKey($cid)) {
            $removed += [PSCustomObject]@{ capabilityId=$cid; name=$snapEntries[$cid].name; type=$snapEntries[$cid].type }
        }
    }
    $changes.removed = $removed

    # Detect field changes
    $trustCh = @(); $actionCh = @(); $riskCh = @(); $secretsCh = @()
    $networkCh = @(); $fwCh = @(); $cloudCh = @(); $prioCh = @()

    foreach ($cid in $currentEntries.Keys) {
        if (-not $snapEntries.ContainsKey($cid)) { continue }
        $cur = $currentEntries[$cid]; $snap = $snapEntries[$cid]

        if ($cur.trustLevel -ne $snap.trustLevel) {
            $trustCh += [PSCustomObject]@{ capabilityId=$cid; name=$cur.name; old=$snap.trustLevel; new=$cur.trustLevel }
        }
        if ($cur.recommendedAction -ne $snap.recommendedAction) {
            $actionCh += [PSCustomObject]@{ capabilityId=$cid; name=$cur.name; old=$snap.recommendedAction; new=$cur.recommendedAction }
        }
        if ($cur.securityRisk -ne $snap.securityRisk) {
            $riskCh += [PSCustomObject]@{ capabilityId=$cid; name=$cur.name; old=$snap.securityRisk; new=$cur.securityRisk }
        }
        $curSecCount = if ($cur.requiredSecrets -is [array]) { $cur.requiredSecrets.Count } else { 0 }
        $snapSecCount = if ($snap.requiredSecrets -is [array]) { $snap.requiredSecrets.Count } else { 0 }
        if ($curSecCount -ne $snapSecCount) {
            $secretsCh += [PSCustomObject]@{ capabilityId=$cid; name=$cur.name; old_count=$snapSecCount; new_count=$curSecCount }
        }
        $curNet = ($cur.networkAccess -eq $true -or $cur.networkAccess -eq "true")
        $snapNet = ($snap.networkAccess -eq $true -or $snap.networkAccess -eq "true")
        if ($curNet -ne $snapNet) {
            $networkCh += [PSCustomObject]@{ capabilityId=$cid; name=$cur.name; old=$snapNet; new=$curNet }
        }
        $curFW = ($cur.fileWriteAccess -eq $true -or $cur.fileWriteAccess -eq "true")
        $snapFW = ($snap.fileWriteAccess -eq $true -or $snap.fileWriteAccess -eq "true")
        if ($curFW -ne $snapFW) {
            $fwCh += [PSCustomObject]@{ capabilityId=$cid; name=$cur.name; old=$snapFW; new=$curFW }
        }
        $curCL = ($cur.cloudRequired -eq $true -or $cur.cloudRequired -eq "true")
        $snapCL = ($snap.cloudRequired -eq $true -or $snap.cloudRequired -eq "true")
        if ($curCL -ne $snapCL) {
            $cloudCh += [PSCustomObject]@{ capabilityId=$cid; name=$cur.name; old=$snapCL; new=$curCL }
        }
        if ($cur.priority -ne $snap.priority) {
            $prioCh += [PSCustomObject]@{ capabilityId=$cid; name=$cur.name; old=$snap.priority; new=$cur.priority }
        }
    }

    $changes.trustChanged = $trustCh; $changes.actionChanged = $actionCh
    $changes.riskChanged = $riskCh; $changes.secretsChanged = $secretsCh
    $changes.networkChanged = $networkCh; $changes.fileWriteChanged = $fwCh
    $changes.cloudChanged = $cloudCh; $changes.priorityChanged = $prioCh

    $totalChanges = $added.Count + $removed.Count + $trustCh.Count + $actionCh.Count +
        $riskCh.Count + $secretsCh.Count + $networkCh.Count + $fwCh.Count +
        $cloudCh.Count + $prioCh.Count
    $changes.totalChanges = $totalChanges

    Write-Host "DIFF: $totalChanges changes | Current: $($currentEntries.Count) entries | Snapshot: $($snapEntries.Count) entries" -ForegroundColor $(if($totalChanges -gt 0){'Yellow'}else{'Green'})
    Write-Host "  Added: $($added.Count) | Removed: $($removed.Count) | Trust: $($trustCh.Count) | Action: $($actionCh.Count)" -ForegroundColor White
    return $changes
}

Write-Verbose "Capability Registry Diff Tool loaded."
