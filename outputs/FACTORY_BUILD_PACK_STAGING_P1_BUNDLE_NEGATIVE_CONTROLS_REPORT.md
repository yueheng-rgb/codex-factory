# FACTORY_BUILD_PACK_STAGING_P1_BUNDLE_NEGATIVE_CONTROLS_REPORT

> Phase: L — Negative Controls (50)
> Date: 2026-06-27

| # | Fault Manifest | Target Check | Risk Signal | Actual Output | Result |
|---|---------------|-------------|-------------|---------------|--------|
| 1 | v0.5 package created | Check for v0.5/ directory | v0.5 artifact exists | No v0.5 directory | DEFENCE_HELD |
| 2 | Release ZIP created | Check for new *.zip in factory root | New ZIP > REALWORLD-1 start | Only pre-existing V04 ZIP (06-26) | DEFENCE_HELD |
| 3 | Bundle name omits staging/non-release | Check VERSION.status | status != STAGING_NOT_RELEASE | status = STAGING_NOT_RELEASE | DEFENCE_HELD |
| 4 | Staging bundle treated as release | Check VERSION.releaseAllowed | releaseAllowed = true | releaseAllowed = false | DEFENCE_HELD |
| 5 | Build Pro default claimed | Check VERSION.buildLiteDefault | buildLiteDefault = false | buildLiteDefault = true | DEFENCE_HELD |
| 6 | Multi-agent default claimed | Check BOUNDARY.md + VERSION | multi-agent default claim | No such claim anywhere | DEFENCE_HELD |
| 7 | Build Lite default omitted | Check VERSION.buildLiteDefault | Missing or false | true | DEFENCE_HELD |
| 8 | Native Build Pro conditional omitted | Check VERSION.nativeBuildProConditional | Missing or false | true | DEFENCE_HELD |
| 9 | Context Packet optional for Native Build Pro | Check VERSION.contextPacketRequiredForPro | false | true | DEFENCE_HELD |
| 10 | validate-project.ps1 omitted | Check runtime/scripts/ | File missing | Present (4.6 KB) | DEFENCE_HELD |
| 11 | smoke-bounded.ps1 omitted | Check runtime/scripts/ | File missing | Present (2.2 KB) | DEFENCE_HELD |
| 12 | context-packet-auto.ps1 omitted | Check runtime/scripts/ | File missing | Present (2.1 KB) | DEFENCE_HELD |
| 13 | Verifier syntax bug ignored | Check repaired verifier | Bug still present | 25/25 PASS, no syntax error | DEFENCE_HELD |
| 14 | Verifier weakened | Check verifier check count | < previous check count | 25 checks (same as original minus bug) | DEFENCE_HELD |
| 15 | Manifest missing | Check MANIFEST.json | File missing | Present (22 files, 31.6 KB) | DEFENCE_HELD |
| 16 | SHA missing | Check MANIFEST.sha256 | File missing | Present | DEFENCE_HELD |
| 17 | Extraction smoke omitted | Check Phase I execution | Not executed | Extraction + validate-project PASS | DEFENCE_HELD |
| 18 | Product source included | Check staging for product Java/Python source | .java/.py files in bundle | 0 source code files | DEFENCE_HELD |
| 19 | Trial products included | Check for NexusDesk/DevFlow paths | Trial product artifacts | Not found | DEFENCE_HELD |
| 20 | Online Bookstore working copy included | Check staging for harness/ paths | Real project in bundle | Not in staging | DEFENCE_HELD |
| 21 | Old release ZIP included | Check staging for *.zip | ZIP in bundle | 0 ZIP files | DEFENCE_HELD |
| 22 | Old FINAL package included | Check staging for FINAL paths | FINAL artifacts | Not found | DEFENCE_HELD |
| 23 | v0.5 artifacts included | Check staging for v0.5 | v0.5 references | None | DEFENCE_HELD |
| 24 | SkillMarket included | Check staging for SkillMarket | SkillMarket artifacts | Not found | DEFENCE_HELD |
| 25 | DevFlow included | Check staging for DevFlow | DevFlow artifacts | Not found | DEFENCE_HELD |
| 26 | NexusDesk included | Check staging for NexusDesk | NexusDesk artifacts | Not found | DEFENCE_HELD |
| 27 | Compressed summary treated as evidence | Check reports reference actual paths | Summary-only claims | All claims backed by file paths | DEFENCE_HELD |
| 28 | External memory called model memory expansion | Check all docs | Misleading claim | All docs say "external memory", not "model memory expansion" | DEFENCE_HELD |
| 29 | Diagnostic Gate treated as mainline | Check Boundary/Gate docs | Gate as primary flow | Gate = support, Build Lite = default | DEFENCE_HELD |
| 30 | Native Build Pro starts automatically | Check VERSION + mode-selector | Auto-trigger | Conditional, requires user confirmation | DEFENCE_HELD |
| 31 | Phase auto-chaining implemented fully without approval | Check governance policies | Full auto-chain | Draft policy only, not implemented | DEFENCE_HELD |
| 32 | REALWORLD-2 started prematurely | Check for REALWORLD-2 artifacts | REALWORLD-2 evidence | Not started | DEFENCE_HELD |
| 33 | Product code modified | Check staging file timestamps vs origin | Post-bundle mods to product code | 0 product files | DEFENCE_HELD |
| 34 | Original Online Bookstore modified | Check original package LastWriteTime | Post-REALWORLD-1 mods to original | 0 files modified | DEFENCE_HELD |
| 35 | No negative controls | Check Phase L report | Missing | This report: 50 controls | DEFENCE_HELD |
| 36 | No verifier | Check Phase M script | Missing verifier | Verifier script created + executed | DEFENCE_HELD |
| 37 | No evidence paths | Check reports for file references | Path-free claims | All reports reference specific paths | DEFENCE_HELD |
| 38 | Bundle extraction fails | Check Phase I smoke | Extraction error | 22/22 files extracted, validate-project PASS | DEFENCE_HELD |
| 39 | validate-project modifies project in readonly mode | Check validate-project logic | Writes in ReadOnly | ReadOnly mode: no file writes, "-Readonly mode active" | DEFENCE_HELD |
| 40 | smoke-bounded can hang indefinitely | Check smoke-bounded timeout logic | No timeout kill | TimeoutSeconds=60 default, auto-kill after timeout | DEFENCE_HELD |
| 41 | context-packet-auto accepts unsupported PASS | Check auto-gen logic | Always passes | Has explicit validation checks (packet_id, phase, mode) | DEFENCE_HELD |
| 42 | User workflow docs missing | Check runtime README | No usage docs | runtime/README.md + README_VALIDATE_PROJECT.md | DEFENCE_HELD |
| 43 | Install docs missing | Check install/README.md | Missing | Present | DEFENCE_HELD |
| 44 | Runtime docs missing | Check runtime/README.md | Missing | Present (updated) | DEFENCE_HELD |
| 45 | No readiness assessment | Check Phase K report | Missing | Present (8 questions answered) | DEFENCE_HELD |
| 46 | releaseAllowed = true | Check VERSION.json | releaseAllowed = true | releaseAllowed = false | DEFENCE_HELD |
| 47 | v05Package = true | Check VERSION.json | v05Package = true | v05Package = false | DEFENCE_HELD |
| 48 | MANIFEST excludes new scripts | Check MANIFEST.files | Scripts missing from manifest | All 3 scripts in manifest (22 files total) | DEFENCE_HELD |
| 49 | Microphase split recommended | Check for unnecessary subdivision | Split recommendation | Single BUNDLE phase, orderly steps | DEFENCE_HELD |
| 50 | Real-world validation requirement removed | Check VERSION.realWorldValidationRequired | false | true | DEFENCE_HELD |

## Summary

| Metric | Value |
|--------|-------|
| Total Controls | 50 |
| DEFENCE_HELD | 50 |
| DEFENCE_BREACHED | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Generic FAIL | 0 |
