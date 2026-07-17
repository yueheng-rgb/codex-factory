# TRUSTED_SOURCE_HIERARCHY.md

> Part of: FACTORY-RECOVERY-0 / D
> Version: 1.0.0

## Tier 1: PRIMARY EVIDENCE (Cannot be auto-generated)
Used to verify and repair everything else. Never auto-regenerated.

| # | Source | Location |
|---|--------|----------|
| 1 | Project registry (valid) | `%USERPROFILE%\.codex-factory\project-registry.json` |
| 2 | Phase reports (completed phases) | `{outputsPath}/FACTORY_*_REPORT.md` |
| 3 | Verifier results (PASS/FAIL) | `{governancePath}/verifier-*-result.json` |
| 4 | Strategy decisions | `{outputsPath}/FACTORY_*_STRATEGY_DECISION_REPORT.md` |
| 5 | User-confirmed identity | project-identity.json with `userConfirmedIdentity: true` |

## Tier 2: DERIVED EVIDENCE (Can be regenerated from Tier 1)
Safe to auto-regenerate when stale or missing.

| # | Source | Rebuilt From |
|---|--------|-------------|
| 6 | Snapshot | Current project state + phase ledger |
| 7 | Attach packet | Current context + project identity |
| 8 | Context index | File system scan + governance files |
| 9 | Memory index | Phase reports + verifier results |
| 10 | Dashboard output | All other sources (read-only) |

## Tier 3: SUPPORTING EVIDENCE (Informational, not authoritative)
Cannot be used as sole evidence for decisions.

| # | Source | Limitation |
|---|--------|-----------|
| 11 | CLI output / terminal logs | Ephemeral, not persisted |
| 12 | Chat/UI summaries | Not structured, not versioned |
| 13 | Agent runtime logs | May be incomplete |
| 14 | Conversation history | Not machine-verifiable |

## Tier 4: UNTRUSTED (Must verify against Tier 1/2)
| # | Source | Risk |
|---|--------|------|
| 15 | Foreign project context | Wrong projectId |
| 16 | Corrupt/malformed files | Parse failure |
| 17 | Manually edited governance files | Tampering possible |
| 18 | Stale artifacts (>30 days) | Out of date |
| 19 | Anonymous agent output | No ledger entry |

## Recovery Rules
- Repair can ONLY use Tier 1 as ground truth
- Tier 2 can be regenerated from Tier 1
- Tier 3 is never used as repair source
- Tier 4 must be verified against Tier 1 before any use
- Dashboard is Tier 2 (derived) — never use dashboard as evidence for repair
- Snapshot/attach packet are Tier 2 — never use as primary evidence
