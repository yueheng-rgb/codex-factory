# R2.3-O Search Trigger Policy

## need_search Detector — 10 Trigger Conditions

| # | Trigger | Score | Example |
|---|---------|:---:|---------|
| T1 | Framework/library/API/CLI/config reference | +2 | "Implement Next.js 15 App Router" |
| T2 | Version/latest/release notes | +2 | "Upgrade to React 19" |
| T3 | External platform (WeChat, payment, maps, cloud) | +3 | "Integrate WeChat Pay API" |
| T4 | Build/test/lint failure from external dep | +3 | "Build fails: module not found" |
| T5 | New dependency introduction | +2 | "Install prisma for database access" |
| T6 | Evidence Pack insufficient | +2 | Quality verdict needs_review or reject |
| T7 | Conflicting sources | +2 | "Docs say X, community says Y" |
| T8 | Security/CVE/dependency upgrade | +3 | "CVE-2024-XXXX in express" |
| T9 | User requests latest | +2 | "Use the latest version" |
| T10 | Low confidence in external facts | +1 | "Maybe it works this way" |

## 6 Non-Trigger Conditions

| # | Condition | Score | Example |
|---|-----------|:---:|---------|
| N1 | Pure internal logic | -2 | "Rename variable a to b" |
| N2 | User provided complete docs | -3 | "Per the provided documentation" |
| N3 | Simple refactor | -2 | "Extract method from existing code" |
| N4 | Style only | -2 | "Change button color to blue" |
| N5 | Evidence Pack sufficient | -3 | Quality verdict high_quality |

## Decision Threshold
- **Score ≥ 2 → need_search=true**
- Score 1 → borderline (low confidence, may trigger)
- Score ≤ 0 → need_search=false

## Trigger Type Mapping
- error_driven_search: build/test failure
- version_uncertainty_search: version/latest reference
- dependency_introduction_search: new dependency
- conflicting_sources_search: conflicting info
- verification_failure_search: evidence insufficient
- initial_search: all other trigger conditions

## Budget
- Max 5 rounds per task
- Max 10 sources per round
- Official docs preferred
- Stop when evidence sufficient or max rounds reached
- Human escalation after 3 consecutive empty rounds
