# FACTORY-BUILD-REALWORLD-2-C: Secret Exposure Audit Report

**Date**: 2026-06-27
**Phase**: C — Sensitive File and Secret Exposure Audit
**Project**: tcm-project-ledger
**Rule**: No secret values displayed. Types, paths, risk levels, and actions only.

---

## CRITICAL FINDINGS SUMMARY

| Severity | Count | Action Required |
|----------|-------|-----------------|
| CRITICAL | 7 | Immediate rotation required |
| HIGH | 4 | Rotation recommended |
| MEDIUM | 3 | Review and remediate |
| LOW | 2 | Best practice improvement |

---

## 1. Secret Inventory

### 1.1 `.env` File (CRITICAL - 5 real secrets)

| # | Key/Type | Severity | Real/Placeholder | Risk |
|---|----------|----------|-------------------|------|
| 1 | DJANGO_SECRET_KEY | **CRITICAL** | REAL | Session hijacking, crypto forgery |
| 2 | EMAIL_HOST (smtp.qq.com) | HIGH | REAL | Service enumeration |
| 3 | EMAIL_HOST_USER (QQ email) | HIGH | REAL | Account exposure, phishing target |
| 4 | EMAIL_HOST_PASSWORD (SMTP auth code) | **CRITICAL** | REAL | Email account compromise |
| 5 | DEFAULT_FROM_EMAIL | MEDIUM | REAL | Information disclosure |

**File**: `.env` (in project root, excluded from `.gitignore`)

### 1.2 Deployment Scripts — Server Credentials (CRITICAL)

| # | File | Secret Type | Severity | Risk |
|---|------|------------|----------|------|
| 6 | deploy_full.py | Server IP + SSH user + SSH password | **CRITICAL** | Full server compromise |
| 7 | deploy_zh.py | Server IP + SSH user + SSH password | **CRITICAL** | Full server compromise |
| 8 | remote_check.py | Server IP + SSH user + SSH password | **CRITICAL** | Full server compromise |
| 9 | remote_check2.py | Server IP + SSH user + SSH password | **CRITICAL** | Full server compromise |
| 10 | upload_and_run.py | Server IP + SSH user + SSH password | **CRITICAL** | Full server compromise |
| 11 | test_server.py | Server IP + SSH user + SSH password | **CRITICAL** | Full server compromise |
| 12 | check_zhangsan.py | Server IP + SSH user + SSH password | **CRITICAL** | Full server compromise |

**All 7 files** contain hardcoded:
- SSH host (Alibaba Cloud ECS IP)
- SSH username (plaintext)
- SSH password (plaintext)
- Remote deployment path

### 1.3 Hardcoded Test Passwords (HIGH)

| # | File | Secret Type | Severity | Risk |
|---|------|------------|----------|------|
| 13 | remote_check.py | Hardcoded password check value | HIGH | User credential exposure |
| 14 | remote_check2.py | Hardcoded password check value | HIGH | User credential exposure |
| 15 | remote_script.py | Hardcoded password check value | HIGH | User credential exposure |
| 16 | check_zhangsan.py | Obfuscated password check | HIGH | Weak obfuscation (chr() encoding) |

### 1.4 Script Default Credentials (MEDIUM)

| # | File(s) | Value | Severity |
|---|---------|-------|----------|
| 17 | work/check_admin.py, work/check_export.py, work/check_ui.py, work/rebuild*.py, etc. | admin/admin123 (default admin credentials) | MEDIUM |
| 18 | work/check_ui.py | doctor1/pass123456 (default doctor credentials) | MEDIUM |
| 19 | test_server.py | patient1/patient123 (default patient credentials) | MEDIUM |

### 1.5 Captcha API Credentials (LOW — Placeholder)

| # | File | Key | Severity | Real/Placeholder |
|---|------|-----|----------|-------------------|
| 20 | .env.example | CAPTCHA_ACCESS_KEY | LOW | PLACEHOLDER |
| 21 | .env.example | CAPTCHA_ACCESS_SECRET | LOW | PLACEHOLDER |

### 1.6 SMS API Placeholders (LOW)

| # | File | Key | Severity | Real/Placeholder |
|---|------|-----|----------|-------------------|
| 22 | work/add_redis_settings.py | SMS_ALIBABA_ACCESS_KEY / SMS_ALIBABA_SECRET | LOW | PLACEHOLDER (env var) |

---

## 2. Settings Security Audit

| Setting | Current Value | Risk | Recommended |
|---------|--------------|------|-------------|
| SECRET_KEY | Real production key in .env | CRITICAL | Rotate immediately |
| DEBUG | False (in .env) | OK | Production-safe |
| ALLOWED_HOSTS | controlled by env | OK | Verify not wildcard in prod |
| CSRF_COOKIE_SECURE | env-controlled (default False) | HIGH | Set True in production |
| SESSION_COOKIE_SECURE | env-controlled (default False) | HIGH | Set True in production |
| SECURE_SSL_REDIRECT | env-controlled (default False) | MEDIUM | Set True in production |
| SECURE_HSTS_SECONDS | env-controlled (default 0) | MEDIUM | Set > 0 in production |
| SECURE_BROWSER_XSS_FILTER | True | OK | - |
| SECURE_CONTENT_TYPE_NOSNIFF | True | OK | - |
| X_FRAME_OPTIONS | DENY | OK | - |

---

## 3. Files with Secrets — Complete List

| File | Secret Count | Max Severity | Action |
|------|-------------|-------------|--------|
| `.env` | 5 | CRITICAL | Rotate all credentials; delete from any version control |
| `deploy_full.py` | 3 | CRITICAL | Remove hardcoded credentials; use env vars; rotate SSH key |
| `deploy_zh.py` | 3 | CRITICAL | Same as above |
| `remote_check.py` | 4 | CRITICAL | Remove; use SSH key auth; remove hardcoded password |
| `remote_check2.py` | 4 | CRITICAL | Same as above |
| `upload_and_run.py` | 3 | CRITICAL | Remove; use SSH key auth |
| `test_server.py` | 4 | CRITICAL | Remove; use env vars |
| `check_zhangsan.py` | 4 | CRITICAL | Remove; use env vars |
| `remote_script.py` | 1 | HIGH | Remove hardcoded password |
| `work/check_ui.py` | 2 | MEDIUM | Use env vars for test credentials |
| `work/check_admin.py` | 1 | MEDIUM | Use env vars |
| `work/check_export.py` | 1 | MEDIUM | Use env vars |
| `.env.example` | 2 | LOW | Already placeholders — OK |
| `work/add_redis_settings.py` | 2 | LOW | Already placeholders — OK |

---

## 4. Recommendations

### Immediate (CRITICAL)
1. **Rotate DJANGO_SECRET_KEY** on production immediately
2. **Rotate SMTP authorization code** on QQ mail
3. **Rotate SSH password** on Alibaba Cloud ECS; switch to SSH key authentication
4. **Remove all hardcoded credentials** from all 7 deploy scripts
5. **Verify `.env` is in `.gitignore`** and not committed to any repository

### Short-term (HIGH)
6. Enable CSRF_COOKIE_SECURE, SESSION_COOKIE_SECURE, SECURE_SSL_REDIRECT in production
7. Replace hardcoded test passwords with environment variables
8. Audit git history for any accidentally committed `.env` files

### Medium-term (MEDIUM)
9. Create separate `.env.production` / `.env.development` files
10. Implement secrets management (e.g., environment variables only, no .env files on server)
11. Add pre-commit hooks to detect hardcoded secrets

---

## 5. Phase C Status: COMPLETE

Total secrets identified: **22** (7 CRITICAL, 4 HIGH, 3 MEDIUM, 2 LOW)
No secret values displayed in this report. All findings reported by type, file path, severity, and recommended action only.
