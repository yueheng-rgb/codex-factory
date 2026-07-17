# Scoring System Policy

> Phase: H18 · Category: protocols · Stability: stable
> Depends on: BOUNDARY.md, SCORING_SYSTEM_GATE.md, evidence-hierarchy.md

## Policy Statement

**The Factory prohibits score-based gating for PASS/FAIL determinations.**

All gating must be verifier-based: binary check (met/not-met), not weighted
score (0.0-1.0 or percentage). This policy is absolute and applies to all
core and optional modules. There are no exceptions.

## Rationale

### Historical Evidence

Three scoring systems were identified in Factory history:

1. **Risk-classifier:** Produced risk scores (0.0-1.0) for work units.
2. **Drift-severity:** Produced drift scores to measure protocol deviation.
3. **Evidence-classification:** Produced confidence scores for evidence quality.

All three demonstrated the same failure patterns:

| Failure Pattern | Risk-Classifier | Drift-Severity | Evidence-Classification |
|---|---|---|---|
| Scores replaced transcript/verifier evidence | YES | YES | YES |
| High scores masked P0 blocking issues | YES | YES | YES |
| Scores downgraded hard floor failures to caveats | YES | YES | NO |
| Scores from Codex self-report without independent verification | YES | YES | YES |
| No negative controls testing scoring accuracy | YES | YES | YES |
| Scoring thresholds were arbitrary (no empirical basis) | YES | YES | YES |

### Why Scores Fail as Gates

**Scores are aggregations.** A 0.85 score might mean "85% of checks passed"
or "most checks passed with high confidence" or "one check failed badly but
others were perfect." The aggregation hides which specific checks failed.
A P0 failure can be buried inside a 0.85 score.

**Scores are subjective.** What constitutes a 0.7 vs 0.8 is a judgment call.
Different agents produce different scores for the same evidence. This
subjectivity makes scores unreproducible and unverifiable.

**Scores encourage threshold gaming.** If the threshold is 0.80 and the score
is 0.78, there is pressure to "find" 0.02 points rather than fix the actual
issue. This produces score inflation, not quality improvement.

**Scores lack negative controls.** None of the historical scoring systems
were tested against known-bad inputs to verify they produce FAIL. Without
negative controls, there is no evidence the scoring system actually detects
failures.

**Scores are not independently verifiable.** A verifier can check: "Does file
X exist? Does it match contract specification?" A verifier cannot check: "Is
0.73 the correct risk score?" The score is the output of a model, not an
observable fact.

## The Alternative: Binary Verifier-Based Gates

Every gate must be a binary question that a verifier can answer definitively:

| Bad (score-based) | Good (binary verifier check) |
|---|---|
| "Code quality score > 0.80" | "All functions have type annotations" |
| "Security score > 0.90" | "No hardcoded secrets detected" |
| "Test coverage score > 75%" | "All contract-specified test files exist and pass" |
| "Compliance score > 0.85" | "Registry entry exists with all required fields" |
| "Overall quality: 4.2/5" | "All gates in contract checklist PASS" |

## Enforcement

### What is Prohibited

- Any gate defined as a score threshold ("must score > X")
- Any PASS/FAIL determination based on a computed score
- Any module that outputs a score used for gating decisions
- Any scoring system packaged as a core or optional module
- Any agent using score as evidence for closure

### What is Required

- All gates must be verifier-based binary checks
- All PASS verdicts must be backed by verifier JSON result
- All FAIL verdicts must specify which specific gate failed and why
- Gate definitions must reference observable, checkable conditions

### What is Allowed

- Scores used for informational/non-gating purposes only (e.g., "code
  complexity score: 12" as a metric, not a gate)
- Scores used in reference/archive material with SCORING_SYSTEM_GATE warning
- Quantitative metrics that inform but do not determine PASS/FAIL

## Legacy Scoring System Handling

Any historical scoring system (risk-classifier, drift-severity,
evidence-classification) found in Factory history must:

1. Carry a `SCORING_SYSTEM_GATE` warning prominently
2. Be classified as `deprecated` if still active in any path
3. Be excluded from all core/runnable pack paths
4. Not be used as a basis for any PASS/FAIL determination
5. Be referenced only for historical analysis, not operational use

## Reference

- `SCORING_SYSTEM_GATE.md` — The binding gate rule
- `MANIFEST.json` — scoringSystemGate section for pack enforcement
- `BOUNDARY.md` — Rule 1: "No scoring system may be packaged as a core PASS/FAIL gate"
- H18-A0 Legacy Capability Inventory: `governance/factory-state/h18-a0-legacy-capability-inventory.json`

## Anti-Patterns

- "Let''s add a quality score as a soft gate" → score-based gating is prohibited
- "The score is just for context, not gating" → if it influences decisions, it''s gating
- "We need a number to track progress" → use binary gate completion count, not a score
- "The model gave it a 0.92 so it must be good" → model scores are not evidence
- "We''ll use a score but verify it" → just use the verifier directly, skip the score

## Version

| Field | Value |
|---|---|
| Phase | H18 |
| Category | protocols |
| Stability | stable |
| Depends on | BOUNDARY.md, SCORING_SYSTEM_GATE.md, evidence-hierarchy.md |
| Referenced by | All gate definitions, all verifier modules, MANIFEST.json |
