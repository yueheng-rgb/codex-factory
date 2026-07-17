# Validate Control Plane 鈥?Verify no tampering since freeze
# Any mismatch in frozen files 鈫?run_failed
param(
    [Parameter(Mandatory=$true)][string]$RunDir
)

$ErrorActionPreference = "Continue"
$errors = [System.Collections.ArrayList]::new()
$passes = [System.Collections.ArrayList]::new()
$exitCode = 0

$lockFile = Join-Path $RunDir "CONTROL_PLANE_LOCK.json"
if (-not (Test-Path $lockFile)) {
    [void]$errors.Add("MISSING: CONTROL_PLANE_LOCK.json 鈥?run not frozen")
    Write-Output (@{ status="FAIL"; errors=$errors } | ConvertTo-Json -Depth 4)
    exit 1
}

$lock = Get-Content $lockFile -Raw -Encoding UTF8 | ConvertFrom-Json
$HarnessRoot = $lock.harnessRoot

# Verify lock file itself hasn't been tampered with
if ($lock.schemaVersion -notin @("6A.1","6A.2","6B-R1","6B-R3","6B-R5")) {
    [void]$errors.Add("LOCK_SCHEMA_VERSION_MISMATCH: $($lock.schemaVersion)")
    $exitCode = 1
}

foreach ($item in $lock.items) {
    # Try multiple locations for the file: runtime/, run dir, harness root
    $candidates = @()
    # Priority: location-specified path, then runtime/, then run dir, then harness root
    if ($item.location -and $item.location -eq "runtime") {
        $candidates += Join-Path $HarnessRoot "runtime\$($item.path)"
    }
    $candidates += Join-Path $HarnessRoot "runtime\$($item.path)"
    $candidates += Join-Path $RunDir $item.path
    $candidates += Join-Path $HarnessRoot $item.path
    # Remove duplicates while preserving order
    $candidates = @($candidates | Select-Object -Unique)
    
    $fp = $null
    foreach ($c in $candidates) {
        if (Test-Path $c) { $fp = $c; break }
    }
    if (-not $fp) { $fp = $candidates[0] }  # Use first candidate for error reporting

    if (-not (Test-Path $fp)) {
        [void]$errors.Add("CONTROL_FILE_MISSING: $($item.path)")
        $exitCode = 1
        continue
    }

    $bytes = [System.IO.File]::ReadAllBytes($fp)
    $currentSha = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    ).Replace("-","").ToLower()

    if ($currentSha -ne $item.sha256) {
        if ($item.mutable -eq $false) {
            [void]$errors.Add("CONTROL_FILE_TAMPERED: $($item.path) 鈥?SHA256 changed (was $($item.sha256), now $currentSha)")
            $exitCode = 1
        } else {
            [void]$passes.Add("Mutable file changed (allowed): $($item.path)")
        }
    } else {
        [void]$passes.Add("Verified: $($item.path)")
    }
}

if ($exitCode -eq 0) {
    [void]$passes.Add("Control plane integrity: PASS")
} else {
    [void]$passes.Add("Control plane integrity: FAIL")
}

$result = @{
    status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }
    errors = $errors
    passes = $passes
    frozenItemCount = $lock.items.Count
} | ConvertTo-Json -Depth 4

Write-Output $result
exit $exitCode
