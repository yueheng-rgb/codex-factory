# FACTORY-REALWORLD-2-LESSONS-0 Section F: User Secret Rotation Boundary

**Timestamp**: 2026-06-28T10:58:00+08:00
**Status**: BOUNDARY_FORMALIZED — CRITICAL

---

## Core Rule

> Codex Factory MUST document what to rotate but MUST NEVER rotate secrets for the user.

## Boundary Table

| ID | Action | Allowed |
|----|--------|---------|
| SRB-001 | IDENTIFY secrets | YES |
| SRB-002 | DOCUMENT rotation steps | YES |
| SRB-003 | GENERATE placeholder values | YES |
| SRB-004 | ADD .env to .gitignore | YES |
| SRB-005 | Generate new production secret values | NO |
| SRB-006 | Execute rotation on production | NO |
| SRB-007 | Print secret values in outputs | NO |
| SRB-008 | Store secrets in governance JSONs | NO |

## User Rotation Checklist (Template)

1. Generate new DJANGO_SECRET_KEY
2. Update .env with new key
3. Generate new SMTP app password
4. Update .env with new SMTP password
5. Change SSH password on server
6. Set up SSH key-based auth
7. Remove hardcoded credentials from deploy scripts
8. Verify deploy scripts work
9. Rotate API keys/tokens
10. Audit: no plaintext credentials remain

User MUST execute all steps offline before production deployment.
