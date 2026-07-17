# Secret Presence Check
# Part of: FACTORY-R2.3-N
# Checks for API key in environment variables without exposing the key value.
# Policy: keys ONLY from env vars, NEVER from files.

function Test-SecretPresence {
    param(
        [Parameter(Mandatory=$true)][string[]]$EnvVarNames,
        [string]$ProviderType = "generic_external_api"
    )
    $found = $false
    $foundVar = $null
    $keyLength = 0
    foreach ($name in $EnvVarNames) {
        $val = [Environment]::GetEnvironmentVariable($name, "Process")
        if ($val -and $val.Length -gt 0) {
            $found = $true
            $foundVar = $name
            $keyLength = $val.Length
            break
        }
    }
    $result = [PSCustomObject]@{
        checkId = "SECRET-CHK-$(Get-Date -Format 'yyyyMMddHHmmss')"
        providerType = $ProviderType
        secretPresent = $found
        envVarFound = if ($found) { $foundVar } else { $null }
        keyLength = if ($found) { $keyLength } else { 0 }
        keyValueRecorded = $false
        checkedAt = Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz"
    }
    return $result
}

function Assert-NoSecretLeak {
    param([string]$Content, [string]$SourceDescription = "unknown")
    $patterns = @(
        '(?i)api[_-]?key\s*[=:]\s*["'']?[a-zA-Z0-9_\-\.]{20,}["'']?',
        '(?i)secret\s*[=:]\s*["'']?[a-zA-Z0-9_\-]{16,}["'']?',
        '(?i)token\s*[=:]\s*["'']?[a-zA-Z0-9_\-\.]{20,}["'']?',
        '(?i)zhipuai[_]?api[_]?key\s*[=:]\s*["'']?[a-zA-Z0-9_\-\.]{10,}["'']?',
        '(?i)glm[_]?api[_]?key\s*[=:]\s*["'']?[a-zA-Z0-9_\-\.]{10,}["'']?'
    )
    $hits = @()
    foreach ($pat in $patterns) {
        $matches = [regex]::Matches($Content, $pat)
        foreach ($m in $matches) {
            $lineNum = ($Content.Substring(0, $m.Index).Split("`n")).Count
            $hits += "Line $lineNum : potential secret pattern in $SourceDescription"
        }
    }
    $clean = $hits.Count -eq 0
    return [PSCustomObject]@{ clean = $clean; hitCount = $hits.Count; hits = $hits; source = $SourceDescription }
}

function New-AllowedSecretExample {
    return "SECRET='<EXAMPLE_JWT_SECRET_PLACEHOLDER>'"
}

Write-Verbose "Secret Presence Check loaded."
