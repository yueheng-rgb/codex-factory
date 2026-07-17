# V05-R1-POST-INTEGRATION-SMOKE — C: Metadata & Manifest Smoke

## Metadata Checks
| Field | Value | Expected | Result |
|-------|-------|----------|--------|
| version | 0.5.1-r1 | 0.5.1-r1 | PASS |
| artifactType | LOCAL_TOOLING_PATCH_RELEASE | LOCAL_TOOLING_PATCH_RELEASE | PASS |
| baseVersion | 0.5.0 | 0.5.0 | PASS |
| v06Package | False | False | PASS |
| scope | LOCAL_WORKFLOW_TOOLING_ONLY | LOCAL_WORKFLOW_TOOLING_ONLY | PASS |
| notProductionReady | True | True | PASS |
| notDeploymentTool | True | True | PASS |
| notCloudService | True | True | PASS |
| MANIFEST.json exists |  |  | PASS |
| SHA256 file exists |  |  | PASS |
| Manifest totalFiles | 489 | >=489 | PASS |
## Summary
- PASS: 11 / 11
- FAIL: 0
