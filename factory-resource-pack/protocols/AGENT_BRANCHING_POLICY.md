# Factory Protocols — Agent + Branching Policy (H24-P2)

## Agent Branching Rules
1. **Isolated builders**: spawn_agent + fork_context:false + contract + owned file scope
2. **Explorers**: spawn_agent + fork_context:true (full current context, read-only)
3. **Handoff**: fork_context:true + limited context transfer
4. **Subagents are INTERNAL**: they do NOT create user-visible conversation branches
5. **Default**: fork_context:false (clean start) — this is the Factory standard

## Session Continuity
1. **Primary mechanism**: Artifact-based session rotation (proven: H18-H24)
2. **Optional carrier**: fork / new-thread / create_thread (if environment supports it)
3. **Mandatory**: Startup verification after ANY rotation mechanism
4. **Prohibited**: Claiming fork/thread provides reliable memory expansion
5. **Prohibited**: Claiming compressed summary is evidence

## Why Artifact Handoff Is Primary
- Thread history: volatile, compressible, not verifiable
- Thread fork: depends on environment capability (not guaranteed)
- Repo artifacts: persistent, SHA256-verifiable, portable across any environment
- Only artifacts can be trusted across windows, machines, and time
