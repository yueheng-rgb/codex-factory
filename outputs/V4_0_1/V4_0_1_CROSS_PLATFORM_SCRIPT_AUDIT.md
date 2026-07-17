# V4.0.1 Cross-Platform Script Audit

## Status: FIXED

## Changes

| Item | Before | After |
|---|---|---|
| README commands | `powershell` prefix | `pwsh` primary, `powershell` fallback |
| Doctor platform check | Not checked | Detects Windows/Linux/macOS |
| Doctor pwsh check | Not checked | Checks pwsh availability, gives platform-specific install advice |
| Docs commands | Mixed pwsh/powershell | Unified to `pwsh` |
| GitHub Actions | Already pwsh | No change needed |

## Doctor New Checks
- `platform` — Windows / Linux / macOS detected
- `pwsh` — available + version, or WARN with install instructions per platform
