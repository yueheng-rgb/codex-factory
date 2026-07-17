# analyze-worker-output.ps1 - Phase 6C-H8
param($WorkerContractPath, $WorkerWorkspacePath)
$ErrorActionPreference = "Continue"
$ts = (Get-Date).ToString("o")

if (-not (Test-Path $WorkerContractPath)) { Write-Output '{"verdict":"FAIL"}'; exit 1 }
if (-not (Test-Path $WorkerWorkspacePath)) { Write-Output '{"verdict":"FAIL"}'; exit 1 }

$wc = Get-Content $WorkerContractPath -Raw | ConvertFrom-Json
$srcDir = Join-Path $WorkerWorkspacePath "src"
if (-not (Test-Path $srcDir)) { $srcDir = $WorkerWorkspacePath }
$jsFiles = @(Get-ChildItem $srcDir -Filter "*.js" -Recurse)

$sourceFiles = @()
$derivedExports = @()
$derivedRequires = @()
$shallowSignals = @()
$ownedViolations = @()
$forbiddenFileVios = @()
$forbiddenDepVios = @()
$totalLines = 0

foreach ($f in $jsFiles) {
    $content = Get-Content $f.FullName -Raw
    $lines = 0
    if ($content) { $lines = @($content -split "`n").Count }
    $totalLines += $lines
    $hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash
    $sourceFiles += @{path=$f.Name; sha256=$hash; sizeBytes=$f.Length; lineCount=$lines}
    
    # Extract exports from module.exports = { key: val } pattern
    if ($content -match 'module\.exports\s*=\s*\{') {
        $m = [regex]::Match($content, 'module\.exports\s*=\s*\{([^}]*)\}')
        if ($m.Success) {
            $block = $m.Groups[1].Value
            $keys = [regex]::Matches($block, '(\w+)\s*:')
            foreach ($k in $keys) {
                $name = $k.Groups[1].Value
                if ($name.Length -gt 1 -and $name -notin $derivedExports) { $derivedExports += $name }
            }
        }
    }
    
    # Extract exports from module.exports.X or exports.X
    $dotExports = [regex]::Matches($content, '(?:module\.exports\.|exports\.)(\w+)')
    foreach ($de in $dotExports) {
        $name = $de.Groups[1].Value
        if ($name -notin $derivedExports) { $derivedExports += $name }
    }
    
    # Extract requires (both single and double quotes)
    $reqsSQ = [regex]::Matches($content, "require\s*\(\s*'([^']+)'")
    $reqsDQ = [regex]::Matches($content, 'require\s*\(\s*"([^"]+)"')
    foreach ($rq in ($reqsSQ + $reqsDQ)) {
        $dep = $rq.Groups[1].Value
        if ($dep -notin $derivedRequires) { $derivedRequires += $dep }
    }
    
    # Shallow signals
    $lineArr = $content -split "`n"
    for ($i = 0; $i -lt $lineArr.Count; $i++) {
        $l = $lineArr[$i].Trim()
        if ($l -match '\bTODO\b|\bFIXME\b') { $shallowSignals += @{signal="TODO/FIXME"; file=$f.Name; line=($i+1)} }
        if ($l -match '\bplaceholder\b|\bnot implemented\b|\bstub\b') { $shallowSignals += @{signal="placeholder/stub"; file=$f.Name; line=($i+1)} }
        if ($l -match 'return\s+null\s*;') { $shallowSignals += @{signal="return null"; file=$f.Name; line=($i+1)} }
    }
    
    # Owned file violation
    $matched = $false
    foreach ($of in $wc.ownedFilesPlanned) {
        if ($f.Name -like "*$of*" -or $of -like "*$($f.Name)*") { $matched = $true }
    }
    if (-not $matched) { $ownedViolations += $f.Name }
    
    # Forbidden file violation
    foreach ($ff in $wc.forbiddenFiles) {
        if ($f.Name -like "*$ff*") { $forbiddenFileVios += $f.Name }
    }
}

# Forbidden dep violations
foreach ($dr in $derivedRequires) {
    foreach ($fd in $wc.forbiddenDependencies) {
        if ($dr -like "*$fd*") { $forbiddenDepVios += $dr }
    }
}

# Evidence files
$evidenceDir = Join-Path $WorkerWorkspacePath "reports"
$evidenceFiles = @(Get-ChildItem $evidenceDir -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })

ConvertTo-Json -Depth 5 -InputObject @{
    runId = $wc.runId; workerId = $wc.workerId
    sourceFiles = $sourceFiles; derivedExports = $derivedExports
    derivedRequires = $derivedRequires
    ownedFileViolations = $ownedViolations
    forbiddenFileViolations = $forbiddenFileVios
    forbiddenDependencyViolations = $forbiddenDepVios
    shallowImplementationSignals = $shallowSignals
    evidenceFilesPresent = $evidenceFiles
    hasNodeModules = (Test-Path (Join-Path $WorkerWorkspacePath "node_modules"))
    hasPackageJson = (Test-Path (Join-Path $WorkerWorkspacePath "package.json"))
    sourceFileCount = $sourceFiles.Count
    totalLineCount = $totalLines
    checkedAt = $ts; verdict = "ANALYZED"; classification = "PASS"
}
exit 0
