# Session Rotation Protocol — Compact + Branching Policy

## Core Rules (H24-P1 Clarified)

### COMPACT_HANDLING
- **Compaction is VERIFIED_FACT**: Codex compresses context when approaching token limits. Compressed summaries are lossy.
- **Compact detection is HYPOTHESIS**: No automatic compact-detection API has been observed. Factory cannot claim automatic compact-triggered rotation.
- **CONFIRMED compact (user-reported or visible tool evidence)**: Current window MAY finish the current narrow task.
- **CONFIRMED compact + new major phase**: MUST perform session rotation (artifact handoff + startup verification) before starting H/DRY/FINAL phase.
- **Multiple compactions**: Mandatory session rotation. No new major phase under any circumstance.

### BRANCHING_TRUTH
- Factory supports **artifact-based session rotation** as the primary mechanism.
- **fork / new-thread / create_thread** may be used as carriers if available in user's Codex environment.
- **Startup verification is ALWAYS required** after any rotation mechanism.
- **Fork/thread is NOT reliable memory expansion** — only artifacts are trustable.
- **Compressed summary is NOT evidence** — always verify against repo artifacts.

### AGENT_BRANCHING
- **Subagents are internal workers**, not user-visible conversation branches.
- **Isolated builders**: spawn_agent + fork_context:false + contract + owned scope.
- **Explorers / handoff**: fork_context:true may be used for justified scenarios.
- **Do NOT create user-visible branch for every builder** by default.
- Creating a subagent does NOT automatically create a visible conversation branch.

### PROHIBITED CLAIMS
- AUTO_WINDOW_CREATION_AFTER_COMPACT
- FORK_INHERITS_FULL_PRE_COMPACT_CONTEXT
- SUBAGENT_EQUALS_USER_VISIBLE_BRANCH
- BRANCH_IS_RELIABLE_MEMORY_EXPANSION
- COMPACT_DETECTION_API_VERIFIED
- COMPRESSED_SUMMARY_AS_EVIDENCE

### ALLOWED CLAIMS
- ARTIFACT_BASED_SESSION_ROTATION
- STARTUP_VERIFICATION_REQUIRED
- FORK_OR_NEW_THREAD_AS_OPTIONAL_CARRIER
- SUBAGENT_INTERNAL_ISOLATION
- FORK_CONTEXT_FALSE_DEFAULT_FOR_BUILDERS
- COMPRESSED_SUMMARY_NOT_EVIDENCE

## Evidence
- H24-P1: Conversation Branching + Session Rotation Feasibility Clarification (PASS, 10/10 negatives)
- H18-H24: 10+ successful artifact-based session rotations
- DRY20/DRY24: fork_context:false builder isolation proven
- H21-A: automation capability classification (CODEX_SELF_REPORT_ONLY where unverified)
