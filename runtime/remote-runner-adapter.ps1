# Codex Factory V3.1 — Remote Runner Adapter
param(
    [Parameter(Mandatory=$true)] [string]$Action,
    [string]$Target = "local"
)

$RepoRoot = (Get-Location).Path

$runners = @(
    @{ runner_id="local"; runner_type="local"; isolation_level="none"; status="AVAILABLE"; description="Direct local execution on host" },
    @{ runner_id="local-isolated-workspace"; runner_type="local-isolated-workspace"; isolation_level="directory"; status="AVAILABLE"; description="Directory-level workspace copy isolation" },
    @{ runner_id="remote-placeholder"; runner_type="remote-placeholder"; isolation_level="container"; status="NOT_IMPLEMENTED"; description="Remote execution placeholder — NO real remote runner connected" },
    @{ runner_id="container-placeholder"; runner_type="container-placeholder"; isolation_level="container"; status="NOT_IMPLEMENTED"; description="Docker/container placeholder — NO container runtime available" }
)

switch ($Action) {
    "list" {
        foreach ($r in $runners) {
            $r | ConvertTo-Json -Compress
        }
    }
    "profile" {
        $r = $runners | Where-Object { $_.runner_id -eq $Target }
        if ($r) {
            $profile = @{
                runner_id = $r.runner_id; runner_type = $r.runner_type
                isolation_level = $r.isolation_level; status = $r.status
                description = $r.description
                limitations = @("Directory-level isolation is NOT VM/container security", "remote-placeholder has NO real remote execution", "container-placeholder has NO Docker/container runtime")
                supported_commands = @("npm test", "npx vitest run", "node", "powershell")
                artifact_capture = ($r.status -eq "AVAILABLE")
                snapshot_aware = $true
                non_claims = @("This is V3.1 RC, NOT production cloud platform", "NO real remote/container execution available", "local-isolated-workspace uses directory copy, NOT kernel isolation")
            }
            $profile | ConvertTo-Json -Depth 3
        } else { Write-Output "UNKNOWN_RUNNER: $Target" }
    }
    "available" {
        $avail = $runners | Where-Object { $_.status -eq "AVAILABLE" }
        Write-Output "Available runners: $($avail.Count)"
        $avail | ForEach-Object { Write-Output "  $_" }
    }
    default { Write-Output "Usage: -Action [list|profile|available] [-Target runner_id]" }
}