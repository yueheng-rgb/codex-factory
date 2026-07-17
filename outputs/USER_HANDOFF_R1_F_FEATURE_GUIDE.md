# USER-HANDOFF-R1 — F: R1 Feature Guide

## 1. Default Workflow
- **What:** Select folder + state requirement → auto-enter Factory flow
- **Invoke:** Just open the project and state your requirement
- **Prevents:** Code written before design discussion; missing handoff paths; destructive cleanup
- **Evidence:** Policy documents, protocol specs, simulation results
- **Caveat:** Requires Factory installed in project folder

## 2. Project Isolation
- **What:** Each project gets projectId, pathFingerprint, contentFingerprint
- **Invoke:** Automatic at mount time; `factory state` shows identity
- **Prevents:** Cross-project context contamination; wrong project cleanup; foreign agent outputs
- **Evidence:** Identity model, registry schema, mount isolation rules
- **Caveat:** User must confirm unknown identities

## 3. State Dashboard
- **What:** CLI dashboard showing project identity, paths, phase, agent ledger, warnings
- **Invoke:** `factory state`, `factory state --json`, `factory state --agents`, `factory state --brief`
- **Prevents:** Blind operation without visibility into project state
- **Evidence:** Dashboard prototype script, data model, fixture smoke
- **Caveat:** Dashboard is working context, not primary evidence

## 4. Recovery
- **What:** Detects stale/corrupt/missing/foreign state and generates recovery plan
- **Invoke:** `factory recover --dry-run`
- **Prevents:** Silent continuation with damaged state; missing verifier auto-fake
- **Evidence:** Failure mode catalog, decision matrix, recovery scan script
- **Caveat:** PLAN first; never auto-repairs without user confirmation

## 5. Multi-Agent Orchestration
- **What:** Role profiles, contracts, handoffs, integrator protocol, failure attribution
- **Invoke:** Factory asks for large projects; you confirm to activate
- **Prevents:** Anonymous agent output; wrong-projectId output; worker bypassing integrator
- **Evidence:** Role profiles, contract/handoff schemas, integrator protocol
- **Caveat:** Never auto-starts; Build Lite remains fallback; runtime integration platform-dependent

## 6. Evidence Taxonomy
- **What:** E0-E8 levels classifying claim support from unsupported to universal proof
- **Invoke:** `factory evidence check` validates claims against evidence level
- **Prevents:** Overclaim (dashboard as primary evidence, local as production-ready)
- **Evidence:** Level model, claim support matrix, overclaim policy, validator script
- **Caveat:** R1 evidence ceiling is E6 (local validation); E7/E8 out of scope

## 7. Project Lifecycle
- **What:** 9 states: NEW, ACTIVE, PAUSED, FROZEN, ARCHIVED, DELETED, MIGRATED, UNKNOWN, CORRUPT
- **Invoke:** `factory lifecycle` shows current state; transitions require confirmation
- **Prevents:** DELETED project mounting; FROZEN project writing; ARCHIVED auto-mounting
- **Evidence:** State model, transition matrix, operation permission matrix, event log schema
- **Caveat:** Destructive transitions require explicit user confirmation
