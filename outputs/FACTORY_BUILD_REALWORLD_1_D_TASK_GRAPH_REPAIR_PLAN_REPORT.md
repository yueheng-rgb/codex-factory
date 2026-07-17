# FACTORY_BUILD_REALWORLD_1_D_TASK_GRAPH_REPAIR_PLAN_REPORT

> Phase: REALWORLD-1 / D — Task Graph and Repair Plan
> Timestamp: 2026-06-27

## Task Graph Status (post-baseline)

| ID | Task | Status | Result |
|----|------|--------|--------|
| T1 | baseline_test | ✅ completed | 30 tests PASS, JaCoCo 65.9% |
| T2 | h2_startup_smoke | ✅ completed | PASS (3.2s, port 8080) |
| T3 | docker_profile_diagnosis | ✅ completed | FAIL: docker profile missing |
| T4 | openapi_endpoint_coverage_repair | pending | Add 14 missing endpoints |
| T5 | readme_endpoint_count_repair | pending | Update from 9 to 24 endpoints |
| T6 | submission_doc_consistency_note | pending | Note 28→24 discrepancy |
| T7 | error_code_docs_repair | pending | Doc 4 missing error codes |
| T8 | coverage_comment_consistency_note | pending | Note percentage variance |
| T9 | diagnostic_gate | pending | Cross-check all repairs |
| T10 | final_verification | pending | Re-run tests + checks |

## Repair Plan (Evidence-Backed)

### T4: OpenAPI Endpoint Coverage Repair
- **File**: `openapi/openapi.yaml`
- **Action**: Add 14 missing endpoint definitions
- **Evidence**: Controller source code confirms each endpoint
- **Scope**: Add paths + schemas for: PUT/DELETE /api/books/{id}, GET /api/books/category/{category}, GET /api/books/search, PUT/DELETE /api/carts/{userId}/items/{itemId}, DELETE /api/carts/{userId}, GET /api/orders, GET /api/orders/user/{userId}, PUT /api/orders/{id}/status, GET/PUT/DELETE /api/users/{id}, GET /api/users

### T5: README Endpoint Count Repair
- **File**: `README.md`
- **Action**: Replace 9-endpoint API table with full 24-endpoint table
- **Evidence**: Controller source code

### T6: Submission Doc Consistency Note
- **Action**: Add note in README or EXPERIMENT_FINAL_REPORT clarifying that 提交说明.txt claim of 28 endpoints is unverified, actual count from source is 24

### T7: Error Code Docs Repair
- **Action**: Update EXPERIMENT_FINAL_REPORT.md error code section to list all 11 codes found in source

### T8: Coverage/Comment Consistency Note
- **Action**: Add note that coverage percentages vary slightly between measurement runs (rounding), and that comment coverage methodology may differ

## Repairs NOT Included
- Docker profile: deferred to user (requires application-docker.yml creation with DB config)
- Empty evidence folders: marked as manual tasks (already noted)
- External service dependencies: require environment setup

## Governance

| Artifact | Path |
|----------|------|
| This Report | `outputs/FACTORY_BUILD_REALWORLD_1_D_TASK_GRAPH_REPAIR_PLAN_REPORT.md` |
| Governance | `governance/factory-build/factory-build-realworld-1-task-graph-repair-plan.json` |
| Task Graph | `.codex-factory/task-graph.json` |
