# Admin System Expert Pack

**Pack ID:** `admin-system`
**Domain:** Admin System / Management Backend
**Version:** 1.0.0
**Status:** ACTIVE

---

## Overview

The Admin System Expert Pack provides domain-specific rules, invariants, benchmarks,
and design patterns for building admin panels, management backends, and internal tools.

It covers:
- Admin authentication and session management
- Role-Based Access Control (RBAC) with multi-level roles
- CRUD table management with pagination, search, and filters
- Form validation and data integrity
- Batch operations with scope enforcement
- Audit logging for sensitive actions
- Destructive action confirmation
- Status transition workflows
- Data export/import with permission controls
- Protected field enforcement

---

## Invariants (13 rules)

| # | Invariant ID | Severity | Category |
|---|-------------|----------|----------|
| 1 | `admin_required_for_admin_routes` | CRITICAL | authentication |
| 2 | `role_permission_must_be_enforced` | CRITICAL | permission |
| 3 | `ordinary_admin_cannot_escalate_role` | CRITICAL | permission |
| 4 | `destructive_action_requires_confirmation` | CRITICAL | safety |
| 5 | `deleted_record_not_listed_by_default` | HIGH | data-integrity |
| 6 | `status_transition_allowed` | HIGH | business-logic |
| 7 | `protected_fields_cannot_be_modified_without_permission` | CRITICAL | permission |
| 8 | `batch_operation_must_be_scoped` | HIGH | safety |
| 9 | `audit_log_required_for_sensitive_actions` | HIGH | audit |
| 10 | `export_requires_permission` | HIGH | permission |
| 11 | `import_requires_validation` | HIGH | data-integrity |
| 12 | `pagination_limit_enforced` | MEDIUM | performance |
| 13 | `search_filter_must_be_whitelisted` | HIGH | security |

---

## Surface Templates

| Template | Description | Risk |
|----------|-------------|------|
| `admin-crud-only` | Simple CRUD admin, single entity, basic auth | MEDIUM |
| `admin-with-roles` | RBAC + audit log | HIGH |
| `admin-full` | RBAC + batch ops + export + status workflows | CRITICAL |
| `admin-super-admin` | Multi-level roles + protected fields + import | L_CLASS |

---

## Benchmarks

| ID | Scenario | Surfaces | Risk | Runnable |
|----|----------|----------|------|----------|
| ADMIN-B1 | Simple CRUD admin | admin-web,api,database | MEDIUM | ✅ |
| ADMIN-B2 | RBAC + audit log | +docs-release | HIGH | ✅ |
| ADMIN-B3 | Full admin (batch, export, status) | +docs-release | CRITICAL | 📋 design-only |
| ADMIN-B4 | Super-admin (all invariants) | +docs-release | L_CLASS | 📋 design-only |

---

## Activation

The pack activates when task description contains keywords like:
- 后台管理, 管理系统, 管理后台, admin, dashboard
- 用户管理, 角色管理, 权限管理, RBAC
- 批量操作, 审计日志, 状态流转
- CRUD管理, 表格管理, 数据导出

Deactivates (no match) for: 文档修改, README, 文案, 样式调整, 商城, 电商, ecommerce, SaaS

---

## Integration Points

| Point | Status |
|-------|--------|
| Surface Plan | ✅ Integrated |
| Risk Classifier | ✅ 10 domain rules |
| Invariant Engine | ✅ 13 invariants |
| Engine Broker | ✅ semgrep required |
| Gate Detection | ✅ Evidence binding |
| Risk Gate | ✅ CRITICAL/L_CLASS require human audit |

---

## Non-Claims

- NOT a complete production admin system
- NOT including SSO/SAML/OIDC
- NOT including real-time notifications
- NOT including complex multi-step approval workflows
- NOT including BI dashboards or data warehousing
- NOT including i18n or a11y compliance
- Design aid only — domain rules, invariants, test patterns

---

## File Structure

```
governance/expert-packs/admin-system/
├── admin-system-pack.json          # Pack definition
├── admin-system-invariants.json    # 13 invariants
├── admin-system-benchmarks.json    # 4 benchmarks
└── ADMIN_SYSTEM_PACK.md            # This file
```
