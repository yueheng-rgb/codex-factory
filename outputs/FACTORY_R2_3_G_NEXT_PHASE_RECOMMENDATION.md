# R2.3-G Next Phase Recommendation

**Phase:** FACTORY-R2.3-G | **Date:** 2026-07-09

## Current State

R2.3-G Skill Audit Capability Trust Pipeline is **complete**:
- 6-stage audit pipeline operational
- 32-risk taxonomy established
- 7/7 simulation PASS (1 legit + 6 malicious)
- 24/24 verification PASS
- CAP-SKILL-004 audited: PASS (0/100 risk)

## Recommendation: Proceed to R2.3-H — Live Skill Runtime Trial

### Rationale

1. **auditPassed ≠ runtimeVerified** — CAP-SKILL-004 has passed audit but has NOT been proven effective in a real project context
2. **Audit pipeline is static** — It cannot verify that a skill actually produces correct behavior
3. **Trust ladder incomplete** — Skills need: candidate → auditPassed → runtimeVerified → production
4. **Negative controls work** — Pipeline correctly quarantines/rejects malicious skills

### R2.3-H Should Include

1. **CAP-SKILL-004 Live Trial** — Load CAP-SKILL-004 in a real project with AGENTS.md files
2. **Behavior Verification** — Verify skill extracts correct commands, rules, and contracts
3. **Skill Usage Ledger Integration** — Record actual skill load/use/reject events
4. **Runtime Sandbox** — Basic sandbox for testing skill behavior without risk
5. **Trust Ladder Advancement** — Move CAP-SKILL-004 from verified → runtimeVerified after live trial

### Pre-conditions for R2.3-H

- [x] Audit pipeline operational
- [x] CAP-SKILL-004 audit passed
- [x] Negative controls verified
- [ ] Live project fixture with AGENTS.md (to be created)
- [ ] Runtime sandbox or safe execution context

### What R2.3-H Should NOT Do

- Do NOT batch-import multiple skills before first live trial
- Do NOT claim runtimeVerified without behavioral evidence
- Do NOT skip audit on any new skill candidate
- Do NOT connect to external APIs/MCP/cloud

### Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Audit false negatives | Medium | Regex-only; supplement with human review |
| Skill behavior mismatch | Medium | Live trial must verify behavior matches skill.json claims |
| Over-reliance on audit | Low | Explicitly enforced: auditPassed ≠ runtimeVerified |
| Pipeline maintenance | Low | Modular stages, clear regex patterns, documented false positive fixes |
