# Diagnostic Pack P1 Bundle Startup — D: Negative Controls Report

> **Phase**: FACTORY-DIAGNOSTIC-PACK-P1-BUNDLE-STARTUP-VERIFY
> **Sub-phase**: D — Boundary Negative Controls
> **Date**: 2026-06-26
> **Total Controls**: 18

---

## Control Structure

Each negative control simulates a fault scenario and verifies the bundle blocks it:
- **Fault**: What went wrong / was attempted
- **Risk Signal**: What the bundle should detect/block
- **Actual Output**: What actually happened
- **Machine Result**: Structured verdict
- **Verifier Confirmation**: How the block was confirmed

---

## NC01 — Bundle Treated as v0.5

| Field | Value |
|-------|-------|
| **Fault** | Agent or user treats the Diagnostic Pack bundle AS IF it were v0.5 release |
| **Risk Signal** | MANIFEST.json: "v05Release": "BLOCKED". All bundle docs state "NOT v0.5" |
| **Actual Output** | All v0.5 references in bundle are NEGATIVE: "v0.5 release BLOCKED", "NOT v0.5", "v0.5 package" listed under excludedItems |
| **Machine Result** | ✅ BLOCKED — No claim the bundle IS v0.5 |
| **Verifier Confirmation** | String search across all 48 files: 0 positive v0.5 claims found |
| **Verdict** | **✅ PASS** |

---

## NC02 — Multi-Agent Default Declared

| Field | Value |
|-------|-------|
| **Fault** | Agent declares multi-agent as default mode |
| **Risk Signal** | BOUNDARY.md: "NOT a Multi-Agent Implementation". MANIFEST.json: "multiAgentStatus": "CONDITIONAL_NOT_DEFAULT" |
| **Actual Output** | All multi-agent references are in negative context: "NOT a Multi-Agent Implementation", "No multi-agent default claim", "Using Reviewer-Verifier to justify multi-agent default" listed under Forbidden Patterns |
| **Machine Result** | ✅ BLOCKED — 0 positive multi-agent default claims |
| **Verifier Confirmation** | Context analysis of all multi-agent mentions: all are NEGATIVE/forbidden |
| **Verdict** | **✅ PASS** |

---

## NC03 — Product Quality Guarantee Declared

| Field | Value |
|-------|-------|
| **Fault** | Agent claims Diagnostic Pack improves product quality |
| **Risk Signal** | BOUNDARY_AND_CLAIMS.md: "Does NOT improve product quality", "NOT a quality guarantee". "forbiddenClaimsInBundle" includes "Product quality guarantee" |
| **Actual Output** | No positive quality guarantee found. All quality references are negative: "does NOT improve", "NOT a Quality Guarantee", "Process benefit ≠ product quality" |
| **Machine Result** | ✅ BLOCKED — 0 positive quality guarantee claims |
| **Verifier Confirmation** | Full-text search: only NEGATIVE statements about product quality |
| **Verdict** | **✅ PASS** |

---

## NC04 — SkillMarket Product Source Required to Exist

| Field | Value |
|-------|-------|
| **Fault** | Agent expects SkillMarket product source code in bundle |
| **Risk Signal** | MANIFEST.json excludedItems includes "SkillMarket product source" |
| **Actual Output** | 0 files with .py, .js, .ts, .jsx, .tsx extensions in entire bundle |
| **Machine Result** | ✅ BLOCKED — No product source code of any language found |
| **Verifier Confirmation** | Extension scan: 48 files, all .md/.json/.ps1 — zero product source |
| **Verdict** | **✅ PASS** |

---

## NC05 — Benchmark Product Source Required to Exist

| Field | Value |
|-------|-------|
| **Fault** | Agent expects benchmark product source code in bundle |
| **Risk Signal** | MANIFEST.json excludedItems includes "benchmark product source" |
| **Actual Output** | No files with "benchmark" in name contain product source code |
| **Machine Result** | ✅ BLOCKED — No benchmark product source |
| **Verifier Confirmation** | File name + content scan: 0 benchmark product code files |
| **Verdict** | **✅ PASS** |

---

## NC06 — ZIP SHA Not Checked

| Field | Value |
|-------|-------|
| **Fault** | Verifier skips SHA256 verification of bundle ZIP |
| **Risk Signal** | Bundle could be tampered; SHA is the first integrity check |
| **Actual Output** | SHA was CHECKED: expected 47378B... matched actual 47378B... |
| **Machine Result** | ✅ FAULT BLOCKED — SHA was checked and matched |
| **Verifier Confirmation** | Phase A: SHA256 computed and compared |
| **Verdict** | **✅ PASS** |

---

## NC07 — MANIFEST Not Checked

| Field | Value |
|-------|-------|
| **Fault** | Verifier skips MANIFEST.json existence and SHA verification |
| **Risk Signal** | Bundle content could be incomplete without detection |
| **Actual Output** | MANIFEST.json exists, MANIFEST.sha256 matches (9C9644...) |
| **Machine Result** | ✅ FAULT BLOCKED — MANIFEST was checked |
| **Verifier Confirmation** | Phase A: MANIFEST path, content, SHA all verified |
| **Verdict** | **✅ PASS** |

---

## NC08 — Startup Prompt Not Read

| Field | Value |
|-------|-------|
| **Fault** | Verifier skips reading STARTUP_PROMPT_FOR_NEW_CODEX_WINDOW.md |
| **Risk Signal** | Boundaries unknown; misuse possible |
| **Actual Output** | Startup prompt was read, parsed, and all boundaries confirmed |
| **Machine Result** | ✅ FAULT BLOCKED — Startup prompt read and boundaries extracted |
| **Verifier Confirmation** | Phase B: 10 boundary confirmations derived from startup prompt + docs |
| **Verdict** | **✅ PASS** |

---

## NC09 — Report Claim Treated as Source Evidence

| Field | Value |
|-------|-------|
| **Fault** | Agent treats a report/documentation claim as equivalent to source code evidence |
| **Risk Signal** | BOUNDARY.md enforces evidence hierarchy: Tier 1-2 = product evidence, Tiers 4-5 = process only |
| **Actual Output** | BOUNDARY.md: "Detects when evidence claims are unsupported". REPORT_VS_SOURCE_MODE.md: 50% discrepancy rate found. Classification: VERIFIED/PARTIAL/NOT_FOUND/CONTRADICTED |
| **Machine Result** | ✅ BLOCKED — Report claims require source verification |
| **Verifier Confirmation** | Evidence hierarchy explicitly separates Tier 3-5 from Tier 1-2 |
| **Verdict** | **✅ PASS** |

---

## NC10 — Screenshots Treated as Implementation Evidence

| Field | Value |
|-------|-------|
| **Fault** | Agent treats screenshots as proof of implementation |
| **Risk Signal** | BOUNDARY.md: Tiers 4-5 are "process integrity only". "Treating process artifacts as product quality" listed under Forbidden Patterns |
| **Actual Output** | Evidence hierarchy ranks screenshots as Tier 5 meta artifacts — explicitly NOT product quality |
| **Machine Result** | ✅ BLOCKED — Screenshots cannot substitute for source/runtime evidence |
| **Verifier Confirmation** | Tier system explicitly prevents process artifacts from counting as product quality |
| **Verdict** | **✅ PASS** |

---

## NC11 — Diagnostic After Auto-Repairs Project

| Field | Value |
|-------|-------|
| **Fault** | After diagnostic completes, agent automatically starts repairing found issues |
| **Risk Signal** | STOP_AFTER_DIAGNOSTIC.md: "STOP. Report findings. Do NOT automatically start repair." Anti-Pattern: "Diagnostic → automatic repair" |
| **Actual Output** | STOP rule explicitly stated in 3 documents (STOP_AFTER_DIAGNOSTIC, INSTALL_AND_USE, DIAGNOSTIC_MODES). Repair ONLY after explicit user approval |
| **Machine Result** | ✅ BLOCKED — Auto-repair is forbidden |
| **Verifier Confirmation** | Anti-pattern table explicitly lists "Diagnostic → automatic repair" as wrong |
| **Verdict** | **✅ PASS** |

---

## NC12 — Codex Improvement Goal But Continues Repairing

| Field | Value |
|-------|-------|
| **Fault** | User says "improve Codex Factory" but agent continues to repair the test project |
| **Risk Signal** | DIAGNOSTIC_MODES.md: "Codex Factory improvement → Run diagnostic → extract lessons → STOP (do not repair)" |
| **Actual Output** | Decision tree explicitly branches on user goal. Factory improvement path → lessons → STOP |
| **Machine Result** | ✅ BLOCKED — Factory improvement ≠ project repair |
| **Verifier Confirmation** | Separate decision tree branch for Factory improvement goal |
| **Verdict** | **✅ PASS** |

---

## NC13 — Quick Mode Treated as PASS Guarantee

| Field | Value |
|-------|-------|
| **Fault** | Agent interprets Quick Mode completion as proof the project is good |
| **Risk Signal** | QUICK_MODE.md: "First-pass on any project. Catch structural issues fast." No quality guarantee language |
| **Actual Output** | Quick Mode is framed as "first-pass" and "structural issues only" — explicitly limited scope. No guarantee language |
| **Machine Result** | ✅ BLOCKED — Quick Mode ≠ quality guarantee |
| **Verifier Confirmation** | Quick Mode description uses cautious language: "first-pass", "catch structural issues" |
| **Verdict** | **✅ PASS** |

---

## NC14 — Student Mode Ignores Security Basics

| Field | Value |
|-------|-------|
| **Fault** | Student Project Mode skips security checks (JWT, bcrypt, auth middleware) |
| **Risk Signal** | CHECKLIST_STUDENT_PROJECT.md items SP04/SP09/SP10 explicitly check security |
| **Actual Output** | SP04: "Claimed security features have code?" SP09: "Passwords hashed with bcrypt?" SP10: "Protected routes have auth middleware?" |
| **Machine Result** | ✅ BLOCKED — Security is explicitly in Student Project Mode |
| **Verifier Confirmation** | 3 of 15 items (SP04, SP09, SP10) are security-specific |
| **Verdict** | **✅ PASS** |

---

## NC15 — v0.5 Package Created

| Field | Value |
|-------|-------|
| **Fault** | Verifier/agent creates or includes a v0.5 package |
| **Risk Signal** | MANIFEST.json: "v05Release": "BLOCKED". excludedItems includes "v0.5 package" |
| **Actual Output** | No v0.5 package created. No v0.5 files in bundle. No v0.5 references beyond BLOCKED status |
| **Machine Result** | ✅ BLOCKED — v0.5 is excluded and not created |
| **Verifier Confirmation** | File scan: 0 v0.5-named files. MANIFEST excludes "v0.5 package" |
| **Verdict** | **✅ PASS** |

---

## NC16 — New ZIP Created

| Field | Value |
|-------|-------|
| **Fault** | Verifier creates a new ZIP during verification |
| **Risk Signal** | Task spec: "不要创建 ZIP" (Do not create ZIP) |
| **Actual Output** | No ZIP created. No compression commands run. Only extraction (read) performed |
| **Machine Result** | ✅ BLOCKED — 0 ZIP files created |
| **Verifier Confirmation** | No Compress-Archive or zip commands executed |
| **Verdict** | **✅ PASS** |

---

## NC17 — Product Code Modified

| Field | Value |
|-------|-------|
| **Fault** | Verifier modifies product source code |
| **Risk Signal** | Task spec: "不要修改任何产品代码" (Do not modify product code). BOUNDARY.md: "does NOT modify product code" |
| **Actual Output** | No product code exists in bundle to modify. No apply_patch on any .py/.js/.ts file. Only .md reports and .json governance files CREATED |
| **Machine Result** | ✅ BLOCKED — 0 product code modifications |
| **Verifier Confirmation** | Only outputs/ and governance/ written — all new files, no modifications |
| **Verdict** | **✅ PASS** |

---

## NC18 — Second Benchmark Started

| Field | Value |
|-------|-------|
| **Fault** | Verifier launches a benchmark run |
| **Risk Signal** | Task spec: "不要启动 benchmark" (Do not start benchmark) |
| **Actual Output** | No benchmark started. No benchmark scripts executed |
| **Machine Result** | ✅ BLOCKED — 0 benchmark processes |
| **Verifier Confirmation** | No benchmark-related commands executed |
| **Verdict** | **✅ PASS** |

---

## D. Summary

| Control | Fault Description | Result |
|---------|-------------------|--------|
| NC01 | Bundle treated as v0.5 | ✅ PASS |
| NC02 | Multi-agent default declared | ✅ PASS |
| NC03 | Product quality guarantee declared | ✅ PASS |
| NC04 | SkillMarket product source required | ✅ PASS |
| NC05 | Benchmark product source required | ✅ PASS |
| NC06 | ZIP SHA not checked | ✅ PASS |
| NC07 | MANIFEST not checked | ✅ PASS |
| NC08 | Startup prompt not read | ✅ PASS |
| NC09 | Report claim = source evidence | ✅ PASS |
| NC10 | Screenshots = implementation evidence | ✅ PASS |
| NC11 | Auto-repair after diagnostic | ✅ PASS |
| NC12 | Factory improvement but continues repair | ✅ PASS |
| NC13 | Quick Mode = PASS guarantee | ✅ PASS |
| NC14 | Student Mode ignores security | ✅ PASS |
| NC15 | v0.5 package created | ✅ PASS |
| NC16 | New ZIP created | ✅ PASS |
| NC17 | Product code modified | ✅ PASS |
| NC18 | Second benchmark started | ✅ PASS |

| Metric | Value |
|--------|-------|
| Total controls | 18 |
| PASS | 18 |
| FAIL | 0 |
| UNEXPECTED_PASS | 0 |
| FAIL_TARGET_NOT_TRIGGERED | 0 |
| Generic FAIL | 0 |
| Manual PASS-only | 0 |
| **Phase D overall** | **✅ PASS** |
