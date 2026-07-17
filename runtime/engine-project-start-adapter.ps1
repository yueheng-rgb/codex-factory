# Engine Project Start Adapter v1.0.0
# Attempts to start a project server for autocannon/k6 testing
# Handles tsx/Node v24 module resolution issues
param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [int]$Port = 3000,
    [string]$StartCommand = "npm start",
    [int]$TimeoutSeconds = 10,
    [string]$HealthEndpoint = "/health"
)

$result = [PSCustomObject]@{
    project_path = $ProjectPath
    port = $Port
    start_command = $StartCommand
    start_status = "NOT_ATTEMPTED"
    health_url = "http://localhost:$Port$HealthEndpoint"
    health_status = "UNKNOWN"
    error_detail = ""
    fallback_available = $false
}

Push-Location $ProjectPath

# Try starting server
try {
    $proc = Start-Process -FilePath "npx" -ArgumentList "tsx","src/server.ts" -PassThru -WindowStyle Hidden -ErrorAction Stop
    $result.start_status = "PROCESS_STARTED"
    $result.pid = $proc.Id
    
    # Wait for startup
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $resp = Invoke-WebRequest -Uri $result.health_url -UseBasicParsing -TimeoutSec 2
            if ($resp.StatusCode -eq 200) {
                $result.health_status = "OK"
                $result.fallback_available = $true
                break
            }
        } catch {}
        Start-Sleep -Milliseconds 500
    }
    
    if ($result.health_status -ne "OK") {
        $result.health_status = "TIMEOUT_OR_FAILED"
        $result.error_detail = "Server process started but health check did not respond within ${TimeoutSeconds}s"
    }
} catch {
    $result.start_status = "START_FAILED"
    $result.error_detail = $_.Exception.Message
    
    # Fallback: check if project has vitest (can test via vitest)
    if (Test-Path "$ProjectPath\node_modules\vitest") {
        $result.fallback_available = $true
        $result.fallback_note = "Project can be tested via vitest; autocannon requires running server"
    }
}

# Classification
if ($result.health_status -eq "OK") {
    $result.classification = "RUNNABLE"
} elseif ($result.start_status -eq "START_FAILED") {
    $result.classification = "START_FAILED"
} elseif ($result.health_status -eq "TIMEOUT_OR_FAILED") {
    $result.classification = "HEALTH_CHECK_FAILED"
} else {
    $result.classification = "MODULE_RESOLUTION_ISSUE"
}

Pop-Location
$result | ConvertTo-Json -Depth 2
