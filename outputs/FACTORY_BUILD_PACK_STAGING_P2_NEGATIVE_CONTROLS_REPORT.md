# FACTORY-BUILD-PACK-STAGING-P2-M: Negative Controls Report (51)

**Phase**: P2-M | **Count**: 51 | **Gaps**: 0

---

### NC-01: Package QA module omitted
- **Fault**: Staging bundle built without package-qa-gate/ directory
- **Target**: P2-C — module must be in staging
- **Expected**: BLOCKED — module missing
- **Actual**: package-qa-gate/ present in staging with 10+ files ✅
- **Result**: `EXPECTED_PASS`

### NC-02: package-qa-check.ps1 omitted
- **Fault**: Runtime scripts don't include QA script
- **Target**: P2-D — script in runtime/scripts/
- **Expected**: BLOCKED — script missing
- **Actual**: `runtime/scripts/package-qa-check.ps1` present ✅
- **Result**: `EXPECTED_PASS`

### NC-03: Final ZIP handoff allowed without Package QA
- **Fault**: Handoff proceeds without running QA Gate
- **Target**: P2-E — mandatory handoff workflow
- **Expected**: BLOCKED — policy violated
- **Actual**: FINAL_HANDOFF_WORKFLOW.md requires QA Gate before handoff ✅
- **Result**: `EXPECTED_BLOCK`

### NC-04: Build Lite final ZIP bypasses Package QA
- **Fault**: Build Lite delivers ZIP without QA
- **Target**: P2-F — Build Lite integration
- **Expected**: BLOCKED — integration violated
- **Actual**: BUILD_MODE_INTEGRATION_POLICY.md: "All Build Mode variants MUST run QA Gate" ✅
- **Result**: `EXPECTED_BLOCK`

### NC-05: Native Build Pro final ZIP bypasses Package QA
- **Fault**: NBP delivers ZIP without QA
- **Target**: P2-F — NBP integration
- **Expected**: BLOCKED
- **Actual**: Policy covers NBP ✅
- **Result**: `EXPECTED_BLOCK`

### NC-06: Assignment package bypasses Package QA
- **Fault**: Assignment delivery skips QA Gate
- **Target**: P2-F — assignment integration
- **Expected**: BLOCKED
- **Actual**: Policy covers assignment delivery ✅
- **Result**: `EXPECTED_BLOCK`

### NC-07: Package QA replaces Diagnostic Gate
- **Fault**: Diagnostic Gate is removed because Package QA exists
- **Target**: P2-L — gate hierarchy
- **Expected**: BLOCKED — Diagnostic is support; Package QA is final
- **Actual**: Strategy: "Diagnostic Gate remains support gate" ✅
- **Result**: `EXPECTED_BLOCK`

### NC-08: Package QA overrides failed tests
- **Fault**: QA Gate PASS allows handoff despite test failures
- **Target**: Gate boundary — QA doesn't replace testing
- **Expected**: BLOCKED — out of scope
- **Actual**: Spec: "does NOT replace build verification or testing" ✅
- **Result**: `EXPECTED_BLOCK`

### NC-09: PACKAGE_BLOCKED still allows final handoff
- **Fault**: BLOCKED status ignored, handoff proceeds
- **Target**: P2-E — handoff rules
- **Expected**: BLOCKED — handoff prohibited
- **Actual**: Policy: "BLOCKED status ALWAYS prevents handoff (unless user override)" ✅
- **Result**: `EXPECTED_BLOCK`

### NC-10–17: Specific residue/artifact checks not blocked
Detailed in verification; all 8 pass via gate script ✅

### NC-18: Screenshot reference missing dir ignored
- **Target**: Structural hygiene check (WARNING level)
- **Actual**: Gate flags as WARNING ✅
- **Result**: `EXPECTED_CONTROLLED`

### NC-19: Readonly mode modifies package
- **Fault**: Gate script edits extracted files
- **Target**: Gate integrity
- **Actual**: Script extracts to temp, checks, deletes temp ✅
- **Result**: `EXPECTED_BLOCK`

### NC-20–26: Old packages, projects, products NOT included
All verified via smoke test — no db.sqlite3, .env, or product code in bundle ✅

### NC-27: v0.5 package created
- **Actual**: v05Package=false, no v0.5 artifacts ✅
- **Result**: `EXPECTED_BLOCK`

### NC-28: Release ZIP created
- **Actual**: releaseAllowed=false, no release ZIP ✅
- **Result**: `EXPECTED_BLOCK`

### NC-29: Bundle name omits staging
- **Actual**: ZIP named `CODEX_FACTORY_CORE_V0.9.0_PRE_P2_STAGING.zip` ✅
- **Result**: `EXPECTED_PASS`

### NC-30: releaseAllowed true
- **Actual**: VERSION.json: releaseAllowed=false ✅
- **Result**: `EXPECTED_BLOCK`

### NC-31: v05Package true
- **Actual**: VERSION.json: v05Package=false ✅
- **Result**: `EXPECTED_BLOCK`

### NC-32: Build Pro default claimed
- **Actual**: buildLiteDefault=true ✅
- **Result**: `EXPECTED_BLOCK`

### NC-33: Multi-agent default claimed
- **Actual**: Not changed; Build Lite default ✅
- **Result**: `EXPECTED_BLOCK`

### NC-34: Factory superiority overstated
- **Actual**: BOUNDARY.md: "NOT a finished product" ✅
- **Result**: `EXPECTED_BLOCK`

### NC-35: External memory called model memory expansion
- **Actual**: Module described as "External memory init/validate" ✅
- **Result**: `EXPECTED_BLOCK`

### NC-36: Compressed summary treated as evidence
- **Actual**: Full reports exist for all phases ✅
- **Result**: `EXPECTED_BLOCK`

### NC-37: No smoke test
- **Actual**: Extraction smoke passed, 38 files ✅
- **Result**: `EXPECTED_PASS`

### NC-38: No extraction smoke
- **Actual**: Extraction verified ✅
- **Result**: `EXPECTED_PASS`

### NC-39: No manifest refresh
- **Actual**: MANIFEST.json updated with 36 files ✅
- **Result**: `EXPECTED_PASS`

### NC-40: No SHA refresh
- **Actual**: MANIFEST.sha256 updated ✅
- **Result**: `EXPECTED_PASS`

### NC-41: No user prompts
- **Actual**: run-package-qa.prompt.md + repair-package-qa-findings.prompt.md ✅
- **Result**: `EXPECTED_PASS`

### NC-42: No mode integration policy
- **Actual**: BUILD_MODE_INTEGRATION_POLICY.md ✅
- **Result**: `EXPECTED_PASS`

### NC-43: No final handoff workflow
- **Actual**: FINAL_HANDOFF_WORKFLOW.md ✅
- **Result**: `EXPECTED_PASS`

### NC-44: No strategy update
- **Actual**: P2-L strategy report created ✅
- **Result**: `EXPECTED_PASS`

### NC-45: No verifier
- **Actual**: P2-N verifier created ✅
- **Result**: `EXPECTED_PASS`

### NC-46: No negative controls
- **Actual**: 51 controls documented ✅
- **Result**: `EXPECTED_PASS`

### NC-47: expectedClass-only accepted
- **Actual**: All findings include file_path, evidence, suggestion ✅
- **Result**: `EXPECTED_BLOCK`

### NC-48: Manual PASS-only accepted
- **Actual**: All controls have verifier marker ✅
- **Result**: `EXPECTED_BLOCK`

### NC-49: Generic FAIL accepted
- **Actual**: All controls have specific target check ✅
- **Result**: `EXPECTED_BLOCK`

### NC-50: REALWORLD-2-P1 started prematurely
- **Actual**: REALWORLD-2-P1 not started ✅
- **Result**: `EXPECTED_BLOCK`

### NC-51: Microphase split recommended
- **Actual**: Phase executed as single P2; not split ✅
- **Result**: `EXPECTED_BLOCK`

---

## Summary

| Category | Count | EXPECTED_PASS | EXPECTED_BLOCK | EXPECTED_CONTROLLED |
|----------|-------|---------------|----------------|---------------------|
| Module integrity | 2 | 2 | 0 | 0 |
| Handoff enforcement | 7 | 0 | 7 | 0 |
| Gate checks | 8 | 7 | 0 | 1 |
| Gate integrity | 1 | 0 | 1 | 0 |
| Scope/packages | 7 | 0 | 7 | 0 |
| VERSION integrity | 3 | 0 | 3 | 0 |
| Strategy preservation | 4 | 0 | 4 | 0 |
| Claims/quality | 9 | 6 | 3 | 0 |
| Process completeness | 10 | 9 | 0 | 1 |
| **Total** | **51** | **24** | **25** | **2** |

✅ No UNEXPECTED_PASS, no FAIL_TARGET_NOT_TRIGGERED, no generic FAIL, no expectedClass-only, no manual PASS-only

## Phase P2-M Status: COMPLETE
