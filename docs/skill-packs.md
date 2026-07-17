# Skill Packs

Create and manage your own skill packs for Codex Factory.

## Quick Start

```powershell
# List installed skill packs
powershell -File runtime/skill-pack-manager.ps1 -Action list

# Create a new skill pack
powershell -File runtime/skill-pack-manager.ps1 -Action create -Name my-ecommerce-pack

# Validate all skill packs
powershell -File runtime/skill-pack-manager.ps1 -Action validate

# Remove a skill pack
powershell -File runtime/skill-pack-manager.ps1 -Action remove -Name my-ecommerce-pack
```

## Pack Structure

```
packs/<pack_name>/
  pack.json          # Required: name, version, requires, provides, validations
  rules/             # Optional: project rules
  prompts/           # Optional: prompt templates
  schemas/           # Optional: custom schemas
```

## Built-in Packs

| Pack | Domain |
|---|---|
| `backend-api-design` | REST/GraphQL API design patterns |
| `auth-permission-security` | Authentication & authorization |
| `database-schema-design` | Database modeling & migrations |
| `frontend-ui-system` | UI component architecture |
| `mobile-miniapp-patterns` | WeChat/Alipay mini-program patterns |
| `product-architecture` | Product-level architecture decisions |
