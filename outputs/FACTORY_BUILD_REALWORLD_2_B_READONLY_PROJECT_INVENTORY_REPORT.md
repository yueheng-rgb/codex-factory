# FACTORY-BUILD-REALWORLD-2-B: Readonly Project Inventory Report

**Date**: 2026-06-27
**Phase**: B — Readonly Project Inventory
**Project**: tcm-project-ledger

---

## 1. Project Identity

| Attribute | Value |
|-----------|-------|
| Project Name | TCM Project Ledger (中医项目台账登记与医师工作量审核系统) |
| Framework | Django |
| Django Version | 5.x (per README; BigAutoField, path() urls, widget_tweaks) |
| Python Version | 3.x |
| Language | Chinese (zh-hans) |
| Timezone | Asia/Shanghai |
| Original Path | `C:\Users\90961\Documents\Codex\2026-06-10\files-mentioned-by-the-user-txt` |

## 2. Project Structure

```
tcm_project_ledger/                    # Django project config
  settings.py                          # Single settings file (no dev/prod split)
  urls.py                              # Project root URL conf
  wsgi.py / asgi.py                    # WSGI/ASGI entry points

core/                                   # Main Django app
  admin.py                             # Django Admin registration (15 models)
  apps.py                              # AppConfig (CoreConfig)
  constants.py                         # Business constants
  error_handler.py                     # Custom 404/500 handlers
  forms.py                             # All forms
  image_utils.py                       # Image handling utilities
  middleware.py                         # LoginLogging + ErrorLogging middleware
  models.py                            # 15 data models
  services.py                          # Business logic layer
  tests.py                             # Unit tests (259 lines)
  urls.py                              # App URL routing (~100 routes)
  validators.py                        # Custom validators
  views.py                             # View logic (1854 lines)
  _trash_views.py                      # Soft-delete views
  templatetags/custom_filters.py       # Custom template filters
  templates/                           # 69 HTML templates
  static/css/                          # CSS assets
  migrations/                          # 13 migration files
  management/commands/seed_data.py     # Seed data command

work/                                  # 35+ helper/repair scripts
  seed_projects.py, fix_*.py, rebuild*.py, etc.

Root files:
  manage.py                            # Django CLI
  db.sqlite3                           # SQLite database (457 KB)
  .env.example                         # Environment template
  .env                                 # Actual environment (exists)
  .gitignore                           # Git ignore rules
  README.md                            # Project documentation
```

## 3. Installed Apps

| App | Purpose |
|-----|---------|
| django.contrib.auth | Authentication |
| django.contrib.contenttypes | Content types |
| django.contrib.sessions | Sessions |
| django.contrib.messages | Flash messages |
| django.contrib.staticfiles | Static files |
| widget_tweaks | Django form rendering |
| core | Main application |

## 4. Data Models (15)

| # | Model | Description |
|---|-------|-------------|
| 1 | UserProfile | User extension (role, phone, avatar, balance, title, status) |
| 2 | Patient | Patient basic info (name, phone, id_card, medical_notes, tags) |
| 3 | Project | Treatment project (name, price, duration, materials, poster) |
| 4 | PatientProject | Patient-project linkage (total/used sessions) |
| 5 | VerificationRecord | Session verification records |
| 6 | TransactionLog | Transaction audit trail (add/deduct/reverse/adjust) |
| 7 | CorrectionRequest | Correction requests (pending/approved/rejected) |
| 8 | OperationLog | Operation audit log |
| 9 | LoginLog | Login audit log (success/failure, IP) |
| 10 | ProjectRate | Project pricing (rate_per_session, effective_date) |
| 11 | AnomalyRecord | Anomaly detection records |
| 12 | IssueReport | Issue/feedback reports |
| 13 | PatientReview | Patient reviews/ratings |
| 14 | ClinicSettings | Clinic configuration singleton |
| 15 | Notification | User notifications |

## 5. URL Routes Summary

| Area | Route Count | Key Routes |
|------|-------------|------------|
| Auth | 3 | login, logout, change-password |
| Dashboard | 4 | /, /admin/, /doctor/, /patient/ |
| Admin: Doctors | 8 | CRUD + reset-password, trash/restore/delete |
| Admin: Patients | 10 | CRUD + trash/restore/hard-delete/empty-trash, add/adjust sessions |
| Admin: Records | 4 | verifications, workload, workload-detail |
| Admin: Corrections | 4 | list, detail, approve, reject |
| Admin: Anomalies | 2 | list, resolve |
| Admin: Export | 2 | export, export-entities |
| Admin: Logs | 2 | operation-logs, login-logs |
| Admin: Projects | 5 | CRUD + showcase |
| Admin: Rates | 1 | project-rates |
| Admin: Reviews | 1 | patient-reviews |
| Admin: Notes | 2 | doctor-notes, clear |
| Admin: Issues | 2 | list, detail |
| Admin: Batch | 1 | batch-assign |
| Doctor | 8 | search, patient-detail, verify, records, workload, corrections |
| Doctor: Issues | 3 | list, create, detail |
| Patient | 4 | dashboard, review, change-password, edit-info, timeline |
| Profile | 2 | view, edit |
| Email | 2 | send-code, email-login |
| Notifications | 4 | list, read, read-all, unread-count |
| Charts/API | 2 | weekly, projects |
| System | 1 | health |
| **Total** | **~75** | |

## 6. Middleware Stack

| # | Middleware | Type |
|---|-----------|------|
| 1 | SecurityMiddleware | Django built-in |
| 2 | SessionMiddleware | Django built-in |
| 3 | CommonMiddleware | Django built-in |
| 4 | CsrfViewMiddleware | Django built-in |
| 5 | AuthenticationMiddleware | Django built-in |
| 6 | MessageMiddleware | Django built-in |
| 7 | XFrameOptionsMiddleware | Django built-in |
| 8 | LoginLoggingMiddleware | Custom (core) |
| 9 | ErrorLoggingMiddleware | Custom (core) |

## 7. Database

| Attribute | Value |
|-----------|-------|
| Default Engine | SQLite |
| SQLite File | db.sqlite3 (457 KB, 2026-06-14) |
| Supported Engines | SQLite, MySQL, PostgreSQL (via env) |
| Migrations | 13 files |
| Cache Backend | DatabaseCache |

## 8. Dependencies (Inferred)

| Package | Evidence |
|---------|----------|
| django (5.x) | manage.py, models patterns, settings |
| python-dotenv | settings.py: `from dotenv import load_dotenv` |
| django-widget-tweaks | INSTALLED_APPS, README |
| openpyxl | README (Excel export) |
| gunicorn | README (production deploy) |
| paramiko | deploy_full.py, deploy_zh.py, remote_check.py, upload_and_run.py |
| Pillow | ImageField usage |

No `requirements.txt` or `Pipfile`/`pyproject.toml` found. Dependencies documented in README only.

## 9. Tests

| Attribute | Value |
|-----------|-------|
| File | core/tests.py |
| Lines | 259 |
| Framework | django.test.TestCase |
| Classes | AuthTests, PatientManagementTests (+ more) |
| Command | `python manage.py test core -v 2` |

## 10. Deployment Scripts (NOT to be executed)

| File | Type | Risk |
|------|------|------|
| deploy_full.py | Full deploy (SFTP + SSH migrate + restart) | PRODUCTION_RISK |
| deploy_zh.py | Quick deploy 3 files + restart | PRODUCTION_RISK |
| remote_check.py | Remote DB query via SSH | PRODUCTION_RISK |
| remote_check2.py | Remote check variant | PRODUCTION_RISK |
| remote_script.py | Local DB inspection script | LOCAL_ONLY |
| upload_and_run.py | Upload + execute remote script | PRODUCTION_RISK |
| test_server.py | Server test | UNKNOWN_RISK |

All deploy scripts contain hardcoded server IP and credentials. See Phase C for details.

## 11. Production/Dev Config Split

| Aspect | Status |
|--------|--------|
| Separate settings file | NO — single settings.py |
| DEBUG control | Via env var `DJANGO_DEBUG` (default True) |
| SECRET_KEY control | Via env var `DJANGO_SECRET_KEY` (has unsafe default) |
| ALLOWED_HOSTS control | Via env var `DJANGO_ALLOWED_HOSTS` (default *) |
| DB config | Via env vars (default SQLite) |
| Static files | STATIC_ROOT configured |
| Security headers | Via env vars (default off) |

## 12. Phase B Status: COMPLETE

All project components inventoried without accessing production systems or exposing secrets.
