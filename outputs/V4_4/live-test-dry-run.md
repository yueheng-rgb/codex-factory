# V4.4 Live Test Dry Run

## Status: **WAITING_FOR_REAL_WORKER_HANDOFFS**

The dry run confirms the live test infrastructure is ready. Placeholder handoffs are
correctly rejected. The system is waiting for real worker outputs from separate
Codex windows.

## Dry Run Results

| Worker | Handoff | Status | Verdict |
|--------|---------|--------|---------|
| worker-backend | placeholder | PENDING | REJECTED — PLACEHOLDER_DETECTED |
| worker-frontend | placeholder | PENDING | REJECTED — PLACEHOLDER_DETECTED |
| worker-qa | placeholder | PENDING | REJECTED — PLACEHOLDER_DETECTED |

**All 3/3 placeholders correctly rejected. 0/3 accepted.**

## What's Ready
- Live test kit at `outputs/V4_4/live-cross-window-kit/`
- 3 self-contained worker prompts
- Main controller instructions
- Handoff return template
- Live test checklist
- Handoff intake and validation commands

## What The User Must Do
1. Open 3 separate Codex windows
2. Paste `WORKER_1_BACKEND_PROMPT.md` into Window A
3. Paste `WORKER_2_FRONTEND_PROMPT.md` into Window B
4. Paste `WORKER_3_TEST_VALIDATION_PROMPT.md` into Window C
5. Each worker produces a real handoff
6. Save handoffs to `runs/v44-live-cross-window/live-handoffs/`
7. Run `validate-live-handoff` and `summarize-live-run`

## Non-Claims
- Dry-run ≠ verified
- Placeholder handoffs are intentionally rejected
- Final classification will be LIVE_CROSS_WINDOW_VERIFIED only after real worker outputs
