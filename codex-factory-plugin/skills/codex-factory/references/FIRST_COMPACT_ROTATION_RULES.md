# Session Rotation Protocol — First-Compact Rules

## Core Rules

### FIRST_COMPACT_REQUIRES_ROTATION_BEFORE_NEW_MAJOR_PHASE
After the first confirmed compact/compression in a Codex session:
- Current window MAY finish the current minor task
- Current window MUST NOT start a new H/DRY/FINAL major phase
- Current window MUST generate a session rotation handoff
- A new window/session MUST perform startup artifact verification before any implementation

### COMPRESSED_SUMMARY_NOT_EVIDENCE
- Compressed summaries produced by Codex compact/compression are NOT trusted evidence
- New windows MUST rely only on: repo artifacts, verifier JSON, manifest SHA256, factory state, handoff capsule
- Any claim based solely on compressed summary content MUST be rejected

### NEW_WINDOW_REQUIRES_ARTIFACT_STARTUP_VERIFICATION
Every new window/session MUST:
1. Read current-factory-state.json
2. Read session-rotation-handoff.json
3. Run factoryctl verify --json
4. Validate MANIFEST.sha256
5. Confirm no unexpected phase artifacts
6. Confirm compressed summary is not being used as evidence

### NO_FULL_CONTEXT_INHERITANCE_CLAIM
- Factory does NOT claim that new windows inherit full context from prior windows
- Artifact-based handoff is the ONLY supported context transfer mechanism
- Thread handoff complements, but does not replace, artifact handoff

### NO_AUTOMATIC_WINDOW_CREATION_CLAIM_UNLESS_VERIFIED
- Factory does NOT claim Codex automatically creates new windows on compact
- If window/session creation is automated in the future, it must be runtime-verified before packaged as fact
- Currently: window creation is a manual user action

## Evidence Chain
- This protocol was formalized in H24-P1 (2026-06-24)
- Based on H18 session rotation handoff design
- Validated through H18→DRY25→H19→DRY26→H20→H21→H22→DRY27→H23→H24 rotations
