# Codex Factory V4.0 — Skill Pack Manager
# Usage: powershell -File runtime/skill-pack-manager.ps1 -Action <list|create|validate|remove> [-Name <name>] [-Json]

param([Parameter(Mandatory=$true)][string]$Action, [string]$Name, [switch]$Json)

$packsDir = "packs"
if (-not (Test-Path $packsDir)) { New-Item -ItemType Directory -Force -Path $packsDir | Out-Null }

$result = @{ action=$Action; timestamp=(Get-Date -Format "o"); status="OK"; details=@() }

switch ($Action) {
    "list" {
        $packs = Get-ChildItem $packsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_template" }
        $result.details = @($packs | ForEach-Object { 
            $manifest = if (Test-Path "$($_.FullName)/pack.json") { Get-Content "$($_.FullName)/pack.json" -Raw | ConvertFrom-Json } else { $null }
            @{ name=$_.Name; hasManifest=($manifest -ne $null); description=if($manifest){$manifest.description}else{"No manifest"} }
        })
        $result.count = $result.details.Count
    }
    "create" {
        if (-not $Name) { $result.status="ERROR"; $result.detail="Name required"; break }
        $packPath = "$packsDir/$Name"
        if (Test-Path $packPath) { $result.status="EXISTS"; break }
        New-Item -ItemType Directory -Force -Path $packPath | Out-Null
        Copy-Item "$packsDir/_template/*" $packPath -Recurse -Force -ErrorAction SilentlyContinue
        @{
            name=$Name; version="1.0.0"; description="User-created skill pack: $Name"
            requires=@(); provides=@(); validations=@()
        } | ConvertTo-Json -Depth 3 | Out-File -FilePath "$packPath/pack.json" -Encoding utf8
        $result.detail = "Created: $packPath"
    }
    "validate" {
        if (-not $Name) { 
            $packs = Get-ChildItem $packsDir -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne "_template" }
            foreach ($p in $packs) { 
                $valid = Test-Path "$($p.FullName)/pack.json"
                $result.details += @{name=$p.Name; valid=$valid; reason=if($valid){"OK"}else{"Missing pack.json"}}
            }
        } else {
            $valid = Test-Path "$packsDir/$Name/pack.json"
            $result.details += @{name=$Name; valid=$valid}
        }
        $result.status = if (($result.details | Where-Object { -not $_.valid }).Count -eq 0) { "VALID" } else { "INVALID" }
    }
    "remove" {
        if (-not $Name) { $result.status="ERROR"; $result.detail="Name required"; break }
        $packPath = "$packsDir/$Name"
        if (-not (Test-Path $packPath)) { $result.status="NOT_FOUND"; break }
        Remove-Item $packPath -Recurse -Force
        $result.detail = "Removed: $Name"
    }
    default {
        $result.status="ERROR"; $result.detail="Unknown action: $Action. Use list|create|validate|remove"
    }
}

if ($Json) { $result | ConvertTo-Json -Depth 4 }
else { Write-Output "Skill Pack Manager: $Action — $($result.status)"; if ($result.details) { $result.details | ForEach-Object { Write-Output "  $($_.name): $($_.valid)$($_.description)" } } }
