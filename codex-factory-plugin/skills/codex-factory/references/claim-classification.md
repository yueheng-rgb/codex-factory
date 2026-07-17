# Claim Classification Protocol

> Phase: H18 · Category: protocols · Stability: stable
> Depends on: BOUNDARY.md, evidence-hierarchy.md, SCORING_SYSTEM_GATE.md

## Purpose

This protocol defines how claims about work completion, agent output, and
system state are classified. Claims are classified based on the evidence
supporting them, not on the identity or authority of the claimant. A claim
from any agent — including Main Agent or Founder — is classified by its
evidence, not its source.

## Claim Classes

### VERIFIED_FACT

**Definition:** A claim backed by the full evidence chain, with verifier
JSON PASS as the primary evidence anchor.

**Required evidence:**
- Verifier JSON result with PASS on relevant gates
- Complete transcript corroborating the claim
- Contract output artifacts present and verifier-checked

**Characteristics:**
- Highest confidence claim class
- Can be used as input to downstream decisions without qualification
- Does not need additional corroboration
- Can be propagated as fact across the system

**Example:**
"The auth module password hashing uses bcrypt with cost factor 12."
— Backed by: Verifier PASS on SECURITY_GATE_01, transcript shows
  implementation, artifact shows bcrypt configuration.

**Propagation rule:** VERIFIED_FACT claims may be treated as true by all
agents. They are the only claim class that can be used without qualification
in closure decisions.

### TRUSTED_EVIDENCE

**Definition:** A claim backed by multiple lower-level evidence sources
(registry + progress + contract output) but not yet confirmed by verifier.

**Required evidence (at least 3 of 4):**
- Registry entry
- Progress event
- Transcript
- Contract output artifacts

**Characteristics:**
- Strong but not definitive
- Likely true but awaiting verifier confirmation
- Should be treated as provisionally true — act on it but verify
- Cannot be used for closure decisions without verifier confirmation

**Example:**
"The auth module implementation is complete."
— Backed by: Registry COMPLETED status, progress events showing phases,
  contract outputs present at expected paths. Verifier not yet run.

**Propagation rule:** TRUSTED_EVIDENCE claims may be used for planning and
scheduling but NOT for closure decisions. They must be qualified as
"awaiting verifier confirmation."

### UNTRUSTED_CLAIM

**Definition:** A claim supported only by summary, self-report, or compressed
context — no primary evidence chain.

**Evidence present:**
- Summary or self-report
- No transcript, no verifier result, or insufficient registry/progress

**Characteristics:**
- Cannot be relied upon for any decision
- May be true or false — indistinguishable from fabrication
- Must be verified before any action based on it
- Default classification for any claim without evidence chain

**Example:**
"The auth module is done and working."
— Backed by: Worker self-report. No transcript, no verifier result,
  no registry entry.

**Propagation rule:** UNTRUSTED_CLAIM must NOT be propagated as truth.
It must be flagged for verification. Decisions based on UNTRUSTED_CLAIM
are governance violations.

### FALSE_CLAIM

**Definition:** A claim contradicted by verifier result or higher-level evidence.

**Evidence:**
- Verifier FAIL on relevant gates that contradicts the claim
- Transcript that contradicts the claim
- Artifact inspection that contradicts the claim

**Characteristics:**
- Actively disproven, not just unproven
- Indicates either error, misunderstanding, or fabrication
- Triggers audit and potential governance action

**Example:**
"All contract outputs are present."
— Contradicted by: Verifier FAIL on OUTPUT_COMPLETENESS gate, showing
  3 of 5 required outputs are missing.

**Propagation rule:** FALSE_CLAIM must be explicitly marked as disproven.
The source of the false claim must be noted. Repeated FALSE_CLAIMs from
the same agent trigger audit.

## Classification Decision Tree

```
Is there a verifier JSON result?
    |
    +-- YES: Does verifier PASS on all relevant gates?
    |           |
    |           +-- YES: Is transcript complete and corroborating?
    |           |           |
    |           |           +-- YES -> VERIFIED_FACT
    |           |           +-- NO  -> TRUSTED_EVIDENCE (verifier PASS but transcript gap)
    |           |
    |           +-- NO: Does verifier FAIL directly contradict the claim?
    |                       |
    |                       +-- YES -> FALSE_CLAIM
    |                       +-- NO  -> UNTRUSTED_CLAIM (verifier inconclusive)
    |
    +-- NO: Are registry + progress + transcript + contract outputs present?
                |
                +-- YES (at least 3/4) -> TRUSTED_EVIDENCE
                +-- NO                 -> UNTRUSTED_CLAIM
```

## Claim Propagation Rules

### Rule 1: Classification must travel with the claim

When propagating a claim to another agent or system, the claim class
(VERIFIED_FACT, TRUSTED_EVIDENCE, UNTRUSTED_CLAIM, FALSE_CLAIM) must
accompany the claim. De-classifying a claim during propagation (e.g.,
propagating UNTRUSTED_CLAIM as if it were VERIFIED_FACT) is a governance
violation.

### Rule 2: Claims degrade when context is compressed

If a claim must be compressed (token limit, context window), its class
degrades:
- VERIFIED_FACT -> TRUSTED_EVIDENCE (compression loses verifier specificity)
- TRUSTED_EVIDENCE -> UNTRUSTED_CLAIM (compression loses evidence references)
- UNTRUSTED_CLAIM -> remains UNTRUSTED_CLAIM (cannot degrade further, but
  compression adds no value)
- FALSE_CLAIM -> remains FALSE_CLAIM

**Better approach:** Reference the claim by its source location rather than
compressing it. "See verifier result at verifier/auth-check-2026-06-24.json"
is superior to compressing the result.

### Rule 3: FALSE_CLAIM must trigger audit

Any FALSE_CLAIM must be reported to the Auditor. A pattern of FALSE_CLAIMs
from the same agent, contract, or scope indicates a systemic issue.

### Rule 4: UNTRUSTED_CLAIM must not block work

UNTRUSTED_CLAIMs should not be used as the basis for blocking decisions.
They lack evidence. Blocking on UNTRUSTED_CLAIM is blocking on noise.

Instead: flag for verification, proceed with TRUSTED_EVIDENCE or
VERIFIED_FACT, and check back when verification is available.

### Rule 5: Claims cannot upgrade without new evidence

A claim classified as UNTRUSTED_CLAIM cannot become TRUSTED_EVIDENCE without
additional evidence. A TRUSTED_EVIDENCE claim cannot become VERIFIED_FACT
without verifier run. Time passing does not upgrade claims.

## Anti-Patterns

- Treating all claims as VERIFIED_FACT because "the agent is reliable"
  -> Classification is evidence-based, not trust-based
- Propagating UNTRUSTED_CLAIM as truth -> governance violation
- Ignoring FALSE_CLAIM because "it was probably a mistake"
  -> FALSE_CLAIM must be audited
- Compressing VERIFIED_FACT into summary and treating summary as VERIFIED_FACT
  -> Compression degrades claim class
- "Founder said it, so it is VERIFIED_FACT"
  -> Founder statements are founder decisions, not VERIFIED_FACT about system
     state. Founder can override gates but cannot declare implementation facts
     without evidence.

## Claim Classification in Closure Decisions

Closure decisions must be based on VERIFIED_FACT claims for all gates.
TRUSTED_EVIDENCE may be used for non-gate context. UNTRUSTED_CLAIM and
FALSE_CLAIM must not appear in closure decisions.

**Closure decision template:**
```
CLOSURE DECISION: <APPROVED|BLOCKED|APPROVED_WITH_CAVEATS>
VERIFIED_FACT basis:
  - Gate A: VERIFIED_FACT (verifier run X, PASS)
  - Gate B: VERIFIED_FACT (verifier run X, PASS)
  - Gate C: VERIFIED_FACT (verifier run Y, PASS)
TRUSTED_EVIDENCE context:
  - Context item 1: TRUSTED_EVIDENCE (awaiting verifier run Z)
P0 blockers: <list or NONE>
P1 caveats: <list or NONE>
P2 caveats: <list or NONE>
```

## Version

| Field | Value |
|--------|-------|
| Phase | H18 |
| Category | protocols |
| Stability | stable |
| Depends on | BOUNDARY.md, evidence-hierarchy.md, SCORING_SYSTEM_GATE.md |
| Referenced by | All verification and closure workflows |
