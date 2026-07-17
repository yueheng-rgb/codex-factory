## Worker: verify-test

**Run:** h10-20260622-225319
**Phase:** 6C-H10
**forkContext:** false (required — clean context, no history)

### Mission
Test capsule.

### Your Worktree
Write exclusively to: $WorktreeRoot

### Files You Own
src/a.ts

### Files You MUST NOT Touch
src/b.ts

### Required Exports (exact names, exact signatures)
fn

### Required Evidence Outputs
test.log

### Required Scenarios
happy

### Required Negative Controls
sad

### What You Do NOT Have
- You do NOT have access to other Workers' capsules or task briefs.
- You do NOT have the full conversation history.
- You do NOT have phase lock or governance internals.
- You do NOT have the canonical source tree.

### Handoff Requirements
When you complete your work, write these files to ranches/verify-test/:

1. **BRANCH_RESULT.md** — What you built, why, what works
2. **BRANCH_DELTA.json** — JSON with ilesCreated, ilesModified, exportsProvided
3. **SOURCE_MANIFEST.json** — All source files in your worktree with summaries
4. **EVIDENCE_MANIFEST.json** — Evidence files you produced with paths

### Forbidden Actions
- Do NOT write outside your worktree.
- Do NOT read or modify forbidden files.
- Do NOT attempt to access other workers' output.
- Do NOT self-verify (leave that to the validator).

### Contract Rules
- fork_context MUST be false in the spawn call.
- All imports use ./ relative paths within src/.
- No worktree paths in source code or test imports.
