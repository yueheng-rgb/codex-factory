# Build Mode — Mode Selector

> Stage 2 of the Build Harness pipeline. Routes project to execution mode.

## Six Modes

| Mode | Complexity | Agents | Default |
|------|-----------|--------|---------|
| VANILLA_BUILD | SMALL | 1 | YES |
| BUILD_LITE | MEDIUM | 1 + harness | No |
| BUILD_REVIEWER | LARGE | 1 + Reviewer | No |
| BUILD_CONTINUATION | LONG_HORIZON | 1 + state | No |
| BUILD_PRO_4_AGENT | HIGH_RISK | 4 | No* |
| DIAGNOSTIC_ONLY | Any | 1 | No |

*Requires explicit user approval. Never automatic.

## Routing Rules

1. User goal = DIAGNOSE_ONLY → DIAGNOSTIC_ONLY, stop after
2. HIGH_RISK → BUILD_PRO_4_AGENT (requires approval)
3. LONG_HORIZON → BUILD_CONTINUATION
4. LARGE → BUILD_REVIEWER
5. MEDIUM → BUILD_LITE
6. SMALL → VANILLA_BUILD

## Output

`{project}/.codex-factory/mode-selection.json`
Template: `templates/mode-selection-result.template.json`

## Policy

`policies/mode-selector-policy.json`
