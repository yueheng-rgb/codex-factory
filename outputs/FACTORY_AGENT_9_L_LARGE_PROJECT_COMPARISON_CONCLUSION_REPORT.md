# FACTORY-AGENT-9 / Large Project Comparison Conclusion

**Date:** 2026-06-26T18:32:02.0582125+08:00  
**Verdict:** MULTI_AGENT_NO_BENEFIT (for OpsFlow Enterprise Lite)  
**Conclusion Type:** EVIDENCE_BACKED_NEGATIVE  

---

## Executive Summary

Independent comparison of three OpsFlow Enterprise Lite implementations:
- **RUN-LP-A (Vanilla Codex):** 85.5/100 — Highest product quality
- **RUN-LP-B (v0.4 Factory Lite):** 66.0/100 — Lowest, missing services
- **RUN-LP-C (v0.5 Agent Company):** 80.0/100 — Below Vanilla on product quality

**v0.5 Agent Company Mode does NOT demonstrate multi-agent benefit on this benchmark.**

## Key Evidence

1. Vanilla Codex produced the most feature-complete product (40 endpoints, 5 services, 168 exports)
2. v0.5 Agent Company scored 80.0 vs Vanilla's 85.5 on product quality dimensions
3. v0.5's process overhead (7 agents, orchestration, gatekeepers) is 3-4x Vanilla
4. v0.5 has superior evidence quality (25/25 verifier, anti-deception gate) but this doesn't translate to better product
5. All 3 runs miss AGENT-5 complexity floors (none reach 80+ source files or 300+ exports)

## Success/Failure Thresholds

| Condition | Met? |
|-----------|------|
| v0.5 > v0.4 product score | YES (80 > 66) |
| v0.5 > Vanilla product score | **NO (80 < 85.5)** |
| Hidden fallback = 0 | YES |
| Anti-deception gate PASS | YES |
| Phase closure gate PASS | YES |
| All agents closed | YES |
| Overhead < 2x Vanilla | NOT CONFIRMED |

**Falsification threshold triggered:** v0.5 does NOT exceed Vanilla on product quality.

## What This Means

- **Not:** Multi-agent is worthless
- **Not:** v0.5 should be abandoned
- **IS:** On OpsFlow Enterprise Lite (a ~40-requirement benchmark), Vanilla Codex is the better choice
- **IS:** Agent Company overhead is only justified when it improves product outcomes
- **IS:** Evidence quality gains (anti-deception, registry, lifecycle) are real but don't compensate for lower product quality

## Recommendation

1. Do NOT declare multi-agent as default
2. Consider multi-agent for larger projects (60+ requirements, 20+ modules)
3. v0.5 evidence quality mechanisms could be ported to v0.4 without full Agent Company
4. Next benchmark should test a larger project where worker isolation may prevent defects that Vanilla introduces