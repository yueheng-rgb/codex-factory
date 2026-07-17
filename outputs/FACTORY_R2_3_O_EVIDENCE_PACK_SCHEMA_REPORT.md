# R2.3-O Evidence Pack Schema Report

## Purpose
Standardized evidence package produced by the Evidence Search Loop. Curated, quality-gated search results ready for agent context injection.

## Schema Fields (all required unless noted)

| Field | Type | Description |
|-------|------|-------------|
| evidenceId | string | EVID-YYYYMMDD-NNN |
| task | string | Task this evidence was gathered for |
| projectId | string | Project context |
| phaseId | string | Phase context |
| searchRound | int | Which round of iterative search |
| queryTime | datetime | When search was performed |
| triggerReason | enum | initial_search, error_driven, version_uncertainty, etc. |
| provider | enum | glm_search, manual, chatgpt_manual, dry_run |
| mode | enum | manual, dry_run, live_api |
| sources[] | array | Source objects with title, url, sourceType, authority, freshness, excerpt |
| qualityGateStatus | object | passed, score, verdict, trustRecommendation |
| allowedNextActions[] | array | What agents may do (use_in_implementation, use_as_reference, etc.) |
| forbiddenUse[] | array | What MUST NOT be done (do_not_enter_skill_registry_directly, etc.) |
| usableByAgents[] | array | Agent IDs allowed to use |
| notUsableByAgents[] | array | Agent IDs forbidden |
| conflictsDetected | bool | Whether conflicting info found |
| deltaFromPreviousRound | string | What changed since previous round |
| roundHistory[] | array | Evidence IDs from prior rounds |

## Source Type Classification
- official_doc → authority: high
- release_note → authority: high
- github_issue → authority: medium-high
- stackoverflow → authority: medium
- community_blog → authority: low-medium
- ai_generated → authority: unknown (needs human review)
- unknown → authority: unknown

## Key Constraint
do_not_enter_skill_registry_directly is always in orbiddenUse. Search results are reference material, not verified knowledge.
