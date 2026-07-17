# Simulation Scenario 8: CLI Name Mismatch → Warning Generated

> Part of: FACTORY-DEFAULT-WORKFLOW-0 / L — Default Workflow Simulation
> Scenario: 8 of 8

---

## Setup
- User or script references a CLI name that does not match the canonical registry

## User Input
> "运行 factory-build 命令"

But canonical name is `factory build`.

## Expected Factory Behavior

1. **Detection**: `factory-build` is not in the CLI name registry
2. **Warning**:
   > "⚠ CLI NAME WARNING: 'factory-build' was used but canonical name is 'factory build'. Using canonical name."
3. **Execution**: Proceeds with canonical name (with warning)
4. **Log**: Mismatch is logged for reconciliation

## Expected Verdict: ✅ PASS (warning generated, canonical name used)
