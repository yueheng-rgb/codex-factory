# Memory Quality Hierarchy

## Levels (L0 = lowest trust, L5 = highest trust)

### L0: Raw Conversation / Compression
- **Trust**: Lowest. Not evidence.
- **Use**: Navigation clue only. Must be verified against L3+ before acting.
- **Example**: "The previous agent said it completed the task."

### L1: Self-Report
- **Trust**: Low. Unverified claim.
- **Use**: Starting point for investigation. Requires artifact confirmation.
- **Example**: "Agent reports all tests passed."

### L2: Artifact Claim
- **Trust**: Medium-Low. Document exists but not verified.
- **Use**: Read with skepticism. Cross-check against L3 state files.
- **Example**: A generated report claiming 60/60 PASS.

### L3: State File
- **Trust**: Medium. Structured, machine-readable, versioned.
- **Use**: Primary source for "what happened." Verifier should cross-check.
- **Example**: project-state.json, task-graph.json, verifier-history.json.

### L4: Verifiable Evidence
- **Trust**: High. Machine-verified, hash-backed, verifier-signed.
- **Use**: Authoritative for claims. Can be cited as evidence.
- **Example**: verifier result JSON with pass/fail counts and timestamp.

### L5: Cross-Verified Evidence
- **Trust**: Highest. Multiple independent sources confirm. Hash-chained.
- **Use**: Freeze-level evidence. Cannot be disputed without new counter-evidence.
- **Example**: Verifier result + file hash + agent close receipt + diagnostic gate = all agree.

## Decision Rules
- L0-L1: NEVER use as sole evidence for a PASS/FAIL claim.
- L2: May be cited but MUST note "unverified artifact."
- L3: Primary operational state. Trust but verify.
- L4: Authoritative for specific checks.
- L5: Can be frozen as permanent evidence.
