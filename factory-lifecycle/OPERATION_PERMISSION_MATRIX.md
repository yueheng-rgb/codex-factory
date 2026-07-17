# OPERATION_PERMISSION_MATRIX.md
> Part of: FACTORY-PROJECT-LIFECYCLE-0 / D

## Permissions Key
A=ALLOWED, C=ALLOWED_WITH_CONFIRMATION, P=PLAN_ONLY, R=READ_ONLY, B=BLOCKED

| Operation | NEW | ACTIVE | PAUSED | FROZEN | ARCHIVED | DELETED | MIGRATED | UNKNOWN | CORRUPT |
|-----------|-----|--------|--------|--------|----------|---------|----------|---------|---------|
| mount | B | A | C | R | R | B | B(redirect) | B | B |
| query memory | B | A | R | R | R | B | B | B | R |
| update memory | B | A | B | B | B | B | B | B | B |
| phase close | B | A | B | B | B | B | B | B | B |
| bootstrap | C | A | C | R | R | B | B | C | B |
| preflight | B | A | R | R | R | B | B | B | B |
| multi-agent | B | C | B | B | B | B | B | B | B |
| cleanup PLAN | B | A | B | B | B | B | B | B | B |
| cleanup execute | B | C | B | B | B | B | B | B | B |
| cleanup DELETE | B | C | B | B | C | B | B | B | B |
| build | B | A | B | B | B | B | B | B | B |
| package | B | A | B | B | B | B | B | B | B |
| release | B | A | B | B | B | B | B | B | B |
| recovery auto | B | A | A(L1) | B | B | B | B | B | B |
| recovery plan | B | A | A | R | R | B | B | B | A |
| identity change | C | C | C | C | C | B | B | A | B |

## Key Rules
- Multi-agent: ONLY on ACTIVE (with confirmation) — blocked on all other states
- Cleanup DELETE: requires lifecycle transition to DELETED with separate protocol
- CORRUPT: only recovery plan allowed, nothing else
- FROZEN/ARCHIVED: query only, no writes
- DELETED: completely blocked except restore
