# Simulation Scenario 7: Final Handoff → Full Paths Required

> Part of: FACTORY-DEFAULT-WORKFLOW-0 / L — Default Workflow Simulation
> Scenario: 7 of 8

---

## Setup
- Project phase completed
- Deliverables exist: source, config, docs, reports

## Expected Factory Behavior

1. **Handoff Template**: Uses structured handoff format
2. **All 7 categories covered**: Root, Source, Config, DB, Docs, Build/Run, Governance
3. **Absolute paths used**: `C:\project\src\index.ts` not `src/index.ts`
4. **UNKNOWN paths**: Marked as `UNKNOWN_WITH_REASON: <reason>`
5. **No omitted categories**: If a category is empty, explicitly state "N/A" or UNKNOWN

## Expected Verdict: ✅ PASS (all path categories covered)
