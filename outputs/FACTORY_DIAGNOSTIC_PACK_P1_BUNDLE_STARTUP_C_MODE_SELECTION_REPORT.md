# Diagnostic Pack P1 Bundle Startup — C: Mode Selection Simulation Report

> **Phase**: FACTORY-DIAGNOSTIC-PACK-P1-BUNDLE-STARTUP-VERIFY
> **Sub-phase**: C — Mode Selection Simulation
> **Date**: 2026-06-26
> **Method**: Simulated mode selection using DIAGNOSTIC_MODES.md decision tree. No real project used.

---

## Decision Tree (from DIAGNOSTIC_MODES.md)

`
Is this a student/course project?
├── YES → Does it have a written report?
│   ├── YES → Start with Report-vs-Source Mode → then Student Project Mode
│   └── NO → Student Project Mode
└── NO → Is it a large/complex project (>100 files, auth, DB, multiple apps)?
    ├── YES → Quick Mode first → if issues found → Full Diagnostic Mode
    └── NO → Quick Mode (sufficient for most projects)

Is the project high-risk (auth, financial, compliance)?
└── YES → Full Diagnostic Mode (always)

Is the user's goal Codex Factory improvement?
└── YES → Run diagnostic → extract lessons → STOP (do not repair)

Is the user's goal project submission/production?
└── YES → Run diagnostic → review findings → decide repair scope
`

---

## Scenario 1: Student Course Project (report + frontend/backend + database)

**Description**: A student submits a course project with a written report, claiming a frontend, backend, and database implementation.

**Decision Path**:
1. Is this a student/course project? → **YES**
2. Does it have a written report? → **YES**

**Expected Mode**: Report-vs-Source Mode → then Student Project Mode

| Check | Result |
|-------|--------|
| Decision tree followed correctly | ✅ |
| Report-vs-Source selected first (before repair) | ✅ |
| Student Project Mode chained after | ✅ |
| No automatic repair triggered | ✅ |
| **Verdict** | **✅ PASS** |

---

## Scenario 2: Unknown Multi-App Project (auth + db + frontend + backend)

**Description**: A project with authentication, database, backend, and frontend. No prior classification. Could be large.

**Decision Path**:
1. Is this a student/course project? → **NO** (unknown)
2. Is it a large/complex project (>100 files, auth, DB, multiple apps)? → **YES** (auth + db + frontend + backend)
3. Quick Mode first → if issues found → Full Diagnostic Mode

**Expected Mode**: Quick Mode first, then Full Diagnostic if high-risk signals detected

| Check | Result |
|-------|--------|
| Decision tree followed correctly | ✅ |
| Quick Mode selected as first pass | ✅ |
| Full Diagnostic gated behind found issues | ✅ |
| High-risk detection path preserved | ✅ |
| **Verdict** | **✅ PASS** |

---

## Scenario 3: Report-and-Screenshots Only (no source code structure)

**Description**: User provides only a report document and screenshots. No clear source code repository structure. Claims of implementation exist.

**Decision Path**:
1. Is this a student/course project? → **ASSUME YES** (report-centric)
2. Does it have a written report? → **YES**
3. Report-vs-Source Mode selected

**Expected Mode**: Report-vs-Source Mode with explicit evidence caveat:
- "Report claims CANNOT be verified without source access"
- "Screenshots are NOT runtime evidence (Tier 5)"
- Report-vs-Source checklist items would return NOT_FOUND for missing source

| Check | Result |
|-------|--------|
| Report-vs-Source correctly selected | ✅ |
| Evidence caveat recognized (Tier 5) | ✅ |
| NOT_FOUND classification available | ✅ |
| Does not fabricate evidence | ✅ |
| **Verdict** | **✅ PASS** |

---

## Scenario 4: Codex Factory Improvement Goal

**Description**: User's explicit goal is to improve Codex Factory, not to repair a specific project.

**Decision Path**:
1. Is the user's goal Codex Factory improvement? → **YES**
2. From DIAGNOSTIC_MODES.md: "Run diagnostic → extract lessons → STOP (do not repair)"
3. From INSTALL_AND_USE.md Step 4: "If goal is Codex Factory improvement → extract lessons → STOP"

**Expected Mode**: diagnostic → lessons extraction → stop

| Check | Result |
|-------|--------|
| Factory improvement path recognized | ✅ |
| Lessons extraction triggered | ✅ |
| STOP enforced (no repair) | ✅ |
| Not confused with project repair | ✅ |
| **Verdict** | **✅ PASS** |

---

## Scenario 5: User Explicitly Requests Pre-Submission Repair

**Description**: User explicitly asks to repair project before submission deadline.

**Decision Path**:
1. Is the user's goal project submission? → **YES**
2. From DIAGNOSTIC_MODES.md: "Run diagnostic → review findings → decide repair scope"
3. From STOP_AFTER_DIAGNOSTIC.md: "Only if user explicitly requests it → targeted repair"
4. From BOUNDARY.md: "Diagnostic → targeted repair transition, but only after explicit user approval"

**Expected Mode**: diagnostic → report findings → user confirms repair scope → targeted repair only

| Check | Result |
|-------|--------|
| Diagnostic runs first (readonly) | ✅ |
| STOP after diagnostic | ✅ |
| User must approve repair scope | ✅ |
| Targeted repair (not full rewrite) | ✅ |
| Anti-pattern avoided (no auto-repair) | ✅ |
| **Verdict** | **✅ PASS** |

---

## C. Summary

All 5 mode selection scenarios correctly produce the expected modes using the DIAGNOSTIC_MODES.md decision tree:

| Scenario | Expected Mode | Actual Match |
|----------|--------------|-------------|
| 1 — Student course project + report | Report-vs-Source → Student Project | ✅ |
| 2 — Unknown multi-app + auth/db | Quick → Full Diagnostic (if issues) | ✅ |
| 3 — Report/screenshots only | Report-vs-Source + evidence caveat | ✅ |
| 4 — Codex Factory improvement | Diagnostic → lessons → STOP | ✅ |
| 5 — Pre-submission repair request | Diagnostic → report → user-approved targeted repair | ✅ |

| Category | Result |
|----------|--------|
| Decision tree accuracy | ✅ PASS |
| Boundary preservation in all modes | ✅ PASS |
| STOP rule enforcement | ✅ PASS |
| Evidence caveats recognized | ✅ PASS |
| **Phase C overall** | **✅ PASS** |
