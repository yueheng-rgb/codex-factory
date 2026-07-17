# SKILL_PROFILE_LOADING_POLICY.md
> Part of: FACTORY-MULTI-AGENT-ORCHESTRATION-1 / E

## Policy
- Role profiles and skill definitions are pre-loaded (stored, not spawned)
- Skills loaded per role from `skills/` directory
- Only skills matching role's allowedTools are loaded
- Profile loading does NOT spawn an agent — just prepares the role definition
- Always-on agents NOT required: load profile, spawn on demand

## Loading Rules
- Router loads: APP_TYPE_ROUTER, STACK_DECISION_GUIDE
- Architect loads: blueprints, design patterns
- Implementer loads: starters, language-specific skills
- Test/Verifier loads: verifier schemas, negative control templates
- Security loads: secret scanning patterns, deploy gate rules
- Package QA loads: manifest schemas, hash verification
- Memory/Context loads: context indexing, evidence preservation
- Integrator loads: contract schemas, handoff schemas, attribution rules

## Forbidden
- Loading skills outside role scope
- Loading skills that grant write access beyond contract
- Auto-loading without role assignment
