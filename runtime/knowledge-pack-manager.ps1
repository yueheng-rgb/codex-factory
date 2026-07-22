# Codex Factory V4 compatibility - Knowledge Pack Manager
#
# This script preserves the legacy actions while applying fail-closed path,
# integrity, and secret-safety checks. V5 users should prefer:
#   factoryctl knowledge import|query|verify

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [Alias("Command")]
    [string]$Action,

    [string]$Name,
    [string]$Source,
    [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:ProjectRoot = [System.IO.Path]::GetFullPath((Get-Location).ProviderPath)
$script:KnowledgeDir = Join-Path $script:ProjectRoot "knowledge"
$script:PacksDir = Join-Path $script:KnowledgeDir "packs"
$script:EvidenceDir = Join-Path $script:KnowledgeDir "evidence"
$script:IndexFile = Join-Path $script:KnowledgeDir "index.json"
$script:KeywordIndexFile = Join-Path $script:KnowledgeDir "keyword-index.json"
$script:IsWindowsPlatform = ($env:OS -match "Windows")
$script:PathComparison = if ($script:IsWindowsPlatform) {
    [System.StringComparison]::OrdinalIgnoreCase
} else {
    [System.StringComparison]::Ordinal
}
$script:AllowedExtensions = @(".md", ".txt", ".json", ".yaml", ".yml", ".openapi")
$script:MaxSourceFileBytes = 10MB

$result = [ordered]@{
    action = $Action.ToLowerInvariant()
    timestamp = (Get-Date -Format "o")
    status = "OK"
    compatibility = "V4_LEGACY_SAFE_MODE"
    v5_recommendation = "Prefer: factoryctl knowledge import|query|verify"
}
$exitCode = 0

function Test-PathInside {
    param(
        [Parameter(Mandatory = $true)][string]$Child,
        [Parameter(Mandatory = $true)][string]$Parent,
        [switch]$AllowEqual
    )

    $childFull = [System.IO.Path]::GetFullPath($Child)
    $parentFull = [System.IO.Path]::GetFullPath($Parent)
    if ($AllowEqual -and $childFull.Equals($parentFull, $script:PathComparison)) {
        return $true
    }

    $separator = [System.IO.Path]::DirectorySeparatorChar
    $alternate = [System.IO.Path]::AltDirectorySeparatorChar
    $parentPrefix = $parentFull
    if (-not $parentPrefix.EndsWith([string]$separator) -and -not $parentPrefix.EndsWith([string]$alternate)) {
        $parentPrefix += $separator
    }

    return $childFull.StartsWith($parentPrefix, $script:PathComparison)
}

function Assert-ProjectPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [switch]$AllowProjectRoot
    )

    $full = [System.IO.Path]::GetFullPath($Path)
    if (-not (Test-PathInside -Child $full -Parent $script:ProjectRoot -AllowEqual:$AllowProjectRoot)) {
        throw "Path escapes the current project root. Only project-contained paths are allowed."
    }
    return $full
}

function Assert-SafePackName {
    param([Parameter(Mandatory = $true)][string]$PackName)

    if ($PackName.Length -gt 64 -or $PackName -notmatch '^[\p{L}\p{N}][\p{L}\p{N}._-]*$') {
        throw "Invalid pack name. Use 1-64 letters, numbers, dot, underscore, or hyphen; start with a letter or number."
    }
    if ($PackName -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$') {
        throw "Invalid pack name: reserved device names are not allowed."
    }
}

function Get-ProjectRelativePath {
    param([Parameter(Mandatory = $true)][string]$Path)

    $full = Assert-ProjectPath -Path $Path -AllowProjectRoot
    if ($full.Equals($script:ProjectRoot, $script:PathComparison)) {
        return "."
    }
    $relative = $full.Substring($script:ProjectRoot.Length).TrimStart('\', '/')
    return ($relative -replace '\\', '/')
}

function Assert-NoReparsePoint {
    param([Parameter(Mandatory = $true)][string]$Path)

    $current = Get-Item -LiteralPath $Path -Force
    while ($null -ne $current) {
        if (($current.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Reparse points (symlinks/junctions) are not accepted by the legacy knowledge importer."
        }
        if ($current.FullName.Equals($script:ProjectRoot, $script:PathComparison)) {
            break
        }
        if (-not (Test-PathInside -Child $current.FullName -Parent $script:ProjectRoot -AllowEqual)) {
            throw "Resolved path escapes the current project root."
        }
        if ($current -is [System.IO.DirectoryInfo]) {
            $current = $current.Parent
        } else {
            $current = $current.Directory
        }
    }
}

function Test-SensitiveSourcePath {
    param([Parameter(Mandatory = $true)][string]$ProjectRelativePath)

    $normalized = ($ProjectRelativePath -replace '\\', '/').Trim('/')
    $segments = @($normalized -split '/')
    foreach ($segment in $segments) {
        if ($segment -match '^(?i:\.git|\.env(?:\..*)?|private|secret|secrets|node_modules|\.codex-factory)$') {
            return $true
        }
    }
    return $false
}

function Test-PotentialSecretContent {
    param([Parameter(Mandatory = $true)][string]$Content)

    if ($Content -match '-----BEGIN (?:RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----') {
        return $true
    }
    if ($Content -match '\bAKIA[0-9A-Z]{16}\b') {
        return $true
    }
    if ($Content -match '(?i)\b(?:sk|rk|pk)-(?:live-|test-)?[a-z0-9_-]{20,}\b') {
        return $true
    }

    $assignmentPattern = '(?i)\b(?:api[_-]?key|access[_-]?token|auth[_-]?token|client[_-]?secret|password)\s*[:=]\s*["'']?([a-z0-9_./+=-]{20,})["'']?'
    foreach ($match in [regex]::Matches($Content, $assignmentPattern)) {
        $candidate = $match.Groups[1].Value
        if ($candidate -notmatch '(?i)placeholder|example|replace|your[-_]?key|change[-_]?me|dummy|sample') {
            return $true
        }
    }
    return $false
}

function Write-JsonAtomic {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object]$Value,
        [int]$Depth = 12
    )

    $full = Assert-ProjectPath -Path ([System.IO.Path]::GetFullPath($Path))
    $parent = Split-Path -Parent $full
    if (-not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    $temporary = Join-Path $parent (([System.IO.Path]::GetFileName($full)) + ".tmp-" + [guid]::NewGuid().ToString("N"))
    $backup = Join-Path $parent (([System.IO.Path]::GetFileName($full)) + ".bak-" + [guid]::NewGuid().ToString("N"))
    $encoding = New-Object System.Text.UTF8Encoding -ArgumentList $false
    try {
        $jsonText = ConvertTo-Json -InputObject $Value -Depth $Depth
        [System.IO.File]::WriteAllText($temporary, $jsonText, $encoding)
        if (Test-Path -LiteralPath $full -PathType Leaf) {
            [System.IO.File]::Replace($temporary, $full, $backup)
            if (Test-Path -LiteralPath $backup -PathType Leaf) {
                Remove-Item -LiteralPath $backup -Force
            }
        } else {
            [System.IO.File]::Move($temporary, $full)
        }
    } finally {
        if (Test-Path -LiteralPath $temporary -PathType Leaf) {
            Remove-Item -LiteralPath $temporary -Force
        }
        if (Test-Path -LiteralPath $backup -PathType Leaf) {
            Remove-Item -LiteralPath $backup -Force
        }
    }
}

function Get-ObjectProperty {
    param(
        [AllowNull()][object]$Object,
        [Parameter(Mandatory = $true)][string]$Property,
        [AllowNull()][object]$Default = $null
    )

    if ($null -eq $Object) { return $Default }
    if ($Object -is [System.Collections.IDictionary]) {
        if ($Object.Contains($Property)) { return $Object[$Property] }
        return $Default
    }
    if ($Object.PSObject.Properties.Name -contains $Property) {
        return $Object.$Property
    }
    return $Default
}

function Get-Index {
    if (-not (Test-Path -LiteralPath $script:IndexFile -PathType Leaf)) {
        return [ordered]@{
            schema_version = "legacy-safe-v1"
            packs = @()
            updated = (Get-Date -Format "o")
        }
    }

    try {
        $parsed = Get-Content -LiteralPath $script:IndexFile -Raw | ConvertFrom-Json
    } catch {
        throw "knowledge/index.json is malformed; refusing to continue."
    }
    $parsedPacks = Get-ObjectProperty -Object $parsed -Property "packs" -Default @()
    if ($null -eq $parsedPacks) { $parsedPacks = @() }

    return [ordered]@{
        schema_version = "legacy-safe-v1"
        packs = @($parsedPacks)
        updated = (Get-ObjectProperty -Object $parsed -Property "updated" -Default (Get-Date -Format "o"))
    }
}

function Save-Index {
    param([Parameter(Mandatory = $true)][object]$Index)

    $Index["schema_version"] = "legacy-safe-v1"
    $Index["updated"] = (Get-Date -Format "o")
    Write-JsonAtomic -Path $script:IndexFile -Value $Index
}

function Get-PackRecord {
    param(
        [Parameter(Mandatory = $true)][object]$Index,
        [Parameter(Mandatory = $true)][string]$PackName
    )

    return @($Index.packs | Where-Object {
        $recordName = [string](Get-ObjectProperty -Object $_ -Property "name" -Default "")
        $recordName.Equals($PackName, $script:PathComparison)
    } | Select-Object -First 1)
}

function Get-AllPackNames {
    param([Parameter(Mandatory = $true)][object]$Index)

    $names = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($record in @($Index.packs)) {
        $recordName = [string](Get-ObjectProperty -Object $record -Property "name" -Default "")
        if ($recordName) { [void]$names.Add($recordName) }
    }
    if (Test-Path -LiteralPath $script:PacksDir -PathType Container) {
        foreach ($directory in @(Get-ChildItem -LiteralPath $script:PacksDir -Directory -Force)) {
            [void]$names.Add($directory.Name)
        }
    }
    return @($names | Sort-Object)
}

function Get-PackValidation {
    param(
        [Parameter(Mandatory = $true)][string]$PackName,
        [Parameter(Mandatory = $true)][object]$Index
    )

    Assert-SafePackName -PackName $PackName
    $packPath = Assert-ProjectPath -Path (Join-Path $script:PacksDir $PackName)
    $sourceMapPath = Join-Path $packPath "source-map.json"
    $detail = [ordered]@{
        pack = $PackName
        hasSourceMap = $false
        manifestAnchorPresent = $false
        manifestHashMatches = $false
        checkedFiles = 0
        missingFiles = @()
        hashMismatches = @()
        sizeMismatches = @()
        unsafePaths = @()
        unexpectedFiles = @()
        duplicatePaths = @()
        valid = $false
    }

    if (-not (Test-Path -LiteralPath $packPath -PathType Container)) {
        $detail.missingFiles = @("<pack-directory>")
        return [pscustomobject]$detail
    }
    try { Assert-NoReparsePoint -Path $packPath } catch {
        $detail.unsafePaths = @("<pack-directory-reparse-point>")
        return [pscustomobject]$detail
    }
    if (-not (Test-Path -LiteralPath $sourceMapPath -PathType Leaf)) {
        return [pscustomobject]$detail
    }
    $detail.hasSourceMap = $true

    try {
        $parsedEntries = Get-Content -LiteralPath $sourceMapPath -Raw | ConvertFrom-Json
        $entries = @()
        foreach ($parsedEntry in $parsedEntries) { $entries += $parsedEntry }
    } catch {
        $detail.unsafePaths = @("<malformed-source-map>")
        return [pscustomobject]$detail
    }

    $record = @(Get-PackRecord -Index $Index -PackName $PackName)
    if ($record.Count -eq 1) {
        $expectedManifestHash = [string](Get-ObjectProperty -Object $record[0] -Property "manifest_sha256" -Default "")
        if ($expectedManifestHash -match '^[a-fA-F0-9]{64}$') {
            $detail.manifestAnchorPresent = $true
            $actualManifestHash = (Get-FileHash -LiteralPath $sourceMapPath -Algorithm SHA256).Hash
            $detail.manifestHashMatches = $actualManifestHash.Equals($expectedManifestHash, [System.StringComparison]::OrdinalIgnoreCase)
        }
    }

    $tracked = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $entries) {
        $relative = [string](Get-ObjectProperty -Object $entry -Property "path" -Default "")
        $expectedHash = [string](Get-ObjectProperty -Object $entry -Property "sha256" -Default "")
        $expectedSize = Get-ObjectProperty -Object $entry -Property "size" -Default -1

        if (-not $relative -or [System.IO.Path]::IsPathRooted($relative) -or $relative -match '(^|[\\/])\.\.([\\/]|$)') {
            $detail.unsafePaths += if ($relative) { $relative } else { "<empty-path>" }
            continue
        }
        $normalized = ($relative -replace '\\', '/').TrimStart('/')
        if (-not $tracked.Add($normalized)) {
            $detail.duplicatePaths += $normalized
            continue
        }

        try {
            $candidate = [System.IO.Path]::GetFullPath((Join-Path $packPath ($normalized -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
            if (-not (Test-PathInside -Child $candidate -Parent $packPath)) {
                throw "unsafe"
            }
        } catch {
            $detail.unsafePaths += $normalized
            continue
        }
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            $detail.missingFiles += $normalized
            continue
        }
        try { Assert-NoReparsePoint -Path $candidate } catch {
            $detail.unsafePaths += $normalized
            continue
        }

        $file = Get-Item -LiteralPath $candidate -Force
        $detail.checkedFiles++
        if ([long]$expectedSize -ne [long]$file.Length) {
            $detail.sizeMismatches += $normalized
        }
        if ($expectedHash -notmatch '^[a-fA-F0-9]{64}$') {
            $detail.hashMismatches += $normalized
        } else {
            $actualHash = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash
            if (-not $actualHash.Equals($expectedHash, [System.StringComparison]::OrdinalIgnoreCase)) {
                $detail.hashMismatches += $normalized
            }
        }
    }

    foreach ($file in @(Get-ChildItem -LiteralPath $packPath -Recurse -File -Force)) {
        if ($file.FullName.Equals($sourceMapPath, $script:PathComparison)) { continue }
        $relative = $file.FullName.Substring($packPath.Length).TrimStart('\', '/') -replace '\\', '/'
        if (-not $tracked.Contains($relative)) {
            $detail.unexpectedFiles += $relative
        }
    }

    $detail.valid = (
        $detail.hasSourceMap -and
        $detail.manifestAnchorPresent -and
        $detail.manifestHashMatches -and
        $detail.missingFiles.Count -eq 0 -and
        $detail.hashMismatches.Count -eq 0 -and
        $detail.sizeMismatches.Count -eq 0 -and
        $detail.unsafePaths.Count -eq 0 -and
        $detail.unexpectedFiles.Count -eq 0 -and
        $detail.duplicatePaths.Count -eq 0
    )
    return [pscustomobject]$detail
}

function Get-ValidatedPackSet {
    param(
        [Parameter(Mandatory = $true)][string[]]$PackNames,
        [Parameter(Mandatory = $true)][object]$Index
    )

    $details = @()
    foreach ($packName in $PackNames) {
        $details += Get-PackValidation -PackName $packName -Index $Index
    }
    return @($details)
}

function Get-ManifestEntries {
    param([Parameter(Mandatory = $true)][string]$PackName)

    $manifestPath = Join-Path (Join-Path $script:PacksDir $PackName) "source-map.json"
    $parsedEntries = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
    $entries = @()
    foreach ($parsedEntry in $parsedEntries) { $entries += $parsedEntry }
    return $entries
}

foreach ($directory in @($script:KnowledgeDir, $script:PacksDir)) {
    if (-not (Test-Path -LiteralPath $directory -PathType Container)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
}

try {
    switch ($result.action) {
        "add" {
            if (-not $Name -or -not $Source) {
                throw "Name and Source are required for add."
            }
            Assert-SafePackName -PackName $Name

            $resolvedSource = Resolve-Path -LiteralPath $Source -ErrorAction Stop
            if ($resolvedSource.Provider.Name -ne "FileSystem") {
                throw "Source must use the local file system."
            }
            $sourceFull = Assert-ProjectPath -Path $resolvedSource.ProviderPath
            Assert-NoReparsePoint -Path $sourceFull
            $sourceItem = Get-Item -LiteralPath $sourceFull -Force

            if ($sourceItem.PSIsContainer) {
                if ((Test-PathInside -Child $script:KnowledgeDir -Parent $sourceFull -AllowEqual) -or
                    (Test-PathInside -Child $sourceFull -Parent $script:KnowledgeDir -AllowEqual)) {
                    throw "Source cannot contain, or be inside, the runtime knowledge directory."
                }
                $candidateFiles = @(Get-ChildItem -LiteralPath $sourceFull -Recurse -File)
            } else {
                if (Test-PathInside -Child $sourceFull -Parent $script:KnowledgeDir -AllowEqual) {
                    throw "Source cannot be inside the runtime knowledge directory."
                }
                $candidateFiles = @($sourceItem)
            }

            $packPath = Assert-ProjectPath -Path (Join-Path $script:PacksDir $Name)
            if (Test-Path -LiteralPath $packPath) {
                $result.status = "ALREADY_EXISTS"
                $result.detail = "Pack already exists. Validate it, then remove it explicitly before re-importing."
                $exitCode = 2
                break
            }

            $stagingRoot = Assert-ProjectPath -Path (Join-Path $script:KnowledgeDir ".staging")
            if (-not (Test-Path -LiteralPath $stagingRoot -PathType Container)) {
                New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
            }
            $stagingPath = Assert-ProjectPath -Path (Join-Path $stagingRoot ($Name + "-" + [guid]::NewGuid().ToString("N")))
            New-Item -ItemType Directory -Path $stagingPath | Out-Null

            try {
                $manifest = @()
                $skipped = 0
                $destinationNames = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
                foreach ($file in $candidateFiles) {
                    Assert-NoReparsePoint -Path $file.FullName
                    $projectRelative = Get-ProjectRelativePath -Path $file.FullName
                    $extension = $file.Extension.ToLowerInvariant()
                    if ($script:AllowedExtensions -notcontains $extension -or (Test-SensitiveSourcePath -ProjectRelativePath $projectRelative)) {
                        $skipped++
                        continue
                    }
                    if ($file.Length -gt $script:MaxSourceFileBytes) {
                        throw "A source file exceeds the 10 MiB legacy safety limit: $projectRelative"
                    }

                    $content = [System.IO.File]::ReadAllText($file.FullName)
                    if ($content.IndexOf([char]0) -ge 0) {
                        throw "A source file is not valid text: $projectRelative"
                    }
                    if (Test-PotentialSecretContent -Content $content) {
                        throw "Potential secret material detected in $projectRelative. Import aborted; no secret value was recorded."
                    }

                    if ($sourceItem.PSIsContainer) {
                        $relative = $file.FullName.Substring($sourceFull.Length).TrimStart('\', '/')
                    } else {
                        $relative = $file.Name
                    }
                    $relative = $relative -replace '\\', '/'
                    if (-not $destinationNames.Add($relative)) {
                        throw "Source contains colliding destination paths: $relative"
                    }

                    $destination = [System.IO.Path]::GetFullPath((Join-Path $stagingPath ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)))
                    if (-not (Test-PathInside -Child $destination -Parent $stagingPath)) {
                        throw "Unsafe destination path detected."
                    }
                    $destinationDirectory = Split-Path -Parent $destination
                    if (-not (Test-Path -LiteralPath $destinationDirectory -PathType Container)) {
                        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
                    }
                    Copy-Item -LiteralPath $file.FullName -Destination $destination
                    $copied = Get-Item -LiteralPath $destination -Force
                    $hash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
                    $manifest += [ordered]@{
                        path = $relative
                        sha256 = $hash
                        size = [long]$copied.Length
                        source = $projectRelative
                        last_modified = $file.LastWriteTimeUtc.ToString("o")
                    }
                }

                if ($manifest.Count -eq 0) {
                    throw "No supported, non-sensitive source files were found."
                }
                $sourceMapPath = Join-Path $stagingPath "source-map.json"
                Write-JsonAtomic -Path $sourceMapPath -Value @($manifest)
                $manifestHash = (Get-FileHash -LiteralPath $sourceMapPath -Algorithm SHA256).Hash.ToLowerInvariant()

                Move-Item -LiteralPath $stagingPath -Destination $packPath
                $stagingPath = $null

                $index = Get-Index
                $newRecord = [ordered]@{
                    name = $Name
                    path = "knowledge/packs/$Name"
                    files = $manifest.Count
                    manifest_sha256 = $manifestHash
                    added = (Get-Date -Format "o")
                }
                $index.packs = @($index.packs | Where-Object {
                    $existingName = [string](Get-ObjectProperty -Object $_ -Property "name" -Default "")
                    -not $existingName.Equals($Name, $script:PathComparison)
                }) + @($newRecord)
                Save-Index -Index $index

                $result.detail = "Added $($manifest.Count) verified files to knowledge pack: $Name"
                $result.pack = $Name
                $result.file_count = $manifest.Count
                $result.skipped_file_count = $skipped
                $result.manifest_sha256 = $manifestHash
            } finally {
                if ($stagingPath -and (Test-Path -LiteralPath $stagingPath)) {
                    if (Test-PathInside -Child $stagingPath -Parent $stagingRoot) {
                        Remove-Item -LiteralPath $stagingPath -Recurse -Force
                    }
                }
            }
        }

        "list" {
            $index = Get-Index
            $result.packs = @($index.packs)
            $result.count = @($index.packs).Count
            $result.detail = "Listed $($result.count) knowledge packs."
        }

        "validate" {
            $index = Get-Index
            if ($Name) {
                Assert-SafePackName -PackName $Name
                $packNames = @($Name)
            } else {
                $packNames = @(Get-AllPackNames -Index $index)
            }
            $details = @(Get-ValidatedPackSet -PackNames $packNames -Index $index)
            $result.details = $details
            $result.count = $details.Count
            $invalid = @($details | Where-Object { -not $_.valid })
            if ($invalid.Count -eq 0) {
                $result.status = "VALID"
                $result.detail = "All selected knowledge packs passed physical file, size, SHA-256, and manifest-anchor checks."
            } else {
                $result.status = "DRIFT_DETECTED"
                $result.detail = "$($invalid.Count) knowledge pack(s) failed integrity validation."
                $exitCode = 2
            }
        }

        "remove" {
            if (-not $Name) { throw "Name is required for remove." }
            Assert-SafePackName -PackName $Name
            $packPath = Assert-ProjectPath -Path (Join-Path $script:PacksDir $Name)
            if (-not (Test-Path -LiteralPath $packPath -PathType Container)) {
                $result.status = "NOT_FOUND"
                $result.detail = "Knowledge pack not found: $Name"
                $exitCode = 2
                break
            }
            if (-not (Test-PathInside -Child $packPath -Parent $script:PacksDir)) {
                throw "Refusing unsafe removal target."
            }
            Assert-NoReparsePoint -Path $packPath
            Remove-Item -LiteralPath $packPath -Recurse -Force
            $index = Get-Index
            $index.packs = @($index.packs | Where-Object {
                $existingName = [string](Get-ObjectProperty -Object $_ -Property "name" -Default "")
                -not $existingName.Equals($Name, $script:PathComparison)
            })
            Save-Index -Index $index
            $result.detail = "Removed knowledge pack: $Name"
        }

        "index" {
            $index = Get-Index
            $packNames = @(Get-AllPackNames -Index $index)
            $details = @(Get-ValidatedPackSet -PackNames $packNames -Index $index)
            $invalid = @($details | Where-Object { -not $_.valid })
            if ($invalid.Count -gt 0) {
                $result.status = "DRIFT_DETECTED"
                $result.detail = "Indexing refused because $($invalid.Count) pack(s) failed integrity validation."
                $result.details = $details
                $exitCode = 2
                break
            }

            $keywords = [ordered]@{}
            foreach ($packName in $packNames) {
                $packPath = Join-Path $script:PacksDir $packName
                foreach ($entry in @(Get-ManifestEntries -PackName $packName)) {
                    $relative = [string](Get-ObjectProperty -Object $entry -Property "path" -Default "")
                    $filePath = Join-Path $packPath ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                    $content = [System.IO.File]::ReadAllText($filePath)
                    $words = @([regex]::Matches($content.ToLowerInvariant(), '[\p{L}\p{N}_-]{3,}') | ForEach-Object { $_.Value } | Sort-Object -Unique)
                    foreach ($word in $words) {
                        if (-not $keywords.Contains($word)) { $keywords[$word] = @() }
                        $reference = "$packName/$relative"
                        if ($keywords[$word] -notcontains $reference) {
                            $keywords[$word] = @($keywords[$word]) + @($reference)
                        }
                    }
                }
            }
            Write-JsonAtomic -Path $script:KeywordIndexFile -Value $keywords
            $result.keywordCount = $keywords.Count
            $result.pack_count = $packNames.Count
            $result.detail = "Indexed $($keywords.Count) keywords across $($packNames.Count) verified packs."
        }

        "build-evidence" {
            $index = Get-Index
            if ($Name) {
                Assert-SafePackName -PackName $Name
                $packNames = @($Name)
            } else {
                $packNames = @(Get-AllPackNames -Index $index)
            }
            $details = @(Get-ValidatedPackSet -PackNames $packNames -Index $index)
            $invalid = @($details | Where-Object { -not $_.valid })
            if ($invalid.Count -gt 0) {
                $result.status = "DRIFT_DETECTED"
                $result.detail = "Evidence export refused because $($invalid.Count) pack(s) failed integrity validation."
                $result.details = $details
                $exitCode = 2
                break
            }

            $evidenceEntries = @()
            foreach ($packName in $packNames) {
                $packPath = Join-Path $script:PacksDir $packName
                foreach ($entry in @(Get-ManifestEntries -PackName $packName)) {
                    $relative = [string](Get-ObjectProperty -Object $entry -Property "path" -Default "")
                    $filePath = Join-Path $packPath ($relative -replace '/', [System.IO.Path]::DirectorySeparatorChar)
                    $content = [System.IO.File]::ReadAllText($filePath)
                    if (Test-PotentialSecretContent -Content $content) {
                        throw "Potential secret material detected during evidence export. Export aborted; no secret value was recorded."
                    }
                    $lineCount = if ($content.Length -eq 0) { 0 } else { @($content -split "`r?`n").Count }
                    $preview = if ($content.Length -gt 200) { $content.Substring(0, 200) + "..." } else { $content }
                    $extension = [System.IO.Path]::GetExtension($relative).ToLowerInvariant()
                    $evidenceType = if ($extension -in @(".yaml", ".yml", ".openapi")) {
                        "spec"
                    } elseif ($extension -eq ".md") {
                        "documentation"
                    } elseif ($extension -eq ".json") {
                        "structured_data"
                    } else {
                        "text"
                    }
                    $evidenceEntries += [ordered]@{
                        source_file = "$packName/$relative"
                        source_hash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash.ToLowerInvariant()
                        source_size = (Get-Item -LiteralPath $filePath).Length
                        evidence_type = $evidenceType
                        line_count = $lineCount
                        preview_first_200_chars = $preview
                        extracted_at = (Get-Date -Format "o")
                    }
                }
            }

            if (-not (Test-Path -LiteralPath $script:EvidenceDir -PathType Container)) {
                New-Item -ItemType Directory -Path $script:EvidenceDir -Force | Out-Null
            }
            $evidencePath = Join-Path $script:EvidenceDir "evidence-pack.json"
            $evidence = [ordered]@{
                schema_version = "legacy-knowledge-evidence-v1"
                generated_at = (Get-Date -Format "o")
                source_packs = @($packNames)
                total_entries = $evidenceEntries.Count
                entries = @($evidenceEntries)
                integrity_validation = "PASS"
                secret_safety_result = "PASS_NO_SECRET_PATTERN_DETECTED"
                usable_as_verified_search_evidence = $false
                limitations = @(
                    "This is a local legacy knowledge export, not an Evidence Search Loop quality-gate receipt.",
                    "Use V5 factoryctl knowledge verify for the authoritative tamper-evident knowledge store."
                )
                non_claims = @(
                    "Every exported entry is bound to a project-relative source path and current SHA-256.",
                    "No absolute source path or raw secret value is recorded.",
                    "Knowledge remains local unless the user explicitly sends this file elsewhere."
                )
            }
            Write-JsonAtomic -Path $evidencePath -Value $evidence
            $result.detail = "Generated a local legacy evidence export with $($evidenceEntries.Count) verified entries."
            $result.evidence_path = "knowledge/evidence/evidence-pack.json"
            $result.evidence_sha256 = (Get-FileHash -LiteralPath $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
            $result.entry_count = $evidenceEntries.Count
        }

        default {
            $result.status = "ERROR"
            $result.detail = "Unknown action. Use add|list|validate|remove|index|build-evidence."
            $exitCode = 1
        }
    }
} catch {
    $result.status = "ERROR"
    $result.detail = $_.Exception.Message
    $exitCode = 1
}

if ($Json) {
    ConvertTo-Json -InputObject $result -Depth 12
} else {
    Write-Output "Knowledge Pack Manager: $($result.action) - $($result.status): $($result.detail)"
    Write-Output "Legacy compatibility path. $($result.v5_recommendation)"
}

exit $exitCode
