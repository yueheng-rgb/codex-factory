# Deployment Manifest Template
# Codex Factory R6.0

## Purpose

Standardized deployment documentation for all Codex Factory projects.
Every project should have a deployment manifest before being considered
for staging or production review.

## Schema

Defined in `schemas/deployment-manifest.schema.json`.

## Example

See `governance/production/deployment-manifest.example.json` for the
SaaS Runtime Validation testbed.

## Sections

1. **Project Info** — name, version, repository
2. **Deployment Targets** — local, Docker, VPS, Vercel, Railway, Fly.io
3. **Environment Variables** — name, required, secret, default, description
4. **Ports** — port numbers and purposes
5. **Health Check** — path for monitoring
6. **Database** — type, migration command, seed command
7. **Rollback Notes** — how to revert
8. **Known Non-Claims** — explicit statements of what this is NOT
9. **Known Risks** — documented limitations

## Rules

- NEVER include real credentials or API keys
- Mark all secret env vars with `secret: true`
- Always include non-claims — be honest about limitations
- Rollback notes must be actionable
- Health check path must return 200 OK
