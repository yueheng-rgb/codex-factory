# Factory evolution roadmap

This roadmap tracks small, testable increments for the Factory control plane. It is deliberately narrower than an autonomous learning system.

## Principle

Factory should improve three moments in local agent work:

1. Confirm intent before work starts.
2. Preserve narrow lessons from human-reviewed corrections.
3. Make repair decisions from explicit evidence instead of guesses.

Every increment must keep the original task contract, write scope, acceptance methods and independent verification path intact.

## Phase 1: result-contrast clarification

Status: implemented.

Goal: record one material behavior choice before planning work.

Delivered:

- `clarify template/create/show/choose`
- immutable draft and decision records
- confirmed task bundle accepted by `tasks validate` and `plan`
- verifier guidance to check selected examples
- offline demo and focused tests

Non-goals:

- autonomous ambiguity detection
- user authentication
- replacing running tasks or repair contracts

Details: [CLARIFICATION_PHASE1.md](CLARIFICATION_PHASE1.md).

## Phase 2: diff teaching

Status: implemented.

Goal: turn one user-designated Git file correction into a project-local candidate Skill after explicit approval.

Delivered:

- `teach template/capture/draft/show/list/suggest/publish/apply`
- source-bound lesson drafts with hashes, examples and counterexamples
- conflict checks for existing Skills
- bounded task attachment through `teach apply`
- offline demos and tests

Non-goals:

- model training
- whole-worktree harvesting
- automatic relevance decisions
- changing other task fields or acceptance

## Phase 3: hypothesis-guided probes

Status: implemented.

Goal: let a controller predeclare two plausible failure explanations and read one approved diagnostic JSON field to guide a repair task.

Delivered:

- `probe template/draft/show/observe/repair-plan`
- direct `repair create --probe` integration
- immutable observation history
- inconclusive handling and sensitive-path rejection
- offline demo and tests

Non-goals:

- running experiments
- proving causality
- consuming repair attempts before approval
- bypassing repair limits or existing child repairs

Details: [HYPOTHESIS_PROBES.md](HYPOTHESIS_PROBES.md).

## Measurement

Current evidence is local and bounded: unit tests, type checks, build checks, package dry-runs, demos and limited native comparison reports. Do not claim general success-rate, token-cost or wall-clock improvement from these slices alone.

Recommended next measurement:

- small native task set with frozen inputs
- per-run success/failure classification
- repair count and failure channel
- prompt size and host wall time
- explicit accounting for controller review effort

Stop adding features if the evaluation does not show where the current friction or failure actually is.
