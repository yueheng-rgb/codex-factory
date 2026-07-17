# FACTORY-BUILD-REALWORLD-2-A: Setup & Evidence Lock Report

**Date**: 2026-06-27
**Phase**: A — Setup and Evidence Lock
**Project**: tcm-project-ledger (中医项目台账登记与医师工作量审核系统)

---

## 1. Evidence Lock Established

| Lock Rule | Status |
|-----------|--------|
| Readonly intake only | ACTIVE |
| No production modification | ACTIVE |
| No deployment allowed | ACTIVE |
| No secret disclosure | ACTIVE |
| No Native Build Pro | ACTIVE |
| No v0.5 package | ACTIVE |
| No release ZIP | ACTIVE |
| No remote connection | ACTIVE |
| No original path modification | ACTIVE |

## 2. Harness Structure Created

- `harness/realworld/tcm-project-ledger/` — REALWORLD-2 working harness
- `harness/realworld/tcm-project-ledger/original-path-record.json` — Original project path evidence
- `governance/factory-build/factory-build-realworld-2-setup-evidence-lock.json` — Governance record

## 3. Original Project Record

- **Path**: `C:\Users\90961\Documents\Codex\2026-06-10\files-mentioned-by-the-user-txt`
- **Framework**: Django 5.x
- **Database**: SQLite (db.sqlite3 present)
- **Deployment evidence**: Alibaba Cloud ECS (server IP and credentials present in deploy scripts — NOT disclosed)
- **Staging bundle**: Codex Factory v0.9.0-pre

## 4. User Approval

- Readonly intake approved
- No production modification authorized
- Factory staging bundle available at `C:\Codex_App_Factory`

## 5. Phase A Status: COMPLETE

Evidence lock is active. Proceeding to Phase B (Readonly Project Inventory).
