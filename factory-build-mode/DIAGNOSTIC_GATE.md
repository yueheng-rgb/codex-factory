# Build Mode — Diagnostic Gate Integration

> Stage 6 of the Build Harness pipeline. Readonly quality check using Diagnostic Pack v1.1.0.

## Integration Point

Diagnostic Gate runs AFTER build completion, BEFORE delivery. It is a stage-gate: pass → DELIVER, critical gaps → REPAIR.

## Gate Rules

1. READONLY: Diagnostic Pack inspects, does not modify
2. STOP: After diagnostic, report findings. Do NOT auto-repair.
3. USER DECIDES: User reviews gaps, approves repair scope
4. RE-VERIFY: After repair, re-run diagnostic gate

## Mode Selection for Gate

| Build Mode | Diagnostic Mode |
|------------|----------------|
| VANILLA_BUILD | Quick Mode (12 items) |
| BUILD_LITE | Quick Mode or Student Project Mode |
| BUILD_REVIEWER | Student Project Mode (15 items) |
| BUILD_CONTINUATION | Full Diagnostic (25 items) per major milestone |
| BUILD_PRO_4_AGENT | Full Diagnostic (25 items) |

## Integration Flow

1. Build completes → Stage 5 done
2. Run Diagnostic Pack in selected mode
3. Readonly: scan codebase, check evidence, flag gaps
4. Output: `{project}/.codex-factory/diagnostic-result.json`
5. Gate decision:
   - 0 critical gaps → Stage 8 (DELIVER)
   - Critical gaps → Stage 7 (REPAIR), user must approve

## Report-vs-Source Integration

If project has report documents:
1. Run Report-vs-Source Mode FIRST
2. Classify claims as VERIFIED/PARTIAL/NOT_FOUND/CONTRADICTED
3. Append to diagnostic result

## Forbidden

- Auto-repair after diagnostic
- Skipping diagnostic gate
- Claiming PASS = project is good
- Treating report claims as source evidence
