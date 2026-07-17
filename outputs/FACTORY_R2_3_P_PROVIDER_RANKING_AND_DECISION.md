# R2.3-P Provider Ranking and Decision

**Date:** 2026-07-10
**Architecture:** Single WebSearch Tool (DIR-010)
**Decision:** GLM Search selected as first Single WebSearch Tool provider

## Selection Criteria (weighted)

| Criteria | Weight | GLM | Tavily | Jina |
|----------|:---:|:---:|:---:|:---:|
| Key available | 3 | 0/3 | 0/3 | 0/3 |
| China accessibility | 2 | 2/2 | 0/2 | 1/2 |
| Coding agent fit | 2 | 1/2 | 2/2 | 2/2 |
| Cost risk | 1 | 1/1 | 0/1 | 0/1 |
| Official docs perf | 1 | 1/1 | 1/1 | 1/1 |
| Existing adapter | 1 | 1/1 | 0/1 | 0/1 |
| Read-only | 1 | 1/1 | 1/1 | 1/1 |
| **Total** | **11** | **7** | **4** | **5** |

## Decision

**GLM Search (ZhipuAI)** scores highest (7/11) primarily due to China accessibility, existing adapter code, and low cost. All providers are BLOCKED pending API key.

## Post-Unblock Pipeline

Single WebSearch Tool (GLM) -> Quality Gate -> Research Intake -> Evidence Pack -> Agent Context

No independent Search Agent. No dual channel. Evidence Pack sole carrier.
