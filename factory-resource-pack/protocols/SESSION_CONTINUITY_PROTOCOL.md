# Factory Protocols — Session Continuity

## Artifact-Based Handoff Protocol
1. Every phase closure writes verifier result, updates current-factory-state.json
2. Session rotation writes session-rotation-handoff.json with evidence hashes
3. New windows start from artifacts, NOT from compressed context
4. Startup verification is mandatory before any implementation

## First-Compact Rule
After first confirmed compact/compression:
- No new major phase (H/DRY/FINAL) in current window
- Must generate handoff and rotate to new window
- New window must pass startup verification

## What Is NOT Claimed
- Automatic window creation
- Full context inheritance
- Compressed summary as evidence
- Thread history as authoritative state
