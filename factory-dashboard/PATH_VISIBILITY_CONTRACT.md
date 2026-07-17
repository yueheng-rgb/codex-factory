# PATH_VISIBILITY_CONTRACT.md

> Part of: FACTORY-STATE-DASHBOARD-0
> Section: F — Path Visibility Contract
> Version: 1.0.0

---

## Purpose

Define what paths MUST be visible in the dashboard and what to do when paths are missing, stale, or unknown.

---

## Always Visible Paths

These paths MUST appear in every dashboard output:

| # | Path | Source |
|---|------|--------|
| 1 | `rootPath` | Project identity |
| 2 | `workingCopyPath` | Project identity |
| 3 | `factoryInstallPath` | Project identity |
| 4 | `governancePath` | Project identity |
| 5 | `outputsPath` | Project identity |
| 6 | `externalConversationSpacePath` | Project identity (if configured) |
| 7 | Latest phase report path | Phase ledger |
| 8 | Latest verifier result path | Governance |
| 9 | Agent ledger path | Agent ledger contract |
| 10 | Cleanup state path | Cleanup isolation |

---

## Path Health Rules

| Condition | Indicator | Action |
|-----------|-----------|--------|
| Path exists and matches projectId | 🟢 HEALTHY | Show path |
| Path exists but belongs to different projectId | 🔴 FOREIGN | Mark FOREIGN_PROJECT_CONTEXT |
| Path does not exist | 🔴 MISSING | UNKNOWN_WITH_REASON: "path not found" |
| Path exists but is stale (>7 days since last update) | 🟡 STALE | Show path + "⚠ Stale: last modified {date}" |
| Path exists but content fingerprint mismatched | 🟡 TAMPERED | Show path + "⚠ Content changed since last verified" |

---

## UNKNOWN_WITH_REASON Rules

| Situation | Format |
|-----------|--------|
| Path field is null in identity | `UNKNOWN_WITH_REASON: not configured` |
| Path does not exist on disk | `UNKNOWN_WITH_REASON: path not found at {path}` |
| Path exists but cannot be read | `UNKNOWN_WITH_REASON: permission denied at {path}` |
| Path belongs to foreign project | `UNKNOWN_WITH_REASON: foreign project {projectId}` |

---

## Anti-Patterns (Blocked)

| Anti-Pattern | Why Blocked |
|-------------|-------------|
| Any path omitted from dashboard | User cannot verify deliverables |
| UNKNOWN path shown as healthy | Misleading |
| FOREIGN path shown as current | Cross-contamination |
| Missing path silently skipped | User unaware of gap |
