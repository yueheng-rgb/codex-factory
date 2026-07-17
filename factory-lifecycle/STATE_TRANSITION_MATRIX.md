# STATE_TRANSITION_MATRIX.md
> Part of: FACTORY-PROJECT-LIFECYCLE-0 / C

## Allowed Transitions

| From | To | Condition |
|------|----|-----------|
| NEW | ACTIVE | User confirms identity |
| NEW | UNKNOWN_NEEDS_CONFIRMATION | Path issue detected |
| ACTIVE | PAUSED | User pauses |
| ACTIVE | FROZEN | User freezes (e.g., for audit) |
| ACTIVE | ARCHIVED | User archives (project complete) |
| ACTIVE | DELETED | User deletes (requires deletion plan + double confirm) |
| ACTIVE | CORRUPT_NEEDS_RECOVERY | Dashboard detection or RECOVERY scan |
| PAUSED | ACTIVE | User resumes |
| PAUSED | ARCHIVED | User archives from paused |
| FROZEN | ACTIVE | User unfreezes (confirmation required) |
| FROZEN | ARCHIVED | User archives from frozen |
| ARCHIVED | ACTIVE | User reactivates (confirmation required) |
| ARCHIVED | DELETED | User deletes (confirmation required) |
| MIGRATED | ACTIVE (new) | Redirect to new identity with confirmation |
| UNKNOWN | ACTIVE | Identity confirmed by user |
| CORRUPT | ACTIVE | Recovery PASS + user confirmation |

## Blocked Transitions
- DELETED → ACTIVE without restore plan + double confirmation
- DELETED → default mount (BLOCKED)
- ARCHIVED → automatic update (BLOCKED)
- FROZEN → automatic phase close (BLOCKED)
- CORRUPT → normal bootstrap without recovery (BLOCKED)
- Any → DELETED without deletion protocol
- Any → MIGRATED without new identity
