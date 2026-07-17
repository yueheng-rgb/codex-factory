# R2.3-O Next Phase Recommendation

## Current State
- Evidence Search Loop: 28/28 verification, 12/12 simulation
- 4 schemas, 4 runtime scripts, 1 provider comparison matrix (10 providers)
- Direction guard: DIR-004 (Evidence Search Loop) is sole active next phase
- GLM live API, Frontend Tool Trial, First Real API — all deferred/deprecated

## Recommendation: R2.3-P — External Search Provider Activation (Optional)

The Evidence Search Loop framework is complete. The next logical step depends on user preference:

### Option A: R2.3-P-A — GLM Search Live Activation
- User sets ZHIPUAI_API_KEY env var
- User explicitly approves live_api_mode
- Run one low-risk public query through the full pipeline
- Promote TOOL-GLM-SEARCH-001 from candidate to liveTested
- Verify: live_api → adapter → quality gate → intake → evidence pack → ledger

### Option B: R2.3-P-B — Batch Skill Import (CAP-SKILL-015)
- Complete the pipeline for CAP-SKILL-015 (project-rules-ecosystem)
- Currently uditPassed_with_controls → promote to actoryRuntimeVerified

### Option C: R2.3-P-C — Return to Business Projects
- Apply the full R2.3 infrastructure (direction guard, evidence search loop, skill runtime, permission gate, sandbox) to a real business project
- First project: small-web-api-demo or new user-specified project

## What R2.3-P Should NOT Do
- Do NOT connect Stitch MCP, DB MCP, or cloud
- Do NOT claim production search capability
- Do NOT un-defer deprecated directions
