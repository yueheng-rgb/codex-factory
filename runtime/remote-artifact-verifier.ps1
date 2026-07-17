# Codex Factory V3.3 — Remote Artifact Verifier
param(
    [Parameter(Mandatory=$true)] [string]$Action,
    [string]$RunId = "",
    [string]$ZipPath = "",
    [switch]$Json
)

$RepoRoot = (Get-Location).Path
$remoteDir = "$RepoRoot/artifacts/remote/$RunId"

function Test-RemoteArtifactExists {
    if (-not $RunId) { return $false }
    $zip = "$remoteDir/artifact.zip"
    return (Test-Path $zip)
}

function Get-ArtifactHash {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "NO_FILE" }
    $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path $Path).Path)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
    return [System.BitConverter]::ToString($hash).Replace("-","").ToLower()
}

function Invoke-VerifyRemoteArtifact {
    $result = @{
        run_id = $RunId
        verified_at = (Get-Date -Format "o")
        checks = @()
        final_status = "PENDING"
        non_claims = @(
            "Remote artifact verifier is READY but no real GitHub Actions artifact provided yet",
            "Do NOT claim REMOTE_ARTIFACT_VERIFIED without passing all checks",
            "local-generated artifacts must be marked LOCAL_REMOTE_SHAPE_VALIDATED"
        )
    }

    # Check 1: Artifact zip exists
    $zipPath = "$remoteDir/artifact.zip"
    if (-not (Test-Path $zipPath)) {
        $result.checks += @{check="artifact_zip_exists"; status="FAIL"; detail="No artifact.zip at $remoteDir"}
        $result.final_status = "REMOTE_ARTIFACT_NOT_PROVIDED"
        return $result
    }
    $result.checks += @{check="artifact_zip_exists"; status="PASS"; detail=$zipPath}

    # Check 2: Hash the zip
    $hash = Get-ArtifactHash -Path $zipPath
    $result.checks += @{check="artifact_hash"; status="PASS"; detail=$hash}

    # Check 3: Unzip to inspect
    $extractDir = "$remoteDir/extracted"
    if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
    try {
        Expand-Archive -Path $zipPath -DestinationPath $extractDir -Force
        $result.checks += @{check="artifact_extraction"; status="PASS"}
    } catch {
        $result.checks += @{check="artifact_extraction"; status="FAIL"; detail="Cannot extract ZIP"}
        $result.final_status = "REMOTE_ARTIFACT_INVALID"
        return $result
    }

    # Check 4: Key files present
    $hasCiReceipt = (Get-ChildItem $extractDir -Recurse -Filter "ci-receipt.json" -ErrorAction SilentlyContinue).Count -gt 0
    $hasStdout = (Get-ChildItem $extractDir -Recurse -Filter "stdout.log" -ErrorAction SilentlyContinue).Count -gt 0
    $hasSnapshot = (Get-ChildItem $extractDir -Recurse -Filter "*SNAPSHOT*" -ErrorAction SilentlyContinue).Count -gt 0
    $result.checks += @{check="ci_receipt_present"; status=if($hasCiReceipt){"PASS"}else{"FAIL"}}
    $result.checks += @{check="stdout_stderr_present"; status=if($hasStdout){"PASS"}else{"PARTIAL"}}
    $result.checks += @{check="snapshot_evidence_present"; status=if($hasSnapshot){"PASS"}else{"PARTIAL"}}

    # Check 5: Secret scan extracted content
    $secretFound = $false
    Get-ChildItem $extractDir -Recurse -File | ForEach-Object {
        $c = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        if ($c -match '(sk-[a-zA-Z0-9]{20,})|(AIza[0-9A-Za-z\-_]{35})|(ghp_[a-zA-Z0-9]{36})|(AKIA[0-9A-Z]{16})') { $secretFound = $true }
    }
    $result.checks += @{check="secret_scan"; status=if(-not $secretFound){"PASS"}else{"FAIL"}}

    # Check 6: Run ID not placeholder
    if ($RunId -match "^PLACEHOLDER|^TEMPLATE|^FAKE") {
        $result.checks += @{check="run_id_not_placeholder"; status="FAIL"; detail="Run ID appears to be a placeholder"}
    } else {
        $result.checks += @{check="run_id_not_placeholder"; status="PASS"}
    }

    $failed = ($result.checks | Where-Object { $_.status -eq "FAIL" }).Count
    if ($failed -gt 0) { $result.final_status = "REMOTE_ARTIFACT_INVALID" }
    else { $result.final_status = "REMOTE_ARTIFACT_VERIFIED" }

    return $result
}

switch ($Action) {
    "verify" {
        $r = Invoke-VerifyRemoteArtifact
        $r | ConvertTo-Json -Depth 4 | Out-File -Encoding utf8 "$RepoRoot/outputs/V3_3/V3_3_REMOTE_ARTIFACT_VERIFICATION_RESULT.json" -NoNewline
        if ($Json) { $r | ConvertTo-Json -Depth 4 }
        else { Write-Output "Remote Artifact: $($r.final_status)" }
    }
    "check" {
        if (Test-RemoteArtifactExists) { Write-Output "ARTIFACT_PRESENT: $remoteDir/artifact.zip" }
        else { Write-Output "ARTIFACT_NOT_PROVIDED: $remoteDir/" }
    }
    default { Write-Output "Usage: -Action [verify|check] -RunId <id>" }
}