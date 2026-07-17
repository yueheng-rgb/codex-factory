# Context Compression Policy

> **Category**: context-compression | **Stability**: stable
>
> Defines compression level detection, evidence trust degradation, summary-as-evidence prohibition,
> and session rotation trigger thresholds for context pressure.

---

## Compression Levels

Context compression is detected at three levels based on observable indicators:

### Level 0: Normal

| Indicator | Threshold |
|-----------|-----------|
| Agent transcript coherence | Full — all agent actions traceable |
| Evidence references | Direct — verifier result or transcript entries |
| Registry integrity | All entries complete and parseable |
| Summary usage | None or explicitly labeled as supplementary |
| Session duration | < 4 hours active work |
| Agent count | < 10 agents |

**Action**: No action required. Normal operation.

### Level 1: Moderate

| Indicator | Threshold |
|-----------|-----------|
| Agent transcript coherence | Partial — some agent actions summarized |
| Evidence references | Mixed — some summary-backed claims |
| Registry integrity | All entries parseable but some may be thin |
| Summary usage | Appears in evidence chains but not as primary |
| Session duration | 4-8 hours active work |
| Agent count | 10-20 agents |

**Actions**:
- Flag all summary-backed evidence as `TRUST_DEGRADED`
- Require verifier re-run for any claim backed by degraded evidence
- Plan session rotation at next phase boundary
- Increase verifier frequency

### Level 2: Critical

| Indicator | Threshold |
|-----------|-----------|
| Agent transcript coherence | Fragmented — significant gaps in agent action trace |
| Evidence references | Mostly summary-backed or unverifiable |
| Registry integrity | Some entries incomplete or stale |
| Summary usage | Summary used as primary evidence for claims |
| Session duration | > 8 hours active work |
| Agent count | > 20 agents |

**Actions**:
- **BLOCK** any phase closure until compression is resolved
- Flag ALL summary-backed evidence as `UNTRUSTED`
- **MANDATORY** session rotation (no deferral)
- Full verifier re-run required after rotation
- Audit all claims made under compression for evidence integrity

---

## Evidence Trust Degradation

When compression is detected, evidence trust degrades according to this schedule:

| Original Evidence Level | Level 0 (Normal) | Level 1 (Moderate) | Level 2 (Critical) |
|------------------------|-------------------|---------------------|---------------------|
| Verifier result | TRUSTED | TRUSTED (if nativeGenerated) | TRUSTED (re-verify) |
| Transcript entry | TRUSTED | TRUST_DEGRADED | UNTRUSTED |
| Registry entry | TRUSTED (supplementary) | TRUST_DEGRADED | UNTRUSTED |
| Progress event | TRUSTED (supplementary) | TRUST_DEGRADED | UNTRUSTED |
| Summary | UNTRUSTED (always) | UNTRUSTED (always) | UNTRUSTED (always) |

**Rules**:
- `TRUSTED`: Evidence is acceptable as primary support for claims.
- `TRUST_DEGRADED`: Evidence requires corroboration from a higher-trust source. Cannot be sole support.
- `UNTRUSTED`: Evidence is NOT acceptable for any claim. Must be replaced or corroborated by `TRUSTED` evidence.
- Summary is ALWAYS `UNTRUSTED` regardless of compression level. Per BOUNDARY.md: "Summary is untrusted evidence unless corroborated by verifier result."

---

## Summary-as-Evidence Prohibition

### Absolute Rule

**No compressed summary may be used as primary evidence for ANY claim in ANY context.**

This prohibition is absolute and applies at all compression levels.

### What Counts as a Compressed Summary

- Agent-produced text that summarizes other agent actions without direct transcript reference
- "In summary..." or "Overall..." statements without specific evidence pointers
- Aggregated progress reports that don't cite individual events
- AI-generated summaries of verifier results (must use actual verifier JSON)
- Any text labeled or functioning as a summary that replaces primary evidence

### What Does NOT Count as a Compressed Summary

- Verifier JSON output (machine-readable, `nativeGenerated: true`)
- Direct transcript excerpts with specific entry references
- Registry entries with timestamps and agent IDs
- Direct CLI output from `factoryctl` commands
- Explicitly labeled supplementary notes (marked "SUPPLEMENTARY — NOT EVIDENCE")

### Detection

The `validate-resource-pack.ps1` script checks for compressed-summary-as-evidence patterns:
- Files in `core/`, `verifier-modules/`, `protocols/`, `policies/` containing both "summary" and "evidence" references
- Flagged as P0 failure if found

---

## Session Rotation Trigger Thresholds

Compression level drives session rotation decisions:

| Compression Level | Rotation Required? | Deadline |
|-------------------|-------------------|----------|
| Level 0 (Normal) | No | N/A |
| Level 1 (Moderate) | Yes — at next phase boundary | Before next phase closure |
| Level 2 (Critical) | Yes — IMMEDIATE | Before any further work |

### Pre-Rotation Requirements for Compression-Driven Rotation

When rotation is triggered by compression:

1. Document compression level and indicators in rotation handoff
2. Flag all `TRUST_DEGRADED` and `UNTRUSTED` evidence in handoff
3. New session MUST begin with full verifier re-run
4. New session MUST re-verify all claims made under compression
5. Rotation handoff must include `"compressionLevel": "moderate|critical"` and `"compressionIndicators": [...]`

---

## Compression Detection Checklist

Main Agent should assess compression level at:
- Start of each session (after startup checklist)
- Before any phase closure
- Before any verifier run
- After every 2 hours of active work
- When agent count crosses thresholds (10, 20)

Assessment questions:
1. Can I trace every agent action to a transcript entry? (Yes=Level 0, Partial=Level 1, No=Level 2)
2. Are all evidence claims backed by verifier JSON or transcript? (Yes=Level 0, Mixed=Level 1, Mostly not=Level 2)
3. Have I used any summary as primary evidence? (No=Level 0, Once=Level 1, Multiple=Level 2)
4. Is the registry complete and current? (Yes=Level 0, Mostly=Level 1, No=Level 2)
5. How many agents are active? (<10=Level 0, 10-20=Level 1, >20=Level 2)

---

## SCORING_SYSTEM_GATE

Per `SCORING_SYSTEM_GATE.md`: Compression level must be determined by binary indicator checks, not by a computed score. No scoring system may determine compression level or trust degradation.
