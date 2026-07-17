# FACTORY-BUILD-PRO-2-P1 — Section E: Mode Selector Policy Update

**Phase**: FACTORY-BUILD-PRO-2-P1 | **Date**: 2026-06-27

## Mode Matrix

| Mode | Status | Context Packet | Native Agent | Approval |
|------|--------|---------------|-------------|----------|
| Build Lite | **DEFAULT** | OPTIONAL | FORBIDDEN | None |
| Native Build Pro | **CONDITIONAL** | **REQUIRED** | REQUIRED | **User must confirm** |
| Vanilla | PRODUCT LEADER | N/A | N/A | N/A |

## Selector Rules

1. Build Lite is DEFAULT — auto-triggered for 'build a project'
2. Native Build Pro requires EXPLICIT user confirmation
3. Project complexity alone does NOT trigger Build Pro
4. Vanilla always available as baseline
