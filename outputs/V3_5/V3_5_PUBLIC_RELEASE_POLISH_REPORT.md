# Codex Factory V3.5 — Public Release Polish Report

## Release Metadata

- **Version**: V3.5
- **Classification**: V3_5_PUBLIC_RELEASE_READY
- **Date**: 2026-07-17
- **Last verified CI run**: 29584799436 (V3_4_2_REMOTE_ARTIFACT_VERIFIED_STRICT)

## Files Changed

| File | Action |
|---|---|
| `README.md` | Rewritten: English public-facing + Chinese summary |
| `LICENSE` | Created: MIT License |
| `PUBLIC_RELEASE_CHECKLIST.md` | Created: pre-public audit checklist |
| `docs/INTERNSHIP_RESUME_BULLETS.md` | Created: internship portfolio packaging |
| `.github/workflows/codex-factory-ci.yml` | Unchanged (hardened in V3.4.1, strict in V3.4.2) |
| `outputs/V3_5/` | Created: V3.5 reports directory |

## README Summary

- **Tone**: Professional, honest, no hype
- **Language**: English primary, Chinese summary included
- **30-second value**: "Make Codex trustworthy for real software engineering"
- **Problem→Solution table**: 6 core problems mapped to Factory solutions
- **Verified Results**: Real CI run data, not simulated
- **Quick Start**: 4 steps (verifier, demo, CI, remote verify)
- **Architecture**: Directory map + verification flow diagram
- **Limitations**: Explicit non-claims section (6 items)
- **Roadmap**: V3.5 → V4.0 phases

## GitHub Metadata

### About Description
```
Engineering reliability framework for AI coding agents.
Snapshot verification, CI artifact traceability, evidence chain auditing.
15/15 strict checks. Verified on real GitHub Actions.
```

### Topics (recommended)
```
codex ai-agents agent-framework software-engineering
runtime-validation ci-cd github-actions artifact-verification
llm-evaluation developer-tools powershell evidence-chain
snapshot-testing engineering-reliability
```

### Pinned Repo Tagline
```
Codex Factory — Make AI coding agents trustworthy through verifiable evidence.
```

### Short Social Sharing Intro
```
I built Codex Factory, an engineering reliability framework for AI coding agents.
It solves the "trust gap" — how do you verify AI-generated code actually works?
With strict snapshot verification, CI artifact traceability, and 57 JSON Schema contracts.
23/23 tests. 15/15 checks. Zero secrets. Open source.
```

## Public Audit Summary

| Audit Area | Result |
|---|---|
| Secret scan (4500+ files) | PASS |
| No .env / auth.json | PASS |
| No private keys | PASS |
| No real API keys in content | PASS |
| No personal path leakage | PASS |
| README claim audit | PASS (all claims backed by CI receipts) |
| Limitations section present | PASS |
| LICENSE file | PASS (MIT) |
| .gitignore configured | PASS |
| .gitattributes configured | PASS |
| No exaggerated claims | PASS |
| Repository structure clean | PASS |
