# OUTPUT_GOVERNANCE_ISOLATION.md

> Part of: FACTORY-PROJECT-ISOLATION-0
> Section: F — Output/Governance Isolation
> Version: 1.0.0

---

## Purpose

Ensure that phase reports, verifier results, strategy decisions, and other governance outputs are scoped to their project and never accidentally read, written, or referenced across project boundaries.

---

## Output Isolation Rules

### Phase Reports
| Rule | Enforcement |
|------|------------|
| Phase report MUST include `projectId` in metadata | Schema validation |
| Phase report stored in project-specific `outputs/` | Path isolation |
| Phase report from another project MUST NOT be loaded as current | Mount gate |
| Phase report from another project viewable as reference only | FOREIGN_REFERENCE |

### Verifier Results
| Rule | Enforcement |
|------|------------|
| Verifier result MUST include `projectId` | Schema validation |
| Verifier result stored in project-specific governance | Path isolation |
| Cross-project verifier comparison allowed but marked | FOREIGN_COMPARISON |

### Strategy Decisions
| Rule | Enforcement |
|------|------------|
| Strategy decision MUST include `projectId` | Schema validation |
| Strategy from another project viewable as reference | FOREIGN_REFERENCE |

### Negative Controls
| Rule | Enforcement |
|------|------------|
| Negative controls MUST include `projectId` | Schema validation |
| Global negative controls (Factory-level) are separate | Global scope marker |

---

## Governance Isolation Rules

### Phase Ledger
- Each project has its own phase ledger
- Phase ledger entries include `projectId`
- Cross-project phase lookup allowed but marked FOREIGN_REFERENCE

### Decision Records
- All decisions scoped to projectId
- Factory-level decisions (affecting all projects) use `projectId: "GLOBAL"`

### Evidence Preservation
- CORE_EVIDENCE is project-scoped
- Global evidence uses global governance path
- Never mix project and global evidence in same directory

---

## Path Isolation

```
Project A:
  C:\project-a\outputs\          ← Project A outputs
  C:\project-a\governance\       ← Project A governance

Project B:
  C:\project-b\outputs\          ← Project B outputs
  C:\project-b\governance\       ← Project B governance

Global:
  %USERPROFILE%\.codex-factory\  ← Global governance
```

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| Phase report from Project A written to Project B outputs | Path contamination |
| Verifier result from Project A treated as Project B result | Wrong attribution |
| Strategy decision from Project A applied to Project B | Wrong context |
| Negative controls from Project A evaluated for Project B | Scope error |
