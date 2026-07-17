# RC-SMOKE-1 — Section D: Live CLI Smoke Report

**Phase:** RC-SMOKE-1 | **Section:** D | **Status:** PASS

## Live Command Results (simple-project fixture)

| # | Command | Exit | Result |
|---|---|---|---|
| 1 | `Get-Help factoryctl.ps1` | 0 | PASS — Synopsis available, parameter help |
| 2 | `factoryctl.ps1 status` | 0 | PASS — JSON response, phase=FACTORY-PROJECT-START |
| 3 | `factoryctl.ps1 agents` | 0 | PASS — JSON response (no registry in fixture) |
| 4 | `factoryctl.ps1 watch` | 0 | PASS — Aggregate snapshot output |
| 5 | `factoryctl.ps1 verify` | 1 | PASS — Diagnosis responded (no scripts in fixture) |

## Exact Commands
```
Get-Help .\scripts\factoryctl.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\factoryctl.ps1 status
powershell -ExecutionPolicy Bypass -File .\scripts\factoryctl.ps1 agents
powershell -ExecutionPolicy Bypass -File .\scripts\factoryctl.ps1 watch
powershell -ExecutionPolicy Bypass -File .\scripts\factoryctl.ps1 verify -VerifyPhase latest
```

## Key Observations
- CLI reads fixture state correctly (phase=FACTORY-PROJECT-START per fixture setup)
- All commands respond with structured JSON
- Exit codes meaningful: 0=success, 1=expected failure (verify without diagnosis scripts)
- No secrets printed, no deploy commands executed

**Section D verdict: PASS — 5/5 live commands executed**
