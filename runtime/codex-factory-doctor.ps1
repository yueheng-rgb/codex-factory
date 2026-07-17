# Codex Factory V4.0 — Doctor (Environment Check)
# Usage: powershell -File runtime/codex-factory-doctor.ps1 [-Json]

param([switch]$Json)

$results = @{
    check_time = (Get-Date -Format "o")
    checks = [System.Collections.ArrayList]@()
    overall = "PENDING"
}

function Add-Check($name, $status, $detail) {
    [void]$results.checks.Add(@{name=$name; status=$status; detail=$detail})
}


# 0. Platform
$isWindows = $IsWindows -or ($env:OS -match 'Windows')
$isLinux = $IsLinux -or ($env:OS -notmatch 'Windows' -and (uname 2>$null) -match 'Linux')
$isMac = $IsMacOS -or ((uname 2>$null) -match 'Darwin')
$platform = if ($isWindows) { "Windows" } elseif ($isLinux) { "Linux" } elseif ($isMac) { "macOS" } else { "Unknown" }
Add-Check "platform" "PASS" $platform

# 0b. pwsh availability
try { $pwshV = & pwsh --version 2>$null; if ($pwshV) { Add-Check "pwsh" "PASS" "pwsh $pwshV" } else { Add-Check "pwsh" "WARN" "pwsh not found. Install: winget install Microsoft.PowerShell (Win) / brew install powershell (Mac) / apt install powershell (Linux)" } } catch { Add-Check "pwsh" "WARN" "pwsh not found. GitHub Actions Linux runner uses pwsh." }

# 1. Git
try { $v = & git --version 2>$null; if ($v) { Add-Check "git" "PASS" $v } else { Add-Check "git" "FAIL" "Not found" } } catch { Add-Check "git" "FAIL" "Error: $_" }

# 2. Node
try { $v = & node --version 2>$null; if ($v) { Add-Check "node" "PASS" $v } else { Add-Check "node" "FAIL" "Not found" } } catch { Add-Check "node" "FAIL" "Error: $_" }

# 3. npm
try { $v = & npm --version 2>$null; if ($v) { Add-Check "npm" "PASS" $v } else { Add-Check "npm" "FAIL" "Not found" } } catch { Add-Check "npm" "FAIL" "Error: $_" }

# 4. PowerShell / pwsh
$psv = $PSVersionTable.PSVersion.ToString()
Add-Check "powershell" "PASS" "PowerShell $psv"

# 5. factory.config.json
if (Test-Path factory.config.json) { Add-Check "factory_config" "PASS" "factory.config.json exists" }
else { Add-Check "factory_config" "WARN" "Not found. Run: powershell -File runtime/codex-factory-init.ps1" }

# 6. .env gitignored
if (Test-Path .gitignore) {
    $gi = Get-Content .gitignore -Raw
    if ($gi -match '\.env') { Add-Check "env_gitignored" "PASS" ".env is in .gitignore" }
    else { Add-Check "env_gitignored" "WARN" ".env NOT in .gitignore — add it!" }
} else { Add-Check "env_gitignored" "WARN" "No .gitignore found" }

# 7. .env exists
if (Test-Path .env) { Add-Check "env_exists" "PASS" ".env exists (local only)" }
else { Add-Check "env_exists" "WARN" "No .env. Copy .env.example and fill in your keys." }

# 8. No secrets in config
if (Test-Path factory.config.json) {
    $cfg = Get-Content factory.config.json -Raw
    if ($cfg -match 'sk-[a-zA-Z0-9]{20,}') { Add-Check "no_secrets_in_config" "FAIL" "API key found in factory.config.json! Move to .env!" }
    else { Add-Check "no_secrets_in_config" "PASS" "No API keys in config" }
} else { Add-Check "no_secrets_in_config" "PASS" "No config to check" }

# 9. GitHub Actions workflow
if (Test-Path .github/workflows/codex-factory-ci.yml) { Add-Check "github_actions_workflow" "PASS" "CI workflow present" }
else { Add-Check "github_actions_workflow" "WARN" "CI workflow not found" }

# 10. Snapshot verifier
if (Test-Path runtime/snapshot-verifier.ps1) { Add-Check "snapshot_verifier" "PASS" "Verifier script present" }
else { Add-Check "snapshot_verifier" "FAIL" "Not found" }

# Summary
$pass = ($results.checks | Where-Object { $_.status -eq "PASS" }).Count
$fail = ($results.checks | Where-Object { $_.status -eq "FAIL" }).Count
$warn = ($results.checks | Where-Object { $_.status -eq "WARN" }).Count
$results.overall = if ($fail -eq 0) { "READY" } else { "ISSUES_FOUND" }

if ($Json) {
    $results | ConvertTo-Json -Depth 3
} else {
    Write-Output "=== Codex Factory Doctor ==="
    Write-Output ""
    foreach ($c in $results.checks) {
        $icon = switch($c.status) { "PASS" { "[OK]" } "FAIL" { "[FAIL]" } "WARN" { "[WARN]" } }
        Write-Output "$icon $($c.name): $($c.detail)"
    }
    Write-Output ""
    Write-Output "Overall: $($results.overall) | Pass=$pass Fail=$fail Warn=$warn"
}
