# V5 Release Decision

Decision on 2026-09-15: **remain `5.0.0-preview.1`; no formal release**.
Code snapshot: `14684e78d2a5611bacb50c8ab5d20670fc2b9e8f`.

## Completed

- Native isolation supports `fork_context=false` as well as `fork_turns=none`;
  missing, malformed or conflicting isolation options still fail closed.
- Canonically installed role contracts are referenced instead of repeated in
  dispatch messages. Missing or changed profiles retain the full inline fallback.
- Same-input static replacement in two captured prompts reduced dispatch bytes
  from 3849 to 3226 (16.19%) and 4320 to 3701 (14.33%). Role-file reading remains
  mandatory; these are not total-context, token, speed or cost measurements.
- T5/T6 fixtures have independent seed/reference calibration, external grading,
  frozen inputs, shared budgets and regression coverage. T5 C uses controller
  guidance, not actual probe-module integration. T6 B/C have identical tasks.
- Windows 202 tests and Ubuntu 201 tests plus one platform skip passed; all three
  CI jobs passed. Tested tarballs were downloaded, rehashed and installed locally.
  See [delivery and provenance](V5_PREVIEW_HANDOFF.md).

## Release Blockers

1. Native handoffs expose an unresolved command-outcome boundary. A pre-fix
   reproduction failure, an absent optional-file diagnostic, and expected failing
   child processes asserted by a successful negative test can still block final
   Factory acceptance. Preserve the actual FAIL receipts. A future change needs
   trustworthy phase/parent-test/expected-exit evidence and negative regressions;
   do not simply allow exit 1, trust a self-declared exception, delete history, or
   weaken acceptance. Current `rg-files-v1` intentionally recognizes only a narrow
   standalone listing case. This conservative behavior is not a failing unit test.
2. Automatic trusted Hook delivery is not established on this host. The bounded
   read-only CLI probe timed out after 60 seconds; no Hook trust bypass was used.
   The successful native path used controller registration and recorded handoffs,
   not automatic Hook attestation. A reviewed installation must exercise the full
   Hook lifecycle before making that claim. Official [Hook trust documentation](https://learn.chatgpt.com/docs/hooks)
   describes the separate review requirement.

## Deferred Scope

- Actual diagnostic probe-module native integration and the frozen 18-run formal
  comparison remain unperformed. Public development cases do not establish model
  performance, semantic lesson selection or production success rates.
- Tokens, monetary costs and active inference time remain unknown. Avoid further
  prompt or concurrency tuning without measurements that include file reads and
  controller overhead.
- CI artifacts expire after 30 days. A permanent release channel, version tag and
  registry publication remain deferred; `private: true` is unchanged.

Native observations and their limitations are tracked in the
[evaluation index](V5_NATIVE_EVALUATION_INDEX.md). No old failed attempt is replaced
by a new run, and no automatic retry is used merely to obtain a green verdict.
