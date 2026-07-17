# R2.3-H Behavior Difference Report

**Comparison:** WITHOUT skill vs WITH CAP-SKILL-004 | **Project:** PROJ-LIVE-TRIAL-001

## Summary

CAP-SKILL-004 produced **11 out of 12 significant behavior differences**.

## Dimension Comparison

| Dimension | WITHOUT Skill | WITH CAP-SKILL-004 | Significant? |
|-----------|:---:|:---:|:---:|
| AGENTS.md detection | ✅ | ✅ | No |
| Build command extraction | ❌ | ✅ `npm run build` | **Yes** |
| Test command extraction | ❌ | ✅ `npm test` | **Yes** |
| Lint command extraction | ❌ | ✅ `npm run lint` | **Yes** |
| Security boundaries | ❌ | ✅ 5 rules | **Yes** |
| Directory rules parsing | ❌ | ✅ 3 rules | **Yes** |
| Forbidden actions catalog | ❌ | ✅ 9 items | **Yes** |
| Handoff field requirements | ❌ | ✅ 6 fields | **Yes** |
| User instruction priority | ❌ | ✅ ADVISORY rule | **Yes** |
| Contract input generation | ❌ | ✅ PIC/AC/FC/NGC | **Yes** |
| Nested AGENTS.md handling | ❌ | ✅ src/AGENTS.md override | **Yes** |
| Skill usage recording | ❌ | ✅ ledger entries | **Yes** |

## Interpretation

- **The 1 non-significant dimension** (AGENTS.md detection) is file-system-level — both contexts can check if AGENTS.md exists.
- **All 11 significant dimensions** involve structured information extraction that ONLY occurs when CAP-SKILL-004 is loaded.
- Without the skill, an agent would have to manually parse AGENTS.md as raw Markdown text with no structured output, no contract integration, and no usage tracking.

## Conclusion

CAP-SKILL-004 materially changes agent behavior in a live project. Its structured extraction, contract input generation, nested scoping, and ledger integration are capabilities that a skill-less agent context cannot replicate.
