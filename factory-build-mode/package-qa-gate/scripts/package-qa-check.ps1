# Package QA Gate Check Script v1.0.0
# Part of Codex Factory — Package QA Gate
# Usage: .\package-qa-check.ps1 -PackagePath <path-to-zip> -ProfilePath <path-to-profile.json> [-OutputPath <path>]
# Status: READ-ONLY — never modifies the package under test.

param(
    [Parameter(Mandatory=$true)]
    [string]$PackagePath,

    [Parameter(Mandatory=$false)]
    [string]$ProfilePath,

    [Parameter(Mandatory=$false)]
    [string]$OutputPath
)

$GATE_VERSION = "1.0.0"
$script:BLOCKING = @()
$script:WARNING = @()
$script:INFO = @()
$script:StartTime = Get-Date

$TEMP_DIR = Join-Path $env:TEMP "package-qa-$([Guid]::NewGuid().ToString('n').Substring(0,8))"

function Add-Finding {
    param($Category, $Severity, $CheckName, $Description, $FilePath, $LineNumber, $Evidence, $Suggestion)
    $finding = @{
        id = "QA-$($script:StartTime.ToString('yyyyMMddHHmmss'))-$((Get-Random -Minimum 1000 -Maximum 9999))"
        category = $Category
        severity = $Severity
        check_name = $CheckName
        description = $Description
        file_path = $FilePath
        line_number = $LineNumber
        evidence = if ($Evidence.Length -gt 200) { $Evidence.Substring(0, 200) + "..." } else { $Evidence }
        suggestion = $Suggestion
    }
    switch ($Severity) {
        "BLOCKING" { $script:BLOCKING += $finding }
        "WARNING"  { $script:WARNING += $finding }
        "INFO"     { $script:INFO += $finding }
    }
}

# ============================================================
# STEP 0: Extract ZIP
# ============================================================
Write-Host "`n=== Package QA Gate v$GATE_VERSION ===" -ForegroundColor Cyan
Write-Host "Package: $PackagePath"
Write-Host ""

if (-not (Test-Path $PackagePath)) {
    Write-Host "[ERROR] Package not found: $PackagePath" -ForegroundColor Red
    exit 1
}

try {
    New-Item -ItemType Directory -Force -Path $TEMP_DIR | Out-Null
    Expand-Archive -Path $PackagePath -DestinationPath $TEMP_DIR -Force
    Write-Host "[OK] Package extracted to: $TEMP_DIR"
} catch {
    Add-Finding -Category "structural_hygiene" -Severity "BLOCKING" -CheckName "ZIP extractability" `
        -Description "Failed to extract ZIP: $_" -FilePath $PackagePath -Suggestion "Repackage the ZIP file"
    Write-Host "[BLOCKING] ZIP extraction failed: $_" -ForegroundColor Red
}

# ============================================================
# STEP 1: Load Assignment Profile
# ============================================================
$profile = $null
if ($ProfilePath -and (Test-Path $ProfilePath)) {
    try {
        $profile = Get-Content $ProfilePath -Raw | ConvertFrom-Json
        Write-Host "[OK] Profile loaded: $($profile.profile_id)"
    } catch {
        Add-Finding -Category "assignment_matching" -Severity "WARNING" -CheckName "Profile load" `
            -Description "Could not parse profile JSON" -FilePath $ProfilePath -Suggestion "Check profile JSON syntax"
        Write-Host "[WARNING] Profile parse failed — assignment checks may be skipped"
    }
} else {
    Add-Finding -Category "assignment_matching" -Severity "WARNING" -CheckName "Profile load" `
        -Description "No assignment profile provided" -FilePath "" -Suggestion "Provide -ProfilePath for assignment matching"
    Write-Host "[WARNING] No profile — assignment matching skipped"
}

# ============================================================
# STEP 2: Get all text files in extracted package
# ============================================================
$textExtensions = @(".py", ".js", ".ts", ".jsx", ".tsx", ".html", ".css", ".md", ".txt", ".json", ".xml", ".yml", ".yaml", ".sql", ".env", ".cfg", ".ini", ".toml")
$allFiles = Get-ChildItem -Path $TEMP_DIR -Recurse -File
$textFiles = $allFiles | Where-Object { $_.Extension -in $textExtensions }

# ============================================================
# CHECK-01: Process Trace Detection
# ============================================================
Write-Host "`n--- CHECK-01: Process Trace Detection ---" -ForegroundColor Yellow

$tracePatterns = @(
    @{Name="GPT residue"; Pattern="\bGPT\b.*\b(assistant|model|generated|created|wrote|produced)\b"; Severity="BLOCKING"},
    @{Name="ChatGPT residue"; Pattern="\bChatGPT\b"; Severity="BLOCKING"},
    @{Name="OpenAI residue"; Pattern="\bOpenAI\b"; Severity="BLOCKING"},
    @{Name="Codex residue"; Pattern="\bCodex\s+(CLI|agent|assistant|generated)\b"; Severity="BLOCKING"},
    @{Name="Factory internal ID"; Pattern="\b(FACTORY-BUILD|FACTORY-AGENT|FACTORY-PACKAGE)-\d+\b"; Severity="BLOCKING"},
    @{Name="Prompt leakage"; Pattern="\b(you are a|your task is|act as a|system prompt|user prompt)\b"; Severity="BLOCKING"},
    @{Name="Wrong instructor"; Pattern="\b(instructor|professor|teacher)\s*[:=]\s*\w+"; Severity="BLOCKING"}
)

$traceFound = 0
foreach ($file in $textFiles) {
    $relPath = $file.FullName.Replace($TEMP_DIR, "").TrimStart("\")
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        foreach ($tp in $tracePatterns) {
            if ($content -match $tp.Pattern) {
                $traceFound++
                $lineNum = 0
                $lines = Get-Content $file.FullName
                for ($i = 0; $i -lt $lines.Count; $i++) {
                    if ($lines[$i] -match $tp.Pattern) { $lineNum = $i + 1; break }
                }
                Add-Finding -Category "process_trace" -Severity $tp.Severity -CheckName $tp.Name `
                    -Description "Found '$($tp.Name)' residue in delivered file" `
                    -FilePath $relPath -LineNumber $lineNum -Evidence ($matches[0]) `
                    -Suggestion "Remove AI/assistant trace references from delivered files"
            }
        }
    } catch { }
}

if ($traceFound -eq 0) {
    Write-Host "  [PASS] No process trace residue detected"
} else {
    Write-Host "  [BLOCKING] $traceFound trace residue(s) found" -ForegroundColor Red
}

# ============================================================
# CHECK-02: Assignment Profile Matching
# ============================================================
Write-Host "`n--- CHECK-02: Assignment Profile Matching ---" -ForegroundColor Yellow

if ($profile) {
    # Check author name in report files
    $reportFiles = Get-ChildItem -Path $TEMP_DIR -Recurse -Filter "*.md" | Where-Object { $_.Name -match "report|readme|readme" }
    foreach ($rf in $reportFiles) {
        $content = Get-Content $rf.FullName -Raw -ErrorAction SilentlyContinue
        $relPath = $rf.FullName.Replace($TEMP_DIR, "").TrimStart("\")
        if ($profile.student_name -and $content -notmatch [regex]::Escape($profile.student_name)) {
            Add-Finding -Category "assignment_matching" -Severity "BLOCKING" -CheckName "Author name match" `
                -Description "Expected author '$($profile.student_name)' not found in report" `
                -FilePath $relPath -Suggestion "Add author name to report or update profile"
        }
        if ($profile.student_id -and $content -notmatch [regex]::Escape($profile.student_id)) {
            Add-Finding -Category "assignment_matching" -Severity "BLOCKING" -CheckName "Author ID match" `
                -Description "Expected student ID '$($profile.student_id)' not found in report" `
                -FilePath $relPath -Suggestion "Add student ID to report or update profile"
        }
    }
    # Check ZIP filename
    $zipName = [System.IO.Path]::GetFileName($PackagePath)
    if ($profile.expected_zip_pattern -and $zipName -notmatch $profile.expected_zip_pattern) {
        Add-Finding -Category "assignment_matching" -Severity "BLOCKING" -CheckName "ZIP name pattern" `
            -Description "ZIP filename '$zipName' does not match expected pattern '$($profile.expected_zip_pattern)'" `
            -FilePath $PackagePath -Suggestion "Rename ZIP to match expected format"
    }
}

# ============================================================
# CHECK-03: Artifact Completeness
# ============================================================
Write-Host "`n--- CHECK-03: Artifact Completeness ---" -ForegroundColor Yellow

# Required report
$reportFound = Get-ChildItem -Path $TEMP_DIR -Recurse -Filter "*.md" | Where-Object { $_.Name -match "report|readme" }
if (-not $reportFound) {
    Add-Finding -Category "artifact_completeness" -Severity "BLOCKING" -CheckName "Required report" `
        -Description "No report/document markdown file found" -FilePath "" -Suggestion "Add a report.md or equivalent"
}

# Required source directory
$srcDirs = @(Get-ChildItem -Path $TEMP_DIR -Directory | Where-Object { $_.Name -match "^(src|source|app|core|lib)$" })
if ($srcDirs.Count -eq 0) {
    # Check if there are any .py/.js/.ts files directly
    $codeFiles = Get-ChildItem -Path $TEMP_DIR -Recurse -Include @("*.py","*.js","*.ts","*.jsx","*.tsx") -File
    if ($codeFiles.Count -eq 0) {
        Add-Finding -Category "artifact_completeness" -Severity "BLOCKING" -CheckName "Source code" `
            -Description "No source code directory or code files found" -FilePath "" -Suggestion "Include source code in package"
    }
}

# SQL file (for DB projects — check if any .py file imports DB library)
$isDBProject = $false
$pyFiles = Get-ChildItem -Path $TEMP_DIR -Recurse -Filter "*.py"
foreach ($pf in $pyFiles) {
    $c = Get-Content $pf.FullName -Raw -ErrorAction SilentlyContinue
    if ($c -match "import (sqlite3|mysql|psycopg2|pymysql|sqlalchemy|django.db)") {
        $isDBProject = $true; break
    }
}
if ($isDBProject) {
    $sqlFiles = Get-ChildItem -Path $TEMP_DIR -Recurse -Filter "*.sql"
    if ($sqlFiles.Count -eq 0) {
        Add-Finding -Category "artifact_completeness" -Severity "BLOCKING" -CheckName "SQL schema file" `
            -Description "Database project detected but no .sql schema file found" -FilePath "" `
            -Suggestion "Include database schema SQL file in package"
    }
}

# README
$readme = Get-ChildItem -Path $TEMP_DIR -Recurse -Filter "README*"
if (-not $readme) {
    Add-Finding -Category "artifact_completeness" -Severity "WARNING" -CheckName "Missing README" `
        -Description "No README file found" -FilePath "" -Suggestion "Add a README.md with project instructions"
}

# ============================================================
# CHECK-04: Technical Correctness
# ============================================================
Write-Host "`n--- CHECK-04: Technical Correctness ---" -ForegroundColor Yellow

$syntaxErrors = 0
foreach ($pf in $pyFiles) {
    $relPath = $pf.FullName.Replace($TEMP_DIR, "").TrimStart("\")
    $result = python -m py_compile $pf.FullName 2>&1
    if ($LASTEXITCODE -ne 0) {
        $syntaxErrors++
        Add-Finding -Category "technical_correctness" -Severity "BLOCKING" -CheckName "Python syntax" `
            -Description "Python syntax error in delivered file" -FilePath $relPath `
            -Evidence ($result -join "; ").Substring(0, [Math]::Min(200, ($result -join "; ").Length)) `
            -Suggestion "Fix Python syntax errors before delivery"
    }
}
if ($syntaxErrors -eq 0) { Write-Host "  [PASS] No Python syntax errors" }

# Library/platform mismatch checks
foreach ($pf in $pyFiles) {
    $c = Get-Content $pf.FullName -Raw -ErrorAction SilentlyContinue
    $relPath = $pf.FullName.Replace($TEMP_DIR, "").TrimStart("\")
    # PyMySQL uses %s, not ?
    if ($c -match "import pymysql" -and $c -match '\?') {
        Add-Finding -Category "technical_correctness" -Severity "BLOCKING" -CheckName "PyMySQL placeholder" `
            -Description "PyMySQL uses %s placeholders, but ? found in file" -FilePath $relPath `
            -Suggestion "Replace ? with %s for PyMySQL compatibility"
    }
    # sqlite3 uses ?, not %s
    if ($c -match "import sqlite3" -and $c -match '%s') {
        Add-Finding -Category "technical_correctness" -Severity "BLOCKING" -CheckName "SQLite placeholder" `
            -Description "sqlite3 uses ? placeholders, but %s found in file" -FilePath $relPath `
            -Suggestion "Replace %s with ? for sqlite3 compatibility"
    }
}

# ============================================================
# CHECK-05: Structural Hygiene
# ============================================================
Write-Host "`n--- CHECK-05: Structural Hygiene ---" -ForegroundColor Yellow

$cacheFiles = Get-ChildItem -Path $TEMP_DIR -Recurse -Include @("*.pyc") -File
$pycacheDirs = Get-ChildItem -Path $TEMP_DIR -Recurse -Directory -Filter "__pycache__"
if ($cacheFiles.Count -gt 0 -or $pycacheDirs.Count -gt 0) {
    Add-Finding -Category "structural_hygiene" -Severity "WARNING" -CheckName "Cache files" `
        -Description "Found $($cacheFiles.Count) .pyc files and $($pycacheDirs.Count) __pycache__ directories" `
        -FilePath "" -Suggestion "Remove cache files before packaging"
}

$nodeModules = Get-ChildItem -Path $TEMP_DIR -Recurse -Directory -Filter "node_modules" -Depth 2
if ($nodeModules) {
    Add-Finding -Category "structural_hygiene" -Severity "WARNING" -CheckName "node_modules" `
        -Description "node_modules directory found in package" -FilePath "" -Suggestion "Remove node_modules before packaging"
}

$venvDirs = Get-ChildItem -Path $TEMP_DIR -Recurse -Directory | Where-Object { $_.Name -match "^(venv|\.venv|env)$" }
if ($venvDirs) {
    Add-Finding -Category "structural_hygiene" -Severity "WARNING" -CheckName "Virtual env" `
        -Description "Virtual environment directory found in package" -FilePath "" -Suggestion "Remove venv before packaging"
}

# Secret scan
$envFiles = Get-ChildItem -Path $TEMP_DIR -Recurse -Filter ".env"
foreach ($ef in $envFiles) {
    $c = Get-Content $ef.FullName -Raw
    $relPath = $ef.FullName.Replace($TEMP_DIR, "").TrimStart("\")
    if ($c -match 'SECRET_KEY\s*=\s*\S+' -and $c -notmatch 'change-this|your-secret|placeholder|xxx') {
        Add-Finding -Category "structural_hygiene" -Severity "BLOCKING" -CheckName "Secret in .env" `
            -Description "Real SECRET_KEY found in .env file" -FilePath $relPath `
            -Suggestion "Remove real secrets from .env; use placeholder values"
    }
}

# Package size
$pkgSize = (Get-Item $PackagePath).Length / 1MB
Add-Finding -Category "structural_hygiene" -Severity "INFO" -CheckName "Package size" `
    -Description "Package size: $([Math]::Round($pkgSize, 2)) MB" -FilePath $PackagePath -Suggestion ""
if ($pkgSize -gt 50) {
    Add-Finding -Category "structural_hygiene" -Severity "WARNING" -CheckName "Package size large" `
        -Description "Package exceeds 50 MB ($([Math]::Round($pkgSize, 1)) MB)" -FilePath $PackagePath `
        -Suggestion "Consider removing large unnecessary files"
}

# ============================================================
# CLEANUP
# ============================================================
Remove-Item -Path $TEMP_DIR -Recurse -Force -ErrorAction SilentlyContinue

# ============================================================
# RESULTS
# ============================================================
$duration = [Math]::Round(((Get-Date) - $script:StartTime).TotalMilliseconds, 0)
$overallStatus = if ($script:BLOCKING.Count -gt 0) { "BLOCKED" } elseif ($script:WARNING.Count -gt 0) { "PASS_WITH_WARNINGS" } else { "PASS" }

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "PACKAGE QA GATE RESULT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Gate Version : v$GATE_VERSION"
Write-Host "Package      : $PackagePath"
Write-Host "Duration     : ${duration}ms"
Write-Host "BLOCKING     : $($script:BLOCKING.Count)" -ForegroundColor $(if($script:BLOCKING.Count -gt 0){'Red'}else{'Green'})
Write-Host "WARNING      : $($script:WARNING.Count)" -ForegroundColor $(if($script:WARNING.Count -gt 0){'Yellow'}else{'Green'})
Write-Host "INFO         : $($script:INFO.Count)"
Write-Host "Status       : $overallStatus" -ForegroundColor $(if($overallStatus -eq 'PASS'){'Green'}elseif($overallStatus -eq 'PASS_WITH_WARNINGS'){'Yellow'}else{'Red'})

# Print BLOCKING findings
if ($script:BLOCKING.Count -gt 0) {
    Write-Host "`n--- BLOCKING FINDINGS ---" -ForegroundColor Red
    foreach ($f in $script:BLOCKING) {
        Write-Host "  [$($f.check_name)] $($f.description)" -ForegroundColor Red
        if ($f.file_path) { Write-Host "    File: $($f.file_path)" }
        if ($f.suggestion) { Write-Host "    Fix : $($f.suggestion)" }
    }
}

if ($script:WARNING.Count -gt 0) {
    Write-Host "`n--- WARNINGS ---" -ForegroundColor Yellow
    foreach ($f in $script:WARNING) {
        Write-Host "  [$($f.check_name)] $($f.description)" -ForegroundColor Yellow
    }
}

# Output JSON result
$result = @{
    gate_version = $GATE_VERSION
    timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
    package_path = $PackagePath
    overall_status = $overallStatus
    blocking_count = $script:BLOCKING.Count
    warning_count = $script:WARNING.Count
    info_count = $script:INFO.Count
    blocking_findings = $script:BLOCKING
    warning_findings = $script:WARNING
    info_findings = $script:INFO
    duration_ms = $duration
} | ConvertTo-Json -Depth 4

if ($OutputPath) {
    $result | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "`nResult saved: $OutputPath"
}

# Exit code
if ($overallStatus -eq "BLOCKED") { exit 2 }
if ($overallStatus -eq "PASS_WITH_WARNINGS") { exit 1 }
exit 0
