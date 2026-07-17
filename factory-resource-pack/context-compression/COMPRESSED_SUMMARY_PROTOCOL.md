# Context Compression Protocol

## Rule: Compressed Summary Is Not Evidence

Codex compact/compression produces a compressed summary of prior context. This summary:
- Is a lossy compression of conversation history
- May omit critical details, state transitions, or evidence references
- Cannot be used as the sole basis for phase decisions or evidence claims

### Protocol After Compression
1. Current window: finish current minor task if safe
2. Current window: generate session-rotation-handoff.json with all evidence hashes
3. Current window: update current-factory-state.json with latest trusted phase
4. New window: perform full startup artifact verification
5. New window: do NOT rely on compressed summary as evidence
6. New window: reject any claim based solely on "the previous window said..."
