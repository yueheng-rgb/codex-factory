# Codex Factory V4 compatibility Doctor
# Usage: powershell -File runtime/codex-factory-doctor.ps1 [-Json]
#
# This Doctor reports legacy compatibility checks. The V5 control-plane Doctor is
# authoritative for new projects:
#   factoryctl doctor --project <project-path> --json

[CmdletBinding()]
param([switch]$Json)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Continue"

$results = [ordered]@{
    check_time = (Get-Date -Format "o")
    doctor_mode = "V4_LEGACY_COMPATIBILITY"
    authoritative_doctor = "factoryctl doctor --project <project-path> --json"
    checks = [System.Collections.ArrayList]@()
    overall = "PENDING"
}

function Add-Check {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][ValidateSet("PASS", "WARN", "FAIL")][string]$Status,
        [Parameter(Mandatory = $true)][string]$Detail
    )
    [void]$results.checks.Add([ordered]@{ name = $Name; status = $Status; detail = $Detail })
}

function Test-GitIgnored {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $false }
    & git check-ignore --no-index --quiet -- $Path 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Test-LikelySecretValue {
    param([AllowNull()][object]$Value)

    if ($null -eq $Value -or $Value -isnot [string]) { return $false }
    $text = [string]$Value
    if (-not $text) { return $false }
    if ($text -match '(?i)placeholder|example|replace|your[-_]?key|change[-_]?me|dummy|sample') { return $false }
    return ($text.Length -ge 12)
}

function Test-ConfigObjectContainsSecret {
    param([AllowNull()][object]$Object)

    if ($null -eq $Object) { return $false }
    if ($Object -is [string] -or $Object -is [ValueType]) { return $false }

    if ($Object -is [System.Collections.IDictionary]) {
        foreach ($key in $Object.Keys) {
            $name = [string]$key
            $value = $Object[$key]
            if ($name -match '(?i)(api[_-]?key|secret|token|password)$' -and $name -notmatch '(?i)_env$') {
                if (Test-LikelySecretValue -Value $value) { return $true }
            }
            if (Test-ConfigObjectContainsSecret -Object $value) { return $true }
        }
        return $false
    }

    if ($Object -is [System.Collections.IEnumerable]) {
        foreach ($item in $Object) {
            if (Test-ConfigObjectContainsSecret -Object $item) { return $true }
        }
        return $false
    }

    foreach ($property in $Object.PSObject.Properties) {
        $name = [string]$property.Name
        $value = $property.Value
        if ($name -match '(?i)(api[_-]?key|secret|token|password)$' -and $name -notmatch '(?i)_env$') {
            if (Test-LikelySecretValue -Value $value) { return $true }
        }
        if (Test-ConfigObjectContainsSecret -Object $value) { return $true }
    }
    return $false
}

function Get-JsonProperty {
    param(
        [AllowNull()][object]$Object,
        [Parameter(Mandatory = $true)][string]$Property,
        [AllowNull()][object]$Default = $null
    )

    if ($null -eq $Object) { return $Default }
    if ($Object.PSObject.Properties.Name -contains $Property) { return $Object.$Property }
    return $Default
}

# Platform
$platformId = [System.Environment]::OSVersion.Platform
$isWindows = ($env:OS -match "Windows") -or ($platformId -eq [System.PlatformID]::Win32NT)
if ($isWindows) {
    $platform = "Windows"
} elseif (Get-Command uname -ErrorAction SilentlyContinue) {
    $uname = (& uname -s 2>$null)
    $platform = if ($uname -match "Darwin") { "macOS" } elseif ($uname -match "Linux") { "Linux" } else { [string]$uname }
} else {
    $platform = [string]$platformId
}
Add-Check -Name "platform" -Status "PASS" -Detail $platform

# PowerShell 7 is preferred, but Windows PowerShell remains a supported legacy path.
if (Get-Command pwsh -ErrorAction SilentlyContinue) {
    $pwshVersion = (& pwsh --version 2>$null | Select-Object -First 1)
    Add-Check -Name "pwsh" -Status "PASS" -Detail ([string]$pwshVersion)
} elseif ($isWindows) {
    Add-Check -Name "pwsh" -Status "WARN" -Detail "PowerShell 7 is not installed; this legacy script can run in Windows PowerShell, but cross-platform commands require pwsh."
} else {
    Add-Check -Name "pwsh" -Status "FAIL" -Detail "PowerShell 7 (pwsh) is required on this platform."
}

# Required tools
if (Get-Command git -ErrorAction SilentlyContinue) {
    $gitVersion = (& git --version 2>$null | Select-Object -First 1)
    Add-Check -Name "git" -Status "PASS" -Detail ([string]$gitVersion)
} else {
    Add-Check -Name "git" -Status "FAIL" -Detail "Git was not found."
}

$nodeMajor = 0
if (Get-Command node -ErrorAction SilentlyContinue) {
    $nodeVersion = [string](& node --version 2>$null | Select-Object -First 1)
    if ($nodeVersion -match '^v?(\d+)') { $nodeMajor = [int]$Matches[1] }
    Add-Check -Name "node" -Status "PASS" -Detail $nodeVersion
} else {
    Add-Check -Name "node" -Status "FAIL" -Detail "Node.js was not found."
}

if (Get-Command npm -ErrorAction SilentlyContinue) {
    $npmVersion = [string](& npm --version 2>$null | Select-Object -First 1)
    Add-Check -Name "npm" -Status "PASS" -Detail $npmVersion
} else {
    Add-Check -Name "npm" -Status "FAIL" -Detail "npm was not found."
}

Add-Check -Name "powershell" -Status "PASS" -Detail ("PowerShell " + $PSVersionTable.PSVersion.ToString())

# V5 availability and runtime boundary
$v5Package = Join-Path (Get-Location).ProviderPath "packages/factory-cli/package.json"
$v5Cli = Join-Path (Get-Location).ProviderPath "packages/factory-cli/dist/cli.js"
if (Test-Path -LiteralPath $v5Package -PathType Leaf) {
    if ($nodeMajor -lt 24) {
        Add-Check -Name "v5_control_plane" -Status "WARN" -Detail "V5 source is present, but Node.js 24+ is required. Install Node.js 24+, build factory-cli, then run the authoritative V5 Doctor."
    } elseif (Test-Path -LiteralPath $v5Cli -PathType Leaf) {
        Add-Check -Name "v5_control_plane" -Status "PASS" -Detail "V5 CLI is built. Run: factoryctl doctor --project <project-path> --json"
    } else {
        Add-Check -Name "v5_control_plane" -Status "WARN" -Detail "V5 source is present but not built. Run npm install and npm run build in packages/factory-cli."
    }
} else {
    Add-Check -Name "v5_control_plane" -Status "WARN" -Detail "V5 CLI was not found in this checkout; legacy checks do not certify the V5 control plane."
}
Add-Check -Name "legacy_provider_boundary" -Status "WARN" -Detail "V4 provider selection is configuration metadata, not proof of model/search connectivity. Confirm with the V5 Doctor and a real smoke task."

# Local configuration. Parse it once; never print its content.
$config = $null
$configRaw = $null
$configValid = $false
$configPath = Join-Path (Get-Location).ProviderPath "factory.config.json"
if (Test-Path -LiteralPath $configPath -PathType Leaf) {
    try {
        $configRaw = Get-Content -LiteralPath $configPath -Raw
        $config = $configRaw | ConvertFrom-Json
        $configValid = $true
        Add-Check -Name "factory_config" -Status "PASS" -Detail "factory.config.json exists and parses as JSON."
    } catch {
        Add-Check -Name "factory_config" -Status "FAIL" -Detail "factory.config.json is malformed. Its content was not printed."
    }
} else {
    Add-Check -Name "factory_config" -Status "WARN" -Detail "factory.config.json was not found. New projects should use factoryctl init; V4 users can run runtime/codex-factory-init.ps1."
}

# Git ignore rules are security controls, not cosmetic warnings.
if (Test-Path -LiteralPath ".gitignore" -PathType Leaf) {
    if (Test-GitIgnored -Path ".env") {
        Add-Check -Name "env_gitignored" -Status "PASS" -Detail ".env is ignored."
    } else {
        Add-Check -Name "env_gitignored" -Status "FAIL" -Detail ".env is not ignored; refusing READY because local credentials could be committed."
    }

    if (Test-GitIgnored -Path ".codex-factory/secrets.env") {
        Add-Check -Name "v5_secrets_gitignored" -Status "PASS" -Detail ".codex-factory/secrets.env is ignored."
    } else {
        Add-Check -Name "v5_secrets_gitignored" -Status "FAIL" -Detail ".codex-factory/secrets.env is not ignored."
    }

    if (Test-GitIgnored -Path "factory.config.json") {
        Add-Check -Name "local_config_gitignored" -Status "PASS" -Detail "factory.config.json is ignored as local configuration."
    } else {
        Add-Check -Name "local_config_gitignored" -Status "WARN" -Detail "factory.config.json is not ignored; keep it secret-free and review before commit."
    }
} else {
    Add-Check -Name "env_gitignored" -Status "FAIL" -Detail "No .gitignore was found; local credentials are not protected from accidental commit."
    Add-Check -Name "v5_secrets_gitignored" -Status "FAIL" -Detail "No .gitignore was found for .codex-factory/secrets.env."
    Add-Check -Name "local_config_gitignored" -Status "WARN" -Detail "No .gitignore was found for local factory configuration."
}

# .env is optional unless an enabled legacy provider needs a key. Do not load,
# parse, hash, prefix, or print secret values here.
$envFileExists = Test-Path -LiteralPath ".env" -PathType Leaf
$requiredSearchEnv = $null
$searchEnabled = $false
if ($configValid) {
    $providers = Get-JsonProperty -Object $config -Property "providers"
    $search = Get-JsonProperty -Object $providers -Property "search"
    $searchType = [string](Get-JsonProperty -Object $search -Property "type" -Default "none")
    if ($searchType -and $searchType -ne "none" -and $searchType -ne "mcp_search") {
        $searchEnabled = $true
        $requiredSearchEnv = [string](Get-JsonProperty -Object $search -Property "api_key_env" -Default "")
    }
}

if ($searchEnabled) {
    $presentInProcess = $false
    if ($requiredSearchEnv -match '^[A-Z][A-Z0-9_]{2,63}$') {
        $presentInProcess = -not [string]::IsNullOrWhiteSpace([Environment]::GetEnvironmentVariable($requiredSearchEnv, "Process"))
    }
    if ($presentInProcess) {
        Add-Check -Name "search_secret_presence" -Status "PASS" -Detail "The configured search credential is present in the process environment; its value was not inspected or recorded."
    } elseif ($envFileExists) {
        Add-Check -Name "search_secret_presence" -Status "WARN" -Detail "An external search provider is enabled and .env exists, but the legacy Doctor does not load or inspect secret files. Verify with the provider smoke test or V5 Doctor."
    } else {
        Add-Check -Name "search_secret_presence" -Status "FAIL" -Detail "An external search provider is enabled, but no process credential or local .env file is present."
    }
} elseif ($envFileExists) {
    Add-Check -Name "env_exists" -Status "PASS" -Detail ".env exists locally; its content was not read."
} else {
    Add-Check -Name "env_exists" -Status "PASS" -Detail "No .env file exists, and no enabled legacy search provider currently requires it."
}

if ($configValid) {
    $rawHighConfidenceSecret = (
        $configRaw -match '\bAKIA[0-9A-Z]{16}\b' -or
        $configRaw -match '(?i)\b(?:sk|rk|pk)-(?:live-|test-)?[a-z0-9_-]{20,}\b' -or
        $configRaw -match '-----BEGIN (?:RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'
    )
    if ($rawHighConfidenceSecret -or (Test-ConfigObjectContainsSecret -Object $config)) {
        Add-Check -Name "no_secrets_in_config" -Status "FAIL" -Detail "Potential credential material exists in factory.config.json. Move it to an ignored local secret store; no value was printed."
    } else {
        Add-Check -Name "no_secrets_in_config" -Status "PASS" -Detail "No high-confidence embedded credential pattern was detected in factory.config.json."
    }
} elseif (-not (Test-Path -LiteralPath $configPath -PathType Leaf)) {
    Add-Check -Name "no_secrets_in_config" -Status "PASS" -Detail "No local config file exists to scan."
}

# CI and legacy verifier checks
if (Test-Path -LiteralPath ".github/workflows/codex-factory-ci.yml" -PathType Leaf) {
    Add-Check -Name "github_actions_workflow" -Status "PASS" -Detail "Legacy CI workflow is present."
} else {
    Add-Check -Name "github_actions_workflow" -Status "WARN" -Detail "Legacy CI workflow was not found."
}

if (Test-Path -LiteralPath "runtime/snapshot-verifier.ps1" -PathType Leaf) {
    Add-Check -Name "snapshot_verifier" -Status "PASS" -Detail "Legacy snapshot verifier is present."
} else {
    Add-Check -Name "snapshot_verifier" -Status "FAIL" -Detail "Legacy snapshot verifier was not found."
}

$knowledgeManager = Join-Path (Get-Location).ProviderPath "runtime/knowledge-pack-manager.ps1"
if (Test-Path -LiteralPath $knowledgeManager -PathType Leaf) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($knowledgeManager, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count -eq 0) {
        Add-Check -Name "legacy_knowledge_manager" -Status "PASS" -Detail "Legacy Knowledge Manager parses successfully and runs in safe compatibility mode."
    } else {
        Add-Check -Name "legacy_knowledge_manager" -Status "FAIL" -Detail "Legacy Knowledge Manager has PowerShell parse errors."
    }
} else {
    Add-Check -Name "legacy_knowledge_manager" -Status "FAIL" -Detail "Legacy Knowledge Manager was not found."
}

$pass = @($results.checks | Where-Object { $_.status -eq "PASS" }).Count
$fail = @($results.checks | Where-Object { $_.status -eq "FAIL" }).Count
$warn = @($results.checks | Where-Object { $_.status -eq "WARN" }).Count
$results.overall = if ($fail -gt 0) {
    "NOT_READY"
} elseif ($warn -gt 0) {
    "READY_WITH_WARNINGS"
} else {
    "READY"
}
$results.summary = [ordered]@{ pass = $pass; fail = $fail; warn = $warn }

if ($Json) {
    ConvertTo-Json -InputObject $results -Depth 6
} else {
    Write-Output "=== Codex Factory Doctor (V4 legacy compatibility) ==="
    Write-Output ""
    foreach ($check in $results.checks) {
        $icon = switch ($check.status) {
            "PASS" { "[OK]" }
            "FAIL" { "[FAIL]" }
            "WARN" { "[WARN]" }
        }
        Write-Output "$icon $($check.name): $($check.detail)"
    }
    Write-Output ""
    Write-Output "Overall: $($results.overall) | Pass=$pass Fail=$fail Warn=$warn"
    Write-Output "Authoritative V5 check: $($results.authoritative_doctor)"
}

if ($results.overall -eq "NOT_READY") { exit 1 }
exit 0
