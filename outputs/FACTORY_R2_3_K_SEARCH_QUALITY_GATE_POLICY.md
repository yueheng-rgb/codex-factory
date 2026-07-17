# R2.3-K Search Quality Gate Policy

## Quality Checks (8-point scale)

| Check | Weight | Description |
|-------|:---:|------|
| SOURCES | 2pt | Has source references with URLs or titles |
| PROVIDER | 1pt | Provider is known and declared |
| FACTS | 1pt | Has claimed facts with certainty levels |
| OFFICIAL_SOURCE | 2pt | At least one official docs source |
| AI_GENERATED | 1pt | AI-generated content is flagged (not penalized if disclosed) |
| UNCERTAINTY | 1pt | Uncertainty is annotated |
| FRESHNESS | 1pt | Sources have publish dates |
| CONSISTENCY | — | Basic consistency check |

## Verdicts

| Score | Verdict | Action |
|------|------|------|
| 8-10 | high_quality | Can enter knowledge pipeline with librarian review |
| 5-7 | acceptable | Human review recommended |
| 3-4 | needs_review | Human review required |
| 0-2 | reject | Do not use |

## Hard Rules

- AI-generated content WITHOUT sources → automatically rejected
- AI-generated content WITH sources → REFERENCE_ONLY, not authoritative
- Official documentation → TRUSTED_REFERENCE, still needs freshness check
- All search results must be reviewed before entering skill/knowledge bank
