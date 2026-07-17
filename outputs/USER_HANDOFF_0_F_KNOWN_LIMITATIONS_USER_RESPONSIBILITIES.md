# USER-HANDOFF-0 — Section F: Known Limitations and User Responsibilities

## Known Limitations

| # | Limitation | Impact |
|---|---|---|
| 1 | Production deployment not validated | Do not use for production server deployment |
| 2 | Cloud service not included | No cloud connectivity or SaaS capability |
| 3 | Factory advantage is STRONG_PARTIAL, not universal | Supported for tested tasks; not proven for all project types |
| 4 | Native Build Pro is conditional | Not activated by default; requires explicit request |
| 5 | Build Lite is default | Suitable for most projects; complex projects may need more |
| 6 | Gates are policy-driven, not code-enforced at runtime | Policy JSONs define behavior; enforcement depends on workflow discipline |
| 7 | Memory quality is in factory-build-mode/ | Not yet a standalone top-level module |

## User Responsibilities

| # | Responsibility |
|---|---|
| 1 | **Manage your own secrets** — never commit real .env files |
| 2 | **Approve high-risk actions** — cleanup DELETE, production actions require confirmation |
| 3 | **Verify scope** — v0.5 is local tooling; production use is at your own risk |
| 4 | **Review gates** — Security/Deploy Gate is a check, not a permission |
| 5 | **Keep CORE_EVIDENCE** — protected by default; do not bypass without cause |

## Default Behaviors You Should Know
- Cleanup DEFAULT mode: PLAN (no deletion)
- Cleanup DELETE: requires `-Confirm` switch
- CORE_EVIDENCE: protected; requires `-ForceEvidence` to override
- Native Build Pro: conditional; requires explicit activation
- Build Lite: default for all new projects

**Section F verdict: COMPLETE**
