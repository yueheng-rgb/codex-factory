# Harness Runbook

## Quick Start

### Initialize a Run
```powershell
& scripts/initialize-run.ps1 -RunId "YOUR-RUN-ID" -ProjectName "my-project"
& scripts/freeze-control-plane.ps1 -RunDir "runs/YOUR-RUN-ID"
& scripts/external-trust-root.ps1 -RunDir "runs/YOUR-RUN-ID" -Action freeze
```

### Run Commands
```powershell
cd runs/YOUR-RUN-ID
npm ci
npm run typecheck
npm run test:unit
npm run build
```

### Task Pipeline
```powershell
# Issue token
$tok = (& scripts/token-lease.ps1 -Action issue -RunId "RUN-ID" -TaskId "T-001" -AgentId "builder-1" -Role builder-agent -TtlSeconds 7200 | ConvertFrom-Json).token

# Claim
& scripts/claim-task.ps1 -TaskId "T-001" -AgentId "builder-1" -Role builder-agent -Token $tok -RunDir "runs/RUN-ID"

# Submit
& scripts/submit-task.ps1 -TaskId "T-001" -AgentId "builder-1" -Role builder-agent -Token $tok -RunDir "runs/RUN-ID" -EvidencePaths @("command-logs/test-unit-stdout.log") -ModifiedFiles @("src/module.ts")

# Validate
$vtok = (& scripts/token-lease.ps1 -Action issue -RunId "RUN-ID" -TaskId "AC-001" -AgentId "validator-1" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& scripts/invoke-validation-command.ps1 -ValidationId "AC-001" -ExecCommand "echo PASS" -WorkingDir "runs/RUN-ID" -RunDir "runs/RUN-ID" -ExecutorRole "test-agent" -Token $vtok

# Verify
$vtok2 = (& scripts/token-lease.ps1 -Action issue -RunId "RUN-ID" -TaskId "T-001" -AgentId "validator-1" -Role test-agent -TtlSeconds 7200 | ConvertFrom-Json).token
& scripts/verify-task.ps1 -TaskId "T-001" -AgentId "validator-1" -Role test-agent -RunDir "runs/RUN-ID" -Token $vtok2
```

### Final Governance
```powershell
& scripts/validate-state.ps1 -RunDir "runs/RUN-ID"
```

## Configuration
```json
{
  "maxConcurrentWorkers": 3,
  "workspaceStrategy": "directory-snapshot",
  "heartbeatIntervalSeconds": 30,
  "timeoutSeconds": 180,
  "autoRedispatch": true,
  "validatorRequired": true,
  "contextBudgetEnforced": true
}
```
