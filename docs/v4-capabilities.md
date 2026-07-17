# V4 Capabilities

Codex Factory V4 is a reliability framework for Codex-assisted software engineering.
It provides structured project decomposition, cross-window worker execution,
artifact verification, and evidence-based quality gates.

## Core Capabilities

### Provider Abstraction (V4.0)
- Choose your LLM, search, memory, and CI providers
- Default: no external search (search_provider=none)
- GLM is optional — no vendor lock-in

### Skill Packs (V4.0.1)
- Create reusable skill packs with rules, prompts, validation
- Enable/disable per project
- Schema-validated (skill-pack.schema.json)

### Knowledge Packs (V4.0.1)
- Import local knowledge with source tracking
- Build evidence packs (source_file + source_hash + claim_text)
- Knowledge never uploaded — stays local

### Task Decomposition (V4.1/V4.1.1)
- Complex requirements → structured task graphs
- Risk classification (P0-P3), worker assignments, validation plans
- Output integrity guarantee (no 0-byte files, exit 1 on failure)

### Agent Execution Runtime (V4.2)
- Convert plans into run workspaces with worker capsules
- Handoff protocol, artifact collection, integration checks
- 11 CLI commands with honest status reporting

### Cross-Window Execution (V4.3/V4.4)
- Self-contained worker prompts for independent Codex windows
- Boundary enforcement: workers cannot cross into others' territory
- V4.4: verified with 3 real Codex windows (8/8 artifacts, 79 tests)

### Boundary Refinement (V4.4.1)
- Capsule forbidden_files use cross-worker patterns (not domain keywords)
- Conflict detector prevents false boundary violations
- 4/4 boundary regression PASS

## Verification Evidence
- **V3.4.2**: GitHub Actions strict remote CI (15/15 PASS)
- **V4.4**: Real cross-window live test (3 windows, A+ classification)

## Non-Claims
- Not a production multi-agent cloud platform
- Manual mode — not fully autonomous
- No marketplace integration
