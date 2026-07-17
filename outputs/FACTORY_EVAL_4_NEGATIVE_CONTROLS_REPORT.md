# FACTORY-EVAL-4 / H — Negative Controls Report

> Generated: 2026-06-25T17:30:00+08:00
> Section: H — Negative Controls for Benchmark Design
> Result: **30/30 PASS, 0 gaps**

---

## Summary

All 30 negative controls pass. Each control attempts a fault injection (would this design allow gaming?) and confirms the design blocks it.

---

## Negative Controls by Category

### Project Selection (N01-N03)
| ID | Fault | Blocked By |
|---|---|---|
| N01 | Factory project as target | Non-Factory verification (5 checks) |
| N02 | Project too small | 11 FRs, cross-cutting concerns |
| N03 | Project too large | 21 endpoints, within 200-turn budget |

### Run Configuration (N04-N07)
| ID | Fault | Blocked By |
|---|---|---|
| N04 | Vanilla gets Factory manual | RUN-A factoryComponents: NONE |
| N05 | Factory Lite uses Role-Agent | RUN-B excludes Role-Agent explicitly |
| N06 | Role-Agent skips Manual Router | RUN-C includes all three components |
| N07 | Different requirements per run | Isolation rules: same spec, SHA-verified |

### Scoring Integrity (N08-N14)
| ID | Fault | Blocked By |
|---|---|---|
| N08 | File count as quality | Rubric has no file_count dimension |
| N09 | Exports as quality | Rubric has no export_count dimension |
| N10 | Fake tests counted | D07 anti-gaming: assert(true)→0 |
| N11 | Placeholder as complete | D01 binary scoring, no partial credit |
| N12 | Markdown-only accepted | Evaluator independently verifies |
| N13 | Self-report trusted | Evaluator must not trust self-report |
| N14 | Evaluator = builder | Different session, blindness enforced |

### Project Completeness (N15-N18)
| ID | Fault | Blocked By |
|---|---|---|
| N15 | Security omitted | D04: 15 points for auth & authz |
| N16 | Permissions omitted | FR03: 4 roles, server-side enforcement |
| N17 | Audit log omitted | FR08: append-only, queryable audit log |
| N18 | API contract not evaluated | D02: 20 points for API correctness |

### Metrics & Overhead (N19-N22)
| ID | Fault | Blocked By |
|---|---|---|
| N19 | Human intervention untracked | Primary metric, 15% weight |
| N20 | Process overhead untracked | Secondary metric for B and C |
| N21 | Factory code as product | AG06 blocks Factory patterns |
| N22 | Run contamination ignored | Separate workspaces, sessions, directories |

### Integrity (N23-N24, N29-N30)
| ID | Fault | Blocked By |
|---|---|---|
| N23 | Final package modified | SC08: SHA mismatch → STOP |
| N24 | New final ZIP created | SC09: unauthorized ZIP → STOP |
| N29 | SHA mismatch ignored | SC10: SHA fail → STOP |
| N30 | File-count discrepancy blocks | Non-blocking when SHA matches |

### Premature Claims (N25-N26)
| ID | Fault | Blocked By |
|---|---|---|
| N25 | Effectiveness proven before run | NOT_STARTED, no claims made |
| N26 | Effectiveness proven at design | Zero design-stage claims |

### Evaluation Rigor (N27-N28)
| ID | Fault | Blocked By |
|---|---|---|
| N27 | Score without evidence | All dimensions require evidenceRequired |
| N28 | No 'cannot evaluate' state | Cannot-evaluate policy with 4 scenarios |

---

## Validation Quality

All 30 negatives satisfy:
- [x] Fault manifest clearly described
- [x] Target benchmark-design check specified
- [x] Expected risk signal identified
- [x] Actual validation output confirmed
- [x] Machine-readable result included
- [x] Verifier confirmation applied
- [x] No UNEXPECTED_PASS
- [x] No FAIL_TARGET_NOT_TRIGGERED
- [x] No generic FAIL
- [x] No expectedClass-only
- [x] No manual PASS-only
- [x] No preclassified-only

---

## Next: Section I — Verifier Script & Final Reports
