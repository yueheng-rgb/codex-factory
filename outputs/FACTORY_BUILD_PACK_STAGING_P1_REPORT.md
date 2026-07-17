# FACTORY-BUILD-PACK-STAGING-P1 — codex-factory-core v0.9.0-pre Staging Build Report

**Phase**: FACTORY-BUILD-PACK-STAGING-P1 | **Date**: 2026-06-27 | **Status**: PASS (33/33)

---

## Staging Directory

`factory-resource-pack-v0.9.0-pre-staging/` — 15 files across 10 modules.

| Module | Status |
|--------|--------|
| build-lite/ | Default mode |
| native-build-pro/ | Conditional mode |
| memory-quality/ | Filtering + verification |
| external-memory/ | Init + validate |
| context-packets/ | Schema + generator + validator |
| diagnostic-gate/ | Support gates + recovery |
| runtime/ | Scripts |
| governance/ | Templates + schemas + policies |
| prompts/ | User prompts + examples |
| install/ | Installation + quickstart |

## VERSION.json

```json
{ "releaseAllowed": false, "v05Package": false, "buildLiteDefault": true, "nativeBuildProConditional": true, "contextPacketRequiredForPro": true }
```

## Installation

```powershell
Copy-Item "factory-resource-pack-v0.9.0-pre-staging\*" "<project>\codex-factory\" -Recurse
```

## Next

`FACTORY-BUILD-REALWORLD-0` — real-world project validation.
