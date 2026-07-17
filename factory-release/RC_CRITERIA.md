# RC Criteria — Release Candidate 0

## Definition
RC-0 is a **candidate artifact for testing**, not a release.
It may be extracted and smoke-tested.
It must not be advertised as a release.

## Required Flags

| Flag | Required Value |
|---|---|
| releaseAllowed | false |
| v05Package | false |
| finalRelease | false |
| rcCandidate | true |
| rcRequiresUserApproval | true |
| artifactType | RELEASE_CANDIDATE |

## Content Rules

### MUST Include:
- All CORE modules per P8 staging manifest
- Factory CLI (`scripts/factoryctl.ps1`)
- Governance state tracking (`governance/factory-state/`)
- Resource pack (`factory-resource-pack/`)
- Memory quality policies, schemas, templates, prompts
- Cleanup planner (`runtime/scripts/factory-cleanup-planner.ps1`)
- Phase close verifier integration
- RC metadata (manifest with SHA256 per asset)
- RC boundary documentation

### MUST NOT Include:
- Real projects (e.g., ecommerce_homework, bigdata_homework, habit-tracker-*, etc.)
- Working copies (fresh-install-target, i-test-target, etc.)
- Old student packages
- Real `.env` files or secrets
- Trial products (runs/, trials/, harness/)
- Release ZIPs inside RC
- v0.5 packages
- Native Build Pro artifacts
- Production deployment scripts
- Real database connections or credentials

## Extraction Rules
- RC must extract to a clean directory
- Extraction must not overwrite existing workspace
- Post-extraction: `factoryctl.ps1` must be present
- Post-extraction: help command must work
- Post-extraction: install dry-run must work

## Smoke Rules
- Safety gate smoke: verify no forbidden content
- CLI smoke: verify core commands respond
- Boundary smoke: verify release flags preserved

## Acceptance
- [ ] All flags correct
- [ ] No forbidden content
- [ ] Extraction clean
- [ ] CLI smoke passes
- [ ] Safety gate smoke passes
