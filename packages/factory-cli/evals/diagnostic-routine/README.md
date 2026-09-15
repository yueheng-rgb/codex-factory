# Diagnostic And Routine Development Variants

T5 and T6 supplement the approved six-task design in
`outputs/FACTORY_CAPABILITY_EVAL_PLAN_20260912.md`. These are public, authored
development fixtures, not the frozen 18-run formal benchmark, unseen evaluation,
natural incidents, or evidence of Agent performance.

| Case | Work | C treatment |
| --- | --- | --- |
| T5 | Localize one injected mapping defect that produces an incorrect total | Bounded controller guidance to compare hypotheses and inspect the shared diagnostic before editing |
| T6 | Add the completely specified `summary.returnCount` field | Same orchestration as B; no lessons or probes |

Each fresh project contains seven small source modules plus a CLI, reproduction
data, a complete visible contract and public tests. Business inputs and initial
source bytes are identical across A/B/C within each case. T5 offers multiple
editable layers; its task does not name the defective layer. Every arm can run
`node cli.cjs diagnose data/repro.json` and inspect `mappedDeltaCents`. The frozen
contract specifies the expected reproduction output without a solution patch.

T5 C is **controller guidance, not actual probe-module integration**. Actual probe
integration requires an independently failed Factory run; this adapter does not
create such a run or claim to have tested that module. T6 adds no capability
treatment, so its B/C comparison alone cannot establish a capability benefit.

## Preparation And Grading

From `C:/Codex_App_Factory/packages/factory-cli`:

```powershell
node --import tsx scripts/eval-diagnostic-routine.ts prepare
node --import tsx scripts/eval-diagnostic-routine.ts grade "<trial-root-from-prepare>" t5
node --import tsx scripts/eval-diagnostic-routine.ts grade "<trial-root-from-prepare>" t6
node --import tsx --test tests/diagnostic-routine.test.ts
```

`prepareDiagnosticRoutine()` is also exported for tests. Preparation returns the
temporary campaign directory, controller manifest, six trial roots, plain or
managed prompts, budget locations and actual **planned assignment** identifiers.
It runs each case's reference and incorrect seed through both public tests and
the external grader. All four calibrations must match before preparation returns.
No git operations, model calls, native spawns, receipts or budget admissions occur.

The controller owns references/calibration roots, per-case graders, SHA-256
input maps, aggregate business-input hashes, fixture/adapter hashes, grader hashes,
and a manifest digest. References and external tests are never copied into Worker
roots. Public tests, diagnostic code, CLI, data and contract are hash-frozen;
changing or deleting one causes grading to fail before running candidate tests.
Editable source is checked by behavior, not by matching reference patch text.

`gradeDiagnosticRoutine(root, caseId)` and `grade` return an offline code check,
not a native success verdict. They check both public and external behavior,
capture artifact hashes and report the existing budget separately. A seeded root
can be graded without inventing a native attempt. CLI exit zero means a grade was
produced; inspect `code_pass` for correctness. Invalid arguments, controller
manifest tampering and grader tampering exit nonzero. Repeated offline grading is
allowed for development; the caller must preserve every result and must never
feed external checks back to an evaluated Agent for repairs.

External checks cover signs, zeros, duplicate IDs, exact output shapes, input
preservation, empty/maximal inputs, validation, CLI reproduction and diagnostic
consistency. They enforce only the visible contract.

## Later Native Controller Use

A receives an ordinary independent task prompt with no Factory installation or
internal Verifier. Its budget lives at the returned controller `budget_root`.
B/C install Factory and prepare a scoped Worker assignment with a dependent,
read-only independent Verifier. The Verifier remains pending until real Worker
completion is captured. Planned assignment IDs are not native Agent IDs.

All arms use the existing `initializeBudget` defaults: 20 continuous wall-clock
minutes and at most two Worker rounds. B/C share that window with their Verifier.
Preparation leaves every budget idle. Admission must happen immediately before
actual native dispatch, with identical model/reasoning settings and fresh contexts.
Use the existing `scripts/live-eval.ts` budget and receipt commands:

1. `budget-admit <budget_root> <run> <assignment> worker 1`. For A, controller
   labels such as `plain` and `plain-worker` are bookkeeping keys, never native IDs.
2. Dispatch externally with no inherited conversation. Capture the real native
   response. B/C use `register <root> initial <assignment> <observation-json>`;
   A uses `budget-bind <budget_root> <run> <assignment> <observation-json>`.
3. Consult `budget-status <budget_root>` before waiting; record actual wait/stop
   observations using `budget-observe <budget_root> <agent> <observation-json>`.
4. B/C capture `handoff`, then use `plan <root> initial` to obtain the independent
   Verifier assignment, admit it as `verifier 1`, and register/capture its actual
   completion. Existing Factory verification decides its own verdict.
5. Repairs use the existing linked repair workflow and round 2 in the same budget.
   Preserve first failures. Run external grading only after final delivery and
   record code correctness, native outcome, Factory verdict and budget separately.

This adapter does not dispatch or coordinate those native calls. No model has
been evaluated by preparing or unit-testing these files. The grader deliberately
does not infer live success from code passing or a planned Factory graph.

## Limits

Directory separation and hashes are not OS isolation or authenticated sealing.
The fixture/reference source is public in this repository; access to controller
material contaminates a trial. Candidate code executes in a local Node process,
not a security sandbox. Use separate access-controlled environments when stronger
separation is required. Keep controller paths and calibration output out of Worker
contexts. Tests are logically immutable via controller checks, not filesystem ACLs.

Preparation cost is measured separately from admission. Tokens, actual fees and
active inference time are unknown. The budget is controller-cooperative and cannot
independently terminate a host. There is no campaign aggregate, hidden-test claim,
18-run result, speed/cost improvement claim, or actual probe integration result.
The adapter and fixture are included in `npm run eval:typecheck`; its regression
tests run with `npm test`. `npm run eval:diagnostic` prepares a fresh campaign.
