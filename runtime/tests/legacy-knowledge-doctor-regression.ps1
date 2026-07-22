# Regression tests for the V4-safe Knowledge Manager and compatibility Doctor.
# Fixtures are synthetic and created only under a validated temporary directory.

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-True {
    param([Parameter(Mandatory = $true)][bool]$Condition, [Parameter(Mandatory = $true)][string]$Message)
    if (-not $Condition) { throw "ASSERTION FAILED: $Message" }
}

function Invoke-JsonScript {
    param(
        [Parameter(Mandatory = $true)][string]$HostPath,
        [Parameter(Mandatory = $true)][string]$ScriptPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $output = @(& $HostPath -NoProfile -ExecutionPolicy Bypass -File $ScriptPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $text = ($output | Out-String).Trim()
    try {
        $value = $text | ConvertFrom-Json
    } catch {
        throw "Child script did not return JSON. Exit=$exitCode Output=$text"
    }
    return [pscustomobject]@{ ExitCode = $exitCode; Text = $text; Value = $value }
}

$repositoryRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "../.."))
$managerSource = Join-Path $repositoryRoot "runtime/knowledge-pack-manager.ps1"
$doctorSource = Join-Path $repositoryRoot "runtime/codex-factory-doctor.ps1"
$hostPath = (Get-Process -Id $PID).Path
$tempParent = [System.IO.Path]::GetFullPath((Join-Path ([System.IO.Path]::GetTempPath()) "codex-factory-legacy-regression"))
$testRoot = [System.IO.Path]::GetFullPath((Join-Path $tempParent ([guid]::NewGuid().ToString("N"))))
$projectRoot = Join-Path $testRoot "project"
$outsideRoot = Join-Path $testRoot "outside"
$encoding = New-Object System.Text.UTF8Encoding -ArgumentList $false

New-Item -ItemType Directory -Path (Join-Path $projectRoot "runtime") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $projectRoot ".github/workflows") -Force | Out-Null
New-Item -ItemType Directory -Path (Join-Path $projectRoot "docs") -Force | Out-Null
New-Item -ItemType Directory -Path $outsideRoot -Force | Out-Null
Copy-Item -LiteralPath $managerSource -Destination (Join-Path $projectRoot "runtime/knowledge-pack-manager.ps1")
Copy-Item -LiteralPath $doctorSource -Destination (Join-Path $projectRoot "runtime/codex-factory-doctor.ps1")
[System.IO.File]::WriteAllText((Join-Path $projectRoot "runtime/snapshot-verifier.ps1"), "# synthetic test fixture", $encoding)
[System.IO.File]::WriteAllText((Join-Path $projectRoot ".github/workflows/codex-factory-ci.yml"), "name: synthetic", $encoding)
$ignoreRules = @"
.env
.env.*
!.env.example
factory.config.json
.codex-factory/secrets.env
knowledge/packs/
knowledge/evidence/
knowledge/.staging/
knowledge/index.json
knowledge/keyword-index.json
"@
[System.IO.File]::WriteAllText((Join-Path $projectRoot ".gitignore"), $ignoreRules.TrimStart(), $encoding)
[System.IO.File]::WriteAllText((Join-Path $projectRoot "docs/architecture.md"), "Authorization is enforced on the server.`n事务边界必须可回滚。`n", $encoding)
[System.IO.File]::WriteAllText((Join-Path $projectRoot "docs/openapi.yaml"), "openapi: 3.0.0`ninfo:`n  title: Fixture`n  version: 1.0.0`n", $encoding)
[System.IO.File]::WriteAllText((Join-Path $outsideRoot "outside.md"), "outside project", $encoding)

Push-Location $projectRoot
try {
    & git init --quiet 2>$null
    Assert-True -Condition ($LASTEXITCODE -eq 0) -Message "temporary git repository should initialize"
    $manager = Join-Path $projectRoot "runtime/knowledge-pack-manager.ps1"
    $doctor = Join-Path $projectRoot "runtime/codex-factory-doctor.ps1"

    # Legacy -Command spelling remains supported.
    $add = Invoke-JsonScript -HostPath $hostPath -ScriptPath $manager -Arguments @("-Command", "add", "-Name", "fixture", "-Source", "docs", "-Json")
    Assert-True -Condition ($add.ExitCode -eq 0 -and $add.Value.status -eq "OK") -Message "add should succeed (exit=$($add.ExitCode), status=$($add.Value.status), detail=$($add.Value.detail))"
    Assert-True -Condition ($add.Value.file_count -eq 2) -Message "add should import two supported files"

    $manifestPath = Join-Path $projectRoot "knowledge/packs/fixture/source-map.json"
    $manifestText = Get-Content -LiteralPath $manifestPath -Raw
    $parsedManifest = $manifestText | ConvertFrom-Json
    $manifest = @()
    foreach ($manifestEntry in $parsedManifest) { $manifest += $manifestEntry }
    Assert-True -Condition ($manifest.Count -eq 2) -Message "manifest should list two files (count=$($manifest.Count), json=$manifestText)"
    Assert-True -Condition (-not $manifestText.Contains($projectRoot)) -Message "manifest must not contain an absolute project path"
    foreach ($entry in $manifest) {
        Assert-True -Condition (-not [System.IO.Path]::IsPathRooted([string]$entry.source)) -Message "manifest source must be project-relative"
        $filePath = Join-Path $projectRoot ("knowledge/packs/fixture/" + ([string]$entry.path))
        $actualHash = (Get-FileHash -LiteralPath $filePath -Algorithm SHA256).Hash
        Assert-True -Condition ($actualHash.Equals([string]$entry.sha256, [System.StringComparison]::OrdinalIgnoreCase)) -Message "manifest hash must match physical file"
    }

    $validate = Invoke-JsonScript -HostPath $hostPath -ScriptPath $manager -Arguments @("-Action", "validate", "-Name", "fixture", "-Json")
    Assert-True -Condition ($validate.ExitCode -eq 0 -and $validate.Value.status -eq "VALID") -Message "fresh pack should validate"
    Assert-True -Condition ([bool]$validate.Value.details[0].manifestHashMatches) -Message "manifest anchor should validate"

    $index = Invoke-JsonScript -HostPath $hostPath -ScriptPath $manager -Arguments @("-Action", "index", "-Json")
    Assert-True -Condition ($index.ExitCode -eq 0 -and $index.Value.status -eq "OK") -Message "index should accept verified packs"

    $evidence = Invoke-JsonScript -HostPath $hostPath -ScriptPath $manager -Arguments @("-Action", "build-evidence", "-Name", "fixture", "-Json")
    Assert-True -Condition ($evidence.ExitCode -eq 0 -and $evidence.Value.status -eq "OK") -Message "evidence export should succeed"
    $evidencePath = Join-Path $projectRoot "knowledge/evidence/evidence-pack.json"
    $evidenceValue = Get-Content -LiteralPath $evidencePath -Raw | ConvertFrom-Json
    Assert-True -Condition (-not [bool]$evidenceValue.usable_as_verified_search_evidence) -Message "legacy knowledge export must not masquerade as verified search evidence"
    Assert-True -Condition (-not ((Get-Content -LiteralPath $evidencePath -Raw).Contains($projectRoot))) -Message "evidence must not contain absolute project paths"

    # Physical tampering must fail both validation and evidence export.
    $tamperTarget = Join-Path $projectRoot "knowledge/packs/fixture/architecture.md"
    [System.IO.File]::AppendAllText($tamperTarget, "tampered", $encoding)
    $tampered = Invoke-JsonScript -HostPath $hostPath -ScriptPath $manager -Arguments @("-Action", "validate", "-Name", "fixture", "-Json")
    Assert-True -Condition ($tampered.ExitCode -eq 2 -and $tampered.Value.status -eq "DRIFT_DETECTED") -Message "file tampering should be detected"
    Assert-True -Condition ($tampered.Value.details[0].hashMismatches.Count -gt 0) -Message "tamper result should identify a hash mismatch"
    $blockedEvidence = Invoke-JsonScript -HostPath $hostPath -ScriptPath $manager -Arguments @("-Action", "build-evidence", "-Name", "fixture", "-Json")
    Assert-True -Condition ($blockedEvidence.ExitCode -eq 2 -and $blockedEvidence.Value.status -eq "DRIFT_DETECTED") -Message "evidence export should fail closed on drift"

    $remove = Invoke-JsonScript -HostPath $hostPath -ScriptPath $manager -Arguments @("-Action", "remove", "-Name", "fixture", "-Json")
    Assert-True -Condition ($remove.ExitCode -eq 0 -and $remove.Value.status -eq "OK") -Message "explicit pack removal should succeed (exit=$($remove.ExitCode), status=$($remove.Value.status), detail=$($remove.Value.detail))"

    # Traversal, out-of-project sources, and secret-like material are rejected.
    $traversal = Invoke-JsonScript -HostPath $hostPath -ScriptPath $manager -Arguments @("-Action", "add", "-Name", "../escape", "-Source", "docs", "-Json")
    Assert-True -Condition ($traversal.ExitCode -eq 1 -and $traversal.Value.status -eq "ERROR") -Message "pack-name traversal should be rejected"
    Assert-True -Condition (-not (Test-Path -LiteralPath (Join-Path $projectRoot "knowledge/escape"))) -Message "traversal must not create an escape directory"

    $outside = Invoke-JsonScript -HostPath $hostPath -ScriptPath $manager -Arguments @("-Action", "add", "-Name", "outside", "-Source", (Join-Path $outsideRoot "outside.md"), "-Json")
    Assert-True -Condition ($outside.ExitCode -eq 1 -and $outside.Value.status -eq "ERROR") -Message "outside source should be rejected"

    $secretSource = Join-Path $projectRoot "secret-fixture"
    New-Item -ItemType Directory -Path $secretSource | Out-Null
    $syntheticSecret = "sk-live-" + ("A" * 28)
    [System.IO.File]::WriteAllText((Join-Path $secretSource "token.txt"), "api_key=$syntheticSecret", $encoding)
    $secret = Invoke-JsonScript -HostPath $hostPath -ScriptPath $manager -Arguments @("-Action", "add", "-Name", "secret-test", "-Source", "secret-fixture", "-Json")
    Assert-True -Condition ($secret.ExitCode -eq 1 -and $secret.Value.status -eq "ERROR") -Message "secret-like source content should be rejected"
    Assert-True -Condition (-not $secret.Text.Contains($syntheticSecret)) -Message "secret-like value must not be echoed"

    # Warnings must not collapse to READY.
    $doctorWarnings = Invoke-JsonScript -HostPath $hostPath -ScriptPath $doctor -Arguments @("-Json")
    Assert-True -Condition ($doctorWarnings.ExitCode -eq 0) -Message "warnings-only Doctor should remain usable"
    Assert-True -Condition ($doctorWarnings.Value.overall -eq "READY_WITH_WARNINGS") -Message "Doctor must preserve warning state"

    # Missing ignore protection is critical and must make the project NOT_READY.
    Remove-Item -LiteralPath (Join-Path $projectRoot ".gitignore") -Force
    $doctorUnsafeIgnore = Invoke-JsonScript -HostPath $hostPath -ScriptPath $doctor -Arguments @("-Json")
    Assert-True -Condition ($doctorUnsafeIgnore.ExitCode -eq 1 -and $doctorUnsafeIgnore.Value.overall -eq "NOT_READY") -Message "missing ignore protection should be NOT_READY"
    [System.IO.File]::WriteAllText((Join-Path $projectRoot ".gitignore"), $ignoreRules.TrimStart(), $encoding)

    # Embedded credentials are reported without printing the value.
    $embeddedSecret = "sk-live-" + ("B" * 28)
    $unsafeConfig = @{
        version = "4.0.0"
        providers = @{
            llm = @{ type = "openai"; api_key = $embeddedSecret }
            search = @{ type = "none" }
            memory = @{ type = "local_snapshot" }
            ci = @{ type = "none" }
        }
    } | ConvertTo-Json -Depth 6
    [System.IO.File]::WriteAllText((Join-Path $projectRoot "factory.config.json"), $unsafeConfig, $encoding)
    $doctorSecret = Invoke-JsonScript -HostPath $hostPath -ScriptPath $doctor -Arguments @("-Json")
    Assert-True -Condition ($doctorSecret.ExitCode -eq 1 -and $doctorSecret.Value.overall -eq "NOT_READY") -Message "embedded credential should be NOT_READY"
    Assert-True -Condition (-not $doctorSecret.Text.Contains($embeddedSecret)) -Message "Doctor must not echo embedded credential values"

    Write-Output "PASS legacy knowledge/doctor regression: safe import, SHA-256 drift, traversal, secret redaction, and warning states verified."
} finally {
    Pop-Location
    $validatedRoot = [System.IO.Path]::GetFullPath($testRoot)
    $validatedParent = [System.IO.Path]::GetFullPath($tempParent)
    $prefix = $validatedParent.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
    if (-not $validatedRoot.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to clean an unexpected test directory."
    }
    if (Test-Path -LiteralPath $validatedRoot) {
        Remove-Item -LiteralPath $validatedRoot -Recurse -Force
    }
}
