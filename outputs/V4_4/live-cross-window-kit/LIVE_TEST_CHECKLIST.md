# V4.4 Live Cross-Window Test Checklist

## Preparation
- [ ] Read `MAIN_CONTROLLER_INSTRUCTIONS.md`
- [ ] Open 3 new Codex windows (A, B, C)
- [ ] Ensure this repo is the workspace in all windows

## Window A: Backend Worker
- [ ] Paste `WORKER_1_BACKEND_PROMPT.md` into Window A
- [ ] Do NOT paste other workers' prompts
- [ ] Do NOT paste full project history
- [ ] Worker produces: handoff + 4 artifacts (T3,T4,T5,T6)
- [ ] Copy worker-handoff.json to `runs/v44-live-cross-window/live-handoffs/worker-backend-handoff.json`

## Window B: Frontend Worker
- [ ] Paste `WORKER_2_FRONTEND_PROMPT.md` into Window B
- [ ] Do NOT paste other workers' prompts
- [ ] Worker produces: handoff + 2 artifacts (T7,T8)
- [ ] Copy worker-handoff.json to `runs/v44-live-cross-window/live-handoffs/worker-frontend-handoff.json`

## Window C: Test & Validation Worker
- [ ] Paste `WORKER_3_TEST_VALIDATION_PROMPT.md` into Window C
- [ ] Do NOT paste other workers' prompts
- [ ] Worker produces: handoff + 2 artifacts (T10,T12)
- [ ] Copy worker-handoff.json to `runs/v44-live-cross-window/live-handoffs/worker-qa-handoff.json`

## After All Workers Return
- [ ] Run: `powershell -File runtime/agent-execution-runtime.ps1 -Command import-live-handoff -RunId runs/v44-live-cross-window`
- [ ] Run: `powershell -File runtime/agent-execution-runtime.ps1 -Command validate-live-handoff -RunId runs/v44-live-cross-window`
- [ ] Run: `powershell -File runtime/agent-execution-runtime.ps1 -Command summarize-live-run -RunId runs/v44-live-cross-window`

## Acceptance Criteria
- [ ] 3/3 workers returned handoffs OR documented blockers
- [ ] All artifacts are non-empty and verifiable
- [ ] No boundary violations detected
- [ ] No fake PASS
- [ ] Final status is one of: LIVE_CROSS_WINDOW_VERIFIED, LIVE_CROSS_WINDOW_BLOCKED, LIVE_CROSS_WINDOW_PARTIAL

## Before Returning to Auditor
- [ ] Confirm no secrets in any handoff
- [ ] Confirm V3.4.2 evidence intact
- [ ] Report final classification honestly
