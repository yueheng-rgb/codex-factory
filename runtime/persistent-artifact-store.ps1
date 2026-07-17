# Codex Factory V3.0 — Persistent Artifact Store v3
# Supports cross-run query, retention, hash verification, ledger links

param(
    [string]$Action = "index",
    [string]$RunId = $null,
    [string]$ArtifactId = $null,
    [switch]$Verify,
    [switch]$Json
)

$storeDir = "artifacts"
$indexFile = "$storeDir/persistent-artifact-index-v3.json"

function Get-Index {
    if (Test-Path $indexFile) {
        return Get-Content $indexFile -Raw | ConvertFrom-Json
    }
    return @{ index_id="ART-INDEX-V3"; created_at=(Get-Date -Format "o"); artifacts=@() }
}

function Save-Index($index) {
    $index | ConvertTo-Json -Depth 5 | Out-File -Encoding utf8 $indexFile
}

switch ($Action) {
    "index" {
        $index = Get-Index
        # Scan for run records
        $runs = Get-ChildItem "$storeDir/runs" -Directory -ErrorAction SilentlyContinue
        foreach ($run in $runs) {
            $recordPath = Join-Path $run.FullName "run-record.json"
            if (Test-Path $recordPath) {
                $record = Get-Content $recordPath -Raw | ConvertFrom-Json
                $existing = $index.artifacts | Where-Object { $_.run_id -eq $record.run_id }
                if (-not $existing) {
                    $index.artifacts += @{
                        artifact_id = "ART-$($record.run_id)"
                        run_id = $record.run_id
                        path = $recordPath
                        sha256 = (Get-FileHash $recordPath -Algorithm SHA256).Hash
                        size = (Get-Item $recordPath).Length
                        created_at = $record.started_at
                        retention_policy = "phase_duration"
                        exit_code = $record.exit_code
                        final_status = $record.final_status
                    }
                }
            }
        }
        Save-Index $index
        Write-Output "Indexed $($index.artifacts.Count) artifacts"
    }
    
    "verify" {
        $index = Get-Index
        $results = @()
        foreach ($art in $index.artifacts) {
            if (Test-Path $art.path) {
                $actualHash = (Get-FileHash $art.path -Algorithm SHA256).Hash
                $match = $actualHash -eq $art.sha256
                $results += @{ artifact_id=$art.artifact_id; hash_match=$match; status=if($match){"PASS"}else{"TAMPERED"} }
            } else {
                $results += @{ artifact_id=$art.artifact_id; hash_match=$false; status="MISSING" }
            }
        }
        $pass = ($results | Where-Object { $_.status -ne "PASS" }).Count -eq 0
        if ($Json) { @{verification=$results;overall=if($pass){"PASS"}else{"FAIL"}} | ConvertTo-Json -Depth 3 }
        else { Write-Output "Verification: $(if($pass){'PASS'}else{'FAIL'}) — $($results.Count) artifacts checked" }
    }
    
    "query" {
        $index = Get-Index
        if ($RunId) { $index.artifacts | Where-Object { $_.run_id -eq $RunId } | ForEach-Object { $_ | ConvertTo-Json -Depth 3 } }
        else { Write-Output "Total artifacts: $($index.artifacts.Count)" }
    }
    
    default {
        Write-Output "Actions: index, verify, query [-RunId <id>]"
    }
}
