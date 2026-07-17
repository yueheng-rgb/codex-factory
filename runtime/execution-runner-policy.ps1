# Codex Factory V3.0 — Execution Runner Policy
# Determines runner_type and preflight checks based on task risk/type

param([string]$TaskRiskLevel = "MEDIUM", [string]$TaskType = "test")

$policy = @{
    risk_level = $TaskRiskLevel
    task_type = $TaskType
    runner_type = "sandbox"
    require_snapshot_verify = $true
    require_artifact_capture = $true
    require_secret_check = ($TaskRiskLevel -in @("CRITICAL","HIGH","L_CLASS"))
    isolate_workspace = ($TaskRiskLevel -ne "LOW")
    human_review_required = ($TaskRiskLevel -in @("CRITICAL","L_CLASS"))
    non_claims = @(
        "Policy is advisory for RC, not enforcement for production",
        "Sandbox is directory-level copy, not VM isolation"
    )
}

if ($TaskRiskLevel -eq "LOW") { $policy.runner_type = "local" }
elseif ($TaskRiskLevel -eq "L_CLASS") { $policy.runner_type = "sandbox"; $policy.require_snapshot_verify = $true }

$policy | ConvertTo-Json -Depth 3
