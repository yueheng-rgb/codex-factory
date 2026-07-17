# V0.5-POST-RELEASE-SMOKE — Section E: CLI Help / Dry-Run Smoke

**Phase:** V0.5-POST-RELEASE-SMOKE | **Section:** E | **Status:** PASS

| Command | Exit | Result |
|---|---|---|
| Get-Help factoryctl.ps1 | 0 | Help available |
| factoryctl.ps1 status | 0 | JSON response (626 chars) |
| factoryctl.ps1 agents | 0 | JSON response |
| factoryctl.ps1 watch | 0 | Aggregate output |
| Cleanup PLAN (inspect) | N/A | PLAN=default, DELETE requires -Confirm |

Exact commands recorded. No deploy/remote/prod DB. No secrets printed.

**Section E verdict: PASS**
