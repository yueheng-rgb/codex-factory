# Build Mode — Complexity Classifier

> Stage 1 of the Build Harness pipeline. Determines project complexity.

## Five Levels

| Level | Criteria | Default Mode |
|-------|----------|-------------|
| SMALL | <=10 files, single app, no auth/DB | VANILLA_BUILD |
| MEDIUM | 11-100 files, 1-2 apps, may have auth/DB | BUILD_LITE |
| LARGE | 100+ files, 2-3 apps, auth+DB | BUILD_REVIEWER |
| LONG_HORIZON | 3+ sessions, multi-day project | BUILD_CONTINUATION |
| HIGH_RISK | Financial/compliance/payment data | BUILD_PRO_4_AGENT* |

*Conditional, requires explicit user approval.

## Inputs

- fileCount, appCount, hasAuth, hasDB, hasPaymentProcessor, hasComplianceReq, estimatedSessions, hasExistingCode, hasReportDocs

## Output

`{project}/.codex-factory/classification.json`
Template: `templates/complexity-classification-result.template.json`

## Policy

`policies/complexity-classifier-policy.json`
