# LIVE-RUNTIME-9-C: Automation Output Contract Report

**Generated**: 2026-06-25T00:53:56+08:00 | **Status**: COMPLETE

## Artifacts Created

| File | Purpose |
|------|---------|
| governance/automation-os/automation-output-contract.schema.json | Required output fields + immutable rules |
| governance/automation-os/automation-runtime-policy.json | 9 runtime rules for automation behavior |

## Output Contract — Required Fields

automationRunId, runMode, checkedAt, watcherResultPath, verdict, alerts[], riskSignals[], evidencePaths[], recommendedAction, userActionRequired

## Runtime Policy — Core Rules

1. Alert is not verifier PASS
2. Cannot mutate governance state
3. Cannot create final ZIP
4. Cannot claim new context/window unless proven
5. Same-thread wakeup NOT a new context
6. May recommend manual new window + artifact startup
7. Simulation must be labeled, never mislabeled
8. Output must be machine-readable JSON
9. Evidence paths required in all alerts

## Verdict

LIVE-RUNTIME-9-C: COMPLETE
