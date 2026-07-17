# CLOUD_DEFERRAL_RECORD.md

> Part of: FACTORY-DEFAULT-WORKFLOW-0
> Section: K — Cloud Deferral Record
> Version: 1.0.0

---

## Purpose

Formally record the decision to defer cloud infrastructure for Codex Factory. This prevents scope creep and ensures cloud-related work is not accidentally started.

---

## Decision

**Cloud is deferred.** No cloud infrastructure (servers, domains, databases, deployment pipelines) will be built, purchased, or configured in the v0.x line unless explicitly re-evaluated.

---

## Rationale

| Reason | Detail |
|--------|--------|
| Cloud does not directly improve Codex reasoning capability | Factory's value is local tooling + governance |
| Premature cloud adds complexity without benefit | v0.5 is a local workflow release |
| User is not blocked without cloud | All v0.5 capabilities are local |
| Cloud introduces security surface | Secrets, user projects should not be on cloud by default |

---

## What Cloud Is NOT Needed For (Now)

| Use Case | Why Not Now |
|----------|------------|
| Running Factory | Factory runs locally |
| Storing user projects | Projects stay on user's machine |
| Storing secrets | Secrets stay local |
| External conversation spaces | Local filesystem is sufficient |
| Real-time collaboration | Not a v0.x requirement |

---

## Possible Future Cloud Use (Post-v1.0)

| Use Case | Conditions |
|----------|-----------|
| Resource pack update distribution | Read-only CDN, no user data |
| Version manifest hosting | Static JSON file |
| Checksum/signature distribution | Static files only |
| Release notes hosting | Static content |
| Optional update channel | Opt-in only |

---

## Cloud Safety Boundaries (When Eventually Adopted)

| Rule | Detail |
|------|--------|
| Must not store user projects | Projects stay local |
| Must not store secrets | Secrets stay local |
| Must not store external conversation spaces | Local by default |
| Must be opt-in | Never auto-upload |
| Read-only by default | Cloud is distribution, not storage |

---

## Re-evaluation Trigger

Cloud decision may be re-evaluated when:
- v1.0 is released and stable
- User explicitly requests cloud features
- Resource pack distribution becomes a bottleneck
