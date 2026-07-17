# V05-R1-POST-INTEGRATION-SMOKE — F: Safe Command Smoke

> Evidence Level: E4_LIVE_EXECUTED_FIXTURE (scripts executed on safe fixtures, not real projects)

## Command Execution Results
| Command | Exit Code | Output (truncated) |
|---------|-----------|---------------------|
| factory-state-dashboard --help | 0 OK | ========================================;  FACTORY STATE DASHBOARD;  🟢 Overall: HEALTHY; ========================================; ; ## 🏷 Project: demo-project; - **ID:** a1b2c3d4-e5f6-7890-abcd-ef1 |
| factory-recovery-scan --help | 0 OK | ========================================;  FACTORY RECOVERY SCAN; ========================================; ; [SCAN] Running health scan...;   🔴 FM-01: Missing project registry;   🟡 FM-10: Missing v |
| factory-evidence-validator --help | 1 | === Evidence Validator ===; FAIL: OVERCLAIM: Claimed E5_RAW_OUTPUT_EXECUTION exceeds evidence E4_LIVE_EXECUTED_FIXTURE.; Verdict: FAIL |
| factory-state-dashboard --brief (fixture) | 0 OK | ========================================;  FACTORY STATE DASHBOARD;  🟢 Overall: HEALTHY; ========================================; ; ## 🏷 Project: demo-project; - **ID:** a1b2c3d4-e5f6-7890-abcd-ef1 |
## Note
- All commands executed against safe fixtures or with --help flag
- No real project data accessed
- No destructive operations attempted
- Scripts parse and execute without fatal errors
