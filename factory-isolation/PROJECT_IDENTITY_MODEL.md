# PROJECT_IDENTITY_MODEL.md

> Part of: FACTORY-PROJECT-ISOLATION-0
> Section: B — Project Identity Model
> Version: 1.0.0

---

## Purpose

Define a unique, stable identity for each project managed by Codex Factory. Every isolation rule depends on being able to reliably distinguish "this project" from "that project."

---

## Identity Fields

| # | Field | Type | Required | Description |
|---|-------|------|----------|-------------|
| 1 | `projectId` | UUID v4 | Yes | Globally unique identifier |
| 2 | `projectName` | string | Yes | Human-readable name |
| 3 | `rootPath` | absolute path | Yes | Project root directory |
| 4 | `workingCopyPath` | absolute path | No | Active working copy path |
| 5 | `factoryInstallPath` | absolute path | Yes | `.codex-factory/` location |
| 6 | `externalConversationSpacePath` | absolute path | No | External conversation space |
| 7 | `governancePath` | absolute path | Yes | Governance directory |
| 8 | `outputsPath` | absolute path | Yes | Outputs directory |
| 9 | `agentLedgerPath` | absolute path | No | Agent ledger file path |
| 10 | `cleanupStatePath` | absolute path | No | Cleanup state file |
| 11 | `createdAt` | ISO 8601 | Yes | When project was first registered |
| 12 | `lastMountedAt` | ISO 8601 | Yes | Last time project was active |
| 13 | `status` | enum | Yes | See status values below |
| 14 | `parentProjectId` | UUID or null | No | If forked/cloned from another project |
| 15 | `sourceProjectId` | UUID or null | No | If migrated from another project |
| 16 | `pathFingerprint` | SHA256 | Yes | Hash of rootPath for path-change detection |
| 17 | `contentFingerprint` | SHA256 | Yes | Hash of key content for tamper detection |
| 18 | `userConfirmedIdentity` | boolean | Yes | Whether user explicitly confirmed this identity |

---

## Status Values

| Value | Description | Mountable | Writable |
|-------|-------------|-----------|----------|
| `ACTIVE` | Currently active project | Yes | Yes |
| `PAUSED` | Temporarily inactive | Yes (with prompt) | Yes |
| `ARCHIVED` | Completed, not default-mounted | No (manual only) | No |
| `FROZEN` | Read-only protected | Yes (query only) | No |
| `DELETED` | Marked deleted | No | No |
| `MIGRATED` | Moved to new identity | No (redirect) | No |
| `UNKNOWN_NEEDS_CONFIRMATION` | Path exists but no identity record | No (until confirmed) | No |

---

## Fingerprint Rules

### pathFingerprint
- Computed from canonical `rootPath` (resolved, no trailing slash, lowercase on Windows)
- Change in pathFingerprint → `UNKNOWN_NEEDS_CONFIRMATION` status
- User must confirm: "This project has moved. Is this the same project?"

### contentFingerprint
- Computed from key identity files (e.g., `package.json`, `AGENTS.md`, `.codex-factory/`)
- Change in contentFingerprint → warning, not block
- Rationale: projects evolve; content change is normal

---

## Identity Creation Rules

1. When Factory is first installed in a folder → generate new `projectId` (UUID v4)
2. When user explicitly registers a project → user confirms identity fields
3. When Factory detects an existing project without identity → `UNKNOWN_NEEDS_CONFIRMATION`
4. When a project is forked → new `projectId`, `parentProjectId` = source
5. When a project is migrated → old identity status = `MIGRATED`, new identity `sourceProjectId` = old

## Identity Immutability

- `projectId` — immutable once created
- `createdAt` — immutable
- All other fields — mutable with audit trail
