# 10-Role Model — Archive Note

**Status**: ARCHIVED (reference only)
**Date Archived**: 2026-06-26
**Reason**: Replaced by 7-role model (5 core + 2 guardrail)

---

## What Was the 10-Role Model?

The 10-role model was an earlier design for multi-agent governance that included:

1. Main Agent
2. Architect
3. Builder (×3)
4. Integrator
5. Reviewer
6. Verifier
7. Integrity Checker
8. Deception Hunter (dedicated role, now folded into Integrity Checker)
9. Drift Monitor (dedicated role, now folded into Integrity Checker + Integrator)
10. Evidence Auditor (dedicated role, now folded into Integrity Checker)

---

## Why It Was Archived

Per **FACTORY-AGENT-0-C failure analysis**, the 10-role model proved:

- **Too many dedicated audit roles** — Deception Hunter, Drift Monitor, and Evidence Auditor overlapped significantly
- **Coordination overhead** — 10 agents communicating created excessive protocol chatter
- **Diminishing returns** — Additional guardrail roles beyond 2 did not improve detection rate

The 7-role model (5 core + 2 guardrail) provides equivalent coverage with less overhead:

- Integrity Checker absorbs: Deception Hunter + Drift Monitor + Evidence Auditor
- Verifier remains dedicated gate role
- 5 core roles unchanged

---

## Reference Materials

- Original 10-role design: `FACTORY-AGENT-0` architecture draft
- Failure analysis: `FACTORY-AGENT-0-C` run report
- Current model: See `roles/`, `policies/`, and `BOUNDARY.md`

---

## When to Revisit

The 10-role model may be worth revisiting if:

- A project exceeds 15 workers simultaneously
- Audit throughput becomes a bottleneck on Integrity Checker
- A new class of deception emerges that requires dedicated detection

For now, **do not default to 10 roles**. Use the 7-role model.

---

*End of Archive Note*
