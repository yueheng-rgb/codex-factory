# FACTORY_BUILD_REALWORLD_1_E_TARGETED_REPAIR_REPORT

> Phase: REALWORLD-1 / E — Targeted Repair
> Timestamp: 2026-06-27

## Repairs Applied

| Task | File | Before | After | Evidence |
|------|------|--------|-------|----------|
| T4 | `openapi/openapi.yaml` | 10 endpoints | **24 endpoints** | Controller source code |
| T5 | `README.md` API table | 9 endpoints | **24 endpoints** | Controller source code |
| T6 | `README.md` | No note | Consistency caveat added | 提交说明.txt vs source |
| T7 | `EXPERIMENT_FINAL_REPORT.md` | 7 error codes | **11 error codes** | service/*.java grep |
| T8 | `EXPERIMENT_FINAL_REPORT.md` | No note | Coverage variance caveat | JaCoCo baseline vs report |

## Repairs Deferred (require user action)

| Risk | Reason |
|------|--------|
| R1: docker profile | Requires application-docker.yml with MySQL/Redis config — environment-specific |
| R6: empty evidence | Screenshots/video/signatures are manual tasks (already noted) |
| R7: external services | MySQL/Redis/JMeter/Jenkins not available in this environment |

## Changes Summary

| Metric | Before Repair | After Repair |
|--------|--------------|---------------|
| OpenAPI endpoint coverage | 10/24 (41.7%) | **24/24 (100%)** |
| README endpoint count | 9 | 24 |
| Error codes documented | 7 | 11 |
| OpenAPI schemas | 5 | 6 (+CartItemRequest) |
| Consistency notes | 0 | 2 |
