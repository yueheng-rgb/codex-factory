# Build Harness Integration — Package QA Gate

**Phase**: F — Build Harness Integration

## 1. Integration Points

The Package QA Gate integrates into the Factory Build Harness at these points:

### Integration 1: Build Mode
- When Build Mode produces a final ZIP, Package QA Gate is automatically invoked
- Gate runs BEFORE the ZIP is handed off to user
- BLOCKED status prevents handoff; requires repair

### Integration 2: Staging Pack
- `scripts/staging-pack.ps1` calls `package-qa-check.ps1` before finalizing any staging bundle ZIP
- Ensures staging bundles meet delivery quality standards

### Integration 3: Context Packet
- QA Gate results are recorded in `.codex-factory/qa-history.json`
- Becomes part of project context for future agents

## 2. Harness Directory Structure

```
factory-build-mode/
  package-qa-gate/
    PACKAGE_QA_GATE_SPEC.md         # Gate specification
    SCOPE_CHECKLIST_POLICY.md       # Scope, checklist, policy
    README.md                        # Implementation README
    schemas/
      package-qa-schemas.json        # JSON schemas
    templates/
      assignment-profile.template.json
      qa-report.template.md
    profiles/                        # Assignment profiles
    scripts/
      package-qa-check.ps1           # Main gate script
    prompts/
      run-package-qa.prompt.md
      repair-package-qa-findings.prompt.md
    fixtures/                        # Test fixtures
```

## 3. Build Pipeline Integration

```
Build Mode
  │
  ├─ Build Lite / Build Pro
  │     │
  │     └─ Produce package ZIP
  │           │
  │           └─ ** Package QA Gate **
  │                 │
  │                 ├─ PASS → Handoff to user
  │                 ├─ PASS_WITH_WARNINGS → Handoff with notes
  │                 └─ BLOCKED → Report → Repair → Re-run
  │
  └─ Staging Pack
        │
        └─ ** Package QA Gate ** (same check)
```

## 4. Phase F Status: COMPLETE
