# FACTORY-BUILD-REALWORLD-2-P1-C: Working Copy Creation Report

**Generated:** 2026-06-28T10:17:03+08:00
**Phase:** FACTORY-BUILD-REALWORLD-2-P1
**Section:** C — Working Copy Creation

---

## Verdict: WORKING_COPY_SAFE

Working copy created at $wc with 117 files. All secrets and deploy scripts excluded. Original project untouched.

## Exclusion Verification (12/12 OK)

| File | Expected | Actual |
|---|---|---|
| .env (secrets) | EXCLUDED | EXCLUDED |
| db.sqlite3 (patient data) | EXCLUDED | EXCLUDED |
| deploy_full.py (SSH creds) | EXCLUDED | EXCLUDED |
| deploy_zh.py (SSH creds) | EXCLUDED | EXCLUDED |
| remote_check.py (prod access) | EXCLUDED | EXCLUDED |
| upload_and_run.py (deploy) | EXCLUDED | EXCLUDED |
| test_server.py (SSH creds) | EXCLUDED | EXCLUDED |
| check_zhangsan.py (passwords) | EXCLUDED | EXCLUDED |
| manage.py | PRESENT | PRESENT |
| README.md | PRESENT | PRESENT |
| core/ | PRESENT | PRESENT |
| tcm_project_ledger/ | PRESENT | PRESENT |

## .codex-factory/ Created

- context-packet.json — full project context for future sessions
- Ready for additional ledger files

## Original Project Protection

Original project at C:\Users\90961\Documents\Codex\2026-06-10\files-mentioned-by-the-user-txt is UNTOUCHED. Evidence lock active.
