# V5 Native Evaluation Index

These are public synthetic development cases, not a frozen 18-run benchmark or
evidence of production success rates. Raw host observations and candidate files
are retained locally, not published as part of this source checkout.

| Historical case | Observed outcome | Important limit |
| --- | --- | --- |
| T3, first attempt, 2026-09-13 | All three arms interrupted by host usage limits | No completed comparison; original failures retained |
| T3, second attempt, 2026-09-14 | A/B/C external checks passed; B/C independently verified; all within 20 minutes | Existing helper was available to every arm; no correctness advantage observed |
| T4, 2026-09-13 | A/B/C external checks passed; B/C independently verified; all within 20 minutes | Controller rejected irrelevant learning; not automatic semantic selection |
| Normalize, 2026-09-15, source `880f2a6` | One Worker and one independent Verifier; Factory PASS; 365999 ms shared observed budget | Controller adapter, not trusted automatic Hook delivery; lower-bound was prepared but not run |

T3 second-attempt observed wall times were A/B/C: 263900 / 620013 / 1027201 ms.
T4 observed wall times were 229622 / 583105 / 528719 ms. They include controller
waiting and scheduling and must not be interpreted as pure inference time or a
causal performance comparison. Tokens, fees and active inference time are unknown.

Local raw archives: `outputs/FACTORY_T3_ATTEMPT2_NATIVE_20260914/`,
`outputs/FACTORY_TRANSFER_BOUNDARY_NATIVE_20260913/`, and
`.codex-work/native-current/`. These ignored directories are not public links.

Reproduction sources: [transfer/boundary fixtures](../packages/factory-cli/evals/transfer-boundary/),
[native adapter](../packages/factory-cli/scripts/live-eval.ts), and
[diagnostic/routine fixtures](../packages/factory-cli/evals/diagnostic-routine/README.md).
Fresh preparation and offline calibration never count as native executions.

## T5/T6 On 2026-09-15

Source: `14684e7`. Six Workers and four independent Verifiers completed and were
closed. All six final public/external code checks passed, frozen inputs were
unchanged, and every arm used one round within its shared 20-minute budget.
All four independent Verifiers proposed PASS, but Factory returned FAIL for all
four B/C runs. These are completed evaluations, not successful Factory deliveries.

| Case/arm | External code | Factory | Observed wall ms |
| --- | --- | --- | ---: |
| T5 A | PASS | Not applicable | 192212 |
| T5 B | PASS | FAIL | 650114 |
| T5 C | PASS | FAIL | 650649 |
| T6 A | PASS | Not applicable | 215369 |
| T6 B | PASS | FAIL | 543017 |
| T6 C | PASS | FAIL | 543445 |

T5 B preserved a pre-fix failing public test. T6 B preserved a failed check for an
absent optional file. Three Verifiers also listed expected failing CLI children
from successful negative assertions; two reported Git diagnostic failures. The
current command policy treats these reported nonzero exits as blocking. No
receipt was edited or discarded, and no no-op retry was used to obtain PASS.

T5 C was bounded controller guidance, **not probe-module integration**. T6 B/C
had identical task instructions. There is no demonstrated correctness advantage,
speedup or cost reduction. The small fixtures lacked Git initialization; directory
separation was not OS isolation. One shared T5 A/B terminal response was retained
after those Workers finished; later captures were per-agent. No external grader
feedback was supplied to an evaluated Agent.

[Public structured summary](evidence/V5_DIAGNOSTIC_ROUTINE_20260915.json) contains
code/receipt hashes, budgets and limitations, not authenticated host attestations.
The full local archive is `.codex-work/diagnostic-routine-20260915/`. Its first
aggregation incorrectly listed installer-created `.gitignore` files as unexpected;
the reviewed aggregation verifies their unchanged pre-dispatch baseline hashes.
Both aggregations and the original final code grades remain preserved.

See the [release decision](V5_RELEASE_DECISION.md) for the unresolved acceptance
boundary and automatic Hook validation requirements.
