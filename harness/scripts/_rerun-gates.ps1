param($runDir, $scripts, $phase)
foreach ($w in 1..4) {
    & "$scripts\compare-worker-manifest-to-source.ps1" `
        -WorkerManifestPath "$runDir\worker-interface-manifests\worker-$w-interface-manifest.json" `
        -SourceManifestPath "$runDir\source-derived-interface-manifests\worker-$w.json" `
        -OutputReportPath "$runDir\reports\honesty-w$w.json" -Phase $phase 2>&1 | Out-Null
    $r = Get-Content "$runDir\reports\honesty-w$w.json" -Raw | ConvertFrom-Json
    Write-Host "Honesty W$w : $($r.verdict)"
}
& "$scripts\detect-interface-drift.ps1" -ContractPath "$runDir\interface-contract.lock.json" `
    -ManifestsDir "$runDir\worker-interface-manifests" -OutputReportPath "$runDir\reports\drift.json" 2>&1 | Select-Object -Last 3
$dr = Get-Content "$runDir\reports\drift.json" -Raw | ConvertFrom-Json
Write-Host "Drift: $($dr.verdict) count=$($dr.driftCount)"
