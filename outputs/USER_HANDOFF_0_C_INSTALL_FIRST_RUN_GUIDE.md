# USER-HANDOFF-0 — Section C: Install and First-Run Guide

## Quick Start (Windows PowerShell)

### 1. Extract the Package
```powershell
Expand-Archive -Path "outputs\codex-factory-core-v0.5.0.zip" -DestinationPath "C:\my-factory-project"
cd C:\my-factory-project
```

### 2. Verify SHA256 (Optional)
```powershell
$expected = "9FD3A5F979FE1FDEA712F69CAC300E2F49F4E84705A0448D98186CA950AC16CB"
$actual = (Get-FileHash -Path "outputs\codex-factory-core-v0.5.0.zip" -Algorithm SHA256).Hash
$actual -eq $expected
```

### 3. Explore Available Commands
```powershell
Get-Help .\scripts\factoryctl.ps1
```

### 4. Check Factory State
```powershell
.\scripts\factoryctl.ps1 status
```

### 5. View Agent Registry
```powershell
.\scripts\factoryctl.ps1 agents
```

### 6. Run Watch (Aggregate View)
```powershell
.\scripts\factoryctl.ps1 watch
```

### 7. Run Cleanup Plan (Safe — No Deletion)
```powershell
.\scripts\factory-cleanup-planner.ps1 -ProjectId "my-project" -Mode PLAN
```

## Key Files to Review
| File | Purpose |
|---|---|
| `AGENTS.md` | Factory bootstrap rules |
| `GLOBAL_CODEX_RULES.md` | Global coding rules |
| `APP_TYPE_ROUTER.md` | Project type classification |
| `STACK_DECISION_GUIDE.md` | Technology stack guidance |
| `factory-release/V05_RELEASE_SCOPE_AND_LIMITATIONS.md` | Scope and limitations |
| `factory-release/v0.5-release-metadata.json` | Release metadata |

**Section C verdict: COMPLETE**
