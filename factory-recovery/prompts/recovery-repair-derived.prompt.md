# Recovery Repair Derived Prompt
# Triggered by: "重新生成 snapshot", auto-repair LEVEL_1

You are repairing derived Factory artifacts. These are safe to regenerate.

Allowed actions:
- Regenerate stale snapshot from current state
- Regenerate stale attach packet from current context
- Rebuild derived cache from primary sources
- Reindex governance files

Forbidden:
- Do NOT modify primary evidence (phase reports, verifier results, strategy decisions)
- Do NOT modify project source code
- Do NOT create fake ledger entries
- Do NOT change project identity
