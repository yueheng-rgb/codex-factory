# Getting Started with Codex Factory

> **5 minutes to your first verified multi-agent project.**

---

## 1. What is Codex Factory?

Codex Factory is **not a code generator**. It's a **multi-agent engineering framework**
that helps Codex handle complex projects reliably.

Here's what it does for you:
- **Configure providers** — choose your LLM, search, memory, CI
- **Add skill packs** — reusable engineering rules and prompts
- **Import knowledge packs** — your own docs, specs, and standards (stays local)
- **Decompose complex tasks** — one big requirement → structured task graph
- **Generate worker capsules** — self-contained assignments for separate Codex windows
- **Collect handoffs and artifacts** — real evidence, not fake PASS
- **Verify everything** — validation, integration checks, execution receipts

---

## 2. Who is this for?

- **DeepSeek / GPT / Claude Codex users** who want to do more than single-prompt work
- **Anyone building complex projects** with multiple modules or concerns
- **Anyone who wants to split work across multiple Codex windows**
- **Teams that need evidence** — not just "it worked on my machine"
- **Anyone tired of fake PASS** — Codex claiming "done" with nothing verifiable

---

## 3. 5-Minute Quick Start

```powershell
# Clone
git clone git@github.com:yueheng-rgb/codex-factory.git
cd codex-factory

# Initialize (choose your providers)
pwsh runtime/codex-factory-init.ps1

# Health check
pwsh runtime/codex-factory-doctor.ps1
```

**That's it. You're ready.** Now choose your path below.

---

## 4. Choose Your Provider

### A. DeepSeek + GLM Search
Best for DeepSeek users who need external search.
- Set `search_provider=glm_zhipu` in `factory.config.json`
- Add `ZHIPUAI_API_KEY` to `.env` (NOT committed to git)
- GLM is **optional** — you can skip this and use `search_provider=none`

### B. GPT / Native Tools / No External Search
- Keep `search_provider=none` (default)
- No GLM needed
- Your current Codex environment already has tools

### C. Local-Only
- `search_provider=none`
- `memory_provider=local_snapshot`
- `ci_provider=local_only`
- Everything stays on your machine

### D. Custom Provider
- See `configs/provider-presets/custom-provider.example.json`
- Bring your own search, memory, or CI provider

---

## 5. Add a Skill Pack

Skill Packs give Codex domain-specific engineering capabilities.
Examples: `admin-system`, `ecommerce`, `saas`, `miniapp`.

```powershell
# List available packs
pwsh runtime/skill-pack-manager.ps1 -Command list

# Create your own
pwsh runtime/skill-pack-manager.ps1 -Command create-template -Name my-springboot-backend -OutputDir packs/my-springboot-backend

# Validate it
pwsh runtime/skill-pack-manager.ps1 -Command validate -Name my-springboot-backend

# Enable it for your project
pwsh runtime/skill-pack-manager.ps1 -Command enable -Name my-springboot-backend
```

A skill pack contains: `rules.md`, `prompts.md`, `validation.md`, `examples/`.

**Rules:** Skill packs cannot bypass risk gates or fake PASS.

---

## 6. Add a Knowledge Pack

Knowledge Packs let Codex use YOUR documents — specs, API docs, database schemas,
company standards, course requirements. **Everything stays local. Never uploaded.**

```powershell
# Add your docs as a knowledge pack
pwsh runtime/knowledge-pack-manager.ps1 -Command add -Name my-project-docs -Source ./docs

# Index them
pwsh runtime/knowledge-pack-manager.ps1 -Command index -Name my-project-docs

# Build evidence (with source tracking)
pwsh runtime/knowledge-pack-manager.ps1 -Command build-evidence -Name my-project-docs
```

Every piece of knowledge is tracked with `source_file`, `source_hash`, and
`line_or_section_reference`. No unsourced claims enter prompts.

---

## 7. Decompose a Complex Project

Create a `requirement.md` describing what you need:

```
Build an admin system with login, RBAC, product management,
user management, dashboard, database schema, API contracts, tests.
```

Run the decomposition engine:

```powershell
pwsh runtime/task-decomposition-engine.ps1 -Requirement requirement.md -OutputDir outputs/my-project
```

This produces:
- `task_graph.json` — structured task breakdown
- `worker_plan.json` — which worker does what
- `validation_plan.json` — how each task is verified
- `risk_classification.json` — P0-P3 risk levels
- `evidence_requirements.json` — what evidence each task needs
- `agent_execution_plan.json` — execution order and dependencies

---

## 8. Start Agent Execution

```powershell
pwsh runtime/agent-execution-runtime.ps1 -Command start -Mode manual -PlanDir outputs/my-project
```

This creates a **run workspace** with:
- Worker capsules (one per worker role)
- Handoff templates
- Artifact requirements
- Validation checklist

---

## 9. Use Multiple Codex Windows

Open 3 separate Codex windows. Paste ONLY the worker's own prompt into each:

| Window | Worker Prompt | Does |
|--------|--------------|------|
| Window A | Backend Worker | Database, API, Auth, CRUD |
| Window B | Frontend Worker | Dashboard, Management pages |
| Window C | QA Worker | Integration tests, verification |

**CRITICAL RULES:**
- Do NOT paste the full project history into worker windows
- Do NOT paste other workers' prompts
- Each worker sees ONLY its own assignment

Pre-made worker prompts: `outputs/V4_4/live-cross-window-kit/`

---

## 10. Collect Handoffs and Verify

When workers finish, save their `worker-handoff.json` files, then:

```powershell
pwsh runtime/agent-execution-runtime.ps1 -Command validate-live-handoff -RunId <run-id>
pwsh runtime/agent-execution-runtime.ps1 -Command collect-artifacts -RunId <run-id>
pwsh runtime/agent-execution-runtime.ps1 -Command validate -RunId <run-id>
pwsh runtime/agent-execution-runtime.ps1 -Command integrate -RunId <run-id>
pwsh runtime/agent-execution-runtime.ps1 -Command close -RunId <run-id>
```

What happens:
- **Placeholder handoffs are rejected** — templates won't pass
- **Forbidden file violations are caught** — workers can't touch others' territory
- **Missing artifacts block integration** — no artifact = no PASS

---

## 11. How Do I Know It Worked?

The **execution receipt** tells you everything:

| Field | What It Means |
|-------|--------------|
| `tasks_completed` | How many tasks actually finished |
| `artifacts_collected` | How many verifiable outputs exist |
| `tests_run / passed / failed` | Test results from workers |
| `blockers` | What's preventing completion |
| `validation_status` | PASS / PARTIAL / FAIL |
| `integration_status` | READY / BLOCKED |
| `final_status` | Overall run status |

Manual mode final status is honest — it won't say VERIFIED unless all evidence is present.

---

## 12. Common Questions

**Do I need GLM?**
No. GLM is one optional search provider. If you use GPT or have native search tools,
keep `search_provider=none`.

**I use GPT — do I still need external search?**
Not necessarily. Your Codex environment likely already has search tools.
Set `search_provider=none` and you're fine.

**Can I upload my own professional knowledge?**
Yes. Use Knowledge Packs. Your documents stay local — never uploaded.

**Can I write my own skill packs?**
Yes. Use `skill-pack-manager.ps1 create-template`. Write your own rules,
prompts, and validation criteria.

**Will it auto-complete my entire project?**
No. Codex Factory is a **manual / evidence-driven multi-agent workflow**.
It provides structure, boundaries, and verification — you (and Codex workers)
still do the work. It is NOT a fully autonomous agent platform.

**Can I pass without artifacts?**
No. **No artifact = no PASS.** Every task must produce verifiable output.

**Where do I put API keys?**
Only in `.env`. Never commit `.env` to git. It's already in `.gitignore`.

---

**Next:** Read the [User Guide](docs/user-guide.md) for deeper concepts.
Try the [V4 Public Demo Guide](docs/v4-public-demo-guide.md) for a step-by-step walkthrough.
