# CLI_DASHBOARD_CONTRACT.md

> Part of: FACTORY-STATE-DASHBOARD-0
> Section: C — CLI Dashboard Contract
> Version: 1.0.0

---

## Purpose

Define the CLI command family for the Factory state dashboard. First version is CLI-only (not Web UI).

---

## Command Family

### `factory state`
Default: full Markdown dashboard output.

```
factory state
```
Output: Markdown-formatted dashboard with all 24 fields, health indicators, warnings.

### `factory state --json`
Output: JSON dashboard per `state-dashboard.schema.json`.

```
factory state --json
```

### `factory state --paths`
Output: All project paths (identity + governance + outputs).

```
factory state --paths
```

### `factory state --agents`
Output: Agent ledger view (see Section E). Shows agent roles, outputs, verdicts, attribution.

```
factory state --agents
```

### `factory state --risks`
Output: Active risks and blockers only.

```
factory state --risks
```

### `factory state --cleanup`
Output: Cleanup status, pending plans, last execution.

```
factory state --cleanup
```

### `factory state --mount`
Output: Mount status, foreign context warnings.

```
factory state --mount
```

### `factory state --brief`
Output: Minimal one-line summary: project name, status, phase, health indicator.

```
factory state --brief
```

---

## CLI Name Canonicalization

| If CLI is named | Canonical alias |
|----------------|-----------------|
| `factory.ps1` | `factory` |
| `factoryctl.ps1` | `factory` (alias `factoryctl` accepted with warning) |

If both exist, `factory` is canonical. `factoryctl` triggers CLI_NAME_WARNING per FACTORY-DEFAULT-WORKFLOW-0 Section H.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Dashboard generated successfully |
| 1 | Project identity not found |
| 2 | Project registry missing |
| 3 | Governance path missing |
| 4 | Agent ledger missing (warning only, dashboard still generated) |
| 5 | Critical corruption detected |

---

## Safety Rules

| Rule | Enforcement |
|------|------------|
| Never print secrets | Filter `.env`, tokens, passwords |
| Never modify project files | Read-only |
| Never trigger cleanup | Display only |
| Never start deploy | Display only |
| Never connect to servers | No network calls |
