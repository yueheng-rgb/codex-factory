# V05-R1-POST-INTEGRATION-SMOKE — G: Behavior Fixture Smoke

> Evidence Level: E3_LIVE_INSPECTED (policies inspected for correct behavior rules)

## Behavior Rule Verification
| # | Rule | Result | Detail |
|---|------|--------|--------|
| 1 | Large project -> multi-agent question | PASS | Multi-Agent Decision Gate present |
| 2 | Multi-agent never auto-starts | PASS | User confirmation required |
| 3 | Cleanup defaults to PLAN | PASS | PLAN-first enforcement |
| 4 | projectId mismatch blocks mount | PASS | Mount isolation rules |
| 5 | Dashboard shows project identity | PASS | Data model includes projectId |
| 6 | Recovery blocks missing verifier | PASS | Failure mode catalog covers verifier |
| 7 | Evidence validator blocks dashboard as primary evidence | PASS | Overclaim policy present |
| 8 | DELETED blocks mount | PASS | Permission matrix covers DELETED |
| 9 | FROZEN blocks write | PASS | Permission matrix covers FROZEN |
| 10 | ARCHIVED not default mount | PASS | Permission matrix covers ARCHIVED |
## Summary: 10 PASS, 0 FAIL (10 rules across 7 phases)
