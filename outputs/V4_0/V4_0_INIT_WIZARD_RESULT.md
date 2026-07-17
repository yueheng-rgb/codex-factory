# V4.0 User Onboarding, Provider Abstraction & Skill/Knowledge Productization

## Classification: V4_0_USER_ONBOARDING_AND_SKILL_KNOWLEDGE_MVP_READY

## Deliverables

| Module | Status | Files |
|---|---|---|
| Provider Abstraction | DONE | schema + 4 presets + .env.example + factory.config.example.json |
| Init Wizard | DONE | runtime/codex-factory-init.ps1 — interactive LLM/search/memory/CI setup |
| Doctor Command | DONE | runtime/codex-factory-doctor.ps1 — 10-point environment check |
| Skill Pack Manager | DONE | runtime/skill-pack-manager.ps1 — list/create/validate/remove |
| Knowledge Pack Manager | DONE | runtime/knowledge-pack-manager.ps1 — add/list/validate/remove/index |
| Project Onboarding | DONE | runtime/project-onboarding-wizard.ps1 — 8 project types |
| README / Docs Update | DONE | README V4.0 section + 4 docs |
| Regression | PASS | V3.4.2 evidence intact, no secrets, no GLM hard binding |

## Key Design Decisions

| Decision | Rationale |
|---|---|
| Search defaults to NONE | GPT/Claude have built-in search; external search is optional |
| GLM NOT default | Provider neutrality — users choose their own stack |
| No API keys in config | Keys go in .env (gitignored); config is key-free |
| Knowledge packs are local-only | Privacy by default; content enters Evidence Pack, not raw prompt |
| Skill packs have validation requirements | Cannot bypass risk/artifact gates |

## Regression Confirmation
- V3.4.2 remote verification evidence: intact
- Snapshot verifier: functional
- GitHub Actions workflow: unchanged
- No secrets committed: confirmed
- No GLM hard binding: confirmed (search type=none default)
