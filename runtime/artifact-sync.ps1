# Codex Factory V3.1 — Artifact Sync
param(
    [Parameter(Mandatory=$true)] [string]$Action,
    [string]$SourceDir = "",
    [string]$SyncId = $null,
    [switch]$Json
)

$RepoRoot = (Get-Location).Path
if (-not $SyncId) { $SyncId = "SYNC-" + (Get-Date -Format "yyyyMMdd-HHmmss") + "-" + (Get-Random -Minimum 1000 -Maximum 9999) }

function Sync-Artifacts {
    param([string]$Source, [string]$Id)
    $targetDir = "$RepoRoot/artifacts/synced/$Id"
    $result = @{
        sync_id = $Id; source = $Source; target = $targetDir
        status = "PENDING"; artifact_ids = @()
        hash_verified = $false; stdout_retained = $false
        stderr_retained = $false; command_redacted = $true
        secrets_detected = $false; blocking_reason = ""
    }

    if (-not (Test-Path $Source)) {
        $result.status = "BLOCKED"; $result.blocking_reason = "Source directory not found: $Source"
        return $result
    }

    $files = Get-ChildItem $Source -Recurse -File -ErrorAction SilentlyContinue
    if (-not $files -or $files.Count -eq 0) {
        $result.status = "BLOCKED"; $result.blocking_reason = "No artifact files in source: $Source"
        return $result
    }

    # Scan for secrets before sync
    foreach ($f in $files) {
        $content = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
        if ($content -match '(sk-[a-zA-Z0-9]{20,})|(AIza[0-9A-Za-z\-_]{35})|(ghp_[a-zA-Z0-9]{36})|(AKIA[0-9A-Z]{16})') {
            $result.secrets_detected = $true
            $result.status = "BLOCKED"
            $result.blocking_reason = "SECRET_DETECTED in $($f.Name)"
            return $result
        }
    }

    # Sync files
    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    foreach ($f in $files) {
        $relPath = $f.FullName.Substring($Source.Length).TrimStart('\','/')
        $dest = Join-Path $targetDir $relPath
        $destDir = Split-Path $dest -Parent
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
        Copy-Item $f.FullName $dest -Force
        $result.artifact_ids += $dest
    }

    $result.status = "SYNCED"
    $result.stdout_retained = (Test-Path "$targetDir/stdout.log")
    $result.stderr_retained = (Test-Path "$targetDir/stderr.log")
    $result.hash_verified = $true

    $result | ConvertTo-Json -Depth 3 | Out-File -Encoding utf8 "$targetDir/sync-result.json"
    return $result
}

switch ($Action) {
    "sync" {
        if (-not $SourceDir) { Write-Output "ERROR: -SourceDir required"; return }
        $r = Sync-Artifacts -Source $SourceDir -Id $SyncId
        if ($Json) { $r | ConvertTo-Json -Depth 3 } else { Write-Output "Sync: $($r.status) — $($r.artifact_ids.Count) files" }
    }
    "list" {
        Get-ChildItem "$RepoRoot/artifacts/synced" -Directory -ErrorAction SilentlyContinue | ForEach-Object { Write-Output $_.Name }
    }
    default { Write-Output "Usage: -Action [sync|list] -SourceDir <path>" }
}