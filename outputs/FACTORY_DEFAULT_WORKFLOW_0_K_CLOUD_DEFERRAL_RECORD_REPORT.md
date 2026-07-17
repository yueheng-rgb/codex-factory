# FACTORY-DEFAULT-WORKFLOW-0 — K: Cloud Deferral Record Report

> Phase: FACTORY-DEFAULT-WORKFLOW-0
> Section: K — Cloud Deferral Record
> Date: 2026-06-28

## Deliverables

| File | Path |
|------|------|
| Deferral Record | `factory-workflow/CLOUD_DEFERRAL_RECORD.md` |
| Governance JSON | `governance/factory-workflow/factory-default-workflow-0-cloud-deferral-record.json` |

## Decision

**Cloud is deferred.** No servers, domains, databases, or deployment pipelines in v0.x.

## Rationale
- Cloud does not improve Codex reasoning capability
- v0.5 is local workflow — cloud adds complexity without benefit
- Security: user projects/secrets should not be on cloud by default

## Future Possibility (Post-v1.0)
- Read-only CDN for resource pack distribution
- Static version manifest / checksums / release notes
- Opt-in update channel only
