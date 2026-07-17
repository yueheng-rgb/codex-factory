# USER-HANDOFF-R1 — D: Install / Upgrade Guide

## Prerequisites
- Windows with PowerShell 5.1+
- Existing v0.5 install OR clean workspace

## Fresh Install

```powershell
# 1. Verify SHA256
$expected = "D563C5E462314E9EEC858E3E0E9D4E2B4131B0546B3FA289B4BD8EB1BE5E6A6B"
$actual = (Get-FileHash "codex-factory-core-v0.5.1-r1.zip" -Algorithm SHA256).Hash
if ($actual -ne $expected) { throw "SHA mismatch!" }

# 2. Extract
Expand-Archive -Path "codex-factory-core-v0.5.1-r1.zip" -DestinationPath ".\Codex_App_Factory" -Force

# 3. Verify CLI
.\Codex_App_Factory\scripts\factoryctl.ps1 --help

# 4. Check state
.\Codex_App_Factory\scripts\factory-state-dashboard-prototype.ps1 --brief
```

## Upgrade from v0.5

```powershell
# 1. Backup current install
Copy-Item -Recurse ".\Codex_App_Factory" ".\Codex_App_Factory_v0.5_backup"

# 2. Extract R1 over existing
Expand-Archive -Path "codex-factory-core-v0.5.1-r1.zip" -DestinationPath ".\Codex_App_Factory" -Force

# 3. Verify governance docs are present
ls .\Codex_App_Factory\governance\factory-*
```

## CLI Reference

| Command | Script |
|---------|--------|
| State dashboard | `scripts\factory-state-dashboard-prototype.ps1 --brief` |
| Recovery scan | `scripts\factory-recovery-scan.ps1 --dry-run` |
| Evidence validator | `scripts\factory-evidence-validator.ps1` |
| Main CLI | `scripts\factoryctl.ps1` |

## Rollback
Keep `codex-factory-core-v0.5.0.zip` as rollback. Restore from backup if needed.
