# Transfer And Boundary Tasks

Two public, authored development variants from the existing six-task plan.
They are not held-out benchmarks, production incidents or Agent success results.
The other four planned tasks are not replaced or removed based on these outcomes.

| Task | Request | Behavior to observe |
| --- | --- | --- |
| T3 | Reconcile fulfilment receipts using the corrected legacy convention | Paraphrase recall, explicit catalog fallback, correct code transfer |
| T4 | Implement exact-text strict messages | Review of exclusions, withholding import guidance, no accidental normalization |

Each arm receives the same eight-source-file Node project, current contract,
history, old and corrected converter, public checks and allowed editing scope.
A is an ordinary Agent; B uses Factory orchestration and an independent Verifier;
C additionally has one pre-authored derived Skill and explicit controller review.
No arm is denied historical facts. The Skill is not claimed to have been learned
live, and its creation cost is not free. A/B may inspect and reuse the same source.

## Prepare

From `packages/factory-cli`:

```powershell
npm run eval:transfer
```

This creates six independent trial directories and a controller manifest, but
does not dispatch agents or start budget clocks. Preparation runs two reference
solutions and six negative calibration variants (unimplemented, wrong boundary,
negative zero). Calibration roots and the frozen external grader remain outside
trial roots. Input hashes are identical within each task's three arms.

Separation is by directory and Agent instructions, not OS access control. The
fixtures are public in this repository. An Agent that reads controller material
has a contaminated attempt, not a held-out success. Use fresh contexts without
this conversation or calibration output for actual trials.

## Controller Workflow

Use `node --import tsx scripts/eval-transfer-boundary.ts` for these commands:

1. Read the manifest's C shortlist. Review current requirements and the Skill's
   applicability and exclusions. A missing shortlist entry may be investigated
   through the existing `teach list/show` commands. Do not edit the task wording
   to improve recall or force a choice based only on the task ID.
2. For C, provide `review <manifest> <trial> <decision-json>`. The JSON contains
   `lesson_id` (an available ID or null) and a nonempty `reason`. The choice freezes
   once. It records catalog fallback and task bytes, not model reasoning costs.
   This is controller-stated review, not an automatic semantic classifier.
3. Call `dispatch <manifest> <trial> worker` immediately before actual native spawn.
   It prepares the Factory plan for B/C, or the plain prompt for A, admits the
   shared budget and returns the prompt and identifiers. It does not spawn.
   Do not pre-admit all six trials and leave them waiting. Keep model/reasoning
   settings the same across arms and preserve whatever the host actually reports.
4. Preserve actual host observations inside each root. Use the existing
   `live-eval.ts register` for B/C or `budget-bind` for A. Read `budget-status`
   before each wait; record waits/stops with `budget-observe`. The shared budget
   is 20 continuous wall-clock minutes, not active inference time. Unknown host
   state blocks further dispatch. See [budget protocol](../README.md#shared-budget).
5. B/C records completion through `live-eval.ts handoff`, then calls this script's
   `dispatch <manifest> <trial> verifier`. Register, wait and handoff that distinct
   read-only Verifier, then use the existing `factoryctl verify` command. A has
   no internal Factory Verifier but preserves its actual Worker completion.
6. The convenience dispatch covers the first Worker/Verifier pair. If repair is
   needed, use the existing `live-eval.ts repair/plan` and `budget-admit` with round
   2 and the linked run. The effective C task is stored in `eval-task.json` so the
   repair retains the same contract. Preserve the initial FAIL; use the existing
   run report for repair lineage. Never obtain a fresh budget for a repair.
7. After all native work terminates, use `grade <manifest> <trial>` once. It runs
   the frozen external checks, captures output and the artifact hash, and records
   code correctness separately from initial Factory status and budget compliance.
   Do not feed external grader output back for repair. Grade only after internal
   repair is finished; the grade is frozen and cannot be overwritten.

The external checks exercise prefix/case/Unicode identity, blank remainder,
duplicates, signed cents, positive zero, input mutation, validation and overflow.
They only enforce the visible current/history contracts. Wrong-boundary variants
demonstrate check sensitivity, not actual Agent mistakes.

## Interpretation

Keep three distinct observations: shortlist recall, controller choice, final
code behavior. `NO_LEXICAL_MATCH` does not prove the Agent cannot solve the task;
a candidate for T4 is not evidence that guidance was applied incorrectly.
The selector currently flags boundary overlap for review rather than interpreting
negation. Do not claim automatic semantic memory or autonomous conflict rejection.

Preparation time and controller apply time are local measured durations; model
review time/tokens/cost remain unknown. They are outside the current dispatch
window and must not be silently omitted from total-cost claims. No comparison of
fees or speed is supported by the prepared fixture alone.

List all six prepared trials and every admission when reporting a campaign.
Unrun, unresolved, host-error, over-budget and code-failure outcomes remain visible.
The initial Factory status may differ from a later repaired code result; report
linked runs separately. No automatic campaign runner or aggregate success-rate
claim is supplied by this development adapter.
