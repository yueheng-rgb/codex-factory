# Worker {{WORKER_ID}} — {{PROJECT_NAME}}

## Project Context
- **Project**: {{PROJECT_NAME}}
- **Run**: {{RUN_ID}}
- **Phase**: {{PHASE}}
- **Your role**: Worker {{WORKER_ID}}

## Task Assignment

### Your Task: {{TASK_ID}}
**Description**: {{TASK_DESCRIPTION}}

### Files You Own
| File | Purpose |
|------|---------|
{{OWNED_FILES_TABLE}}

### Interfaces You Must Provide (Exports)
| Interface ID | Function | File | Signature |
|---|---|---|---|
{{EXPORTS_TABLE}}

### Interfaces You May Import (Dependencies)
| Interface ID | Function | From Worker | File |
|---|---|---|---|
{{IMPORTS_TABLE}}

## Contract Lock
The interface contract is **locked** in `interface-contract.lock.json`. Do NOT change exported function names or signatures. Any deviation will be caught by the interface drift detector.

## Boundaries (OWNERSHIP)
{{OWNERSHIP_RULES}}

## Acceptance Criteria
{{ACCEPTANCE_CRITERIA_LIST}}

## Required Deliverables
1. Your source file(s) in `workspace/{{WORKER_ID}}/src/`
2. Your `worker-interface-manifest.json` listing all actual exports
3. Your `worker-implementation-manifest.json` listing all files produced
4. Do NOT write to any other worker's workspace
5. Do NOT write to `canonical-integrated/`

## Remember
- You are one of multiple Workers. Other Workers depend on your exported interfaces matching the locked contract.
- If you discover an issue with the contract, report it via handoff — do NOT silently change function signatures.
- The Validator will verify your outputs independently.
