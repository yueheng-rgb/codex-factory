# Release Candidate Boundary — Branching Policy

## Branching/Session Rotation Rules
- Primary: artifact-based session rotation
- Carrier: fork/new-thread (optional, environment-dependent)
- Mandatory: startup verification after any rotation
- Prohibited: auto-window, full-context-inheritance, subagent=user-branch, memory-expansion

## Compact Policy
- CONFIRMED compact + new major phase → session rotation
- Multiple compactions → mandatory rotation
- Detection is HYPOTHESIS → no automatic triggers

## Agent Policy
- Builders: fork_context:false (default)
- Explorers: fork_context:true
- Subagents are internal, not user-visible branches
