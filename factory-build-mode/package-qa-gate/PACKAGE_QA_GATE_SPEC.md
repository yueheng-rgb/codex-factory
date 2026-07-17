# Package QA Gate Specification v1.0

**Version**: 1.0.0
**Status**: ACTIVE
**Gate Type**: FINAL_DELIVERY
**Position**: After BUILD, before HANDOFF

---

## 1. Purpose

The Package QA Gate is a **lightweight, script-based final checkpoint** that runs on any delivery package (ZIP, project bundle, experiment report package, source code package) before it is handed off to the user or external recipient.

It catches issues that build verification does not: assignment conformance, process trace residue, artifact completeness, naming conventions, and technical hygiene.

## 2. Gate Position in Pipeline

```
BUILD → PACKAGE → **PACKAGE QA GATE** → HANDOFF
                      ↓ (BLOCK if findings)
                   REPAIR → RE-RUN QA
```

## 3. Check Categories

### CHECK-01: Process Trace Detection
Detect residue from AI/assistant tools in delivered files.

| Pattern | Detection Method | Severity |
|---------|-----------------|----------|
| `GPT`, `ChatGPT`, `OpenAI` references | Regex scan | BLOCKING |
| `Codex`, `Codex CLI`, `codex-factory` references | Regex scan | BLOCKING |
| `FACTORY-`, `BUILD-`, `QA-` internal IDs | Regex scan | BLOCKING |
| Prompt/instruction text leaked into output | Heuristic | BLOCKING |
| Wrong instructor/context references | Regex scan | BLOCKING |

### CHECK-02: Assignment Profile Matching
Verify delivered content matches the assignment/task profile.

| Check | Method | Severity |
|-------|--------|----------|
| Expected student/author name | Profile match | BLOCKING |
| Expected student/author ID | Profile match | BLOCKING |
| Expected ZIP filename format | Pattern match | BLOCKING |
| Expected project/deliverable name | Profile match | WARNING |

### CHECK-03: Artifact Completeness
Verify all required files are present.

| Check | Method | Severity |
|-------|--------|----------|
| Required report/document file | Manifest check | BLOCKING |
| Required source code directory | Manifest check | BLOCKING |
| Required SQL/schema file (DB projects) | Manifest check | BLOCKING |
| Required README | Manifest check | WARNING |
| Screenshot/image references valid | Path resolution | WARNING |

### CHECK-04: Technical Correctness
Verify delivered code/artifacts are technically sound.

| Check | Method | Severity |
|-------|--------|----------|
| Python syntax errors | `python -m py_compile` | BLOCKING |
| JS/TS syntax errors | `node --check` if available | WARNING |
| Library/platform mismatch (e.g., PyMySQL + `?`) | Pattern scan | BLOCKING |
| SQLite + `%s` mismatch | Pattern scan | BLOCKING |
| Required DB tables present | Schema comparison | BLOCKING |
| Import errors | Static analysis | WARNING |

### CHECK-05: Structural Hygiene
Verify package structure is clean and professional.

| Check | Method | Severity |
|-------|--------|----------|
| No `__pycache__` in package | File scan | WARNING |
| No `.pyc` files in package | File scan | WARNING |
| No `node_modules` in package | File scan | WARNING |
| No `.env` with real secrets | Secret scan | BLOCKING |
| No `venv/` in package | File scan | WARNING |
| ZIP can be extracted cleanly | Extract test | BLOCKING |
| ZIP size within reasonable bounds | Size check | WARNING |

## 4. Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| BLOCKING | Must fix before handoff | Block delivery, report, repair required |
| WARNING | Should fix, may handoff with note | Report, optional repair |
| INFO | Informational only | Report only |

## 5. Gate Behavior

```
RUN package-qa-check.ps1 -PackagePath <path-to-zip>

Output:
  PASS: all BLOCKING checks passed → handoff allowed
  PASS_WITH_WARNINGS: BLOCKING passed, WARNINGs present → handoff with caution
  BLOCKED: ≥1 BLOCKING failure → handoff prohibited, repair required
  ERROR: gate itself failed → investigate gate, not package
```

## 6. Integration Rules

| Rule | Description |
|------|-------------|
| Gate is read-only | Never modifies the package under test |
| Gate is a gate, not a builder | Does not fix issues; only reports them |
| Gate does not rewrite architecture | Does not suggest structural changes |
| Gate does not add features | Does not suggest additions beyond requirements |
| Gate does not claim product correctness | "Pass" means gate checks passed, not that product is bug-free |

## 7. Version

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-06-27 | Initial spec from QA-001 defect formalization |
