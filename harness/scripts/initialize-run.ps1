# Initialize a new Harness Run — Phase 6B-R1
# Creates run directory, generates stubs, records harness baseline, records run_initialized via hash-chain.
param(
    [Parameter(Mandatory=$true)][string]$RunId,
    [Parameter(Mandatory=$false)][string]$ProjectName = "untitled",
    [Parameter(Mandatory=$false)][string]$Description = ""
)

$ErrorActionPreference = "Stop"
$HarnessRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$RunsDir = Join-Path $HarnessRoot "runs"
$RunDir = Join-Path $RunsDir $RunId
$utf8 = New-Object System.Text.UTF8Encoding($false)

if (Test-Path $RunDir) { throw "RunId '$RunId' already exists" }

New-Item -ItemType Directory -Path $RunDir -Force | Out-Null
@("evidence","handoffs") | ForEach-Object { New-Item -ItemType Directory -Path (Join-Path $RunDir $_) -Force | Out-Null }

# Stub files
$tasksStub = @{ schemaVersion="6B-R1"; runId=$RunId; tasks=@() } | ConvertTo-Json -Depth 4
$acceptStub = @{ schemaVersion="6B-R1"; runId=$RunId; acceptanceItems=@() } | ConvertTo-Json -Depth 4
$ownerStub = @{ schemaVersion="6B-R1"; runId=$RunId; ownership=@{} } | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText((Join-Path $RunDir "TASKS.json"), $tasksStub, $utf8)
[System.IO.File]::WriteAllText((Join-Path $RunDir "ACCEPTANCE.json"), $acceptStub, $utf8)
[System.IO.File]::WriteAllText((Join-Path $RunDir "OWNERSHIP.json"), $ownerStub, $utf8)

# --- Harness baseline recording (Phase 6B-R1) ---
$harnessBaseline = @{
    schemaVersion = "6B-R1"
    runId = $RunId
    recordedAt = (Get-Date).ToString("o")
    files = @()
}
$harnessDirs = @("scripts", "config", "templates")
foreach ($dir in $harnessDirs) {
    $dirPath = Join-Path $HarnessRoot $dir
    if (Test-Path $dirPath) {
        Get-ChildItem $dirPath -Recurse -File | Sort-Object FullName | ForEach-Object {
            $relPath = $_.FullName.Substring($HarnessRoot.ToString().Length).TrimStart('\/').Replace('\', '/')
            $hash = [System.BitConverter]::ToString(
                [System.Security.Cryptography.SHA256]::Create().ComputeHash(
                    [System.IO.File]::ReadAllBytes($_.FullName)
                )
            ).Replace("-","").ToLower()
            $harnessBaseline.files += @{
                path = $relPath
                sha256 = $hash
                size = $_.Length
            }
        }
    }
}
$harnessBaseline["fileCount"] = $harnessBaseline.files.Count
$harnessBaseline["rootHash"] = [System.BitConverter]::ToString(
    [System.Security.Cryptography.SHA256]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes(
            ($harnessBaseline.files | ForEach-Object { "$($_.path):$($_.sha256)" } | Sort-Object) -join "|"
        )
    )
).Replace("-","").ToLower()

$baselineFile = Join-Path $RunDir "HARNESS_BASELINE.json"
[System.IO.File]::WriteAllText($baselineFile, ($harnessBaseline | ConvertTo-Json -Depth 6), $utf8)

# Set active run
$ar = @{ activeRunId=$RunId; projectName=$ProjectName; startedAt=(Get-Date).ToString("o") } | ConvertTo-Json
[System.IO.File]::WriteAllText((Join-Path $HarnessRoot "runtime\active-run.json"), $ar, $utf8)

# Record first event via hash-chain
$result = & (Join-Path $PSScriptRoot "append-hash-event.ps1") -RunDir $RunDir -EventData @{
    event = "run_initialized"
    actor = "orchestrator"
    projectName = $ProjectName
    description = $Description
}

Write-Output (@{ status="initialized"; runId=$RunId; runDir=$RunDir; result=$result } | ConvertTo-Json)
