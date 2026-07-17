# Tool Availability Detector v1.0.0
# Part of: FACTORY-R3.0
# Detects which external tools are installed on the host machine.
# Does NOT install tools. Does NOT download. Missing tools ¡ú SKIPPED_WITH_REASON.

function Invoke-ToolAvailabilityCheck {
    param(
        [string[]]$EngineIds = @(),
        [switch]$ExportJson,
        [string]$OutputPath = "outputs\R3_0_TOOL_AVAILABILITY_REPORT.json"
    )

    $engines = if ($EngineIds.Count -gt 0) {
        @($EngineIds | ForEach-Object { Get-EngineById -EngineId $_ })
    } else {
        @(Get-EngineRegistry)
    }

    $results = @()

    foreach ($engine in $engines) {
        $exe = $engine.required_executable
        $result = @{
            engine_id = $engine.engine_id
            available = $false
            executable_path = ""
            version = ""
            skip_reason = ""
            install_hint = if ($engine.install_hint_windows) { $engine.install_hint_windows } else { $engine.install_hint }
            category = $engine.category
            checked_at = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
        }

        # Handle npx-based tools (playwright, autocannon, firecrawl)
        if ($exe -eq "npx") {
            try {
                $npxCheck = Get-Command npx -ErrorAction Stop
                $result.executable_path = $npxCheck.Source
                # Check if the specific package is available
                $pkgName = switch ($engine.engine_id) {
                    "playwright" { "@playwright/test" }
                    "autocannon" { "autocannon" }
                    "firecrawl_reader" { "@anthropic-ai/firecrawl" }
                    default { "" }
                }
                if ($pkgName) {
                    try {
                        $pkgCheck = npm list -g $pkgName --depth=0 2>$null
                        if ($LASTEXITCODE -eq 0) {
                            $result.available = $true
                            $verCheck = npm list -g $pkgName --depth=0 --json 2>$null | ConvertFrom-Json
                            $result.version = "npm-global"
                        } else {
                            # Check local
                            $pkgCheckLocal = npm list $pkgName --depth=0 2>$null
                            if ($LASTEXITCODE -eq 0) {
                                $result.available = $true
                                $result.version = "npm-local"
                            } else {
                                $result.skip_reason = "Package $pkgName not installed (npx available)"
                            }
                        }
                    } catch {
                        $result.skip_reason = "Package $pkgName not verified"
                    }
                } else {
                    $result.available = $true
                    $result.version = "npx-available"
                }
            } catch {
                $result.skip_reason = "npx not found in PATH"
            }
        }
        # Handle npx-based tools that use 'npx' as executable but check specific package
        if ($exe -eq "npx") {
            # playwright, autocannon, firecrawl_reader
            try {
                $npxCheck = Get-Command npx -ErrorAction Stop
                $result.executable_path = $npxCheck.Source
                $pkgName = switch ($engine.engine_id) {
                    "playwright" { "@playwright/test" }
                    "autocannon" { "autocannon" }
                    "firecrawl_reader" { "@anthropic-ai/firecrawl" }
                    default { "" }
                }
                # Try running the package to check availability
                if ($engine.engine_id -eq "autocannon") {
                    $testOutput = & npx --yes autocannon --version 2>&1 | Select-Object -First 1
                    if ($LASTEXITCODE -eq 0 -or $testOutput -match 'autocannon v') {
                        $result.available = $true
                        $testStr = "$testOutput"
                        if ($testStr -match 'autocannon v(\S+)') { $result.version = $Matches[1] }
                    } else {
                        $result.skip_reason = "autocannon not available via npx"
                    }
                } elseif ($engine.engine_id -eq "playwright") {
                    $testOutput = & npx playwright --version 2>&1 | Select-Object -First 1
                    if ($LASTEXITCODE -eq 0 -or $testOutput -match 'Version') {
                        $result.available = $true
                        $testStr = "$testOutput"
                        if ($testStr -match 'Version (\S+)') { $result.version = $Matches[1] }
                    } else {
                        $result.skip_reason = "playwright not available via npx"
                    }
                }
            } catch {
                $result.skip_reason = "npx not found in PATH"
            }
        }
        # Handle standard executables (semgrep, codeql, k6)
        else {
            try {
                $cmd = Get-Command $exe -ErrorAction Stop
                $result.executable_path = $cmd.Source
                try {
                    $verOutput = & $exe --version 2>&1 | Select-Object -First 1
                    $result.version = $verOutput.ToString().Trim()
                } catch {
                    $result.version = "unknown"
                }
                $result.available = $true
            } catch {
                # Try common install paths
                $commonPaths = @(
                    "$env:LOCALAPPDATA\Programs\semgrep\semgrep.exe",
                    "$env:ProgramFiles\CodeQL\codeql\codeql.exe",
                    "$env:USERPROFILE\.cargo\bin\semgrep.exe"
                )
                $found = $false
                foreach ($p in $commonPaths) {
                    if ($p -match $exe -and (Test-Path $p)) {
                        $result.executable_path = $p
                        $result.available = $true
                        $result.version = "found-at-path"
                        $found = $true
                        break
                    }
                }
                if (-not $found) {
                    $result.skip_reason = "$exe not found in PATH or common install locations"
                }
            }
        }

        $results += [PSCustomObject]$result
    }

    if ($ExportJson) {
        $outDir = Split-Path $OutputPath -Parent
        if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
        $results | ConvertTo-Json -Depth 3 | Set-Content -Path $OutputPath -Encoding UTF8
    }

    return $results
}

function Format-ToolAvailabilityReport {
    param([Parameter(Mandatory=$true)]$Results)

    Write-Host "`n===== TOOL AVAILABILITY REPORT =====" -F Cyan
    $available = ($Results | Where-Object { $_.available }).Count
    $missing = ($Results | Where-Object { -not $_.available }).Count
    Write-Host "Available: $available / $($Results.Count) | Missing: $missing" -F $(if ($missing -eq 0){"Green"}else{"Yellow"})

    foreach ($r in $Results) {
        $icon = if ($r.available) { "[AVAIL]" } else { "[MISS]" }
        $color = if ($r.available) { "Green" } else { "Yellow" }
        Write-Host "  $icon $($r.engine_id): $($r.version)" -F $color
        if (-not $r.available) {
            Write-Host "    SKIP: $($r.skip_reason)" -F DarkGray
            Write-Host "    HINT: $($r.install_hint)" -F DarkGray
        } else {
            Write-Host "    PATH: $($r.executable_path)" -F DarkGray
        }
    }
}

# Functions exported via dot-source