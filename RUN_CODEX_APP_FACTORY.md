# RUN_CODEX_APP_FACTORY.md ? Single Entry Point

> This is the **only document** a user needs to reference when creating a project with Codex App Factory.
>
> Usage:
> ```
> Read C:\Codex_App_Factory\RUN_CODEX_APP_FACTORY.md,
> then create a project from this requirement:
>
> <user's natural-language requirement>
> ```
>
> Codex must automatically execute all stages below. Do NOT ask the user to
> send separate Phase A/B/C/D instructions.

---

## Stage 0: Factory Bootstrap

1. Read these foundational documents (lightweight, routing-first):
   - `CODEX_FACTORY_DIRECTION.md` ? factory purpose and rules
   - `APP_TYPE_ROUTER.md` ? project type classification rules
   - `STACK_DECISION_GUIDE.md` ? tech stack decision rules
   - `STARTER_REGISTRY.md` ? available starters and their type mappings
   - `STARTER_QUALITY_CHECKLIST.md` ? starter quality rules

2. Read Project Expertise Flow skill at:
   `%USERPROFILE%\.agents\skills\project-expertise-flow\SKILL.md`

3. Read Architecture Scaling Ladder if the project appears to be M+:
   `%USERPROFILE%\.agents\skills\architecture-scaling-ladder\SKILL.md`

4. Based on the project type determined in Stage 2, selectively read:
   - The chosen starter's `PROJECT_BRIEF.md` and `README.md`
   - Any type-specific skill (e.g., supabase-postgres-best-practices for API projects)

5. Read `BENCHMARK_RUN_PROTOCOL.md` for validation rules.
6. Read `POWERSHELL_TEXT_SAFETY.md` before any file operations.

**Do NOT** read all documents indiscriminately. Use the router first, then read selectively.

---

## Stage 1: Requirement Interpretation

From the user's natural-language input, extract and record:

### Must Extract
- Core project goal (one sentence)
- Target users (who will use this)
- Core business loop (what must work end-to-end)
- Explicit constraints (what the user said NOT to do)
- Implicit constraints (security, data consistency, error handling)
- Deferred features (what NOT to implement in first version)
- Whether sensitive data is involved (PII, medical, financial)
- Whether payment, auth, quotas, audit, or concurrent writes are needed

### Must NOT Add (unless requested)
- Points/rewards system
- Membership tiers
- Leaderboards
- Recommendation engine
- Complex dashboards
- AI features
- Social/feed systems
- Chat/messaging
- Notification systems

### May Add (technical necessities)
- Server-side auth validation
- Error/empty/loading states
- Data consistency guards (unique constraints, idempotency)
- Unified API response format
- Basic audit logging (for admin systems)

---

## Stage 2: Project Classification

Output and record:

| Attribute | Value |
|---|---|
| Application Type | content-site / fullstack-admin / saas-tool / api-service / threejs-interactive |
| Size Level | S / M / L / XL |
| Risk Level | low / medium / high |
| Recommended Starter | one of the 5 starters |
| Rejected Starters | list all 4 others with rejection reasons |
| Needs Starter Combo | yes/no |
| Should Prototype First | yes/no |

### Type Selection Rules

- Content/landing page ? `vite-react-content-site` (S, low risk)
- Admin/management system with auth + CRUD ? `next-fullstack-admin` (M, medium)
- SaaS/AI tool with quota + generation ? `next-saas-ai-tool` (M-L, medium)
- Pure API/backend service ? `node-api-postgres` (M-L, medium)
- 3D interactive web ? `vite-threejs-interactive` (M, medium)

### Anti-Patterns

- Do NOT choose `next-fullstack-admin` just because "admin" appears in the requirement.
- Do NOT choose `vite-react-content-site` for projects that need backend APIs.
- Do NOT choose `next-saas-ai-tool` for projects with no AI/generation component.
- Do NOT decompose into microservices for S/M projects.


### Risk Level Rules

Risk is at least **medium** when ANY of the following are present:
- Multi-role permissions (admin + user or more)
- Capacity/stock/quota limits with concurrent writes
- Status changes with access control implications
- Audit requirements (who did what, when)
- Financial data or payment (then risk ≥ high)

Risk is **low** ONLY when:
- Single role or no auth needed
- Read-only or single-writer pattern
- No sensitive data
- Mock/staging only, not production-facing

---

## Stage 3: Auto-Stop Check

**Only pause and ask the user** when:

1. Core goals in the requirement contradict each other
2. Cannot determine which project type this is
3. Target path would overwrite an existing non-factory project
4. User needs real API keys, real payments, or real sensitive data
5. Project is L/XL and production implementation has clear safety/legal/data risks
6. Target directory contains files that would be deleted

**Do NOT pause** for normal S/M projects just to "confirm the plan." Execute the flow.

---

## Stage 4: Project Initialization

1. Determine safe target path:
   - Factory test projects ? `C:\Codex_Test_Projects\_factory_benchmarks\<project-name>`
   - Real projects ? `C:\Codex_Real_Projects\<project-name>`
   - User-specified ? use the provided path after safety check

2. Run the copy script:
   ```powershell
   C:\Codex_App_Factory\scripts\create-project-from-starter.ps1 `
     -StarterName <chosen-starter> `
     -TargetPath <target-path> `
     -ProjectName <project-name>
   ```

3. Verify:
   - `package.json` name is correct
   - No `PROJECT_NAME` residual in source files
   - `PROJECT_BRIEF.md` is filled with interpreted requirement

4. Create run state:
   - `mkdir <target-path>\.codex-factory`
   - Write `run-state.json` from `FACTORY_RUN_STATE.template.json`
   - Set `currentStage: "stage-5-business-closure"`

---

## Stage 5: Minimal Business Closure

Implement the first-version minimal loop based on PROJECT_BRIEF.

### Rules
- Reuse starter structure; do not restructure without reason
- Do not add large dependencies (no new frameworks, UI kits, state libraries)
- Do not implement deferred features
- Keep `main.ts` / `page.tsx` lightweight (assembly only)
- Separate UI, business logic, data access, and state
- Mark all mock data clearly: "?? Mock ? ??????"
- Do not connect real databases, real auth, real AI APIs, or real payments

### Per-Type Guidance

**Content Site**: Edit `src/data/siteContent.ts`, customize `src/App.tsx` and components. CSS-only visual design.

**Fullstack Admin**: Edit `lib/mock-db.ts` with business entities, implement list/detail/status-change routes, audit log, search/filter.

**SaaS AI Tool**: Implement mock AI provider, quota system, generation history, idempotency. All generation logic in server-side API routes.

**API Service**: Implement route handlers, service layer, repository layer, validation, pagination, idempotency, audit logging.

**Three.js Interactive**: Define exhibits in `exhibits/exhibitDefinitions.ts`, create geometry, setup interaction controller, information panel, resize, lifecycle/dispose.

---

## Stage 6: Automatic Validation

### Universal (all types)
```powershell
npm install
npm run typecheck
npm run build
npm run dev    # short-start only, verify no crash
```

### Type-Specific

**Content Site**:
- Page loads without console errors
- Hero, features, CTA sections present
- Mobile viewport no overflow
- No login/admin/form elements

**Fullstack Admin**:
- Login placeholder ? dashboard
- List page with search/filter
- Detail page with status change
- API returns unified `{ ok, data }` format
- Permission boundary (user?admin)

**SaaS AI Tool**:
- Mock generation succeeds
- Quota decrements on success
- Quota NOT decremented on failure
- History shows user's records
- Idempotency replay returns cached result
- No API key in client code

**API Service**:
- Health endpoint returns `{ ok: true }`
- Auth middleware enforces tokens
- CRUD operations with unified response
- Pagination with strict validation
- Idempotency on write operations
- Audit logging

**Three.js Interactive**:
- Canvas renders with 6+ objects
- Raycaster click selects correct object
- Selection highlights and panel syncs
- Empty click clears selection
- UI panel does not trigger scene selection
- Resize maintains accuracy
- Dispose stops animation and removes canvas

---


### ⚠️ Fullstack Admin — Mandatory Functional Tests

After engineering validation (install/typecheck/build/dev), fullstack-admin projects MUST execute real browser functional tests:

1. Login as each role (student + admin)
2. Create a test entity (admin)
3. View/search entity list (student)
4. Perform write operation (register, status change)
5. Verify duplicate prevention
6. Verify capacity/limit enforcement
7. Verify admin-only operations rejected for non-admin
8. Verify permission boundaries at API level (not just UI hiding)
9. Verify data isolation between users
10. Confirm mock data reset on restart

These tests may use Playwright with system Chrome/Edge channel. Do NOT download Chromium.

---

## Stage 7: Defect Classification & Factory Backflow

If validation fails:

1. Classify each defect:
   - **Generated project issue** ? fix in the project
   - **Starter source defect** ? fix in BOTH project AND source starter
   - **Copy script defect** ? fix script, re-copy, re-validate
   - **Environment issue** ? document, do not hack around

2. Only backflow to source starter if the defect affects ALL projects of that type.

3. Run factory gate tests after any source starter modification:
   ```powershell
   C:\Codex_App_Factory\scripts\test-copy-encoding.ps1
   C:\Codex_App_Factory\scripts\test-copy-content-integrity.ps1
   ```

---

## Stage 8: Final Report

Output a concise report with:

1. Project name, type, size, risk, starter
2. What was implemented (minimal loop description)
3. What was deferred
4. Validation results (install/typecheck/build/dev all pass?)
5. Defects found and classification
6. Starter backflow performed (list files)
7. Current limitations (mock data, no real auth, etc.)
8. Next steps for production (when ready)

---

## Resume Existing Run

If `<target-path>\.codex-factory\run-state.json` exists:

1. Read `run-state.json` to get current stage and completed stages
2. Verify actual file state (not just the JSON)
3. Resume from the first incomplete stage
4. Do NOT re-copy the starter
5. Do NOT delete completed work
6. Do NOT trust old chat context as the sole source of truth
7. Re-verify stages marked PASS (existence check, not full re-run)
8. Update `run-state.json` after each completed stage

---


### Report Structure

The final report MUST distinguish:
1. **First attempt** — what passed and failed on the initial run
2. **Fixes applied** — what was changed and why
3. **Post-audit verification** — results after fixes

Do NOT claim "all pass" when functional tests are pending.
Do NOT mark `finalStatus: "completed"` until ALL validation gates (engineering + functional) pass.

---


---

## Stage 9: Evidence Trail Validation Gate

Before outputting the final report, run the evidence validator:

```powershell
C:\Codex_App_Factory\scripts\validate-factory-run.ps1 -ProjectPath <target-path>
```

### Pass Criteria
- run-state.json exists and is valid JSON
- run-events.jsonl exists with at least run_started
- runId consistent across all events and state
- sequence continuous with no gaps
- Stage started/completed pairing valid
- functionalTests and finalStatus consistent
- No RUNID_MISMATCH, SEQUENCE_GAP, or STATUS_CONTRADICTION errors

### On Failure
1. Record `validation_failed` event
2. Fix the state file or event log
3. Re-run the validator
4. Preserve the original failure event

Only when the validator passes may the final report claim:
- `orchestration completed`
- `run-state complete`
- `evidence trail complete`



## Evidence Architecture (Phase 5E)

### Per-Run Directory Structure

Each run or remediation uses an isolated directory:

```
.codex-factory/
├── current-run.json          # Points to active runId
├── runs/
│   └── <runId>/
│       ├── run-state.json    # Run-specific state
│       ├── run-events.jsonl  # Events for THIS run only
│       └── evidence/         # Run-specific evidence files
└── archived-reconstructed-runs/
    └── run-events-reconstructed.jsonl  # Archived historical events
```

**Rules**:
- One `run-events.jsonl` MUST contain exactly one runId
- Reconstructed/historical events go to `archived-reconstructed-runs/`, never to active logs
- Each remediation uses a NEW runId with `parentRunId` pointing to the original
- `current-run.json` always points to the active run

### Execution-Time Event Writing (MANDATORY)

Every real action MUST follow this sequence:

```
1. append-factory-event.ps1  →  stage_started or validation_started
2. Execute the actual command or modification
3. Save real log/result files as evidence
4. append-factory-event.ps1  →  validation_passed / validation_failed
5. append-factory-event.ps1  →  stage_completed
```

**FORBIDDEN**:
- Writing all events at the end after completing an entire Stage
- Manually constructing past timestamps
- Using fixed increment seconds (e.g., +1s, +5s) to simulate real time
- Passing timestamp or sequence as external parameters to append scripts
- Mixing multiple runIds in one events file
- Including `[RECONSTRUCTED]` events in active run logs

### append-factory-event.ps1 Guarantees

- timestamp: ALWAYS generated by `Get-Date` at call time (never externally passed)
- sequence: ALWAYS auto-incremented from last event (never externally passed)
- Single runId: rejects writes if file already contains a different runId
- One line per call with immediate `Flush()`
- `[RECONSTRUCTED]` markers are rejected in active logs
- Sensitive data patterns are rejected

## Automation Boundaries

### Can Auto-Execute
- New project creation in safe directories
- Starter copying and file modification
- npm install, typecheck, build
- dev server short-start
- Local HTTP/API testing
- System browser testing (Chrome/Edge via Playwright channel)
- Mock data and mock auth

### MUST Pause
- Overwriting non-empty directories without `-Force`
- Deleting files outside the project directory
- Using real production API keys
- Real payment integration
- Real patient/PII/sensitive data
- Production deployment
- Modifying existing real projects outside `_factory_*` directories
- L/XL projects going straight to production implementation
