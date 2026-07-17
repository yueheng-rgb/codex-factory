# FACTORY-BUILD-PACK-ARCHITECTURE-P1 — Section H: Context Packet Integration

| Trigger | Packet Type | Required |
|---------|------------|----------|
| Phase start | PHASE_START_PACKET | Build Pro |
| Agent spawn | AGENT_START_PACKET | Build Pro |
| Review | REVIEWER_PACKET | Build Pro |
| Recovery | RECOVERY_PACKET | Build Pro |
| Repair | REPAIR_PACKET | Build Pro |
| User summary | USER_SUMMARY_PACKET | Optional |

Flow: Trigger → Generate → Validate (21 checks) → PASS → Agent allowed | FAIL → Blocked
