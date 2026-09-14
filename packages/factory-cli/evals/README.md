# Native Agent Evaluation (Local Preview)

For the planned paraphrase-transfer and non-applicable-experience variants,
run `npm run eval:transfer`. It prepares a same-input A/B/C task pack with external
calibration and shared budget admission, without launching agents. See
[transfer and boundary workflow](transfer-boundary/README.md).

For assumption-based analysis without native agents, run `npm run eval:forecast`
from this package. It is a separate source-only conditional model with explicit
illustrative inputs, positive/negative scenarios and sensitivity calculations;
it never generates measured success rates or combines these estimates with the
native reports below. See [effect analysis](../../../docs/FACTORY_EFFECT_FORECAST.zh-CN.md).

This source-only suite exercises the existing Factory control plane with actual
host Worker/Verifier calls. It does not call a hosted Evals API, add dependencies,
choose another model, or fabricate Agent IDs. The controller must have permission
to use native sub-agents. Preparing cases does not launch agents.

## Cases

| Case | Category | Frozen acceptance |
| --- | --- | --- |
| normalize | Natural implementation | Input validation, Unicode, stable deduplication, prototype-like strings, nonmutation |
| lower-bound | Deliberately seeded defect + linked repair | Empty arrays, duplicates, endpoints, deterministic reference comparison |

Both cases are tiny, public, synthetic tests. They are a workflow smoke test, not
a representative benchmark, hidden evaluation set, or production success rate.
The seeded baseline Worker must inspect/test without editing; its expected FAIL
is excluded from natural first-attempt counts. The repair Worker later implements
the same original contract inside a linked run. A distinct read-only Verifier
reviews every attempt. Main-controller execution of acceptance is also required.

## Prepare And Run

From `packages/factory-cli`:

```powershell
npm run build
npm run eval:prepare
```

Preparation prints an isolated temporary directory and assignment IDs. Each case
is a fully initialized Factory project with its own scopes, context, baseline,
skills, local Git repository (no commit or remote), and immutable acceptance
script. Prior campaigns are not overwritten. Legacy campaigns created before
the Git preflight keep their original environment history.

Controller workflow (replace placeholders with actual returned values):

Newly prepared cases include a shared evaluation budget. Before **each** native
spawn, run `budget-admit` as described below; after registration follow the returned
budget action. Historical projects without a ledger retain their original behavior
and are reported as budget-unmeasured, not retroactively compliant.

1. Read each initial spawn plan. Call the host's actual spawn tool with fresh
   context and the declared role/scope. Workers edit only `solution.cjs`; Verifiers
   edit nothing. Do not delegate runtime bookkeeping to the evaluated agent.
2. Preserve the successful raw response under the case's
   `.codex-factory/host-observations/`, with controller timestamps and the actual
   tool name. Never turn an offline fixture into a native observation.
3. Register through `scripts/live-eval.ts register <root> <run> <assignment>
   <observation>`. The adapter labels its own metadata separately and preserves
   `host_response` verbatim inside the existing receipt format.
4. Wait for actual completion. Preserve the original wait response with
   `tool: multi_agent_v1__wait_agent`, `started_at`, `returned_at`, and `response`.
   A completed turn retrieved through `mcp__codex_app__read_thread` is also
   supported after interruption; preserve its actual parsed response and tool name,
   not an invented wait result. Keep earlier failed host turns in separate records.
5. Require a final `FACTORY_HANDOFF_JSON=` line. Use
   `scripts/live-eval.ts handoff <root> <run> <assignment> <observation>`.
   It binds the completion to the registered Agent, normalizes project-contained
   absolute paths, and calls the existing handoff validation. The original host
   response is never changed by normalization.
   The required shape is `artifacts:[{path:"solution.cjs",sha256:"<64 hex>"}]`,
   not an array of filenames; `proposed_verdict` is PASS, FAIL or BLOCKED.
   Store malformed candidate observations in a `rejected/` subdirectory and ask
   the same Worker to correct the format without deleting command failures.
6. Use `scripts/live-eval.ts plan <root> <run>` to get the independent Verifier
   assignment. Repeat spawn/register/wait/handoff, then use
   `node dist/cli.js verify --project <root> --run <run> --task worker
   --verifier-assignment <id>`. A FAIL receipt is a real evaluated result, not an
   excuse to change checks or fake a passing command.
7. Before repair, run `scripts/live-eval.ts checkpoint <root>` to freeze the
   initial run's file snapshot. Pass the original task (stored in
   `.codex-factory/eval-task.json`, wrapped in a task array) to `repair create`.
   Use a stable request ID. Plan/dispatch/verify the returned linked run without
   resetting the old task. Confirm prior host execution stopped before retrying.
   For the first repair of these fixed cases, the shorthand
   `scripts/live-eval.ts repair <root> <request-id>` checkpoints the initial run
   and uses the preserved original task directly.
   An optional final `<from-run>` argument targets a later failed repair; the
   runtime repair cap still applies; new evaluation budgets are stricter:
   at most two Worker rounds total, including the initial round.

These scripts run via `node --import tsx scripts/live-eval.ts ...`.
The workflow is controller-driven, not an unattended runner. Reusing the native
host adapter does not prove automatic Hook delivery or trusted Hook installation.

## Shared Budget

Commands use `node --import tsx scripts/live-eval.ts` from this package:

```powershell
# Before spawning round 1's Worker (round 2 is the single repair).
node --import tsx scripts/live-eval.ts budget-admit <root> <run> <assignment> worker 1
# Spawn through the actual host, capture its response, then use existing register.
node --import tsx scripts/live-eval.ts register <root> <run> <assignment> <spawn-observation>
node --import tsx scripts/live-eval.ts budget-status <root>
# Preserve each actual wait/close response and its controller timestamps.
node --import tsx scripts/live-eval.ts budget-observe <root> <agent> <observation>
```

- Defaults: 20 minutes from the first admission, two Worker rounds, one active
  admission per trial. Worker, Verifier, repair, controller gaps and quota waits
  share one uninterrupted **wall-clock** window. This is not active model time.
  Preparation before admission is excluded; Skill construction must be measured
  separately, not assumed free. No automatic pause, budget reset or hidden resume.
- `DISPATCH_ALLOWED` authorizes one spawn for the named assignment. `register`
  binds the actual host ID; it rejects absent admission. A slow spawn is retained
  even after deadline so the controller can stop that ID. Do not spawn again.
- Before every wait, read `budget-status`. `WAIT` supplies a timeout of at most
  30 seconds and at most the remaining window. Less than 10 seconds remaining
  yields `STOP_REQUIRED` rather than an oversized normal wait.
- On `STOP_REQUIRED`, call the native close tool for that agent and preserve its
  response. `budget-observe` then returns `CONFIRM_STOP_REQUIRED`: close reports
  previous status, not proof of termination. A bounded host status check must
  confirm shutdown/completion/error. Stop-confirmation overhead can exceed the
  window and stays in `overrun_ms`; unknown/not-found state does not clear a slot.
  If admission exists but the spawn response was lost, recover that response;
  do not invent an ID or drop the slot. No next dispatch while unresolved.
- Normal handoff records the same native completion into the budget, including
  when `budget-observe` has already captured it. Budgeted handoffs currently need
  native wait evidence; recovered thread timing remains unresolved. Verifier uses
  a separate admission with `verifier` and the same round/run. Any additional
  Worker dispatch consumes the next round; this bounded protocol does not grant
  unlimited same-round resumes, including handoff-format corrections.
- For a plain-Agent A arm, use `budget-init <root>`, then the same admission
  protocol with `budget-bind <root> <run> <assignment> <spawn-observation>` instead
  of Factory registration. The ledger is controller-owned and not Agent guidance.
  This makes the helper usable in all arms; the archived pilot controller is not
  modified or automatically upgraded to this protocol.
- This is **cooperative controller enforcement**, not a host-independent watchdog.
  It cannot kill a native Agent while this controller is suspended. CLI exit 0
  means a record was processed, not permission to continue: inspect `action`.
  Sequential controller ownership is required; a local ledger is not trusted
  host attestation or protection against manual file tampering.

`budget-status` supplies elapsed wall time, overrun, rounds, observed terminal
states and observation hashes. Raw responses are retained in `eval-budget.json`.
`within_budget: true` says only that the captured intervals were within limits,
not that the task passed. Tokens, money and active execution time remain null.
The normal report includes budget data beside quality results. If a timeout or
host error leaves Factory handoff evidence incomplete, normal summarization can
still reject it; preserve `budget-status` and list the trial as interrupted or
over-budget, never drop it or count it as a quality PASS.

## Report

```powershell
npm run eval:report -- C:\path\to\manifest.json
npm run eval:typecheck
```

The report checks the frozen acceptance digest, runtime evidence, native response
hashes, captured completions against recorded handoffs after path normalization,
repair lineage and original-run snapshot. It lists
every run found; an unlinked or incomplete/corrupt run cannot silently disappear
from the metrics. Unfinished host execution without completion is rejected.

`tokens` and `cost` remain null unless the relevant host actually reports them.
Account-wide usage percentages are not per-evaluation token or cost measurements.
Host wall time includes controller delays, suspension and polling; recovered host
turn timing is labelled separately. Do not compare interrupted wall time with
uninterrupted inference speed or promote a one-case pass into a success-rate claim.

New receipts use the versioned `rg-files-v1` command policy: exit 1 from a
recognized standalone `rg --files` listing is retained as `NO_MATCH`, not failure.
Explicit acceptance commands, exit 2/errors, unknown options, shell wrappers and
compound commands remain blocking. Do not remove or change reported exit codes.
Receipts without a policy marker retain the old strict nonzero-fails semantics;
historical FAIL runs are not upgraded or rewritten. This is a narrow runtime
classification, not an evaluator override or general permission to ignore errors.

Temporary projects are retained for inspection. Archive their actual files before
OS temporary cleanup if long-term evidence is needed; a summary alone is not a
substitute for the project, frozen checks and receipts.

## Evaluation Rationale

Task-specific checks, edge cases, explicit metrics and preserving logs follow
[OpenAI's evaluation guidance](https://developers.openai.com/api/docs/guides/evaluation-best-practices).
The implementation uses existing local contracts only; it does not integrate the
hosted Evals platform. Research gate classification: P2 test supplementation.
