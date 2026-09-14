# Hypothesis-Guided Repair Probes

## Stage 3 Design

This implements the next slice of the approved evolution direction, not a new
application or an autonomous repair engine.

1. Type: local developer tool, extending the existing Factory CLI.
2. Architecture: TypeScript, synchronous local records, no new dependencies.
3. Resources: existing repair preparation, hashed drafts, file locks, path checks;
   hypothesis exploration as design inspiration, not imported agent infrastructure.
4. Roles/journey: controller reads a failed task, proposes two explanations and one
   distinguishing observation, user approves, CLI reads the observation, controller
   reviews the matching branch before requesting a normal repair.
5. Pages: none. CLI template, draft, show and observe commands.
6. API: local functions only; no HTTP service or arbitrary command executor.
7. Data: immutable draft bound to project/run/task/receipt, one observation per
   draft including file hash, timestamp and explicit approval text. No database.
8. Boundaries: explicit project-relative regular JSON file, at most 64 KiB;
   exclude credential paths and runtime/instruction state. No product writes.
9. Completeness: two distinct scalar predictions, failure-evidence references,
   rationale, branch-specific follow-up, review, idempotent observation,
   inconclusive result, unchanged original acceptance and repair limits.
10. Failure patterns: identical predictions; ungrounded hypotheses; missing field;
    wrong scalar type; stale diagnostics; changed source receipt; escaped paths;
    secret-containing input; repeat reads changing history; causal overclaiming.
11. Minimum slice: one predeclared JSON Pointer observation from an existing
    diagnostic output. Running an experiment or producing the diagnostic remains
    a separately authorized host action, not something this CLI performs.
12. Required paths: failure -> reviewed probe -> matching/inconclusive observation
    -> normal repair approval; malformed input rejects without changing a run;
    repeated observe returns the saved result without rereading newer data.

## Interpretation

The controller authors the hypotheses; Factory checks structure and receipt
binding, not scientific validity. A matching prediction is only a lead among the
two proposed explanations, not proof of causality. An unexpected value or absent
field is inconclusive. JSON type matters: `0` and `"0"` differ. Diagnostics may be
stale or fabricated; the saved hash proves bytes read, not who produced them or
which execution they describe. The controller must review their provenance.

Approval text is an explicit workflow record, not authenticated human identity.
Secret detection is heuristic, not DLP. No automatic repair, retry reservation,
agent dispatch, model training, acceptance relaxation or confidence percentage.

## Research

- [HypoExplore](https://github.com/JaywonKoo17/HypoExplore): hypothesis/evidence
  exploration in visual architecture research; adapted conceptually only.
- [RFC 6901](https://datatracker.ietf.org/doc/html/rfc6901): JSON Pointer tokens and
  escapes for deterministic field selection.
- [Node filesystem](https://nodejs.org/api/fs.html) and
  [crypto](https://nodejs.org/api/crypto.html): local reads and content hashes.
- [LangGraph interrupts](https://docs.langchain.com/oss/python/langgraph/interrupts):
  review/resume and idempotency inspiration, without a LangGraph dependency.

Research Evidence Pack and gate result: `.codex-work/probes/` (local work output).

## Use

From `packages/factory-cli`, run `npm run demo:probe -- --observe-demo` for the
offline end-to-end example. It uses explicitly simulated host receipts and a real
local JSON observation; it neither calls a model nor proves repair effectiveness.
Without `--observe-demo`, the demo stops at the reviewable draft.

For a real failed task, first run `repair prepare`, then author `probe.json` using
`probe template`. Replace all example causes, predictions and provenance with
task-specific information. Never reuse demo approval text for a real project.

```powershell
npm run cli -- probe draft --project C:\Projects\my-app --from-run run-001 --task worker --file probe.json --json
npm run cli -- probe show --project C:\Projects\my-app --id <probe-id>
# Only after the user reviews and approves the displayed draft:
npm run cli -- probe observe --project C:\Projects\my-app --id <probe-id> --draft-hash <hash> --reply <actual-approval> --json
```

The JSON result includes `source_evidence`, `observation_path` and `next_step`.
Use `probe repair-plan --id <id> --json` to preview a task containing the tentative
lead and exact evidence paths, without reserving an attempt. After normal repair
approval, use `repair create --from-run <same-run> --task <same-task> --probe <id>
--request-id <stable-id> --json`, then `run continue` on the returned repair.
The --probe, --reuse-task and --tasks modes are mutually exclusive. The original
locked repair checks and two-attempt limit still apply; repeated identical
requests return the same repair. BLOCKED returns no tasks, and EXISTING_REPAIR
means follow the existing child, not request another one.

For an explicitly selected published lesson, write the repair-plan JSON to a
task file, use `teach apply --tasks <file> --task <id> --id <lesson-id> --reason
<applicability>` and review the resulting ordinary task JSON for the existing
`repair create --tasks` route. No automatic task relevance inference or changed
acceptance is implied. `npm run demo:probe -- --repair-demo` demonstrates the
direct path through preparation and a worker dispatch plan, without starting a
native Agent or claiming a completed fix.

INCONCLUSIVE is not a license to choose either cause. Errors before observation
commit can be retried after fixing the input. Once observed, the draft always
returns its historical result; a new observation needs a revised, reviewed draft
with updated diagnostic provenance, not deletion of old records.
