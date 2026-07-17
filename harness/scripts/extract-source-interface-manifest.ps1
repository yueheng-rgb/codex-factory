# extract-source-interface-manifest.ps1 — Phase 6C-U0-C
# Regex-based extraction of TypeScript exports and imports from source files.
# No AST, no heavy dependencies. Extracts: export function/class/const/interface/type, import { X } from './path'
param(
    [Parameter(Mandatory=$true)][string]$SourceRoot,
    [Parameter(Mandatory=$true)][string]$WorkerId,
    [Parameter(Mandatory=$true)][string]$TaskId,
    [Parameter(Mandatory=$true)][string]$OutputPath,
    [string]$Phase = "Phase 6C-U0-C"
)

$ErrorActionPreference = "Continue"
$warnings = [System.Collections.ArrayList]::new()
$exports = [System.Collections.ArrayList]::new()
$imports = [System.Collections.ArrayList]::new()

if (-not (Test-Path $SourceRoot)) {
    Write-Error "Source root not found: $SourceRoot"
    exit 1
}

# Find all .ts and .tsx files
$tsFiles = Get-ChildItem $SourceRoot -Recurse -Include "*.ts","*.tsx" -File

if ($tsFiles.Count -eq 0) {
    $warnings.Add("No TypeScript files found in $SourceRoot") | Out-Null
}

foreach ($file in $tsFiles) {
    $content = Get-Content $file.FullName -Raw
    $lines = $content -split '\r?\n'
    $relPath = ($file.FullName -replace ".*?[\\\\/]workspace[\\\\/][^\\\\/]+[\\\\/]", "").Replace('\', '/').Replace("//", "/")
    
    $lineNum = 0
    foreach ($line in $lines) {
        $lineNum++
        $trimmed = $line.Trim()
        
        # Skip comments and empty lines
        if ($trimmed -match '^\s*//' -or $trimmed -match '^\s*\*' -or $trimmed.Length -eq 0) { continue }
        
        # --- Exports ---
        # export function name
        if ($trimmed -match 'export\s+function\s+(\w+)') {
            [void]$exports.Add(@{
                name = $Matches[1]; kind = "function"; file = $relPath; sourceLine = $lineNum
                interfaceId = "export.$($Matches[1])"
            })
        }
        # export class Name
        elseif ($trimmed -match 'export\s+class\s+(\w+)') {
            [void]$exports.Add(@{
                name = $Matches[1]; kind = "class"; file = $relPath; sourceLine = $lineNum
                interfaceId = "export.$($Matches[1])"
            })
        }
        # export const name
        elseif ($trimmed -match 'export\s+const\s+(\w+)') {
            [void]$exports.Add(@{
                name = $Matches[1]; kind = "const"; file = $relPath; sourceLine = $lineNum
                interfaceId = "export.$($Matches[1])"
            })
        }
        # export interface Name
        elseif ($trimmed -match 'export\s+interface\s+(\w+)') {
            [void]$exports.Add(@{
                name = $Matches[1]; kind = "interface"; file = $relPath; sourceLine = $lineNum
                interfaceId = "export.$($Matches[1])"
            })
        }
        # export type Name
        elseif ($trimmed -match 'export\s+type\s+(\w+)\s*=') {
            [void]$exports.Add(@{
                name = $Matches[1]; kind = "type"; file = $relPath; sourceLine = $lineNum
                interfaceId = "export.$($Matches[1])"
            })
        }
        # export default function/class name or export default name
        elseif ($trimmed -match 'export\s+default\s+(?:function|class)?\s*(\w+)') {
            [void]$exports.Add(@{
                name = $Matches[1]; kind = "default"; file = $relPath; sourceLine = $lineNum
                interfaceId = "export.$($Matches[1])"
            })
        }
        
        # --- Imports (from local/relative paths only) ---
        # import { X, Y } from './path'
        if ($trimmed -match "import\s+\{([^}]+)\}\s+from\s+['\x22](\.\/[^'\x22]+)['\x22]") {
            $names = $Matches[1] -split ',' | ForEach-Object { $_.Trim() }
            $from = $Matches[2]
            foreach ($n in $names) {
                if ($n.Length -gt 0) {
                    # Handle "name as alias" — extract the original name
                    $originalName = $n
                    $aliasName = $n
                    if ($n -match '(\w+)\s+as\s+(\w+)') {
                        $originalName = $Matches[1]
                        $aliasName = $Matches[2]
                    }
                    [void]$imports.Add(@{
                        name = $originalName; alias = $aliasName; file = $relPath; sourceLine = $lineNum
                        fromFile = $from; interfaceId = "import.$originalName"
                    })
                }
            }
        }
        # import * as X from './path'
        elseif ($trimmed -match "import\s+\*\s+as\s+(\w+)\s+from\s+['\x22](\.\/[^'\x22]+)['\x22]") {
            [void]$imports.Add(@{
                name = "*"; alias = $Matches[1]; file = $relPath; sourceLine = $lineNum
                fromFile = $Matches[2]; interfaceId = "import.namespace.$($Matches[1])"
            })
        }
        # import X from './path' (default import)
        elseif ($trimmed -match "import\s+(\w+)\s+from\s+['\x22](\.\/[^'\x22]+)['\x22]") {
            [void]$imports.Add(@{
                name = "default"; alias = $Matches[1]; file = $relPath; sourceLine = $lineNum
                fromFile = $Matches[2]; interfaceId = "import.default.$($Matches[1])"
            })
        }
    }
}

$manifest = @{
    phase = $Phase
    reportType = "source-derived-interface-manifest"
    workerId = $WorkerId
    taskId = $TaskId
    sourceRoot = $SourceRoot
    sourceDerived = $true
    extractionMode = "regex-minimal"
    sourceFiles = ($tsFiles | ForEach-Object { $_.FullName.Replace($SourceRoot, '').TrimStart('\', '/').Replace('\', '/') })
    exports = @($exports)
    imports = @($imports)
    warnings = @($warnings)
    extractedAt = (Get-Date).ToString("o")
}

# Ensure output directory exists
$outputDir = Split-Path $OutputPath -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

[System.IO.File]::WriteAllText($OutputPath, ($manifest | ConvertTo-Json -Depth 6), (New-Object System.Text.UTF8Encoding($false)))
Write-Output ($manifest | ConvertTo-Json -Depth 4)
exit 0