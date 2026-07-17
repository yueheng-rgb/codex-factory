# Release Candidate Validation Checklist — H24-P2

## Startup Verification (mandatory after any rotation)
- [ ] Read current-factory-state.json and session-rotation-handoff.json
- [ ] Run factoryctl verify --json → must PASS
- [ ] Validate MANIFEST.sha256
- [ ] Confirm no unexpected new phase artifacts
- [ ] Confirm compressed summary is NOT used as evidence
- [ ] Only trust: repo artifacts, verifier JSON, manifest SHA, factory state, handoff capsule

## Branching Policy Verification
- [ ] Final package does NOT claim auto-window-creation-after-compact
- [ ] Final package does NOT claim fork-inherits-full-pre-compact-context
- [ ] Final package does NOT claim subagent-equals-user-visible-branch
- [ ] Final package does NOT claim branch-is-reliable-memory-expansion
- [ ] Builder default = fork_context:false
- [ ] Subagent isolation is via spawn_agent + contract

## Pre-Final-ZIP Gate
- [ ] All CORE_RC assets validated
- [ ] MANIFEST.sha256 verifies
- [ ] factoryctl verify returns PASS
- [ ] Plugin remains EXPERIMENTAL
- [ ] No excluded assets in core
- [ ] Branching policy reflected in docs
- [ ] **User explicitly confirms final ZIP creation**

## This is NOT a production release
