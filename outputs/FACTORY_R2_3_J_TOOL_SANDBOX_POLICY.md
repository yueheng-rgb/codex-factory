# R2.3-J Tool / MCP Sandbox Policy

**Phase:** FACTORY-R2.3-J | **Date:** 2026-07-10

## Sandbox Levels

| Level | Name | Description | When Applied |
|-------|------|-------------|-------------|
| 0 | no-run | Tool invocation rejected entirely | quarantine, rejected, deprecated, unknown tools |
| 1 | dry-run | Tool reports what it would do without executing | dryRunSupported + sandboxAvailable |
| 2 | read-only sandbox | Tool can read project files but not write | verifier, linter, scanner tools |
| 3 | disposable workspace | Tool runs in temp workspace, artifacts reviewed before merge | code generators, MCP write tools |
| 4 | network-disabled sandbox | Sandbox with network blocked | tools that don't need network access |
| 5 | network-limited sandbox | Sandbox with allowlisted network targets | MCP servers, search providers |
| 6 | secretless execution | Tool runs with no API keys or credentials | All sandboxed tools by default |
| 7 | human-approved execution | Tool runs only after human confirmation | High-risk tools (Stitch MCP, DB MCP) |

## Tool-Specific Sandbox Requirements

| Tool | Min Sandbox Level | Network | Human Approval | File Write | Notes |
|------|:---:|:---:|:---:|:---:|------|
| Stitch MCP | 3 (disposable) | Required | Required | Yes | High risk: generates UI code, must review before merge |
| Playwright Verifier | 3 (disposable) | Optional | No | No | Can run in network-disabled mode for localhost testing |
| GLM Search Provider | 5 (network-limited) | Required | Required | No | API key required; results must be treated as untrusted research intake |
| Database MCP | 3 (disposable) | Required | Required | Yes | Dry-run first; readonly mode preferred; no DROP/TRUNCATE |
| Code Generator | 3 (disposable) | No | Required | Yes | Output must be reviewed by architect before integration |
| Local CLI Verifier | 2 (read-only) | No | No | No | Safe: reads project files, runs verification, no writes |
| Node.js SDK | 2 (read-only) | No | No | No | Safe: code execution in controlled environment |

## Hard Rules

1. **High-risk MCP servers (Stitch, Database) must NOT run directly in project directories** — always disposable workspace first.
2. **File-write tools must run in disposable workspace** — output reviewed by human before merge.
3. **API-key tools (GLM Search) are local-first rejected** — no API keys configured = no execution.
4. **All tool invocations must be recorded** in tool-invocation-index.jsonl.
5. **Post-run artifact scan** required for any tool that produced files.
6. **Rollback plan** required before any file-write tool execution.

## Cloud Policy

- Local-first: no cloud services, no remote execution
- Future: sandbox could run on local Mac mini or cloud runner — but not in this phase
