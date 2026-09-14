# Lesson selection notes

Factory teaching stores project-local lessons, but it does not know semantic relevance by itself. Selection is intentionally conservative.

## Current selector

`teach suggest` produces a lexical shortlist for one pending task. It reports matched terms and boundary-overlap terms so the controller can review them.

This is not a probability, ranking guarantee or permission to apply a lesson automatically.

## Required review

Before using `teach apply`, the controller must check:

- the lesson is published, not only drafted
- `applies_when` matches the current task
- `do_not_apply_when` does not match
- the counterexample is not closer to the current task than the positive example
- applying the lesson does not weaken acceptance, expand scope or conflict with user requirements

`teach apply` requires a written reason explaining why the conditions match. The output should be reviewed like any other task input before `tasks validate`, `plan` or `repair create --tasks`.

## Evaluation boundary

Existing fixtures test that suggestions are discoverable, exclusions are visible, changed Skills are rejected and one selected lesson can be attached without rewriting unrelated task fields.

These checks do not prove:

- broad semantic recall
- general task success-rate improvement
- reduced token cost
- autonomous transfer

Use the selector as a review aid. Keep the final decision with the controller and the actual user-approved task contract.
