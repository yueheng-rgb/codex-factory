# Codex Factory v0.5.1-r1 — User Handoff Guide

## Installation
1. Extract `codex-factory-core-v0.5.1-r1.zip` to your project workspace
2. Verify SHA256 matches: `D563C5E462314E9EEC858E3E0E9D4E2B4131B0546B3FA289B4BD8EB1BE5E6A6B`
3. The Factory will auto-detect when you select the project folder

## Quick Start
1. Select your project folder containing the Factory
2. State your requirement ("build a fullstack admin dashboard")
3. Factory auto-enters: Bootstrap -> Router -> Preflight -> Discussion
4. **Large projects:** Factory will ask whether to use multi-agent mode
5. Follow the flow; code is written only after design confirmation

## Key Rules
- **Cleanup:** Say "delete project cache" to trigger a cleanup PLAN. Factory will not delete without your confirmation.
- **Multi-Agent:** Only for large/complex projects. Factory asks first. Never auto-starts.
- **Handoff:** Every completed project handoff includes full file paths.
- **Dashboard:** Run `factory state` anytime to see project health.
- **Recovery:** If Factory detects issues, run `factory recover --dry-run` for a plan.

## CLI Reference
| Command | Purpose |
|---------|---------|
| `factory state` | Project dashboard |
| `factory state --agents` | Agent ledger view |
| `factory recover --dry-run` | Recovery scan |
| `factory evidence check` | Evidence validator |
| `factory cleanup plan` | Cleanup planning |
| `factory lifecycle` | Lifecycle state |

## Evidence Caveat
Dashboard display, snapshots, and attach packets are working context — not primary evidence of correctness. Production claims require validated production deployment evidence.
