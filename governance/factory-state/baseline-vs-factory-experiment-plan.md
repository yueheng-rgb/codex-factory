# Baseline vs Factory Experiment Plan

## Candidate Task
Build a mini approval workflow system with role separation, four-eyes principle, immutable audit, and redaction.

## Bare-Agent Baseline
- Single Codex prompt: "Build a workflow approval system"
- No harness, no phase lock, no contracts, no worker isolation
- Single agent authors all code
- Pass/fail determined by manual inspection

## Factory-Controlled Method
- H7 pre-spawn contracts → H9 readiness → H10 worker capsules → spawn_agent workers → H8 post-spawn → H11 directness → acceptance
- 5 isolated workers with fork_context:false
- Machine-verified: RUN_STATE chain, acceptance evidence, derived metrics, verifier

## Metrics Compared
| Metric | Baseline Expected | Factory Expected |
|--------|------------------|-----------------|
| Architecture complexity | ~5 files, monolith | 50+ files, 5 workers |
| Live scenario count | ~3-5 | 24+ |
| Negative-control count | 0 | 18 |
| Evidence completeness | manual | machine-verified JSON |
| Phase stability | fragile | governed by phase lock |
| Worker isolation | none | H10 capsules/worktrees |
| Direct invariant coverage | implicit | H11 alias map |
| False PASS detection | none | DRY18-B negative controls + skeptic |

## Pass/Fail Criteria
Factory improves upper bound if:
- Live scenarios > 2x baseline
- Evidence is machine-readable and verifiable
- Negative controls detect injected faults that baseline misses
- Phase lock prevents stale-context continuation
- Worker isolation prevents cross-worker contamination

## What Counts as Evidence
- Baseline run with bare-agent output
- Factory run with full harness output
- Side-by-side comparison of scenario count, fault detection, evidence integrity

## Note
Do not run this experiment in H12 unless trivial. This is the plan only.
