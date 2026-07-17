# External Trust Root — Phase 6B-R3 Harness Hardening
# Freezes an external trust baseline OUTSIDE the run directory so that
# a compromised run cannot tamper with its own lock.
# Phase 6B-R3: Refuses to re-freeze after run_sealed.
param(
    [Parameter(Mandatory=$true)]
    [string]$RunDir,

    [Parameter(Mandatory=$true)]
    [ValidateSet("freeze","validate")]
    [string]$Action
)

$ErrorActionPreference = "Stop"

$HarnessRoot      = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$HarnessControl   = Join-Path $HarnessRoot "..\harness-control"
$LocksDir         = Join-Path $HarnessControl "locks"
$SequenceFile     = Join-Path $LocksDir "_freeze_sequence.json"
$TrustRootFile    = Join-Path $LocksDir "$(Split-Path $RunDir -Leaf)\trust-root.json"
$ControlPlaneLock = Join-Path $RunDir "CONTROL_PLANE_LOCK.json"
$ScriptsDir       = Join-Path $HarnessRoot "scripts"

# --- RUN_SEALED CHECK (Phase 6B-R3) ---
if ($Action -eq "freeze") {
    $stateFile = Join-Path $RunDir "RUN_STATE.jsonl"
    if (Test-Path $stateFile) {
        $existing = @(Get-Content $stateFile -Encoding UTF8 | Where-Object { $_.Trim().Length -gt 0 })
        foreach ($line in $existing) {
            try {
                $evt = $line | ConvertFrom-Json
                if ($evt.event -eq "run_sealed") {
                    Write-Output (ConvertTo-Json -Compress -Depth 2 @{
                        status = "REJECTED"
                        reason = "RUN_ALREADY_SEALED: run_sealed event exists at seq=$($evt.seq). Cannot re-freeze external trust root."
                    })
                    exit 1
                }
            } catch {}
        }
    }
}

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

function Write-JsonFile {
    param([string]$Path, $Data)
    $parent = Split-Path $Path -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, ($Data | ConvertTo-Json -Depth 6), $utf8)
}

function Get-DirSha256 {
    param([string]$Dir)
    if (-not (Test-Path $Dir)) { return "DIR_NOT_FOUND" }
    $files = Get-ChildItem $Dir -Recurse -File | Sort-Object FullName
    $combined = ($files | ForEach-Object {
        $hash = [System.BitConverter]::ToString(
            [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                [System.IO.File]::ReadAllBytes($_.FullName)
            )
        ).Replace("-","").ToLower()
        "$($_.FullName):$hash"
    }) -join "|"
    return [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($combined)
        )
    ).Replace("-","").ToLower()
}

function Get-FileSha256 {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "NOT_FOUND" }
    return [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.IO.File]::ReadAllBytes($Path)
        )
    ).Replace("-","").ToLower()
}

# ------------------------------------------------------------------
# Monotonic freeze sequence
# ------------------------------------------------------------------

function Get-NextFreezeSequence {
    if (Test-Path $SequenceFile) {
        $seq = Get-Content $SequenceFile -Raw -Encoding UTF8 | ConvertFrom-Json
        return [int]$seq.lastSequence + 1
    }
    return 1
}

function Set-FreezeSequence {
    param([int]$Seq)
    Write-JsonFile $SequenceFile @{ lastSequence = $Seq }
}

# ------------------------------------------------------------------
# FREEZE Action
# ------------------------------------------------------------------

if ($Action -eq "freeze") {
    if (-not (Test-Path $ControlPlaneLock)) {
        Write-Output (ConvertTo-Json -Compress -Depth 2 @{
            status = "FAILED"
            reason = "CONTROL_PLANE_LOCK not found at $ControlPlaneLock"
        })
        exit 1
    }

    $controlPlaneLockSha256 = Get-FileSha256 $ControlPlaneLock
    $harnessBaselineSha256 = Get-DirSha256 $ScriptsDir
    $freezeSequence = Get-NextFreezeSequence

    $trustRoot = @{
        schemaVersion           = "6B-R3"
        runId                   = Split-Path $RunDir -Leaf
        controlPlaneLockSha256  = $controlPlaneLockSha256
        harnessBaselineSha256   = $harnessBaselineSha256
        frozenAt                = (Get-Date).ToString("o")
        freezeSequence          = $freezeSequence
        trustRootFile           = $TrustRootFile
    }

    Write-JsonFile $TrustRootFile $trustRoot
    Set-FreezeSequence $freezeSequence

    Write-Output (ConvertTo-Json -Compress -Depth 4 $trustRoot)
    exit 0
}

# ------------------------------------------------------------------
# VALIDATE Action
# ------------------------------------------------------------------

if ($Action -eq "validate") {
    $errors = @()
    $passes = @()

    # Detection 1: trust root file existence
    if (-not (Test-Path $TrustRootFile)) {
        $errors += @{
            code   = "trust_root_missing"
            detail = "Trust root file not found at $TrustRootFile"
        }
        Write-Output (ConvertTo-Json -Compress -Depth 4 @{
            status = "FAILED"
            errors = $errors
        })
        exit 1
    }

    $trustRoot = Get-Content $TrustRootFile -Raw -Encoding UTF8 | ConvertFrom-Json

    # Detection 2: control plane lock hash
    $currentCpSha = Get-FileSha256 $ControlPlaneLock
    if ($currentCpSha -ne $trustRoot.controlPlaneLockSha256) {
        $errors += @{
            code           = "control_plane_lock_modified"
            detail         = "CONTROL_PLANE_LOCK hash does not match frozen baseline"
            expectedSha256 = $trustRoot.controlPlaneLockSha256
            actualSha256   = $currentCpSha
        }
    }

    # Detection 3: scripts directory hash
    $currentScriptsSha = Get-DirSha256 $ScriptsDir
    if ($currentScriptsSha -ne $trustRoot.harnessBaselineSha256) {
        $errors += @{
            code           = "governance_modified"
            detail         = "Harness scripts directory hash does not match frozen baseline"
            expectedSha256 = $trustRoot.harnessBaselineSha256
            actualSha256   = $currentScriptsSha
        }
    }

    if ($errors.Count -eq 0) {
        Write-Output (ConvertTo-Json -Compress -Depth 4 @{
            status = "VALID"
            trustRoot = $trustRoot
        })
        exit 0
    } else {
        Write-Output (ConvertTo-Json -Compress -Depth 4 @{
            status = "FAILED"
            errors = $errors
            trustRoot = $trustRoot
        })
        exit 1
    }
}
