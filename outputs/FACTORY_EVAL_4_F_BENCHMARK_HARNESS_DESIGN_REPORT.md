# FACTORY-EVAL-4 / F — Benchmark Harness Design Report

> Generated: 2026-06-25T17:22:00+08:00
> Section: F — Benchmark Harness Design

---

## Harness Components (7 Scripts, Design-Only)

| ID | Script | Purpose |
|---|---|---|
| H01 | `create-fixture.ps1` | Creates fresh workspace with benchmark spec for a run |
| H02 | `inventory-artifacts.ps1` | Scans run output, produces file inventory JSON |
| H03 | `check-requirements.ps1` | Structural pre-check of FR01-FR11 coverage |
| H04 | `check-structure.ps1` | Verifies expected directory/file patterns exist |
| H05 | `check-api-contract.ps1` | Curl-based endpoint existence check |
| H06 | `run-tests.ps1` | Runs test suite, captures pass/fail |
| H07 | `generate-eval-report.ps1` | Produces structured evaluation JSON from scores |

### Evaluation Orchestrator
- `benchmark/teamflow-lite/evaluation/full-evaluation.ps1` — Runs H02→H03→H04→H05→H06→H07 pipeline

---

## Directory Structure

```
benchmark/teamflow-lite/
├── spec/
│   ├── benchmark-spec.md          (Section B copy)
│   └── evaluation-rubric.md       (Section D copy)
├── fixtures/
│   ├── run-a-fixture/             (Vanilla workspace seed)
│   ├── run-b-fixture/             (Factory Lite workspace seed)
│   └── run-c-fixture/             (Role-Agent workspace seed)
├── harness/
│   ├── create-fixture.ps1         (skeleton)
│   ├── inventory-artifacts.ps1    (skeleton)
│   ├── check-requirements.ps1     (skeleton)
│   ├── check-structure.ps1        (skeleton)
│   ├── check-api-contract.ps1     (skeleton)
│   ├── run-tests.ps1              (skeleton)
│   └── generate-eval-report.ps1   (skeleton)
├── evaluation/
│   └── full-evaluation.ps1        (skeleton)
└── results/
    ├── run-a/
    ├── run-b/
    ├── run-c/
    └── comparison/
```

---

## Anti-Gaming Notes

- File counts from H02 are recorded but **never** used as quality scores
- H03 is a **structural pre-check only** — final scoring by independent evaluator
- H05 checks endpoint existence only — response quality scored by evaluator
- All harness scripts are run **after** the builder completes — builders cannot use harness to cheat

---

## Implementation Status

**DESIGN_ONLY** — script skeletons deferred to FACTORY-EVAL-5 (Vanilla baseline) and subsequent phases.

---

## Next: Section G — Anti-Gaming Controls & Stop Conditions
