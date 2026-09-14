# Result-contrast clarification: phase 1

Design direction approved in the conversation on 2026-09-11. This implements the
first of four exploratory directions, not an autonomous learning framework.

## Project Expertise Flow

1. Type: existing local developer tool; Router has no exact CLI category. Do not
   misclassify the hospital example as a new hospital system.
2. Architecture: existing Node/TypeScript monolith, local JSON and file locks.
3. Resources: existing task validator, atomic writer, managed controller skill;
   HumanEvalComm and AskBench inspire clarification, not runtime dependencies.
4. Roles/journey: main controller proposes; user selects or rejects both; worker
   implements only confirmed behavior; independent verifier checks examples.
5. Surfaces: CLI create/show/choose, readable comparison and JSON, no web pages.
6. API outline: local createClarification, inspectClarification,
   chooseClarification, readConfirmedClarificationTasks. No HTTP endpoints.
7. Data: immutable draft plus one decision containing generated tasks; local
   project IDs, content hashes, creation/confirmation timestamps. No new DB.
8. Boundaries: controller records an explicit user reply; no automatic default,
   no command execution during clarification, no new write scope. This is not
   authentication of the human behind a CLI invocation.
9. Completeness: exactly two options for one critical ambiguity; shared example
   input with distinct outcomes; inspect after interruption; explicit selection;
   repeated same selection is idempotent; reject stale hashes/contradictions;
   selected examples travel into task description and verifier context.
10. Main failure patterns: vague examples; incomparable inputs; identical outputs;
    guessed consent; forced binary answers; stale comparison; double selection;
    changed base scope; dropped original acceptance; treating examples as PASS.
11. Minimum slice: draft -> readable comparison -> choose with displayed hash
    and actual reply -> confirmed tasks -> existing validate/plan pipeline.
    The main agent authors semantic alternatives. CLI is a deterministic recorder
    and compiler, not a standalone natural-language ambiguity detector.
12. Paths to check: choose either behavior and inspect its plan; reject an
    unconfirmed draft as task input; repeat choice; reject different repeat;
    preserve base acceptance/scope; verifier sees selected examples; old task
    files still work. One end-to-end offline demo, focused tests, normal build.

## Scope

A draft contains a single independent pending worker task, the original request,
one question and two options. Each option has an ID, label, requirement and up to
three paired examples. Each example has a shared `input` and contrasting
`expected_output`. A task keeps its original executable acceptance methods; the
worker must encode selected examples in its scoped tests and the verifier must
inspect them. The CLI does not turn arbitrary example text into shell commands.

Confirmation writes a single atomic decision bundle, never starts a run. The
bundle includes only the selected behavior in the generated task description.
`tasks validate` and `plan` accept this bundle after checking it against the
stored draft/decision. Raw task arrays remain supported; this workflow is not
a security boundary against an actor who can rewrite arbitrary project files.

When neither option fits, do not confirm. The controller clarifies in free text,
creates a revised draft, shows it and asks again. A decision cannot modify a
running task or replace an original repair contract. No global preference memory.

## Research

- https://github.com/jie-jw-wu/human-eval-comm
- https://github.com/jialeuuz/askbench
- https://docs.langchain.com/oss/python/langgraph/interrupts
- https://nodejs.org/api/fs.html
- https://nodejs.org/api/crypto.html

Live-source Evidence Pack v2 and implementation gate are generated under
`.codex-work/clarification/`. LangGraph is not installed. No benchmark gain,
original-research novelty, or universal ambiguity detection is claimed.

## Milestone (2026-09-11)

Implemented template/create/show/choose CLI, immutable comparison and decision
records, selected-example task compilation, confirmed-bundle input for the
existing validator/planner, controller Skill instructions and verifier guidance.
No dependencies added; no changes to the original acceptance engine.

Verification: TypeScript build; six focused clarification tests; the existing
full suite passed 146/146. The offline demo traversed the real CLI from a pair of
contrasting outputs to a selected, validated task and initial plan. Native model
execution and reduction in user rework are not measured in this phase.

Run `npm run demo:clarify` from `packages/factory-cli` to view the comparison, or
append `-- --option keep-last` to preview a selected plan in a fresh temp project.
This deliberately does not fabricate a human reply outside the labeled demo or
claim a plan is an implemented product. The next separate phase is learning a
candidate reusable Skill from a user-supplied code diff.

The legacy research gate was run with Windows PowerShell 5.1: PowerShell 7's
automatic JSON date conversion changes the hash representation in that legacy
script. The gate was not relaxed or modified. Repository-wide diff whitespace
checks report pre-existing Markdown hard breaks in RUNTIME_VALIDATION_REPORT.md;
that unrelated file was left unchanged by this phase.
