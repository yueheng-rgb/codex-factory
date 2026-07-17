# FACTORY-RELEASE-CANDIDATE-0 — Section B: RC Criteria and Boundary Definition Report

**Phase:** FACTORY-RELEASE-CANDIDATE-0
**Section:** B
**Generated:** 2026-06-28T20:30:00+08:00
**Status:** COMPLETE

---

## 1. RC Definition

RC-0 is a **candidate artifact for testing**, not a release. It may be extracted and smoke-tested.
It must not be advertised as a release.

## 2. Files Created

| File | Purpose |
|---|---|
| `factory-release/RC_BOUNDARY.md` | RC boundary: identity, inclusion/exclusion, version, release boundary, session rotation |
| `factory-release/RC_CRITERIA.md` | RC criteria: required flags, content rules, extraction rules, smoke rules, acceptance |

## 3. Required Flags

| Flag | Value |
|---|---|
| releaseAllowed | false |
| v05Package | false |
| finalRelease | false |
| rcCandidate | true |
| rcRequiresUserApproval | true |
| artifactType | RELEASE_CANDIDATE |

## 4. Source Boundary

Source: P8 staging pack definition + current project state.

**Included (CORE):**
- AGENTS.md, GLOBAL_CODEX_RULES.md, APP_TYPE_ROUTER.md, STACK_DECISION_GUIDE.md
- factory-resource-pack/, scripts/factoryctl.ps1, governance/ (all subdirectories)
- memory-quality/ (policies, schemas, templates, prompts)
- runtime/scripts/factory-cleanup-planner.ps1
- schemas/, prompts/, templates/, blueprints/, starters/, skills/
- scripts/ (excluding monitoring/)
- EXTERNAL_SKILLS_RESEARCH.md

**Included (EXPERIMENTAL, with caveats):**
- codex-factory-plugin/ (development preview)
- codex-factory-plugin/mcp/ (prototype reference)
- codex-factory-plugin/automation/ (design reference)
- scripts/monitoring/ (prototype reference)

**Excluded:**
- All real projects (ecommerce_homework, bigdata_homework, habit-tracker-*, tiny-typescript-service)
- All working copies (fresh-install-target, i-test-target, harness-control)
- All trial/harness/run artifacts
- All historical scoring/failure-router
- All old student packages
- Real .env, secrets, keys
- Release ZIPs, v0.5 packages

## 5. Acceptance

- [x] RC criteria defined
- [x] RC boundary defined
- [x] Flags specified
- [x] Inclusion/exclusion boundaries clear
- [x] Version boundary clear (0.9.0-pre-rc0)
- [x] Release boundary preserved (v0.5 BLOCKED)

**Section B verdict: COMPLETE**
