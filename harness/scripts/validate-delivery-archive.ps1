# Harness Validate Delivery Archive 鈥?Phase 6B-R5 Round-Trip Gate
# Uses System.IO.Compression.ZipArchive for forward-slash entries.
# Validates structure, round-trip npm ci/typecheck/build/dev, and backslash rejection.
param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [Parameter(Mandatory=$true)][string]$ZipPath
)

$ErrorActionPreference = "Stop"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$warnings = [System.Collections.ArrayList]::new()
$exitCode = 0

Write-Output "=== Validate Delivery Archive (Phase 6B-R5) ==="

# 1. Delete old ZIP
if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force; Write-Output "Deleted old ZIP: $ZipPath" }

# 2. Pack with .NET ZipArchive 鈥?forced forward-slash paths
$files = Get-ChildItem -Path $ProjectPath -Recurse -File | Where-Object {
    $d = $_.DirectoryName
    ($d -notmatch '\\node_modules') -and ($d -notmatch '\\dist') -and ($d -notmatch '\\\.git') -and ($d -notmatch '\\\.codex-factory\\runs')
}
Write-Output "Packing $($files.Count) files with forward-slash paths..."

Add-Type -AssemblyName System.IO.Compression.FileSystem; Add-Type -AssemblyName System.IO.Compression
$projectRoot = (Resolve-Path $ProjectPath).Path.TrimEnd('\')

try {
    $zipStream = [System.IO.File]::Create($ZipPath)
    $zipArchive = New-Object System.IO.Compression.ZipArchive($zipStream, [System.IO.Compression.ZipArchiveMode]::Create)
    
    foreach ($f in $files) {
        $relativePath = $f.FullName.Substring($projectRoot.Length).TrimStart('\', '/')
        # FORCE forward slashes 鈥?no backslashes allowed in ZIP entries
        $entryName = $relativePath.Replace('\', '/')
        
        # Skip empty entry names
        if ([string]::IsNullOrEmpty($entryName)) { continue }
        
        $entry = $zipArchive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
        $entryStream = $entry.Open()
        $fileBytes = [System.IO.File]::ReadAllBytes($f.FullName)
        $entryStream.Write($fileBytes, 0, $fileBytes.Length)
        $entryStream.Close()
    }
    
    $zipArchive.Dispose()
    $zipStream.Close()
    $zipStream.Dispose()
} catch {
    try { if ($zipArchive) { $zipArchive.Dispose() } } catch {}
    try { if ($zipStream) { $zipStream.Close(); $zipStream.Dispose() } } catch {}
    throw "ZIP_CREATION_FAILED: $_"
}

$zipSize = (Get-Item $ZipPath).Length
Write-Output "ZIP: $ZipPath ($([math]::Round($zipSize/1KB,1)) KB)"
[void]$passes.Add("ZIP: $([math]::Round($zipSize/1KB,1)) KB")

# 3. Verify ZIP contents
$z = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)
$entries = @($z.Entries | Where-Object { $_.Name.Length -gt 0 })
$z.Dispose()
Write-Output "Entries: $($entries.Count)"

# --- Backslash check: ANY backslash in any entry name 鈫?immediate failure ---
$backslashEntries = @($entries | Where-Object { $_.FullName -match '\\' })
$backslashCount = $backslashEntries.Count
if ($backslashCount -gt 0) {
    [void]$errors.Add("ZIP_BACKSLASH_ENTRIES: $backslashCount entries use backslash separators. All entries must use forward slashes (/).")
    $exitCode = 1
} else {
    [void]$passes.Add("All entries use forward slashes")
}

# Count forward-slash entries (entries containing /)
$forwardSlashEntries = @($entries | Where-Object { $_.FullName -match '/' })
$forwardSlashCount = $forwardSlashEntries.Count
[void]$passes.Add("Directory-structured entries: $forwardSlashCount")

# --- Flat check: if all entries are at root (no / in any entry name) ---
$rootOnlyCount = @($entries | Where-Object { $_.FullName -notmatch '/' }).Count
if ($rootOnlyCount -eq $entries.Count -and $entries.Count -gt 2) {
    [void]$errors.Add("ZIP_FLATTENED: All $($entries.Count) entries at root with no directory structure")
    $exitCode = 1
}

# --- Check for required directories ---
$requiredDirs = @("src/", "tests/", "outputs/")
$entryNames = @($entries | ForEach-Object { $_.FullName })
foreach ($rd in $requiredDirs) {
    $found = $entryNames | Where-Object { $_ -like "$rd*" }
    if ($found) { [void]$passes.Add("Found dir: $rd ($($found.Count) entries)") }
    else { [void]$errors.Add("MISSING_DIR: $rd"); $exitCode = 1 }
}

# --- Duplicate entry check ---
$dup = $entryNames | Group-Object | Where-Object { $_.Count -gt 1 }
$duplicateCount = $dup.Count
if ($duplicateCount -eq 0) { [void]$passes.Add("No duplicate ZIP entries") }
else { [void]$errors.Add("DUPLICATE_ZIP_ENTRIES: $duplicateCount duplicate(s)"); $exitCode = 1 }

# --- Critical files check (generic) ---
$criticalFiles = @("src/main.ts", "index.html", "package.json", "tsconfig.json")
foreach ($cf in $criticalFiles) {
    $found = $entryNames | Where-Object { $_ -like "*$cf" -or $_ -eq $cf }
    if ($found) { [void]$passes.Add("Found: $cf") }
    else { [void]$errors.Add("MISSING_CRITICAL: $cf"); $exitCode = 1 }
}

# --- Check for report file ---
$reportFound = $entryNames | Where-Object { $_ -like "*FACTORY_FINAL_REPORT.md" -or $_ -like "outputs/report.md" }
if ($reportFound) { [void]$passes.Add("Found: report") }
else { [void]$warnings.Add("MISSING_REPORT: No FACTORY_FINAL_REPORT.md or outputs/report.md") }

# 4. Round-trip extraction
$rtd = Join-Path ([System.IO.Path]::GetTempPath()) "f-rt-$([System.Guid]::NewGuid().ToString().Substring(0,8))"
New-Item -ItemType Directory -Path $rtd -Force | Out-Null
Write-Output "Extracting to: $rtd"

try {
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $rtd)
    [void]$passes.Add("Extraction OK")

    $wd = $rtd
    Write-Output "WorkDir: $wd"

    Push-Location $wd

    # npm ci
    Write-Output "npm ci..."
    $cio = & npm ci 2>&1
    if ($LASTEXITCODE -eq 0) { [void]$passes.Add("npm ci: PASS") }
    else { [void]$errors.Add("NPM_CI_FAILED"); $exitCode = 1 }

    # typecheck
    Write-Output "typecheck..."
    $tco = & npm run typecheck 2>&1
    if ($LASTEXITCODE -eq 0) { [void]$passes.Add("typecheck: PASS") }
    else { [void]$errors.Add("TYPECHECK_FAILED"); $exitCode = 1 }

    # build
    Write-Output "build..."
    $bo = & npm run build 2>&1
    if ($LASTEXITCODE -eq 0) { [void]$passes.Add("build: PASS") }
    else { [void]$errors.Add("BUILD_FAILED"); $exitCode = 1 }

    # dev start with full health check (Phase 6A.3)
    Write-Output "dev start (health check)..."
    $devPort = 5199
    $devHost = "127.0.0.1"
    $devUrl = "http://${devHost}:${devPort}"

    $devProc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c npm run dev -- --host $devHost --port $devPort --strictPort 2>&1" -PassThru -NoNewWindow -WorkingDirectory $wd
    $devProcId = $devProc.Id

    $portListening = $false
    $timeoutSec = 30
    $startTick = [Environment]::TickCount
    do {
        Start-Sleep -Milliseconds 500
        $conn = netstat -an 2>$null | Select-String "${devHost}:${devPort}" | Select-String "LISTENING"
        if ($conn) { $portListening = $true; break }
    } while (([Environment]::TickCount - $startTick) / 1000 -lt $timeoutSec)

    if (-not $portListening) {
        [void]$errors.Add("DEV_PORT_NOT_LISTENING: $devUrl after ${timeoutSec}s")
        $exitCode = 1
    } else {
        [void]$passes.Add("Port listening: $devUrl")

        try {
            $r = Invoke-WebRequest -Uri $devUrl -TimeoutSec 10 -UseBasicParsing
            if ($r.StatusCode -ne 200) {
                [void]$errors.Add("DEV_HTTP_NOT_200: status=$($r.StatusCode)")
                $exitCode = 1
            } else {
                [void]$passes.Add("HTTP 200: $devUrl")
                $html = $r.Content

                # Check for root node
                $rootFound = $false
                foreach ($rootId in @('id="app"','id="root"','id="app-root"','class="app"')) {
                    if ($html -match $rootId) { $rootFound = $true; [void]$passes.Add("Root node found: $rootId"); break }
                }
                if (-not $rootFound) {
                    [void]$errors.Add("DEV_NO_ROOT_NODE: HTML does not contain expected root element")
                    $exitCode = 1
                }

                # Check not default error page
                $errorIndicators = @("404 Not Found","500 Internal Server","Cannot GET","Error:","Uncaught")
                foreach ($ei in $errorIndicators) {
                    if ($html -match $ei) {
                        [void]$errors.Add("DEV_ERROR_PAGE: page contains '$ei'")
                        $exitCode = 1
                        break
                    }
                }

                $healthEvidence = @{
                    url = $devUrl
                    statusCode = $r.StatusCode
                    contentLength = $html.Length
                    rootFound = $rootFound
                    checkedAt = (Get-Date).ToString("o")
                } | ConvertTo-Json -Depth 3
                [System.IO.File]::WriteAllText((Join-Path $wd "dev-health-check.json"), $healthEvidence, (New-Object System.Text.UTF8Encoding($false)))
                [void]$passes.Add("Dev health evidence saved")
            }
        } catch {
            [void]$errors.Add("DEV_HTTP_FAIL: $_")
            $exitCode = 1
        }
    }

    # Clean up: kill the dev process
    try {
        Stop-Process -Id $devProcId -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        [void]$passes.Add("Dev process cleaned")
    } catch {
        [void]$errors.Add("DEV_CLEANUP_FAIL: $_")
        $exitCode = 1
    }

    # Check for residual node processes
    $residual = Get-Process -Name "node" -ErrorAction SilentlyContinue | Where-Object { $_.Id -eq $devProcId }
    if ($residual) {
        [void]$errors.Add("DEV_RESIDUAL_PROCESS: node process $devProcId still running")
        $exitCode = 1
    }

    # Verify key files
    $verifyFiles = @("index.html", "src/main.ts", "package.json")
    foreach ($vf in $verifyFiles) {
        $fp = Join-Path $wd $vf
        if (Test-Path $fp) { [void]$passes.Add("Verified: $vf") }
        else { [void]$errors.Add("MISSING: $vf"); $exitCode = 1 }
    }

    Pop-Location
} finally {
    Get-Process -Name "node" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $rtd -Recurse -Force -ErrorAction SilentlyContinue
}

$result = @{
    status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
    zipPath = $ZipPath
    zipSizeBytes = $zipSize
    zipEntries = $entries.Count
    forwardSlashEntryCount = $forwardSlashCount
    backslashEntryCount = $backslashCount
    duplicateEntryCount = $duplicateCount
    passes = $passes
    errors = $errors
    warnings = $warnings
} | ConvertTo-Json -Depth 3

Write-Output $result
exit $exitCode
