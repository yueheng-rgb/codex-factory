# Native Build Pro Overhead & Benefit Metrics

## Overhead Metrics (recorded per run)
| Metric | Unit | BUILD-8 Reference |
|--------|------|-------------------|
| Planning time (spec + blueprint + task graph) | minutes | ~5 min |
| Agent capsule creation | count | 3 capsules |
| Write-scope map creation | count | 1 map |
| Agent spawn count | count | 3 |
| Agent wait time (total) | minutes | ~5-10 min |
| Integration/verification time | minutes | ~2 min |
| Total overhead vs Build Lite | % | ~30-40% |

## Benefit Metrics
| Metric | BUILD-8 Finding |
|--------|-----------------|
| Output richness | Build Pro > Build Lite (richer UI, more polish) |
| Parallel output | 3 agents produced output simultaneously |
| Context isolation | fork_context:false = no cross-contamination |
| Audit trail | Full lifecycle per agent |
| Recovery readiness | External memory + agent handoff = recoverable |

## Decision Rule
- If overhead > 50% and benefit = marginal → prefer Build Lite
- If overhead < 50% and benefit = clear (team, complex, parallel) → Build Pro justified
