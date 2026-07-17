# FACTORY-BUILD-REALWORLD-2-D: Deployment & Production Safety Audit Report

**Date**: 2026-06-27
**Phase**: D — Deployment and Production Safety Audit
**Project**: tcm-project-ledger
**Rule**: Inspect only. Do not execute any deploy/remote commands.

---

## 1. Deployment Script Classification

| # | File | Classification | Rationale |
|---|------|---------------|-----------|
| 1 | deploy_full.py | **PRODUCTION_RISK** | SFTP upload + SSH migrate + systemctl restart on production |
| 2 | deploy_zh.py | **PRODUCTION_RISK** | SFTP upload + systemctl restart on production |
| 3 | remote_check.py | **PRODUCTION_RISK** | SSH into production + Django DB queries |
| 4 | remote_check2.py | **PRODUCTION_RISK** | SSH into production + Django shell queries |
| 5 | upload_and_run.py | **PRODUCTION_RISK** | SFTP upload + SSH remote execution |
| 6 | test_server.py | **PRODUCTION_RISK** | SSH into production + HTTP tests against production |
| 7 | check_zhangsan.py | **PRODUCTION_RISK** | SSH into production + DB queries |
| 8 | remote_script.py | **LOCAL_ONLY** | Local Django shell script (no remote connection) |
| 9 | fix_hint.py | **LOCAL_ONLY** | Local helper script |
| 10 | fix_multiple.py | **LOCAL_ONLY** | Local helper script |
| 11 | fix_pinyin2.py | **LOCAL_ONLY** | Local helper script |
| 12 | fix_redirect.py | **LOCAL_ONLY** | Local helper script |
| 13 | _audit2.py, _audit3.py, _full_audit.py | **LOCAL_ONLY** | Local audit scripts |
| 14 | _fix_load2.py, _fix_load_pos.py | **LOCAL_ONLY** | Local fix scripts |

---

## 2. Production Commands Identified (NOT to be executed)

### In deploy_full.py:
- `sftp.put(local, remote)` — File upload to production
- `python3 manage.py migrate` — Production DB migration
- `python3 manage.py check` — Production Django check
- `sudo systemctl restart tcm-ledger` — Production service restart

### In deploy_zh.py:
- `sftp.put(...)` — Upload 3 files to production
- `sudo systemctl restart tcm-ledger` — Production service restart
- `python3 manage.py check` — Production Django check

### In remote_check.py / remote_check2.py:
- Remote Django ORM queries against production DB
- Password validation against production user accounts

### In upload_and_run.py:
- SFTP upload of arbitrary script
- Remote execution + script cleanup

### In test_server.py:
- SSH into production server
- HTTP POST to production login endpoint

---

## 3. Production Infrastructure (from README)

| Component | Evidence | Risk Assessment |
|-----------|----------|-----------------|
| Web Server | Nginx reverse proxy | Standard, safe when configured properly |
| WSGI Server | Gunicorn (4 workers) | Standard, safe |
| System Service | systemd (tcm.service) | Standard, safe |
| Server OS | Ubuntu (per SSH user) | Standard |
| Cloud Provider | Alibaba Cloud ECS (per IP) | Standard |
| Deployment Path | /opt/tcm_project_ledger | Standard |
| Service Name | tcm-ledger | Non-standard but acceptable |

---

## 4. Deployment Safety Assessment

| Check | Status | Notes |
|-------|--------|-------|
| Deploy scripts present | YES | 7 production-touching scripts |
| Scripts execute remote commands | YES | All 7 do SSH + systemctl/migrate |
| Hardcoded credentials in scripts | YES | All 7 have credentials |
| DEBUG=False in production | YES (per .env) | Confirmed |
| ALLOWED_HOSTS configured | YES (env-based) | Need to verify not wildcard |
| collectstatic configured | YES | STATIC_ROOT = staticfiles/ |
| HTTPS enforced | UNKNOWN | SECURE_SSL_REDIRECT default False |
| Database backup mechanism | DOCUMENTED | Manual cp in README |
| Rate limiting on login | YES | Middleware with cache-based limiting |
| Audit logging | YES | LoginLog + OperationLog |

---

## 5. Risks Identified

### PRODUCTION_RISK (7 scripts)
All deploy/remote scripts can mutate production state (restart services, run migrations, modify files). They also contain hardcoded credentials making them extremely dangerous if leaked.

### REMOTE_MUTATING
- `deploy_full.py`: Can modify production code and DB schema
- `deploy_zh.py`: Can modify production code
- `upload_and_run.py`: Can execute arbitrary code on production

### Deployment Architecture Risk
- **No CI/CD pipeline**: Manual script-based deployment
- **No rollback mechanism**: No backup/restore automation
- **No deployment logging**: Success/failure not systematically tracked
- **No staging environment**: Changes go directly to production

---

## 6. Recommended Deployment Improvements

1. **Immediate**: Remove hardcoded credentials from all deploy scripts
2. **Immediate**: Switch to SSH key-based authentication
3. **Short-term**: Implement environment-variable-based deploy config
4. **Short-term**: Add deployment logging
5. **Medium-term**: Set up CI/CD pipeline
6. **Medium-term**: Create staging environment
7. **Medium-term**: Implement automated database backups
8. **Long-term**: Containerize with Docker for reproducibility

---

## 7. Phase D Status: COMPLETE

All deploy scripts inspected and classified without execution. No remote connections made. No production systems accessed.
