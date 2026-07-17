# Thread / Session Handoff Feasibility

**Phase**: H20-C
**Status**: FEASIBILITY ASSESSMENT

## Questions Answered

### 1. Can threads complement session-rotation-handoff.json?
**Yes.** Threads can serve as an additional notification/coordination layer.
Codex supports create_thread, fork_thread, handoff_thread, set_thread_archived, set_thread_pinned.
However, threads do NOT inherit full conversation context — they receive structured summaries.

### 2. Can thread handoff replace artifact-based handoff?
**No.** Threads cannot replace `session-rotation-handoff.json` because:
- Threads may lose context after compression
- Artifact handoff provides verifiable SHA256 evidence
- Thread handoff does not produce machine-readable verification results
- Factory verifiers depend on JSON state, not thread summaries

### 3. Can threads provide full context inheritance?
**No (UNVERIFIED).** Thread inheritance behavior depends on `fork_context` parameter and
is subject to context window limits. Full context inheritance cannot be guaranteed and
should not be claimed as a feature.

### 4. Recommended integration pattern
- Primary: `session-rotation-handoff.json` (artifact-based, verifiable)
- Complementary: Thread handoff for coordination/notification
- Never: Replace artifact handoff with thread-only handoff
