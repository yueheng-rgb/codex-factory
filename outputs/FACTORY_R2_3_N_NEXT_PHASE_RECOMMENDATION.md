# R2.3-N Next Phase Recommendation (CORRECTED — 2026-07-10)

> **⚠️ CORRECTION:** Original recommendation (R2.3-O Frontend Tool Trial with GLM Live API alternative) has been **superseded** by Direction Reconciliation Step 0. See governance/direction-decisions/direction-decision-index.jsonl for full audit trail (DIR-001 through DIR-006).

## Original (Superseded) Recommendation
- ~~R2.3-O → Frontend Tool Trial (Playwright Runtime Verification)~~ → **DEFERRED (DIR-002)**
- ~~Alternative: R2.3-N-EXT → Live API Test~~ → **DEFERRED (DIR-001)**

## Current Active Next Phase: R2.3-O — Evidence Search Loop

**Rationale:** Claim Audit confirmed R2.3-N classification as LIVE_API_READY_NOT_EXECUTED. The Factory needs a search capability that works in iterative loops (initial, error-driven, version-uncertainty, dependency-intro, conflicting-sources), not just one-time search. Evidence Search Loop builds on the Search Adapter MVP.

### R2.3-O Should Include
1. **Search Trigger Policy** — 
eed_search detector for task analysis, build failures, version uncertainty, dependency introduction, conflicting sources
2. **Evidence Pack Schema** — Standardized evidence format with sources, authority, freshness, uncertainty
3. **Reader/Extractor Abstraction** — Manual/dry_run first, future external readers (Jina, Firecrawl, etc.)
4. **Iterative Search Loop** — Initial → error-driven → version-uncertainty → dependency-intro → conflicting-sources → stop
5. **Search Provider Comparison Matrix** — GLM, Tavily, Exa, Brave, Jina, Firecrawl, Kimi, manual — all compared
6. **Agent Access Control** — Implementer reads approved Evidence Pack only, never calls provider directly

### What R2.3-O Should NOT Do
- Do NOT connect Stitch MCP, DB MCP, or cloud
- Do NOT require real GLM API key
- Do NOT execute live_api (remains gated)
- Do NOT claim GLM live integration completed
- Do NOT let Implementer agent search directly
- Do NOT treat external AI summaries as authoritative

### Deferred Directions (Valid, but prerequisites not met)
| Direction | ID | Prerequisites |
|-----------|-----|------|
| GLM Live API Smoke Test | DIR-001 | User sets ZHIPUAI_API_KEY + explicit approval |
| Frontend Tool Trial | DIR-002 | Sandbox maturity validated via Evidence Search Loop |
| Search Provider Live API | DIR-006 | Provider key + approval + comparison matrix |

### Historical Context
- Original FACTORY_R2_3_N_NEXT_PHASE_RECOMMENDATION.md content is preserved in FACTORY_R2_3_N_CLAIM_AUDIT_REPORT.md as audit evidence
- No historical files were deleted
