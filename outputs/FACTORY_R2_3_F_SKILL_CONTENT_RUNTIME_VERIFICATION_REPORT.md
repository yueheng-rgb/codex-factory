# FACTORY R2.3-F Skill Content Runtime Verification — Report

**Phase:** FACTORY-R2.3-F-SKILL-CONTENT-RUNTIME-VERIFICATION
**Status:** COMPLETE
**Date:** 2026-07-09
**Verification:** 20/20 PASSED
**Behavior Simulation:** 22/22 PASSED

---

## 1. Executive Summary

R2.3-F advances CAP-SKILL-004 (agents-md-ecosystem) from "registry verified" to "content-loadable, agent-usable, behavior-verifiable" status. This phase establishes the distinction between **metadata verified** (R2.3-E: registry entry + pipeline approval) and **behavior verified** (R2.3-F: real SKILL.md content + fixture-based behavior simulation + usage ledger). CAP-SKILL-004 now has a complete skill package with 4811 characters of instructions, extractable behavior evidence, and a rollback path.

---

## 2. Skill Package Format

Defined in `schemas/factory-skill-package.schema.json`:

| Field | Purpose |
|-------|---------|
| skillId, name, version | Identity |
| status | candidate/adapted/verified/runtimeVerified/deprecated/quarantine |
| trustLevel | AVAILABLE/CAUTION/TRUSTED/VERIFIED |
| applicableAgents, applicableProjectTypes | Scope |
| triggerConditions | When the skill loads |
| instructions | Primary skill content (loaded from SKILL.md) |
| allowedTools, forbiddenActions | Tool permissions |
| verificationMethod | Format + behavior check specification |
| failureModes | Known failure patterns + recovery |
| rollbackPolicy | Can rollback + procedure + data loss risk |

---

## 3. CAP-SKILL-004 Content Inventory

```
skills/CAP-SKILL-004/
├── skill.json          — Package metadata (version 1.0.0)
├── SKILL.md            — 4811 chars of instructions (6 core rules)
├── examples/
│   └── fixture-agents-md.md  — Test fixture with build/test/lint/security/conventions/handoff
└── verification/       — Verification directory
```

### SKILL.md Core Rules

1. **AGENTS.md Discovery** — Walk directory tree, collect all AGENTS.md files
2. **Content Extraction** — Parse build/test/lint commands, security boundaries, conventions
3. **Scope Resolution** — Nested AGENTS.md overrides parent; report conflicts
4. **Contract Input Generation** — Translate rules into PIC/AC/FC/NGC fragments
5. **User Instruction Priority** — Flag conflicts, never override user instructions
6. **Tool Restrictions** — Read-only for AGENTS.md; no file modification or command execution

---

## 4. Runtime Components

### Skill Content Loader (`runtime/skill-content-loader.ps1`)

9 validation checks in sequence:
1. Skill directory exists
2. skill.json exists + valid JSON
3. Required fields present
4. Status gate (deprecated/quarantine → reject)
5. Permission gate (capability → agent check)
6. Agent applicability
7. SKILL.md exists → load instructions
8. Build structured summary (truncated to 1000 chars)
9. Return loaded skill with metadata

### Skill Context Injector (`runtime/skill-context-injector.ps1`)

Extends R2.3-D execution context with:
- `loadedSkillRefs` — array of loaded skill summaries
- `rejectedSkillRefs` — array of rejection reasons
- `skillWarnings` — aggregated warnings
- `skillsLoadedCount` / `skillsRejectedCount`

### Usage Ledger (`governance/skill-usage/skill-usage-index.jsonl`)

Records every skill load/rejection/rollback with: recordId, timestamp, projectId, phaseId, agentId, skillId, decision, reason, loadedSections, inputRefs, caveats.

---

## 5. Behavior Simulation Results (22/22)

| Category | Checks | Result |
|----------|--------|--------|
| Fixture AGENTS.md | 7 checks | All PASS |
| Command extraction (regex) | 3 checks | Build/Test/Lint extracted |
| Security boundaries | 1 check | Rules detected |
| Directory rules | 1 check | 3 directory scopes |
| Context injection comparison | 5 checks | Skill vs no-skill contexts |
| Usage ledger | 2 checks | Records exist |
| Conflict detection | 1 check | TS vs JS conflict |
| Rollback | 1 check | Record written |
| Quarantine gate | 1 check | Rejected correctly |

---

## 6. Metadata Verified vs Behavior Verified

| Property | Metadata Verified (R2.3-E) | Behavior Verified (R2.3-F) |
|----------|---------------------------|---------------------------|
| Evidence | Registry entry + pipeline approval | Fixture test + extraction proof |
| Content | Registry metadata only | SKILL.md (4811 chars) |
| Agent loading | Permission gate check | Full loader: schema + status + gate + content |
| Rollback | Decision log only | Usage ledger + rollback path |
| Status | `verified` | `verified` (runtimeVerified deferred) |

**CAP-SKILL-004 status remains `verified`** — `runtimeVerified` is reserved for when the skill is exercised with a real agent runtime (not simulation). This is intentional: we do NOT claim behavior verification is complete, only that the MVP infrastructure is in place.

---

## 7. Rollback / Deprecate / Quarantine

- **Invoke-SkillRollback**: Writes rollback usage record, supports target status (deprecated/quarantine)
- **Status gate**: Loader rejects deprecated/quarantine skills at check #4
- **Deprecation path**: Change skill.json status → loader auto-rejects
- **Quarantine path**: Change skill.json status → loader auto-rejects + usage logged

---

## 8. New Files

```
schemas/factory-skill-package.schema.json          [NEW]
schemas/skill-usage.schema.json                    [NEW]
skills/CAP-SKILL-004/skill.json                    [NEW]
skills/CAP-SKILL-004/SKILL.md                      [NEW — 4811 chars]
skills/CAP-SKILL-004/examples/fixture-agents-md.md [NEW]
runtime/skill-content-loader.ps1                   [NEW — 9 checks]
runtime/skill-context-injector.ps1                 [NEW]
runtime/skill-behavior-simulation.ps1              [NEW — 22 scenarios]
governance/skill-usage/skill-usage-index.jsonl     [NEW]
harness/verification/verify-r2-3-f-skill-content-runtime.ps1 [NEW]
```

## 9. R2.3-G Recommendations

1. **Promote to runtimeVerified**: Exercise CAP-SKILL-004 with a real agent on a project with actual AGENTS.md files
2. **Multi-skill batch load**: Test loading CAP-SKILL-004 + another verified skill simultaneously
3. **Skill conflict detection**: When two loaded skills have conflicting allowedTools/forbiddenActions
4. **Skill version upgrade path**: skill.json v1.0.0 → v1.1.0 with migration
5. **Real project trial**: Run the complete Factory Bootstrap + Skill Loading cycle on a non-simulation project
