param($runDir, $phase)
$now = (Get-Date).ToString("o")
$srcExt = "ts"
foreach ($w in 1..4) {
    $srcDir = Join-Path $runDir "workspace\worker-$w\src"
    $jsFiles = Get-ChildItem $srcDir -Filter *.js -ErrorAction SilentlyContinue
    $tsFiles = Get-ChildItem $srcDir -Filter *.ts -ErrorAction SilentlyContinue
    if ($jsFiles.Count -gt 0) { $srcExt = "js" }
    elseif ($tsFiles.Count -gt 0) { $srcExt = "ts" }
    else { Write-Host "=== Worker $w : no source files found ==="; continue }
    Write-Host "=== Worker $w : extracting source manifest ($srcExt) ==="
    $sourceFiles = Get-ChildItem $srcDir -Filter "*.$srcExt"
    $exports = @()
    $imports = @()
    foreach ($f in $sourceFiles) {
        $content = Get-Content $f.FullName -Raw
        $relPath = "src/$($f.Name)"
        if ($srcExt -eq "js") {
            # JS exports: module.exports = { X, Y }
            $modExports = [regex]::Matches($content, 'module\.exports\s*=\s*\{([^}]*)\}')
            foreach ($m in $modExports) {
                $names = $m.Groups[1].Value -split ',' | ForEach-Object { ($_ -replace '^\s+|\s+$','') }
                foreach ($n in $names) {
                    if ($n) {
                        $exports += @{ interfaceId = "export.$n"; name = $n; file = $relPath; kind = "module-exports" }
                    }
                }
            }
            # JS exports.X = pattern
            $expExports = [regex]::Matches($content, 'exports\.(\w+)\s*=')
            foreach ($m in $expExports) {
                $name = $m.Groups[1].Value
                if ($name -and -not ($exports | Where-Object { $_.name -eq $name })) {
                    $exports += @{ interfaceId = "export.$name"; name = $name; file = $relPath; kind = "exports-dot" }
                }
            }
            # JS cross-worker imports: (const|var|let) { X, Y } = require('../../worker-N/src/file')
            # Also handle double-quoted require paths
            $jsPattern = '(?:const|var|let)\s+\{([^}]+)\}\s*=\s*require\s*\(\s*[''"""]\.\.\/\.\.\/worker-(\d)\/src\/([^''"""]+)[''"""]\s*\)'
            $importMatches = [regex]::Matches($content, $jsPattern)
            foreach ($m in $importMatches) {
                $names = $m.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() }
                $fromW = "worker-$($m.Groups[2].Value)"
                foreach ($n in $names) {
                    if ($n) {
                        $imports += @{ interfaceId = "import.$n"; name = $n; fromWorkerId = $fromW; file = $relPath }
                    }
                }
            }
        } else {
            $exportMatches = [regex]::Matches($content, 'export\s+(type|interface|function|const)\s+(\w+)')
            foreach ($m in $exportMatches) {
                $exports += @{ interfaceId = "export.$($m.Groups[2].Value)"; name = $m.Groups[2].Value; file = $relPath; kind = $m.Groups[1].Value }
            }
            $pattern = 'import\s+(?:type\s+)?\{([^}]+)\}\s+from\s+[''"""]\.\.\/\.\.\/worker-(\d)\/src\/([^''"""]+)[''"""]'
            $importMatches = [regex]::Matches($content, $pattern)
            foreach ($m in $importMatches) {
                $names = $m.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() }
                $fromW = "worker-$($m.Groups[2].Value)"
                foreach ($n in $names) {
                    if ($n) {
                        $imports += @{ interfaceId = "import.$n"; name = $n; fromWorkerId = $fromW; file = $relPath }
                    }
                }
            }
        }
    }
    $manifest = @{
        sourceFiles = @($sourceFiles | ForEach-Object { "src/$($_.Name)" })
        reportType = "source-derived-interface-manifest"
        extractedAt = $now
        imports = $imports
        workerId = "worker-$w"
        phase = $phase
        exports = $exports
        sourceDerived = $true
        language = $srcExt
    }
    $manifest | ConvertTo-Json -Depth 4 | Out-File (Join-Path $runDir "source-derived-interface-manifests\worker-$w.json") -Encoding UTF8
    Write-Host "  Exports: $($exports.Count), Cross-worker imports: $($imports.Count)"
}
Write-Host "All 4 source manifests extracted."