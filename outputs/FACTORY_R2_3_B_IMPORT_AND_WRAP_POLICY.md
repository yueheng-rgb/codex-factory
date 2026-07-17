# FACTORY R2.3-B — Import and Wrap Policy

> **Phase:** FACTORY-R2.3-B
> **Date:** 2026-07-09

---

## 1. Capability Lifecycle States

`
candidate → imported → adapted → verified → active
                                        ↘ rejected → archived
active → deprecated → archived
active → quarantined → (review) → active | rejected
`

## 2. Action Definitions

### import
- **Meaning:** Use capability as-is with minimal Factory configuration
- **Applies to:** VERIFIED trust, local-only, no secrets needed
- **Examples:** ESLint, TypeScript, Vitest, Prisma CLI
- **Requirements:** Register in capability registry, document version
- **No:** Modification, wrapping, adaptation needed

### adapt
- **Meaning:** Convert to Factory-compatible format or extract relevant portions
- **Applies to:** TRUSTED trust, format mismatch, scope mismatch
- **Examples:** cursor-rules → Factory rule format, claude-agent-skills → SKILL.md
- **Requirements:** LIB-001 review, format conversion, conflict check
- **Output:** Adapted skill/config in knowledge-bank/

### wrap
- **Meaning:** Create a Factory-compatible interface around an external tool
- **Applies to:** MCP servers, external APIs, CLI tools needing sandbox
- **Examples:** playwright-mcp → Factory sandbox wrapper, glm-search → Research Intake adapter
- **Requirements:** Permission gate integration, sandbox configuration, rate limiting
- **Output:** Wrapper config in runtime/

### monitor
- **Meaning:** Track but do not integrate. Re-evaluate periodically.
- **Applies to:** AVAILABLE trust, emerging tech, high risk, not yet needed
- **Examples:** stitch-mcp, v0-dev, cloud services
- **Requirements:** Monthly review by LIB-001, trust level re-assessment
- **No:** Integration into agent workflow

### reject
- **Meaning:** Evaluated and found unsuitable. Reason documented.
- **Applies to:** BLOCKED trust, license incompatibility, security risk
- **Examples:** (none identified yet in this survey)
- **Requirements:** Rejection reason documented in registry
- **No:** Further consideration unless circumstances change

### quarantine
- **Meaning:** Blocked due to security concern. Requires security review to unblock.
- **Applies to:** CRITICAL security risk, cloud services with credential access
- **Examples:** cloud-provider-mcp, cloud-queue-service, cloud-secrets-manager
- **Requirements:** SEC-001 audit, sandbox test, human approval chain
- **No:** Any use until quarantine lifted

### deprecate
- **Meaning:** Was active, now outdated or superseded.
- **Applies to:** Superseded by newer version, no longer maintained
- **Requirements:** Mark in registry, point to replacement, 12-month archive period

## 3. Import Safety Gates

| Gate | Required For | Performed By |
|------|-------------|-------------|
| Source provenance check | import, adapt | LIB-001 |
| License compatibility | import, adapt | LIB-001 |
| Security scan (secrets, unsafe patterns) | import, adapt, wrap | SEC-001 |
| Network access audit | import, wrap | SEC-001 |
| File write scope audit | import, wrap | SEC-001 |
| Conflict test (existing skills) | adapt | LIB-001 |
| Sandbox dry-run | wrap | VER-001 |
| Human approval | wrap (high risk) | PM-001 |
| Performance impact assessment | wrap (heavy tools) | VER-001 |

## 4. Wrap vs Adapt Decision

| If... | Then... |
|-------|---------|
| External tool works as-is, just needs permission gating | **wrap** |
| External tool has different format/API, needs conversion | **adapt** |
| External tool is a complete replacement for Factory skill | **adapt** (convert to SKILL.md) |
| External tool needs sandbox + rate limit + scope restriction | **wrap** |

