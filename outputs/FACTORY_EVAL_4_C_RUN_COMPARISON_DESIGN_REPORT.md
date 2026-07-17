# FACTORY-EVAL-4 / C — Run Comparison Design Report

> Generated: 2026-06-25T17:10:00+08:00
> Section: C — Three-Run Comparison Design

---

## Design Principle

Three independent, isolated runs of the **identical** TeamFlow Lite benchmark. Same specification (Section B), same acceptance criteria, same evaluation rubric (Section D). Only the Factory configuration differs.

---

## Three Runs

### RUN-A: Vanilla Codex
| Aspect | Detail |
|---|---|
| Factory components | **NONE** |
| Codex mode | Default — no Factory skills, no MCP, no governance |
| Workspace | Fresh, no Codex_App_Factory |
| Input | Benchmark spec only |
| Expected behavior | Codex operates with its native capabilities |

### RUN-B: Factory Lite
| Aspect | Detail |
|---|---|
| Factory components | Manual Router + Proof-of-Read |
| Loaded artifacts | factory-manual-index.json, factory-page-router.json, factory-always-on-constitution.md |
| Workspace | Factory Manual Router available |
| NOT loaded | Role-Agent Model, taxonomy, profiles, contracts, drift detection |
| Expected behavior | Single-agent Codex with structured guidance and read verification |

### RUN-C: Factory Role-Agent
| Aspect | Detail |
|---|---|
| Factory components | Manual Router + Proof-of-Read + Role-Agent Company Model |
| Loaded artifacts | All Manual Router + all Role-Agent (taxonomy, model, profiles, contracts, drift) |
| Roles active | architect, backend-dev, frontend-dev, db-engineer, security-reviewer, qa-engineer, tech-writer |
| Expected behavior | Role-specialized agents with cross-role contracts and drift detection |

---

## Primary Metrics (Weighted)

| Metric | Weight | Better Direction | Measures |
|---|---|---|---|
| **Quality score** | 50% | Higher | Composite rubric score (0-100) |
| **Requirements covered** | 20% | Higher | FR01-FR11 criteria met (~55 total) |
| **Human interventions** | 15% | Lower | Times human had to unblock/guide |
| **Message turns** | 10% | Lower | Codex turns to complete (excl. eval) |
| **Tests passing** | 5% | Higher | Real tests with meaningful assertions |

## Secondary Metrics

- **Process overhead**: Extra turns on process artifacts (receipts, contracts, drift) — tracked for B and C
- **Code quality indicators**: Error handling, validation, security patterns, documentation

---

## Isolation Rules

| Rule | Enforcement |
|---|---|
| Separate workspaces | Fresh empty directory per run |
| Separate sessions | New Codex window per run |
| No cross-contamination | Run results invisible to subsequent runs |
| Same spec | Identical Section B spec for all |
| Same criteria | Identical acceptance criteria |
| Same rubric | Identical Section D rubric |

---

## Run Order

1. **RUN-A (Vanilla)** first — establish baseline without any Factory knowledge
2. **RUN-B (Factory Lite)** second — test Manual Router value against baseline
3. **RUN-C (Role-Agent)** last — test full model after prior runs inform expectations

Each run in a completely fresh session.

---

## Start Conditions

- [ ] FACTORY-EVAL-4 all sections PASS
- [ ] FACTORY-EVAL-5 explicitly authorized by user
- [ ] FINAL package SHA256 verified unchanged

**Status: NOT_STARTED** — design phase only.

---

## Next: Section D — Evaluation Rubric
