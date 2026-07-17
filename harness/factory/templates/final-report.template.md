# {{PHASE}}: {{PROJECT_NAME}} Run Report

**Status: {{STATUS}}** | **Date: {{DATE}}** | **Run: {{RUN_ID}}**

## 1. What This Run Did
{{WHAT_DID}}

## 2. What This Run Did NOT Do
{{WHAT_DID_NOT}}

## 3. Contract Summary
| Metric | Value |
|--------|-------|
| Contract interfaces | {{CONTRACT_INTERFACE_COUNT}} |
| Cross-worker dependencies | {{CROSS_WORKER_DEP_COUNT}} |
| Locked | {{LOCKED}} |

## 4. Task Results
| Task | Worker | Status | Issues |
|------|--------|--------|--------|
{{TASK_RESULTS_TABLE}}

## 5. Gate Results
| Gate | Status |
|------|--------|
{{GATE_RESULTS_TABLE}}

## 6. Validation
{{VALIDATION_SUMMARY}}

## 7. Files Produced
{{FILES_PRODUCED}}

## 8. Final Verdict
**{{FINAL_VERDICT}}**
