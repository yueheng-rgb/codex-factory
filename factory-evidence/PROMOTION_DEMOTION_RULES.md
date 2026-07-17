# PROMOTION_DEMOTION_RULES.md
> Part of: FACTORY-EVIDENCE-TAXONOMY-0 / D

## Promotion Rules (only via new execution)
- E0→E4+: Must execute on fixture with captured output
- E1→E4+: Must implement + execute, not just design
- E2→E4+: Must execute, not just review
- E3→E5+: Must execute full behavior, not just inspect
- E4→E5+: Must produce real output files with inventory/hash
- E5→E6: Must run on real project working copy
- E6→E7: Requires production deployment + user approval (out of v0.5 scope)
- E7→E8: Requires multiple project types + repeated trials

## Demotion Rules (automatic on detection)
- Claimed E5 but missing inventory/hash → demote to E4
- Claimed E6 but no real project → demote to E5
- Claimed E7 but no production deploy → demote to E6
- Claimed E8 but single project type → demote to E7
- Using snapshot/dashboard as primary → demote to E3 at most
- Live-inspected claimed as E2E → demote to E3 with caveat

## Forbidden Promotion
- Dashboard/snapshot/attach-packet → NEVER promote to primary evidence
- Chat summary → NEVER promote to any evidence level
- Foreign context → NEVER promote to current project evidence
- Corrupt evidence → NEVER promote (BLOCKED)
- Design score → NEVER reuse as executed score
