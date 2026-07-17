# Evidence Hierarchy

> Phase: H18 · Category: protocols · Stability: stable
> Depends on: BOUNDARY.md, SCORING_SYSTEM_GATE.md

## Purpose

This protocol defines the evidence hierarchy used throughout the Factory.
Not all information is evidence. This hierarchy determines what can be used
to support PASS/FAIL verdicts, closure decisions, and claim validation.

## Hierarchy (Strictly Ordered)

Evidence at a higher level overrides evidence at a lower level.
Lower-level evidence is UNTRUSTED unless corroborated by higher-level evidence.

```
Level 1: VERIFIER RESULT (JSON)          <- GOLD STANDARD
Level 2: TRANSCRIPT (complete, unedited) <- PRIMARY EVIDENCE
Level 3: REGISTRY ENTRY                   <- STRUCTURAL EVIDENCE
Level 4: PROGRESS EVENT                   <- TEMPORAL EVIDENCE
Level 5: SUMMARY                          <- UNTRUSTED (unless corroborated)
----------------------------------------------------------- TRUST BOUNDARY ---
BELOW THIS LINE IS NOT EVIDENCE:
- Compressed summary                     <- NEVER evidence
- Manual PASS-only verdict               <- NEVER evidence
- ExpectedClass-only verdict             <- NEVER evidence
- Generic FAIL without specifics         <- NEVER evidence
- Self-reported completion               <- NEVER evidence (without corroboration)
- Score-based assessment                 <- NEVER evidence (per SCORING_SYSTEM_GATE.md)
```

## Level 1: Verifier Result (JSON)

**Definition:** Machine-readable JSON output from a Verifier run, produced by
a readonly agent following verifier protocols.

**Why highest:** Verifier is independent, readonly, and follows a defined gate
checklist. Verifier JSON is structured, specific, and references evidence sources.

**Required characteristics:**
- Machine-readable JSON format
- Gate-by-gate PASS/FAIL with specific evidence references
- Specific failure reasons for each FAIL (never generic)
- Timestamp after all evidence timestamps
- Verifier run ID for traceability

**Override rule:** Nothing overrides a verifier result except another verifier
result from a more recent run, or a founder override with explicit acknowledgment.

**Corroboration rule:** Verifier result alone is sufficient. It does not need
corroboration from lower levels — it IS the corroboration for lower levels.

## Level 2: Transcript (Complete, Unedited)

**Definition:** The complete, unedited session transcript from a worker
implementation session. Covers the entire session from start to completion claim.

**Why second:** Transcript is the primary record of what actually happened.
It can be audited for scope adherence, protocol compliance, and work quality.
Unlike summary, transcript preserves details that may be critical for verification.

**Required characteristics:**
- Complete: covers the full session
- Unedited: no sections removed or modified
- Traceable: includes sequence markers or timestamps
- Verifiable: can be cross-referenced with artifacts and registry entries

**Invalid as evidence:**
- Truncated transcript (missing sections)
- Edited transcript (modified after session)
- Summary labeled as "transcript"
- Transcript that does not cover the claimed scope

**Corroboration rule:** Transcript is trusted when corroborated by verifier
result. Transcript alone is strong evidence but not sufficient for PASS without
verifier check.

## Level 3: Registry Entry

**Definition:** An entry in AGENT_REGISTRY.json recording agent spawn,
status, and completion data.

**Why third:** Registry entries provide structural evidence that an agent
existed, was assigned a contract, and transitioned through defined states.
They establish the existence and status of agents.

**Required characteristics:**
- Valid agent ID
- Contract reference
- Status transitions with timestamps
- Spawn and completion timestamps

**Invalid as evidence:**
- Entry missing required fields
- Temporal inconsistency (completedAt before spawnedAt)
- Status inconsistency (COMPLETED without progress events)
- Registry entry not matching any known spawn event

**Corroboration rule:** Registry entry is trusted when corroborated by
transcript and/or verifier result. Registry entry alone is weak evidence.

## Level 4: Progress Event

**Definition:** An entry in AGENT_PROGRESS.jsonl recording a progress
update from an agent at a specific point in time.

**Why fourth:** Progress events provide temporal evidence that work was
ongoing. They establish a timeline and can detect staleness or fabrication.

**Required characteristics:**
- Agent ID matching registry
- Contract ID matching assignment
- Phase indicator
- Timestamp within expected work window

**Invalid as evidence:**
- Progress event with timestamp after completion claim (retroactive)
- Stale progress (last event > 4x expected interval before completion)
- Only "started" events with no intermediate progress
- Progress event from unknown agent (not in registry)

**Corroboration rule:** Progress events are trusted when corroborated by
registry entry and transcript. Progress events alone are weak temporal evidence.

## Level 5: Summary

**Definition:** A human-readable summary of work completed, produced by the
worker as part of the completion report.

**Why fifth and UNTRUSTED:** Summary discards detail. It is selective,
subjective, and cannot be independently verified without the underlying
transcript and artifacts. The worker chooses what to include and exclude.

**Required characteristics (to be considered at all):**
- Specific references to artifacts and transcripts
- Acknowledgment of limitations
- Disclaimer that summary is informational, not authoritative

**Invalid as evidence:**
- Summary without references to underlying evidence
- Summary claiming completion without evidence chain
- "It works" or similarly vague claims
- Summary that contradicts transcript or artifacts

**Corroboration rule:** Summary is UNTRUSTED unless corroborated by verifier
result. Even when corroborated, summary is the weakest form of evidence and
should not be the sole basis for any decision.

## Below the Trust Boundary

These are explicitly NOT evidence. They carry zero evidentiary weight.

### Compressed Summary

**Definition:** A summary that has been further compressed (token-limited,
context-window-optimized, or lossy-compressed).

**Why NOT evidence:** Double compression discards even more detail. The
compression process may introduce hallucinations, omissions, or distortions.
There is no way to verify what was lost.

**Rule:** Compressed summary is NEVER evidence. Period. No exceptions.
If a compressed summary is the only available record, treat the work as
having no evidence.

### Manual PASS-Only Verdict

**Definition:** A PASS verdict produced manually (not by Verifier JSON run)
with no FAIL checks or gate-by-gate assessment.

**Why NOT evidence:** Cannot verify that all gates were checked. No evidence
references. No specific PASS/FAIL per gate. Likely a rubber-stamp.

**Rule:** Manual PASS-only is NEVER evidence. Only Verifier JSON runs count.

### ExpectedClass-Only Verdict

**Definition:** A verdict based on "expected behavior" or "expected output
class" rather than specific gate checking.

**Why NOT evidence:** Does not verify actual outputs against contract
specifications. Assumes rather than checks.

**Rule:** ExpectedClass-only is NEVER evidence. Verifier must check actual
outputs, not expected classes.

### Generic FAIL Without Specifics

**Definition:** A FAIL verdict that says "failed" without specifying which
gate failed and why.

**Why NOT evidence:** Cannot determine what needs repair. Cannot verify
the FAIL is legitimate. Generic FAIL is a placeholder, not evidence.

**Rule:** Generic FAIL without specifics is NEVER evidence. Every FAIL must
specify the gate and the specific reason.

### Self-Reported Completion

**Definition:** A worker claiming completion without the full evidence chain
(registry entry + progress event + transcript + contract output).

**Why NOT evidence:** Self-report without evidence chain is indistinguishable
from fabrication. The worker has incentive to claim completion.

**Rule:** Self-reported completion without evidence chain is NEVER evidence.

### Score-Based Assessment

**Definition:** Any PASS/FAIL determination based on a computed score (0.0-1.0,
percentage, weighted average, etc.).

**Why NOT evidence:** Per SCORING_SYSTEM_GATE.md, scoring systems can mask
P0 failures behind high scores, downgrade hard floors, and lack negative
controls. No scoring system in Factory history passed independent accuracy
testing.

**Rule:** Score-based assessment is NEVER evidence. All gating must be
verifier-based binary checks (met/not-met), not weighted scores.

## Evidence Chain Requirements

For any completion claim to be valid, the full evidence chain must be present
and consistent:

```
Verifier Result (JSON)
    |
    +-- References -> Transcript
    |                     |
    |                     +-- Consistent with -> Registry Entry
    |                                               |
    |                                               +-- Consistent with -> Progress Events
    |                                                                           |
    |                                                                           +-- Consistent with -> Contract Output Artifacts
    |
    +-- Gate-by-gate checks cover all contract requirements
```

Any break in the chain invalidates the claim at that point and below.
Evidence below the break is UNTRUSTED.
Evidence above the break may still be valid for partial assessment.

## Version

| Field | Value |
|--------|-------|
| Phase | H18 |
| Category | protocols |
| Stability | stable |
| Depends on | BOUNDARY.md, SCORING_SYSTEM_GATE.md |
| Referenced by | All protocols, claim-classification.md, scoring-system-policy.md |
