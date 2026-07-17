# Invoke Validation Command 鈥?Phase 6A.2 with hash-chain events
# Trusted execution wrapper. Records exit code, stdout/stderr SHA256.
param(
    [Parameter(Mandatory=$true)][string]$ValidationId,
    [Parameter(Mandatory=$true)][string]$ExecCommand,
    [Parameter(Mandatory=$true)][string]$WorkingDir,
    [Parameter(Mandatory=$true)][string]$RunDir,
    [Parameter(Mandatory=$true)][string]$ExecutorRole,
    [Parameter(Mandatory=$false)][string]$Token
)

$ErrorActionPreference = "Continue"
$ScriptsDir = $PSScriptRoot
$HarnessRoot = Resolve-Path (Join-Path $ScriptsDir "..")
$evidenceDir = Join-Path $RunDir "evidence"
if (-not (Test-Path $evidenceDir)) { New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null }

$startedAt = (Get-Date).ToString("o")
$stdoutFile = Join-Path $evidenceDir "$ValidationId-stdout.log"
$stderrFile = Join-Path $evidenceDir "$ValidationId-stderr.log"

# Generate authorization proof for validation_started (Phase 6A.3)
$startEventData = [ordered]@{ event="validation_started"; validationId=$ValidationId; command=$ExecCommand; actor=$ExecutorRole }
$startCanonical = ($startEventData | ConvertTo-Json -Compress -Depth 6)
if ($Token) {
    $proofResult = & (Join-Path $ScriptsDir "token-lease.ps1") -Action sign -RunId (Split-Path $RunDir -Leaf) -TaskId $ValidationId -Token $Token -Operation "validation_started" -EventCanonicalJson $startCanonical 2>&1 | ConvertFrom-Json
    if (-not $proofResult -or $proofResult.status -ne "signed") { Write-Warning "PROOF_GENERATION_FAILED: $($proofResult.reason)" }
}

# Record validation_started via hash-chain
$startEvt = [ordered]@{ event="validation_started"; validationId=$ValidationId; command=$ExecCommand; actor=$ExecutorRole }
if ($Token -and $proofResult.status -eq "signed") {
    $startEvt["authorizationProof"] = $proofResult.authorizationProof
    $startEvt["tokenLeaseId"] = $proofResult.tokenLeaseId
    $startEvt["proofNonce"] = $proofResult.nonce
    $startEvt["tokenIssuedAt"] = $proofResult.issuedAt
    $startEvt["tokenExpiresAt"] = $proofResult.expiresAt
}
& (Join-Path $ScriptsDir "append-hash-event.ps1") -RunDir $RunDir -EventData $startEvt

# Execute
$exitCode = 0
try {
    Push-Location $WorkingDir
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    $psi.Arguments = "/c $ExecCommand"
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    $exitCode = $proc.ExitCode
    Pop-Location
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($stdoutFile, $stdout, $utf8)
    [System.IO.File]::WriteAllText($stderrFile, $stderr, $utf8)
} catch {
    $exitCode = -1
    $_ | Out-File $stderrFile -Append -Encoding UTF8
    Pop-Location -ErrorAction SilentlyContinue
}

$finishedAt = (Get-Date).ToString("o")

# SHA256 of outputs
function Get-FileSha($p) { if (Test-Path $p) { return [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.IO.File]::ReadAllBytes($p))).Replace("-","").ToLower() } return "" }
$stdoutSha = Get-FileSha $stdoutFile
$stderrSha = Get-FileSha $stderrFile

$status = if ($exitCode -eq 0) { "passed" } else { "failed" }

# Save result JSON
$result = @{
    validationId = $ValidationId; command = $ExecCommand; workingDir = $WorkingDir
    startedAt = $startedAt; finishedAt = $finishedAt; exitCode = $exitCode
    stdoutPath = $stdoutFile; stderrPath = $stderrFile
    stdoutSha256 = $stdoutSha; stderrSha256 = $stderrSha
    executorRole = $ExecutorRole; status = $status
} | ConvertTo-Json -Depth 4
[System.IO.File]::WriteAllText((Join-Path $evidenceDir "$ValidationId-result.json"), $result, (New-Object System.Text.UTF8Encoding($false)))

# Record validation result via hash-chain (with Phase 6A.3 proof)
$valResultEvt = [ordered]@{ event="validation_$status"; validationId=$ValidationId; exitCode=$exitCode; actor=$ExecutorRole; stdoutSha256=$stdoutSha; stderrSha256=$stderrSha }
if ($Token -and $proofResult.status -eq "signed") {
    $resCanonical = ($valResultEvt | ConvertTo-Json -Compress -Depth 6)
    $resProof = & (Join-Path $ScriptsDir "token-lease.ps1") -Action sign -RunId (Split-Path $RunDir -Leaf) -TaskId $ValidationId -Token $Token -Operation "validation_$status" -EventCanonicalJson $resCanonical 2>&1 | ConvertFrom-Json
    if ($resProof.status -eq "signed") {
        $valResultEvt["authorizationProof"] = $resProof.authorizationProof
        $valResultEvt["tokenLeaseId"] = $resProof.tokenLeaseId
        $valResultEvt["proofNonce"] = $resProof.nonce
        $valResultEvt["tokenIssuedAt"] = $resProof.issuedAt
        $valResultEvt["tokenExpiresAt"] = $resProof.expiresAt
    }
}
& (Join-Path $ScriptsDir "append-hash-event.ps1") -RunDir $RunDir -EventData $valResultEvt

Write-Output $result
exit 0
