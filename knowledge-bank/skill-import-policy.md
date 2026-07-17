# Skill Import Policy
> Part of: FACTORY-R2.1-INFRA-MVP / Skill Registry Skeleton
> Version: 1.0.0

## Import Pipeline

```
Request -> Source Check -> Content Audit -> Script Audit
-> Network Audit -> Scope Audit -> Conflict Test
-> Sandbox Test -> Trust Level Assignment -> Registry Entry
```

## Trust Level Definitions

| Level | Icon | Auto-Load | Production Use | Criteria |
|-------|------|-----------|----------------|----------|
| VERIFIED | 🟢 | Yes | Yes | Official source OR audited by security team |
| TRUSTED | 🟡 | Yes (warning) | With review | Known community, all checks passed |
| AVAILABLE | 🔵 | No | With caution | Security checks passed, not Factory-validated |
| UNVERIFIED | ⬜ | No | No | In registry, incomplete checks |
| BLOCKED | 🔴 | No | No | Failed security check |

## Skill Types

- **internal**: Created by Codex Factory team
- **imported**: Imported from external source without modification
- **adapted**: Imported and modified for Factory compatibility
- **untrusted_candidate**: Submitted but not yet audited
- **deprecated**: No longer recommended, kept for reference
- **superseded**: Replaced by a newer skill

## Import Rules

1. All imports go through LIB-001
2. Source must be traceable (URL, repo, author)
3. SKILL.md must be read in full before audit
4. Scripts must be auditable (no obfuscation)
5. Network requirements must be documented
6. Write scope must not exceed skill directory
7. Conflict with existing VERIFIED skill = BLOCK until resolved
8. After import, skill enters UNVERIFIED until full audit

## Deprecation Rules

1. Skill not used in 6 months -> review for deprecation
2. Superseded skill -> mark SUPERSEDED, point to replacement
3. Security issue found -> immediate BLOCK
4. Deprecated skills kept for 12 months then archived
