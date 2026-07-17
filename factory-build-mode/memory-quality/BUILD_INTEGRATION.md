# Build Integration: Memory Quality + Build Modes

## Integration Points
| Build Mode | Memory Quality Requirements |
|------------|---------------------------|
| **Vanilla** | None (no external memory) |
| **Build Lite** | Ingestion policy (L3+), summary verification at phase boundaries |
| **Native Build Pro** | Full: ingestion, filtering, context packet generation before each spawn, role-filtered packets per agent |

## Native Build Pro Integration
1. **Before spawning**: Generate role-specific context packet from .codex-factory/
2. **Agent capsule includes**: context packet reference + relevant sections
3. **After agent close**: Validate agent output against packet claims
4. **Phase boundary**: Verify all packets, archive superseded state
