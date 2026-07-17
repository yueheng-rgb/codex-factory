# Codex Factory V3.5 — Public Release Checklist

> Run this checklist before switching the repository from Private to Public.

## Pre-Release Audit

### Secrets & Credentials

- [x] No `.env` files committed (verified via filename scan — none found)
- [x] No `auth.json` committed (verified — none found)
- [x] No private keys (`*.pem`, `*.pfx`, `*.jks`) committed (none found)
- [x] No GitHub tokens (`ghp_`, `gho_`, `ghs_`, `ghr_`, `github_pat_`) in content
- [x] No OpenAI keys (`sk-`, `sk-or-`) in content
- [x] No cloud provider keys (`AKIA...`, `AIzaSy...`) in content
- [x] No DeepSeek keys in content
- [x] Secret scan on 4500+ files: PASS (2 regex false positives in scripts)

### Personal Information

- [x] No real email addresses in committed code (git config email is GitHub-noreply)
- [x] No phone numbers in committed code
- [x] No local filesystem paths pointing to personal directories
- [x] Git history review: no sensitive data in commit messages

### Claims & Accuracy

- [x] README does not claim "production deployment"
- [x] README does not claim "SaaS platform"
- [x] README has explicit Limitations / Non-Claims section
- [x] All "VERIFIED" claims are backed by reproducible evidence (CI receipts)
- [x] No exaggerated performance numbers
- [x] No fake user testimonials

### Repository Metadata

- [x] LICENSE file present (MIT)
- [x] README.md is public-ready (English primary, Chinese summary)
- [x] `.gitattributes` configured for cross-platform LF normalization
- [x] `.gitignore` excludes `node_modules/`, `.next/`, `dist/`, `*.zip`, `artifacts/remote/`
- [x] No large binaries committed (largest text file is snapshot manifest)

### GitHub Settings (Manual)

- [ ] Repository visibility: switch from Private → Public
- [ ] About description set (see `github_metadata` in V3.5 report)
- [ ] Topics added (see `github_metadata` in V3.5 report)
- [ ] Actions permissions: allow all actions
- [ ] Branch protection: optional (recommend `main` protection after public)
- [ ] Issues enabled
- [ ] Discussions: optional
- [ ] Wiki: optional (disable by default)

### CI / Actions

- [x] Workflow uses `workflow_dispatch` (manual trigger only — no auto-run on push)
- [x] No secrets hardcoded in workflow YAML
- [x] Workflow tested and verified (run 29584799436: 15/15 PASS)
- [ ] (Optional) Add GitHub Actions status badge to README

### Documentation

- [x] README.md: project value, quick start, architecture, limitations, roadmap
- [x] Chinese summary included for bilingual readers
- [x] Verified results section with real run IDs
- [x] `docs/INTERNSHIP_RESUME_BULLETS.md` for internship portfolio use

## Post-Release Actions

- [ ] Pin repository to GitHub profile
- [ ] Share on relevant platforms (optional)
- [ ] Monitor for issues / questions
- [ ] Update roadmap as features land

## Sign-Off

- **Date**: 2026-07-17
- **Version**: V3.5
- **Classification**: V3_5_PUBLIC_RELEASE_READY
- **Auditor**: Automated (Codex Factory CI + manual review)
