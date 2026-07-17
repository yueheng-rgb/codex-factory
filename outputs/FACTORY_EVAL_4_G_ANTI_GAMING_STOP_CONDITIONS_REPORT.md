# FACTORY-EVAL-4 / G — Anti-Gaming Controls & Stop Conditions Report

> Generated: 2026-06-25T17:25:00+08:00
> Section: G — Anti-Gaming Controls and Stop Conditions

---

## Anti-Gaming Controls (14 Controls)

| ID | Gaming Attempt | Detection Mechanism |
|---|---|---|
| AG01 | File count inflation | File count recorded as metadata only; not in scoring rubric |
| AG02 | Export count inflation | D01 checks feature existence, not export counts |
| AG03 | Fake tests (assert(true)) | D07 requires meaningful assertions; evaluator inspects source |
| AG04 | Placeholder/TODO features | Binary FR scoring — no credit for stubs |
| AG05 | Markdown-only completion | Evaluator verifies endpoints and UI independently |
| AG06 | Factory code as product | Evaluator checks for Factory-specific patterns in project code |
| AG07 | Role-agent overuse for trivia | Process overhead tracked separately; excessive spawns flagged |
| AG08 | Proof-of-read spam | Receipts counted but process overhead tracked; not scored |
| AG09 | Artificial cross-role contracts | Contracts tracked but not scored |
| AG10 | Process artifacts over product | Rubric D01-D08 measure product only |
| AG11 | Hidden human assistance | Human intervention count tracked per run |
| AG12 | Post-hoc requirement changes | Spec frozen before any run; SHA256 recorded |
| AG13 | Different requirements per run | Same spec SHA256-verified for all three runs |
| AG14 | Run contamination | Separate workspaces, sessions, directories; cross-reference checks |

---

## Stop Conditions (10 Conditions)

| ID | Condition | Trigger | Action |
|---|---|---|---|
| SC01 | Project too small | FR needs < 2 endpoints or < 1 page | STOP — redesign |
| SC02 | Project too large | Run > 200 turns, < 50% criteria met | STOP — reduce scope |
| SC03 | Evaluation incomparable | Different stacks or scope across runs | STOP — enforce consistency |
| SC04 | Vanilla uses Factory | Factory patterns in Vanilla output | STOP — restart with isolation |
| SC05 | Different requirements | FR coverage deviates >10% from spec | STOP — restart with same spec |
| SC06 | Missing artifacts | No runnable project or source files | STOP — record as run failure |
| SC07 | Tests can't run | Test suite fails, no workaround | STOP — D07=0, record caveat |
| SC08 | FINAL package modified | SHA256 mismatch vs handoff | STOP — integrity violation |
| SC09 | New final ZIP | Any ZIP not the verified FINAL | STOP — integrity violation |
| SC10 | SHA mismatch | SHA256 verification fails | STOP — integrity violation |

---

## Next: Section H — Negative Controls
