# R2.3-N Search Quality Gate Update

## Changes from R2.3-K → R2.3-N

### Scoring Upgrade: 10-point → 12-point

| Check | R2.3-K | R2.3-N | Change |
|-------|:---:|:---:|--------|
| Has source references | 2 pts | 2 pts (now validates URL format) | Tighter |
| Provider known | 1 pt | 1 pt | Same |
| Has claims/facts | 1 pt | removed | Replaced by source type check |
| Official sources | 2 pts | 2 pts (boost) | Same |
| AI-generated flag | penalty | penalty + source type awareness | Enhanced |
| Uncertainty annotated | 1 pt | 1 pt | Same |
| Freshness (dates) | 1 pt | 1 pt | Same |
| Basic consistency | 1 pt | 1 pt | Same |
| **Source type distribution** | — | 2 pts (official +1, blog +1, github +1) | **NEW** |
| **Advertisement detection** | — | -2 penalty | **NEW** |
| **Title presence** | — | 1 pt | **NEW** |
| **Snippet presence** | — | 1 pt | **NEW** |
| **Duplicate detection** | — | 1 pt | **NEW** |

### New Verdict Thresholds
- ≥10: high_quality
- ≥7: acceptable
- ≥4: needs_review
- <4: reject

### New Trust Recommendations
- 	rusted_reference — official docs + high_quality
- eference_only — acceptable quality, cross-check recommended
- 
eeds_human_review — AI-generated or advertisements detected
- do_not_use — rejected quality

### Advertisement/Marketing Detection
Sources with sourceType dvertisement or marketing trigger a -2 score penalty and flag ADVERTISMENT_DETECTED.

### Duplicate Detection
URLs are compared; duplicates counted. If any found, DUPLICATES flag is raised but score penalty is 0 (informational only).

### AI-Generated Source Handling
- AI-generated without official sources → flagged AI_ONLY, trust=needs_human_review
- AI-generated with official sources → flagged AI_MIXED, trust=reference_only
- Non-AI provider → +1 score bonus
