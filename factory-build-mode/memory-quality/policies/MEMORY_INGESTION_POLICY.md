# Memory Ingestion Policy

## What CAN enter .codex-factory/
- Verifier results (JSON with pass/fail counts)
- Decision log entries (timestamped, with rationale)
- Task graph status updates
- Agent handoff receipts
- Agent close receipts
- File hashes (SHA256)
- Project state transitions
- Active risk updates
- Architecture/requirement maps

## What MUST be filtered OUT
- Raw conversation logs (too large, low signal)
- Unverified self-reports ("I think it worked")
- Redundant state (unchanged from previous write)
- Emotional/opinion content
- Prompts and system messages

## What MUST be downgraded
- Compressed summaries → mark as L0, navigation only
- Generated reports without verifier → mark as L2
- Handoff without close receipt → mark as L2, incomplete

## Ingestion Check
Before writing to .codex-factory/:
1. Is this verifiable? (L4+) → ACCEPT
2. Is this state? (L3) → ACCEPT with version
3. Is this claim? (L0-L2) → FLAG, require evidence reference
4. Is this redundant? → SKIP
5. Is this conversation noise? → REJECT
