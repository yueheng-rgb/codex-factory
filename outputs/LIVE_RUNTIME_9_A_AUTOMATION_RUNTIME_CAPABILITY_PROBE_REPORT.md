# LIVE-RUNTIME-9-A: Automation Runtime Capability Probe Report

**Generated**: 2026-06-25T00:53:56+08:00 | **Status**: COMPLETE

## Summary

| Classification | Count |
|---------------|-------|
| VERIFIED_FACT | 3 |
| PARTIALLY_VERIFIED | 6 |
| HYPOTHESIS | 1 |
| REJECTED | 1 |

## Key Classifications

| Capability | Classification |
|------------|---------------|
| automation tool available | VERIFIED_FACT |
| can run against project files | VERIFIED_FACT |
| can emit machine-readable JSON | VERIFIED_FACT |
| can schedule project automation | PARTIALLY_VERIFIED |
| can run watcher script | PARTIALLY_VERIFIED |
| can notify user | PARTIALLY_VERIFIED |
| can archive when clean | PARTIALLY_VERIFIED |
| can generate startup packet | PARTIALLY_VERIFIED |
| can mutate governance state | PARTIALLY_VERIFIED (policy prohibits) |
| can create new carrier/window | HYPOTHESIS |
| same-thread wakeup as new context | REJECTED |

## Note

utomation_update tool exists in current schema. Real scheduled execution cannot be tested without creating a live automation. All watcher tests use SCHEDULED_MODE_SIMULATION and are honestly labeled.

## Verdict

LIVE-RUNTIME-9-A: COMPLETE
