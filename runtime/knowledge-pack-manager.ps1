# Codex Factory V4.0 — Knowledge Pack Manager
# Usage: powershell -File runtime/knowledge-pack-manager.ps1 -Action <add|list|validate|remove|index> [-Name <name>] [-Source <path>]

param([Parameter(Mandatory=$true)][string]$Action, [string]$Name, [string]$Source, [switch]$Json)

$kbDir = "knowledge"
$packsDir = "$kbDir/packs"
$indexFile = "$kbDir/index.json"
foreach ($d in @($kbDir, $packsDir)) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null } }

$result = @{ action=$Action; timestamp=(Get-Date -Format "o"); status="OK" }

function Get-Index {
    if (Test-Path $indexFile) { return Get-Content $indexFile -Raw | ConvertFrom-Json }
    return @{ packs=@(); updated=(Get-Date -Format "o") }
}

function Save-Index($idx) {
    $idx.updated = (Get-Date -Format "o")
    $idx | ConvertTo-Json -Depth 4 | Out-File -FilePath $indexFile -Encoding utf8 -NoNewline
}

switch ($Action) {
    "add" {
        if (-not $Name -or -not $Source) { $result.status="ERROR"; $result.detail="Name and Source required"; break }
        if (-not (Test-Path $Source)) { $result.status="ERROR"; $result.detail="Source not found: $Source"; break }
        $packPath = "$packsDir/$Name"
        New-Item -ItemType Directory -Force -Path $packPath | Out-Null
        $files = Get-ChildItem $Source -Recurse -File | Where-Object { $_.Extension -match '\.(md|txt|json|ya?ml|openapi)$' -and $_.Name -notmatch 'private|secret|\.env' }
        $manifest = @()
        foreach ($f in $files) {
            $rel = $f.FullName.Replace((Resolve-Path $Source).Path, '').TrimStart('\','/')
            $dest = "$packPath/$rel"
            $destDir = Split-Path $dest -Parent
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
            Copy-Item $f.FullName $dest -Force
            $hash = (Get-FileHash $dest -Algorithm SHA256).Hash
            $manifest += @{ path=$rel; sha256=$hash; size=$f.Length; source=$f.FullName }
        }
        $manifest | ConvertTo-Json -Depth 3 | Out-File -FilePath "$packPath/source-map.json" -Encoding utf8
        $idx = Get-Index
        $idx.packs = @($idx.packs | Where-Object { $_.name -ne $Name }) + @{ name=$Name; path=$packPath; files=$files.Count; added=(Get-Date -Format "o") }
        Save-Index $idx
        $result.detail = "Added $($files.Count) files to knowledge pack: $Name"
    }
    "list" {
        $idx = Get-Index
        $result.packs = $idx.packs
        $result.count = $idx.packs.Count
    }
    "validate" {
        if ($Name) { $packs = @($Name) } else { $packs = @(Get-ChildItem $packsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) }
        $result.details = @()
        foreach ($p in $packs) {
            $sm = "$packsDir/$p/source-map.json"
            $valid = Test-Path $sm
            $missing = if ($valid) { 
                $map = Get-Content $sm -Raw | ConvertFrom-Json
                @($map | Where-Object { -not (Test-Path "$packsDir/$p/$($_.path)") } | ForEach-Object { $_.path })
            } else { @() }
            $result.details += @{ pack=$p; hasSourceMap=$valid; missingFiles=$missing.Count; valid=($valid -and $missing.Count -eq 0) }
        }
        $result.status = if (($result.details | Where-Object { -not $_.valid }).Count -eq 0) { "VALID" } else { "DRIFT_DETECTED" }
    }
    "remove" {
        if (-not $Name) { $result.status="ERROR"; $result.detail="Name required"; break }
        $packPath = "$packsDir/$Name"
        if (-not (Test-Path $packPath)) { $result.status="NOT_FOUND"; break }
        Remove-Item $packPath -Recurse -Force
        $idx = Get-Index; $idx.packs = @($idx.packs | Where-Object { $_.name -ne $Name }); Save-Index $idx
        $result.detail = "Removed: $Name"
    }
    "index" {
        $idx = Get-Index
        $keywords = @{}
        foreach ($p in $idx.packs) {
            $smPath = "$packsDir/$($p.name)/source-map.json"
            if (Test-Path $smPath) {
                $map = Get-Content $smPath -Raw | ConvertFrom-Json
                foreach ($entry in $map) {
                    $content = Get-Content "$packsDir/$($p.name)/$($entry.path)" -Raw -ErrorAction SilentlyContinue
                    if ($content) {
                        $words = [regex]::Matches($content.ToLower(), '\b[a-z0-9_-]{4,}\b') | ForEach-Object { $_.Value } | Select-Object -Unique
                        foreach ($w in $words) { if (-not $keywords[$w]) { $keywords[$w] = @() }; $keywords[$w] += "$($p.name)/$($entry.path)" }
                    }
                }
            }
        }
        $result.keywordCount = $keywords.Count
        $keywords | ConvertTo-Json -Depth 3 | Out-File -FilePath "$kbDir/keyword-index.json" -Encoding utf8
        $result.detail = "Indexed $($keywords.Count) keywords across $($idx.packs.Count) packs"
    }

    "build-evidence" {
        if ($Name) { $packs = @($Name) } else { $idx = Get-Index; $packs = @($idx.packs | ForEach-Object { # Codex Factory V4.0 — Knowledge Pack Manager
# Usage: powershell -File runtime/knowledge-pack-manager.ps1 -Action <add|list|validate|remove|index> [-Name <name>] [-Source <path>]

param([Parameter(Mandatory=$true)][string]$Action, [string]$Name, [string]$Source, [switch]$Json)

$kbDir = "knowledge"
$packsDir = "$kbDir/packs"
$indexFile = "$kbDir/index.json"
foreach ($d in @($kbDir, $packsDir)) { if (-not (Test-Path $d)) { New-Item -ItemType Directory -Force -Path $d | Out-Null } }

$result = @{ action=$Action; timestamp=(Get-Date -Format "o"); status="OK" }

function Get-Index {
    if (Test-Path $indexFile) { return Get-Content $indexFile -Raw | ConvertFrom-Json }
    return @{ packs=@(); updated=(Get-Date -Format "o") }
}

function Save-Index($idx) {
    $idx.updated = (Get-Date -Format "o")
    $idx | ConvertTo-Json -Depth 4 | Out-File -FilePath $indexFile -Encoding utf8 -NoNewline
}

switch ($Action) {
    "add" {
        if (-not $Name -or -not $Source) { $result.status="ERROR"; $result.detail="Name and Source required"; break }
        if (-not (Test-Path $Source)) { $result.status="ERROR"; $result.detail="Source not found: $Source"; break }
        $packPath = "$packsDir/$Name"
        New-Item -ItemType Directory -Force -Path $packPath | Out-Null
        $files = Get-ChildItem $Source -Recurse -File | Where-Object { $_.Extension -match '\.(md|txt|json|ya?ml|openapi)$' -and $_.Name -notmatch 'private|secret|\.env' }
        $manifest = @()
        foreach ($f in $files) {
            $rel = $f.FullName.Replace((Resolve-Path $Source).Path, '').TrimStart('\','/')
            $dest = "$packPath/$rel"
            $destDir = Split-Path $dest -Parent
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
            Copy-Item $f.FullName $dest -Force
            $hash = (Get-FileHash $dest -Algorithm SHA256).Hash
            $manifest += @{ path=$rel; sha256=$hash; size=$f.Length; source=$f.FullName }
        }
        $manifest | ConvertTo-Json -Depth 3 | Out-File -FilePath "$packPath/source-map.json" -Encoding utf8
        $idx = Get-Index
        $idx.packs = @($idx.packs | Where-Object { $_.name -ne $Name }) + @{ name=$Name; path=$packPath; files=$files.Count; added=(Get-Date -Format "o") }
        Save-Index $idx
        $result.detail = "Added $($files.Count) files to knowledge pack: $Name"
    }
    "list" {
        $idx = Get-Index
        $result.packs = $idx.packs
        $result.count = $idx.packs.Count
    }
    "validate" {
        if ($Name) { $packs = @($Name) } else { $packs = @(Get-ChildItem $packsDir -Directory -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }) }
        $result.details = @()
        foreach ($p in $packs) {
            $sm = "$packsDir/$p/source-map.json"
            $valid = Test-Path $sm
            $missing = if ($valid) { 
                $map = Get-Content $sm -Raw | ConvertFrom-Json
                @($map | Where-Object { -not (Test-Path "$packsDir/$p/$($_.path)") } | ForEach-Object { $_.path })
            } else { @() }
            $result.details += @{ pack=$p; hasSourceMap=$valid; missingFiles=$missing.Count; valid=($valid -and $missing.Count -eq 0) }
        }
        $result.status = if (($result.details | Where-Object { -not $_.valid }).Count -eq 0) { "VALID" } else { "DRIFT_DETECTED" }
    }
    "remove" {
        if (-not $Name) { $result.status="ERROR"; $result.detail="Name required"; break }
        $packPath = "$packsDir/$Name"
        if (-not (Test-Path $packPath)) { $result.status="NOT_FOUND"; break }
        Remove-Item $packPath -Recurse -Force
        $idx = Get-Index; $idx.packs = @($idx.packs | Where-Object { $_.name -ne $Name }); Save-Index $idx
        $result.detail = "Removed: $Name"
    }
    "index" {
        $idx = Get-Index
        $keywords = @{}
        foreach ($p in $idx.packs) {
            $smPath = "$packsDir/$($p.name)/source-map.json"
            if (Test-Path $smPath) {
                $map = Get-Content $smPath -Raw | ConvertFrom-Json
                foreach ($entry in $map) {
                    $content = Get-Content "$packsDir/$($p.name)/$($entry.path)" -Raw -ErrorAction SilentlyContinue
                    if ($content) {
                        $words = [regex]::Matches($content.ToLower(), '\b[a-z0-9_-]{4,}\b') | ForEach-Object { $_.Value } | Select-Object -Unique
                        foreach ($w in $words) { if (-not $keywords[$w]) { $keywords[$w] = @() }; $keywords[$w] += "$($p.name)/$($entry.path)" }
                    }
                }
            }
        }
        $result.keywordCount = $keywords.Count
        $keywords | ConvertTo-Json -Depth 3 | Out-File -FilePath "$kbDir/keyword-index.json" -Encoding utf8
        $result.detail = "Indexed $($keywords.Count) keywords across $($idx.packs.Count) packs"
    }
    default { $result.status="ERROR"; $result.detail="Unknown action. Use add|list|validate|remove|index|build-evidence" }
}

if ($Json) { $result | ConvertTo-Json -Depth 4 }
else { Write-Output "Knowledge Pack Manager: $Action — $($result.status): $($result.detail)" }
.name }) }
        $evidenceDir = "knowledge/evidence"
        if (-not (Test-Path $evidenceDir)) { New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null }
        $evidenceEntries = @()
        foreach ($pn in $packs) {
            $smPath = "$packsDir/$pn/source-map.json"
            if (-not (Test-Path $smPath)) { continue }
            $map = Get-Content $smPath -Raw | ConvertFrom-Json
            foreach ($entry in $map) {
                $filePath = "$packsDir/$pn/$($entry.path)"
                if (-not (Test-Path $filePath)) { continue }
                $content = Get-Content $filePath -Raw -ErrorAction SilentlyContinue
                $lines = $content -split "`n"
                $evidenceEntries += @{
                    source_file = "$pn/$($entry.path)"
                    source_hash = $entry.sha256
                    source_size = $entry.size
                    evidence_type = if ($entry.path -match '\.ya?ml$|openapi') { "spec" } elseif ($entry.path -match '\.md. Use add|list|validate|remove|index|build-evidence" }
}

if ($Json) { $result | ConvertTo-Json -Depth 4 }
else { Write-Output "Knowledge Pack Manager: $Action — $($result.status): $($result.detail)" }
) { "documentation" } elseif ($entry.path -match '\.json. Use add|list|validate|remove|index|build-evidence" }
}

if ($Json) { $result | ConvertTo-Json -Depth 4 }
else { Write-Output "Knowledge Pack Manager: $Action — $($result.status): $($result.detail)" }
) { "structured_data" } else { "text" }
                    line_count = $lines.Count
                    preview_first_200_chars = if ($content.Length -gt 200) { $content.Substring(0,200) + "..." } else { $content }
                    extracted_at = (Get-Date -Format "o")
                }
            }
        }
        $evidence = @{
            generated_at = (Get-Date -Format "o")
            source_packs = $packs
            total_entries = $evidenceEntries.Count
            entries = $evidenceEntries
            non_claims = @(
                "Knowledge pack content enters Evidence Pack with full source traceability",
                "Each entry has source_file, source_hash, and line_count",
                "No raw content is injected into prompts without source attribution",
                "User knowledge is local-only by default"
            )
        }
        $evidence | ConvertTo-Json -Depth 4 | Out-File -FilePath "$evidenceDir/evidence-pack.json" -Encoding utf8 -NoNewline
        $result.detail = "Evidence pack generated: $($evidenceEntries.Count) entries from $($packs.Count) packs"
        $result.evidence_path = "$evidenceDir/evidence-pack.json"
    }
    default { $result.status="ERROR"; $result.detail="Unknown action. Use add|list|validate|remove|index|build-evidence" }
}

if ($Json) { $result | ConvertTo-Json -Depth 4 }
else { Write-Output "Knowledge Pack Manager: $Action — $($result.status): $($result.detail)" }
