# Thread Handoff Boundary — H24-P2 Updated

## Status: COMPLEMENTARY ARTIFACT HANDOFF ONLY

## What Thread Handoff IS (Allowed)
- Artifact-based session rotation (PRIMARY mechanism)
- fork / new-thread as optional carrier (if environment supports it)
- Startup verification ALWAYS required after rotation
- Compressed summary is NOT evidence

## What Thread Handoff IS NOT (Forbidden)
- NOT full context inheritance (REJECTED — compressed summaries are lossy)
- NOT automatic window creation after compact (REJECTED — no mechanism observed)
- NOT reliable memory expansion (REJECTED — only artifacts are trustable)
- NOT subagent = user-visible branch (REJECTED — sub-agents are internal)

## Agent Branching Policy
- Isolated builders: spawn_agent + fork_context:false + contract
- Explorers: spawn_agent + fork_context:true
- Default: fork_context:false (clean start)
- Creating subagent does NOT create user-visible branch

## Prohibited Claims
AUTO_WINDOW_CREATION_AFTER_COMPACT | FORK_INHERITS_FULL_PRE_COMPACT_CONTEXT | SUBAGENT_EQUALS_USER_VISIBLE_BRANCH | BRANCH_IS_RELIABLE_MEMORY_EXPANSION | COMPACT_DETECTION_API_VERIFIED | COMPRESSED_SUMMARY_AS_EVIDENCE
