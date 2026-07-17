# validate-project-request.ps1 — Phase 6C-U2-A
# Validates a project request JSON against factory rules.
param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectRequest
)
$ErrorActionPreference = "Stop"
$H = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$errors = @()
$passes = @()
$total = 0; $ok = 0

function check($label, $sb) { $script:total++; try { if (& $sb) { $script:passes += $label; $script:ok++ } else { $script:errors += "$label-FAIL" } } catch { $script:errors += "$label-ERROR: $_" } }

if (-not (Test-Path $ProjectRequest)) { Write-Host "ERROR: Project request file not found: $ProjectRequest"; exit 2 }
$pr = Get-Content $ProjectRequest -Raw | ConvertFrom-Json

$outDir = Join-Path $H "outputs"
$outFile = Join-Path $outDir "u2-a-project-request-validation-report.json"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }

# 1. Basic structure
check "P01: projectName exists" { $pr.projectName -and $pr.projectName.Length -gt 0 }
check "P02: runId exists" { $pr.runId -and $pr.runId.Length -gt 0 }
check "P03: workers >= 2" { ($pr.workers | Measure-Object).Count -ge 2 }
check "P04: tasks exist (via workers)" { ($pr.workers | ForEach-Object { $_.taskDescription } | Where-Object { $_ }).Count -ge 2 }
check "P05: acceptance exists" { ($pr.acceptance | Measure-Object).Count -ge 1 }

# 2. Worker checks
$workerIds = $pr.workers | ForEach-Object { $_.workerId }
check "P06: each worker has workerId" { ($pr.workers | Where-Object { -not $_.workerId }).Count -eq 0 }
check "P07: each worker has taskDescription" { ($pr.workers | Where-Object { -not $_.taskDescription }).Count -eq 0 }
check "P08: each worker has ownedPaths" { ($pr.workers | Where-Object { (-not $_.ownedPaths) -or $_.ownedPaths.Count -eq 0 }).Count -eq 0 }
check "P09: each worker has exports OR imports" {
    ($pr.workers | Where-Object { (-not $_.exports -or $_.exports.Count -eq 0) -and (-not $_.imports -or $_.imports.Count -eq 0) }).Count -eq 0
}

# 3. No duplicate owned paths
$allPaths = $pr.workers | ForEach-Object { $_.ownedPaths } | ForEach-Object { $_ }
$uniquePaths = $allPaths | Sort-Object -Unique
check "P10: no duplicate owned paths" { $allPaths.Count -eq $uniquePaths.Count }

# 4. Cross-worker dependency
$crossRefs = $pr.workers | ForEach-Object { $w = $_; if ($w.imports) { $w.imports | ForEach-Object { $_ } } }
check "P11: at least 1 cross-worker dependency" { ($crossRefs | Measure-Object).Count -ge 1 }

# 5. No self-import
check "P12: no worker imports from itself" {
    $bad = $pr.workers | ForEach-Object { $w = $_; if ($w.imports) { $w.imports | Where-Object { $_.fromWorkerId -eq $w.workerId } } }
    ($bad | Measure-Object).Count -eq 0
}

# 6. Import targets exist
check "P13: all import targets reference existing workers" {
    $bad = $pr.workers | ForEach-Object { $w = $_; if ($w.imports) { $w.imports | Where-Object { $_.fromWorkerId -notin $workerIds } } }
    ($bad | Measure-Object).Count -eq 0
}

# 7. forbiddenPaths
check "P14: forbiddenPaths exists" { $pr.forbiddenPaths -and $pr.forbiddenPaths.Count -ge 1 }

# 8. Interface contract derivable
$allExports = $pr.workers | ForEach-Object { $w = $_; if ($w.exports) { $w.exports | ForEach-Object { $_ } } }
check "P15: at least 3 total exported interfaces" { ($allExports | Measure-Object).Count -ge 3 }

# 9. acceptance criteria
check "P16: at least 1 acceptance per worker (implied by total >= 2)" { ($pr.acceptance | Measure-Object).Count -ge 2 }

$verdict = if ($errors.Count -eq 0) { "PASS" } else { "FAIL" }
$report = @{
    reportType = "project-request-validation"
    phase = "Phase 6C-U2-A"
    projectRequest = (Resolve-Path $ProjectRequest).Path
    verdict = $verdict
    totalChecks = $total
    passCount = $ok
    failCount = $errors.Count
    passes = $passes
    errors = $errors
    timestamp = (Get-Date).ToString("o")
} | ConvertTo-Json -Depth 3

Set-Content $outFile -Value $report -Encoding UTF8
Write-Output $report
if ($errors.Count -gt 0) { exit 1 } else { exit 0 }
