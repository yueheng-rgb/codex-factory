# K: R1 Risk Register

| # | Risk | Severity | Mitigation | Blocker? | Verify |
|---|------|----------|------------|----------|--------|
| 1 | Too many docs without CLI discoverability | MEDIUM | CLI commands surface key features | No | `factory state` coverage |
| 2 | CLI name mismatch (`factory` vs `factoryctl`) | HIGH | Canonical name resolution plan | Yes | Name reconciliation check |
| 3 | Prototype scripts not production-hardened | MEDIUM | Mark as MVP; harden in R2 | No | Smoke tests pass |
| 4 | User confusion v0.5 vs v0.5-R1 | MEDIUM | Clear release notes, version manifest | No | User guide clarity |
| 5 | Theory features overclaimed as real validated | HIGH | Evidence taxonomy enforcement | Yes | Overclaim audit |
| 6 | Dashboard/recovery/evidence at fixture-level | LOW | Fixture testing is appropriate for R1 | No | Smoke on fixtures |
| 7 | Lifecycle delete commands misunderstood | HIGH | PLAN-first, double confirm, docs | Yes | `factory project delete` requires plan |
| 8 | Multi-agent roles overcomplicate simple tasks | LOW | Build Lite remains default | No | Decision gate preserves Lite |
