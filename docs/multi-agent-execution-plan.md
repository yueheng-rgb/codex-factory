# Multi-Agent Execution Plan

## Agent Roles

| Agent | Role | Authority |
|---|---|---|
| Main Agent | Project Lead | Final decision, acceptance, rejection |
| Integrator Agent | Integration Lead | Merge all worker outputs, resolve conflicts |
| Worker Agents | Domain specialists | Execute assigned tasks within defined scope |

## Worker Boundaries

Workers operate within strict boundaries:
- **Allowed files**: only their assigned `src/<worker>/` and `tests/<worker>/` directories
- **Forbidden files**: auth, secrets, config outside their scope
- **Handoff requirements**: must produce stdout.log and artifact receipt
- **Completion criteria**: all assigned tasks have output artifacts

## Execution Order

1. Requirement Analysis → 2. Architecture Design → 3. Data Model → 4. API Contract
5. Backend Modules → 6. Frontend Modules → 7. Integration → 8. Testing → 9. Documentation → 10. Final Verification

## Gates

Before each phase transition:
1. Snapshot Verifier (15/15 check)
2. Secret Scan
3. Review Gate (for P0/P1 risk tasks)
4. Artifact Gate (all output artifacts present)
