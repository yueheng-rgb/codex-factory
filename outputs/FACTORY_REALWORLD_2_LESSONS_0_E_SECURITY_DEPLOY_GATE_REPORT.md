# FACTORY-REALWORLD-2-LESSONS-0 Section E: Security/Deploy Gate Formalization

**Timestamp**: 2026-06-28T10:58:00+08:00
**Status**: GATE_FORMALIZED

---

## SECURITY_DEPLOY_GATE — Required Gate

**Type**: REQUIRED for deployed/online projects
**Trigger**: .env secrets, deploy scripts, server IPs, API tokens, production DB refs

## 10 Gate Checks

| ID | Check | Blocking |
|----|-------|----------|
| SDG-001 | No secret values in output | YES |
| SDG-002 | Working-copy free of plaintext production creds | YES |
| SDG-003 | User rotation checklist generated | YES |
| SDG-004 | No deploy/remote/SSH executed | YES |
| SDG-005 | No production DB accessed | YES |
| SDG-006 | Original project protected | YES |
| SDG-007 | Security changes = config/docs only | NO |
| SDG-008 | CSRF/Session defaults documented | NO |
| SDG-009 | HTTPS recommendation documented | NO |
| SDG-010 | Dev/prod split recommendation documented | NO |

**Blocking rule**: Any YES-blocking check fails → phase CANNOT PASS.

## Integration Points

- **Build Lite**: Run after working-copy, before modifications
- **Package QA Gate**: Included in final delivery check
- **Staging Pack**: Include gate result in staging bundle
