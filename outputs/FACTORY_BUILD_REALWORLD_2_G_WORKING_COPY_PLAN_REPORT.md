# FACTORY-BUILD-REALWORLD-2-G: Working-Copy Plan

**Date**: 2026-06-27
**Phase**: G — Working-Copy Plan

---

## 1. Working-Copy Location

| Attribute | Value |
|-----------|-------|
| Source | `C:\Users\90961\Documents\Codex\2026-06-10\files-mentioned-by-the-user-txt` |
| Proposed Working Copy | `C:\Codex_App_Factory\harness\realworld\tcm-project-ledger\working-copy\` |
| Copy Method | `robocopy` (Windows) with exclusions |
| User Approval Required | YES — before any copy creation |

## 2. Exclusion List (NOT to copy)

| Path/Pattern | Reason |
|-------------|--------|
| `.env` | Contains real production secrets |
| `db.sqlite3` | Contains real patient data |
| `__pycache__/` | Compiled artifacts |
| `*.pyc` | Compiled artifacts |
| `media/` | Uploaded files |
| `staticfiles/` | Collected static |
| `venv/`, `.venv/` | Virtual environment |
| `work/` | Helper scripts (optional) |
| `deploy_full.py`, `deploy_zh.py` | Production deploy scripts |
| `remote_check.py`, `remote_check2.py` | Remote access scripts |
| `upload_and_run.py` | Remote execution script |
| `test_server.py` | Production test script |
| `check_zhangsan.py` | Production query script |

## 3. Files TO Copy

| Path | Reason |
|------|--------|
| `manage.py` | Django entry point |
| `tcm_project_ledger/` | Project configuration |
| `core/` | Main application |
| `.env.example` | Environment template |
| `.gitignore` | Git configuration |
| `README.md` | Documentation |
| `requirements.txt` (if exists) | Dependencies |
| `fix_*.py`, `_audit*.py`, `_fix_*.py` | Audit/repair scripts |

## 4. Post-Copy Setup Plan

1. Create virtual environment
2. Install dependencies (django, django-widget-tweaks, openpyxl, python-dotenv, Pillow)
3. Copy `.env.example` to `.env` with development-safe values
4. Run `python manage.py migrate`
5. Run `python manage.py seed_data`
6. Run `python manage.py test core -v 2`
7. Run `python manage.py check`
8. Smoke test with `python manage.py runserver`

## 5. Safety Boundaries

| Rule | Enforcement |
|------|------------|
| No original project modification | File copy only; original untouched |
| No production DB access | New SQLite created in working copy |
| No remote connections | Deploy scripts excluded from copy |
| No secret exposure | `.env` excluded; `.env.example` used as template |

## 6. Phase G Status: COMPLETE

Working-copy plan ready. Awaiting user approval before execution.
