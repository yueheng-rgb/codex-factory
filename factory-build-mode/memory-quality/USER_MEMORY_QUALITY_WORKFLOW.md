# User Memory Quality Workflow

## What Changed (and What Didn't)

### Normal Answers — NO CHANGE
Your normal interactions with Codex remain detailed and helpful. Codex will still give full explanations, code examples, and thorough answers. **Minimal Mode is for memory ingestion only.**

### Memory Ingestion — NOW MINIMAL
When Codex writes to memory (External Conversation Space, Snapshot, Attach Packet, phase ledger, risk ledger, decision ledger), records are:
- ≤ 500 characters (minimal, self-contained)
- Include evidence path (where to find the full report)
- Include caveat (what limitations apply)
- Validated by 15 checks before writing

### Socratic Questions — RARE, HIGH-RISK ONLY
Codex may ask clarifying questions ONLY when:
- Two strategies conflict
- Phase scope is unclear
- Release/deploy/security boundary is involved
- Evidence classification is ambiguous

You will NOT be asked questions during normal execution.

## User Commands

| Command | Effect |
|---------|--------|
| "写入最简记忆记录" | Force minimal memory record for current phase |
| "不要写入外接对话空间" | Skip memory ingestion this phase |
| "审查记忆记录后再写入" | Review record before it is written |
| "标记此记录为 RETIRED" | Retire a stale memory record |

## What Memory Records Look Like

```
MEM-PHASE_RESULT-20260628-a1b2
FACTORY-AB-0-R1: Executed trial. Factory 87 vs Vanilla 50.
Verdict: FACTORY_ADVANTAGE_SUPPORTED_FOR_THIS_TASK.
Evidence: outputs/FACTORY_AB_0_R1_EXECUTED_MATCHED_TRIAL_REPORT.md
Caveat: Single task type. Not generalizable. DESIGN_ONLY tag NOT applied
         (this is executed, not design).
Status: ACTIVE
```

## Anti-Patterns (Will Be Blocked)

- ❌ Memory record without evidence path
- ❌ Memory record without caveat for partial claims
- ❌ Design analysis presented as execution evidence
- ❌ Local trial presented as production readiness
- ❌ Overclaim language ("proves", "guarantees")
