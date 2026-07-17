# Project Onboarding

Start a new project with Codex Factory guardrails.

## Quick Start

```powershell
# Interactive onboarding
powershell -File runtime/project-onboarding-wizard.ps1 -ProjectName my-new-app

# Quick mode (default recommendations)
powershell -File runtime/project-onboarding-wizard.ps1 -ProjectName my-new-app -Quick
```

## Supported Project Types

| Type | Description |
|---|---|
| `backend-api` | REST / GraphQL API |
| `admin-system` | Admin dashboard / management system |
| `ecommerce` | E-commerce platform |
| `miniapp` | WeChat / Alipay mini-program |
| `saas` | Multi-tenant SaaS application |
| `game-threejs` | Game (Three.js / WebGL) |
| `cpp-tool` | C++ tool / library |
| `custom-complex-project` | Custom complex project |

## Output

The wizard generates:
- `project.factory.json` — project configuration with recommended packs and evidence requirements
- Recommendations for skill packs, search, and CI
- Evidence requirements for verification
