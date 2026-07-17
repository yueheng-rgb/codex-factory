# Build Mode — Project Intake

> Stage 0 of the Build Harness pipeline. Accepts project requirements or project path.

## Two Intake Paths

### Path 1: New Project
User describes what they want to build. Template: `templates/new-project-intake.template.json`

Fields: projectName, productGoal, userType, featureList, techStackPreference, complexityExpectation, deliveryGoal, constraints, mustHave, niceToHave, forbiddenActions.

### Path 2: Existing Project
User provides project path and goal. Template: `templates/existing-project-intake.template.json`

Fields: projectPath, projectGoal (CONTINUE/REPAIR/EXTEND/REFACTOR/DIAGNOSE_THEN_BUILD), knownIssues, userPriority, allowedModificationScope, forbiddenPaths, reportDocsPath, continueFromStage.

## Intake Output

After intake, the system produces:
- `{project}/.codex-factory/intake.json` — filled manifest
- Proof-of-Read confirmation (system confirms it understood the requirements)

## Gate

Proof-of-Read: Before proceeding to CLASSIFY, the system must confirm it correctly understood:
1. What the user wants
2. Whether this is new or existing
3. The user's primary goal (build? diagnose? repair? continue?)
4. Any constraints or forbidden actions

## Examples

See `examples/example-new-project-intake.json` and `examples/example-existing-project-intake.json`.
