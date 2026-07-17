# Context Packet Generator

## Purpose
Generate a minimal, high-quality context packet from .codex-factory/ external memory files.

## Generation Rules
1. Read all .codex-factory/ files
2. Apply ingestion policy: filter L0-L1, keep L3+
3. Apply decay: skip superseded decisions, archive old state
4. Extract: current phase, active risks, recent decisions (last 5), rejected claims
5. Include: evidence paths with file hashes
6. Exclude: raw conversation, unverified claims, redundant state
7. Target: max 2000 words
8. Tag with target audience (role-specific filtering applied separately)

## Generator Script (pseudocode)
```
function generateContextPacket(projectPath, targetRole):
  packet = new ContextPacket()
  for file in .codex-factory/:
    if file.level >= L3:
      extract relevant sections for targetRole
  apply role filtering (see ROLE_CONTEXT_FILTERING.md)
  validate packet size < 2000 words
  return packet
```
