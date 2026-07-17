# FACTORY-BUILD-PACK-ARCHITECTURE-P1 — Section I: Native Agent Lifecycle Integration

5 stages: PRE_SPAWN → SPAWN → ACTIVE → CLOSE → POST_CLOSE

Key rules:
- No spawn without validated AGENT_START_PACKET
- No spawn without write scope
- All spawns: fork_context:false
- All agents must close with receipt
- UI count ≠ active truth
- Agent count ≠ quality proof
