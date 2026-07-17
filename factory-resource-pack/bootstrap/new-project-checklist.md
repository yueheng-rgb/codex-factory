# New Project Checklist — Codex Factory

> **Category**: bootstrap | **Stability**: stable
>
> Use this checklist when starting a brand-new project under Codex Factory governance.

---

## Phase 0: Initial State Setup

- [ ] **Create project root directory** with standard Factory structure:
  ```
  project-root/
  ├── factory-resource-pack/       (copied from Factory)
  ├── governance/
  │   └── factory-state/
  │       ├── AGENT_REGISTRY.json
  │       ├── AGENT_PROGRESS.jsonl
  │       ├── FACTORY_STATE.json
  │       └── PHASE_HISTORY.jsonl
  ├── phases/
  │   └── (phase-specific directories)
  ├── artifacts/
  └── README.md
  ```
- [ ] **Copy factory-resource-pack** from `C:\Codex_App_Factory\factory-resource-pack\` to `project-root\factory-resource-pack\`
- [ ] **Run initial validation**: `.\factory-resource-pack\bootstrap\validate-resource-pack.ps1`
- [ ] **Confirm validation PASS** before proceeding (exit code 0)
- [ ] **Initialize registry files**:
  - `AGENT_REGISTRY.json`: `[]` (empty array)
  - `AGENT_PROGRESS.jsonl`: empty file
  - `FACTORY_STATE.json`: initial state document
  - `PHASE_HISTORY.jsonl`: empty file
- [ ] **Configure project metadata**:
  - Project name
  - Project description
  - Initial phase plan

---

## Phase 1: First Phase Specification

- [ ] **Determine first phase type**: H (governance) or DRY (delivery)
  - New projects default to starting with an H-phase for governance setup
  - Existing codebases may start with DRY if governance already exists
- [ ] **Create first phase directory**: `phases/<phase-id>/`
- [ ] **Copy appropriate phase template**:
  - `factory-resource-pack/phase-templates/H-phase-template.md` for H phases
  - `factory-resource-pack/phase-templates/DRY-phase-template.md` for DRY phases
- [ ] **Fill phase specification**: Complete all required sections, remove no sections
- [ ] **Define deliverables** (DRY) or **define governance scope** (H)
- [ ] **Set complexity floors**: Minimum agent count, event count, artifact count, duration
- [ ] **Define negative controls**: At minimum the required set from the template
- [ ] **Save completed spec** as `phases/<phase-id>/PHASE_SPECIFICATION.md`

---

## Phase 2: Governance Initialization

- [ ] **Register Main Agent**: `.\factory-resource-pack\core\agent-tracking\register-agent.ps1 -AgentRole "H1-Builder"`
- [ ] **Record initial progress**: `.\factory-resource-pack\core\agent-tracking\record-progress.ps1 -Event "Phase H1 started"`
- [ ] **Verify Factory state**: `.\factory-resource-pack\core\factoryctl\factoryctl.ps1 status`
- [ ] **Confirm clean state**: No stale agents, no unmet floors, no negative gaps
- [ ] **Create initial BOUNDARY.md** for project (if different from Factory defaults)
- [ ] **Initialize project-specific policies** in `governance/policies/` (if needed)

---

## Phase 3: Verification Readiness

- [ ] **Confirm all core schemas validate**: Run `validate-resource-pack.ps1` and check schema parse results
- [ ] **Confirm MANIFEST.json references are correct**: Pack paths match project structure
- [ ] **Confirm handoff scripts are executable**: Test `generate-handoff.ps1` and `handoff-verify.ps1`
- [ ] **Set up session rotation tracking**: Initialize `session-rotation-handoff.json` if multi-session project

---

## Acceptance Criteria

Before considering the project "started":

1. `validate-resource-pack.ps1` exits with code 0
2. `factoryctl.ps1 status` returns clean state
3. First phase specification is complete (no placeholder sections)
4. Registry files initialized and parseable
5. Negative controls defined for first phase
6. SCORING_SYSTEM_GATE.md acknowledged in transcript

---

## Anti-Patterns to Avoid

- ❌ Starting implementation before governance setup (H-phase first)
- ❌ Skipping validation (`validate-resource-pack.ps1` must run and pass)
- ❌ Using placeholder phase specs (every section must be filled)
- ❌ Omitting negative controls (required for all phases)
- ❌ Starting with DRY phase without governance foundation
- ❌ Deploying scoring systems as gates (per SCORING_SYSTEM_GATE.md)
