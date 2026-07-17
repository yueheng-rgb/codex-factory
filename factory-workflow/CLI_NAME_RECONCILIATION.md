# CLI_NAME_RECONCILIATION.md

> Part of: FACTORY-DEFAULT-WORKFLOW-0
> Section: H — CLI Name Reconciliation
> Version: 1.0.0

---

## Purpose

Ensure CLI command names used in Factory documentation, scripts, and user-facing instructions are consistent. Mismatched names cause user confusion and automation failures.

---

## Registered CLI Names (v0.5)

| Canonical Name | Location | Type |
|---------------|----------|------|
| `factory` | Factory CLI entry point | User-facing |
| `package-qa-check.ps1` | `factory-build-mode/` | Internal |
| `generate-context-packet.ps1` | `factory-build-mode/` | Internal |
| `validate-context-packet.ps1` | `factory-build-mode/` | Internal |
| `append-decision.ps1` | `factory-build-mode/` | Internal |
| `generate-handoff.ps1` | `factory-build-mode/` | Internal |
| `init-memory.ps1` | `factory-build-mode/` | Internal |
| `read-memory.ps1` | `factory-build-mode/` | Internal |
| `recover-startup.ps1` | `factory-build-mode/` | Internal |
| `update-state.ps1` | `factory-build-mode/` | Internal |
| `update-task.ps1` | `factory-build-mode/` | Internal |
| `validate-memory.ps1` | `factory-build-mode/` | Internal |

---

## Name Mismatch Policy

When a CLI name mismatch is detected:

| Scenario | Action |
|----------|--------|
| Script referenced by wrong name in docs | Log warning, use canonical name |
| User uses wrong name | Accept with warning, suggest canonical name |
| Script renamed but old name still referenced | Log FATAL if both names exist |
| Name collision (two scripts claim same name) | Log FATAL, block until resolved |

### Warning Format

```
⚠ CLI NAME WARNING: 'old-name' was used but canonical name is 'new-name'.
  Using canonical name 'new-name'. Please update your references.
```

---

## Reconciliation Checklist

When adding or renaming CLI commands:

1. [ ] Update `CLI_NAME_RECONCILIATION.md` registry
2. [ ] Check all scripts for references to old name
3. [ ] Check all governance JSONs for references
4. [ ] Check all report MDs for references
5. [ ] Run verifier to confirm no stale references
6. [ ] If renaming, add redirect/alias for backward compatibility (1 version)

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| CLI name mismatch ignored silently | User confusion |
| Two scripts with same functional name | Ambiguity |
| Renaming without registry update | Drift |
| Old name referenced in docs after rename | User follows dead instructions |
