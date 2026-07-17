<#
.SYNOPSIS Validates the integrity of a Codex Factory Resource Pack.
.DESCRIPTION Checks MANIFEST.json, SHA256, core assets, categories, policies, schemas,
    scoring gate, failure-router exclusion, compressed-summary prohibition, and unverified-claims.
.PARAMETER PackPath Path to the factory-resource-pack directory. Defaults to script parent dir.
.PARAMETER OutputPath Path to write validation result JSON. Defaults to PackPath/bootstrap/VALIDATION_RESULT.json.
#>
param(
    [string]$PackPath = (Split-Path $PSScriptRoot -Parent),
    [string]$OutputPath = $null
)

$ErrorActionPreference = "Stop"
$ManifestPath = Join-Path $PackPath "MANIFEST.json"
$ManifestHashPath = Join-Path $PackPath "MANIFEST.sha256"
if (-not $OutputPath) { $OutputPath = Join-Path $PSScriptRoot "VALIDATION_RESULT.json" }

$script:Results = @{
    timestamp = (Get-Date -Format "o")
    packPath = $PackPath
    checks = @()
    overallVerdict = "PENDING"
    failures = @()
    warnings = @()
}

function Add-Check($CheckId,$Description,$Priority,$Status,$Detail) {
    $script:Results.checks += @{checkId=$CheckId;description=$Description;priority=$Priority;status=$Status;detail=$Detail}
    if ($Status -eq "FAIL") {
        if ($Priority -eq "P0") { $script:Results.failures += "[$CheckId] $Description : $Detail" }
        else { $script:Results.warnings += "[$CheckId] $Description : $Detail" }
    }
}

function Write-Result {
    $p0Failures = ($script:Results.checks | Where-Object { $_.priority -eq "P0" -and $_.status -eq "FAIL" }).Count
    $script:Results.overallVerdict = if ($p0Failures -gt 0) { "FAIL" } else { "PASS" }
    $script:Results.failureCount = $script:Results.failures.Count
    $script:Results.warningCount = $script:Results.warnings.Count
    $script:Results.totalChecks = $script:Results.checks.Count
    $json = $script:Results | ConvertTo-Json -Depth 5
    if (-not (Test-Path (Split-Path $OutputPath -Parent))) { New-Item -ItemType Directory -Force -Path (Split-Path $OutputPath -Parent) | Out-Null }
    $json | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Output $json
    exit $(if ($script:Results.overallVerdict -eq "PASS") { 0 } else { 1 })
}

# === 1: MANIFEST exists and parses ===
$checkId = "MANIFEST_EXISTS"
if (-not (Test-Path $ManifestPath)) {
    Add-Check $checkId "MANIFEST.json must exist" "P0" "FAIL" "File not found: $ManifestPath"
    Write-Result
}
try {
    $manifestContent = Get-Content -Raw -Path $ManifestPath -Encoding UTF8
    $manifest = $manifestContent | ConvertFrom-Json
    Add-Check $checkId "MANIFEST.json exists and parses" "P0" "PASS" "Parsed, version $($manifest.version)"
} catch {
    Add-Check $checkId "MANIFEST.json must parse as JSON" "P0" "FAIL" "Parse error: $_"
    Write-Result
}

# === 2: MANIFEST.sha256 matches (raw bytes via Get-FileHash) ===
$checkId = "MANIFEST_HASH"
if (Test-Path $ManifestHashPath) {
    try {
        $storedHash = (Get-Content -Raw -Path $ManifestHashPath -Encoding UTF8).Trim() -split '\s+' | Select-Object -First 1
        $computedHash = (Get-FileHash -Path $ManifestPath -Algorithm SHA256).Hash
        if ($computedHash -eq $storedHash.ToUpper()) {
            Add-Check $checkId "MANIFEST.sha256 matches" "P0" "PASS" "Hash: $computedHash"
        } else {
            Add-Check $checkId "MANIFEST.sha256 must match" "P0" "FAIL" "Stored: $storedHash, Computed: $computedHash"
        }
    } catch {
        Add-Check $checkId "MANIFEST.sha256 validation error" "P0" "FAIL" "Error: $_"
    }
} else {
    Add-Check $checkId "MANIFEST.sha256 must exist" "P0" "FAIL" "File not found: $ManifestHashPath"
}

# === 3: Core assets present ===
$checkId = "CORE_ASSETS"
$coreAssetPaths = @(
    "core/factoryctl/factoryctl.ps1",
    "core/agent-tracking/register-agent.ps1",
    "core/agent-tracking/record-progress.ps1",
    "core/handoff/generate-handoff.ps1",
    "core/handoff/handoff-verify.ps1"
)
$missingAssets = @()
foreach ($ap in $coreAssetPaths) {
    if (-not (Test-Path (Join-Path $PackPath $ap))) { $missingAssets += $ap }
}
if ($missingAssets.Count -eq 0) {
    Add-Check $checkId "All required core assets present" "P0" "PASS" "$($coreAssetPaths.Count) assets checked"
} else {
    Add-Check $checkId "All required core assets must be present" "P0" "FAIL" "Missing: $($missingAssets -join ', ')"
}

# === 4: Categories present (non-physical categories allowed) ===
$checkId = "CATEGORIES_PRESENT"
# Categories that do not require physical directories in the pack
$nonPhysicalCategories = @("optional-modules", "excluded", "reference-archive", "deprecated")
$expectedCategories = $manifest.categories
$missingCategories = @()
foreach ($cat in $expectedCategories) {
    if ($cat -in $nonPhysicalCategories) { continue }
    $catPath = Join-Path $PackPath $cat
    if (-not (Test-Path $catPath)) { $missingCategories += $cat }
}
if ($missingCategories.Count -eq 0) {
    Add-Check $checkId "All required categories present" "P0" "PASS" "$($expectedCategories.Count) in manifest, $($nonPhysicalCategories.Count) non-physical excluded"
} else {
    Add-Check $checkId "All required categories must be present" "P0" "FAIL" "Missing: $($missingCategories -join ', ')"
}

# === 5: Policy JSONs parse ===
$checkId = "POLICIES_PARSE"
$policyDir = Join-Path $PackPath "policies"
$policyErrors = @()
if (Test-Path $policyDir) {
    Get-ChildItem -Path $policyDir -Filter "*.json" | ForEach-Object {
        try { $null = Get-Content $_.FullName -Raw | ConvertFrom-Json }
        catch { $policyErrors += "$($_.Name): $_" }
    }
}
if ($policyErrors.Count -eq 0) {
    Add-Check $checkId "All policy JSONs parse" "P0" "PASS" "No parse errors in policies/"
} else {
    Add-Check $checkId "All policy JSONs must parse" "P0" "FAIL" "Errors: $($policyErrors -join '; ')"
}

# === 6: Schema JSONs parse ===
$checkId = "SCHEMAS_PARSE"
$schemaDir = Join-Path $PackPath "schemas"
$schemaErrors = @()
if (Test-Path $schemaDir) {
    Get-ChildItem -Path $schemaDir -Filter "*.json" | ForEach-Object {
        try { $null = Get-Content $_.FullName -Raw | ConvertFrom-Json }
        catch { $schemaErrors += "$($_.Name): $_" }
    }
}
if ($schemaErrors.Count -eq 0) {
    Add-Check $checkId "All schema JSONs parse" "P0" "PASS" "No parse errors in schemas/"
} else {
    Add-Check $checkId "All schema JSONs must parse" "P0" "FAIL" "Errors: $($schemaErrors -join '; ')"
}

# === 7: No unevaluated expressions in packaged JSON ===
$checkId = "NO_UNEVALUATED_EXPRESSIONS"
$jsonDirsToCheck = @("policies", "schemas", "verifier-modules", "negative-fixtures")
$unevalPattern = '<<.*>>|\$\{.*\}|\{\{.*\}\}'
$unevalFound = @()
foreach ($dir in $jsonDirsToCheck) {
    $dirPath = Join-Path $PackPath $dir
    if (Test-Path $dirPath) {
        Get-ChildItem -Path $dirPath -Filter "*.json" -Recurse | ForEach-Object {
            $content = Get-Content -Raw -Path $_.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content -match $unevalPattern) { $unevalFound += "$dir/$($_.Name)" }
        }
    }
}
if ($unevalFound.Count -eq 0) {
    Add-Check $checkId "No unevaluated expressions in packaged JSON" "P0" "PASS" "No <<>>, `$`, or {{}} patterns found"
} else {
    Add-Check $checkId "No unevaluated expressions in packaged JSON" "P0" "FAIL" "Found in: $($unevalFound -join ', ')"
}

# === 8: SCORING_SYSTEM_GATE: no scoring-as-PASS in core ===
$checkId = "NO_SCORING_AS_PASS"
$coreFilesToCheck = @("core", "verifier-modules", "policies")
$scoreViolations = @()
foreach ($dir in $coreFilesToCheck) {
    $dirPath = Join-Path $PackPath $dir
    if (Test-Path $dirPath) {
        Get-ChildItem -Path $dirPath -Include "*.json","*.ps1","*.md" -Recurse | ForEach-Object {
            $content = Get-Content -Raw -Path $_.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
            # Match "score" only when used in a scoring-as-PASS context (not in prohibition or description of the gate itself)
            if (($content -match '\bscoring\b' -or $content -match '\bscore\b') -and
                $content -notmatch 'SCORING_SYSTEM_GATE|Do not package scoring|No core module may emit PASS/FAIL based on computed score|scoring system prohibition|no scoring-as-PASS|Do not use scoring') {
                $scoreViolations += "$dir/$($_.Name)"
            }
        }
    }
}
if ($scoreViolations.Count -eq 0) {
    Add-Check $checkId "SCORING_SYSTEM_GATE: no scoring-as-PASS in core" "P0" "PASS" "No scoring-as-PASS patterns in core/verifier-modules/policies"
} else {
    Add-Check $checkId "SCORING_SYSTEM_GATE: no scoring-as-PASS in core" "P0" "FAIL" "Violations: $($scoreViolations -join ', ')"
}

# === 9: No failure-router in core ===
$checkId = "NO_FAILURE_ROUTER_IN_CORE"
$failureRouterFound = @()
$coreFilesToCheck = @("core")
foreach ($dir in $coreFilesToCheck) {
    $dirPath = Join-Path $PackPath $dir
    if (Test-Path $dirPath) {
        Get-ChildItem -Path $dirPath -Include "*.json","*.ps1","*.md" -Recurse | ForEach-Object {
            $content = Get-Content -Raw -Path $_.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($content -match 'failure.router|failure-router|failureRouter|FAILURE_ROUTER') {
                $failureRouterFound += "$dir/$($_.Name)"
            }
        }
    }
}
if ($failureRouterFound.Count -eq 0) {
    Add-Check $checkId "No failure-router in core" "P0" "PASS" "Core is clean"
} else {
    Add-Check $checkId "Failure-router excluded from core" "P0" "FAIL" "Found in: $($failureRouterFound -join ', ')"
}

# === 10: No compressed-summary-as-evidence (context-aware: exclude prohibition mentions) ===
$checkId = "NO_COMPRESSED_SUMMARY_AS_EVIDENCE"
$summaryViolations = @()
$allDirs = @("core", "verifier-modules", "protocols", "policies")
foreach ($dir in $allDirs) {
    $dirPath = Join-Path $PackPath $dir
    if (Test-Path $dirPath) {
        Get-ChildItem -Path $dirPath -Recurse -Include "*.json","*.md" | ForEach-Object {
            $content = Get-Content -Raw -Path $_.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
            # Only flag if compressed-summary appears as evidence, not as prohibition
            if (($content -match 'compressed.summary' -or $content -match 'compressedSummary') -and
                ($content -match '"evidence"' -or $content -match 'evidenceRef' -or $content -match 'as.evidence') -and
                $content -notmatch 'NOT.*evidence|not.*evidence|Do not|must not|prohibited|NOT trusted|untrusted|DO NOT') {
                $summaryViolations += "$dir/$($_.Name)"
            }
        }
    }
}
if ($summaryViolations.Count -eq 0) {
    Add-Check $checkId "No compressed-summary-as-evidence" "P0" "PASS" "No violations (prohibition mentions excluded)"
} else {
    Add-Check $checkId "Compressed summary must not be used as evidence" "P0" "FAIL" "Found in: $($summaryViolations -join ', ')"
}

# === 11: No unverified claims marked as facts (context-aware) ===
$checkId = "NO_UNVERIFIED_CLAIMS_AS_FACTS"
$unverifiedFound = @()
$allDirs = @("core", "protocols", "reference-archive")
foreach ($dir in $allDirs) {
    $dirPath = Join-Path $PackPath $dir
    if (Test-Path $dirPath) {
        Get-ChildItem -Path $dirPath -Recurse -Include "*.json","*.md" | ForEach-Object {
            $content = Get-Content -Raw -Path $_.FullName -Encoding UTF8 -ErrorAction SilentlyContinue
            # Only flag if VERIFIED_FACT appears as a claim, not as a classification label in prohibition docs
            if (($content -match 'VERIFIED_FACT' -or $content -match 'UNVERIFIED_FACT') -and
                $content -notmatch 'classification|classify|CLAIM_CLASSIFICATION|DO NOT|must not|prohibited') {
                $unverifiedFound += "$dir/$($_.Name)"
            }
        }
    }
}
if ($unverifiedFound.Count -eq 0) {
    Add-Check $checkId "No unverified claims marked as facts" "P1" "PASS" "No violations (classification mentions excluded)"
} else {
    Add-Check $checkId "Unverified claims must not be marked as VERIFIED_FACT" "P1" "FAIL" "Found in: $($unverifiedFound -join ', ')"
}

# === 12: nativeGenerated ===
$checkId = "NATIVE_GENERATED_FLAG"
if ($manifest.nativeGenerated -eq $true) {
    Add-Check $checkId "MANIFEST.json has nativeGenerated: true" "P1" "PASS" "Confirmed"
} else {
    Add-Check $checkId "MANIFEST.json must have nativeGenerated: true" "P1" "FAIL" "nativeGenerated is $($manifest.nativeGenerated)"
}

# === 13: SCORING_SYSTEM_GATE enforcement ===
$checkId = "SCORING_GATE_ENFORCED"
if ($manifest.scoringSystemGate -and $manifest.scoringSystemGate.enforced -eq $true) {
    Add-Check $checkId "SCORING_SYSTEM_GATE enforcement confirmed" "P0" "PASS" "Gate enforced per manifest"
} else {
    Add-Check $checkId "SCORING_SYSTEM_GATE must be enforced" "P0" "FAIL" "Gate not confirmed in manifest"
}

# === 14: Boundary rules present ===
$checkId = "BOUNDARY_RULES_PRESENT"
if ($manifest.boundaryRules -and $manifest.boundaryRules.Count -gt 0) {
    Add-Check $checkId "Boundary rules present in manifest" "P0" "PASS" "$($manifest.boundaryRules.Count) boundary rules"
} else {
    Add-Check $checkId "Boundary rules must be present in manifest" "P0" "FAIL" "No boundary rules"
}

Write-Result
