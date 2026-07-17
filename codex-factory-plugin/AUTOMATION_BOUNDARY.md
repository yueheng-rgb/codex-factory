# Automation Boundary — codex-factory-plugin

## Status: EXPERIMENTAL — DESIGN_FEASIBLE_IMPLEMENTATION_HYPOTHETICAL

## What Automation CAN Do (Design)

| Capability | Status |
|------------|--------|
| Read factory state | PROTOTYPE (MONITORING_PASS) |
| Check manifest integrity | PROTOTYPE (SHA256 validated) |
| Report alerts (non-blocking) | DESIGN |
| Recommend actions (advisory) | DESIGN |

## What Automation CANNOT Do (Enforced)

| Prohibition | Mechanism |
|-------------|-----------|
| Mutate governance state | doesNotMutateState: true |
| Update currentTrustedPhase | No write path |
| Mark phase PASS/FAIL | MONITORING_PASS/ALERT enum (separate) |
| Create final ZIP | No file creation |
| Replace verifier evidence | evidenceWeight: signal-only |
| Suppress verifier FAIL | Verbatim pass-through |
| Convert ALERT to PASS | No conversion path |

## Runtime Automation Status

| Claim | Classification |
|-------|---------------|
| Automation tool exists | PARTIALLY_VERIFIED |
| Scheduled monitoring possible | PARTIALLY_VERIFIED |
| Can run factoryctl verify | HYPOTHESIS |
| Can notify without mutation | PARTIALLY_VERIFIED |
| Cannot write governance state | HYPOTHESIS |
| Output is machine-readable | VERIFIED_FACT |
| Can wake/continue thread | CODEX_SELF_REPORT_ONLY |

## DRY27 Required For

- Live automation scheduling
- Thread wakeup verification
- Drift alert in scheduled mode
- Automation preventing state mutation at runtime

