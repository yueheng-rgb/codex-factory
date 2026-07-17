# Cloud/Sync Readiness — codex-factory-plugin

## Status: NOT READY

This plugin has NOT been tested for cloud synchronization or cross-project distribution.

## Current Capabilities

| Capability | Status | Evidence |
|------------|--------|----------|
| Local file integrity | VERIFIED | MANIFEST.sha256 validates |
| Relative path resolution | VERIFIED | DRY25-S0 repair confirmed |
| Cross-project sync | HYPOTHESIS | Not tested |
| Cloud distribution | HYPOTHESIS | Not tested |
| Manifest preservation | VERIFIED | SHA256 chain intact |
| No absolute paths | VERIFIED | Bootstrap uses relative paths |

## Sync Requirements (Untested)

1. Plugin directory must be self-contained (no external file references)
2. All paths must be workspace-relative or plugin-relative
3. Manifest SHA must survive copy/move/zip operations
4. Skill files must not reference host-specific paths
5. MCP configuration must use relative module resolution

## Current Blockers

- No cross-project copy test performed
- No ZIP packaging test performed
- No cloud storage integration tested
- Automation templates reference local-only paths

