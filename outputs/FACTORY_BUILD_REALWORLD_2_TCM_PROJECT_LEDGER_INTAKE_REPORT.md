# FACTORY-BUILD-REALWORLD-2-J: TCM Project Ledger Intake Report

**Date**: 2026-06-27
**Phase**: J — Real Project Intake Summary and Next Step
**Project**: tcm-project-ledger (中医项目台账登记与医师工作量审核系统)

---

## Q1: Is this project suitable for REALWORLD-2?

**YES.** This is an ideal REALWORLD-2 candidate:
- Real deployed Django project on Alibaba Cloud ECS
- Production database with real patient/doctor data
- Multiple deployment scripts proving production usage
- Real credentials (email, SSH) present — evidence of real deployment
- Complex multi-role system (admin/doctor/auditor/patient)
- 15 models, 75+ URL routes, 69 templates, 1854-line views
- ~259 lines of tests

## Q2: Is it more suitable than Online Bookstore?

**YES.** Compared to a hypothetical bookstore:
- More complex security surface (3 roles + patient self-service)
- Real cloud deployment with SSH/nginx/gunicorn/systemd
- Medical/healthcare domain — higher compliance sensitivity
- Actual production credentials found — more urgent security remediation needed
- Real patient data in SQLite — privacy implications

## Q3: What makes it a real deployed project?

| Evidence | Proof |
|----------|-------|
| `.env` with real SECRET_KEY | Not a placeholder — unique production key |
| `.env` with real QQ SMTP credentials | Real email sending configured |
| 7 deploy scripts with real server IP | 124.221.10.61 (Alibaba Cloud ECS) |
| SSH credentials in deploy scripts | Real ubuntu user with password auth |
| systemd service config in README | tcm-ledger.service documented |
| Nginx config in README | Reverse proxy with domain reference |
| Gunicorn config in README | 4 workers on production |
| SQLite with real data | 457 KB, last modified 2026-06-14 |
| Seed data with default accounts | admin/admin123, doctor1/doctor123 |

## Q4: What are the top security/deploy risks?

### 🔴 CRITICAL (Immediate Action Required)

1. **DJANGO_SECRET_KEY in .env** — Session hijacking, crypto forgery risk
2. **SMTP password in .env** — QQ email account compromise
3. **SSH password in 7 scripts** — Full server compromise via hardcoded credentials
4. **Server IP + credentials combination** — Single leak = full production access

### 🟠 HIGH (Short-term)

5. **CSRF_COOKIE_SECURE defaults to False** — CSRF tokens over HTTP in production
6. **SESSION_COOKIE_SECURE defaults to False** — Session cookies over HTTP
7. **No HTTPS enforcement** — SECURE_SSL_REDIRECT default False
8. **Hardcoded test passwords** — User credential exposure in scripts

### 🟡 MEDIUM

9. No CI/CD pipeline — manual script-based deployment
10. No rollback mechanism — no automated backup/restore
11. No separate dev/prod settings files

## Q5: Should next phase be readonly deeper audit, working-copy validation, or targeted repair?

**Working-copy validation (REALWORLD-2-P1).** Rationale:
- Readonly audit is complete (Phases A-J)
- All risks documented and classified
- Next logical step: validate the project actually runs correctly in isolation
- Working-copy validation confirms the project is functional before any repair
- Secret rotation must happen BEFORE any repair work begins

## Q6: Should Native Build Pro be used now?

**NO.** Native Build Pro adds complexity that is not needed for:
- Working-copy creation (simple file copy)
- Local Django validation (manage.py check/test/runserver)
- Secret rotation (manual process)

Native Build Pro may be appropriate in REALWORLD-2-P2 if automated remediation is needed at scale.

## Q7: What user approval is required before any modification?

| Action | Approval Required |
|--------|-------------------|
| Create working copy | ✅ YES — Phase G plan presented |
| Run local validation | ✅ YES — Phase H plan presented |
| Modify original project | ❌ FORBIDDEN — evidence lock active |
| Execute deploy scripts | ❌ FORBIDDEN — deploy gate active |
| Connect to production server | ❌ FORBIDDEN — security gate active |
| Rotate secrets | ✅ YES — requires separate approval |
| Begin targeted repair | ✅ YES — after P1 validation passes |

---

## Intake Verdict

| Criterion | Result |
|-----------|--------|
| Suitable for REALWORLD-2 | ✅ YES |
| Readonly intake complete | ✅ Phases A-J done |
| No secrets exposed in reports | ✅ All masked |
| No production accessed | ✅ No connections made |
| No original files modified | ✅ Read-only access only |
| Clear next step defined | ✅ REALWORLD-2-P1 working-copy validation |
| Build Lite selected | ✅ |
| Security/Deploy Gate active | ✅ |
| Context Packet planned | ✅ |
| Native Build Pro deferred | ✅ |

---

## Recommended Next Phase: REALWORLD-2-P1

**Action**: Create working copy → local validation → test suite run → runserver smoke test

**Prerequisites**: 
1. User approval for working copy creation
2. Python 3.8+ available on local machine
3. pip packages: django, django-widget-tweaks, openpyxl, python-dotenv, Pillow

**Duration estimate**: ~15 minutes

---

## Phase J Status: COMPLETE
