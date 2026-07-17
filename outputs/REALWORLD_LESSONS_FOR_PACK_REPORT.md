# REALWORLD_LESSONS_FOR_PACK_REPORT

> Phase: REALWORLD-1-P1 — Lessons for Pack Improvement
> Source: REALWORLD-1 Online Bookstore validation experience
> Date: 2026-06-27

---

## 1. What Worked Well

| Element | Why | Pack Impact |
|---------|-----|-------------|
| Working Copy isolation | Zero risk to original project; user trusts factory | Keep as default for all write operations |
| Diagnostic Gate as support | Caught 4 real doc/source inconsistencies without blocking flow | Keep as support gate, not mainline |
| Context Packet risk carry | 7 risks survived phase transition intact | Make Context Packet auto-generate from active-risks.json |
| Negative controls | 40/40 prevented scope creep into Build Pro / v0.5 | Template for future phases |
| JaCoCo baseline | Quick coverage snapshot proved report consistency | Add `check_coverage` as standard gate |
| Source grep for error codes | Found 11 codes vs 7 reported — grep beats reading docs | Add `grep_error_codes` to diagnostic gate defaults |

## 2. What Was Friction for the User

| Issue | Severity | Fix for Pack |
|-------|----------|-------------|
| 10 separate phase commands required | 🔴 High | Pack needs single entry: `validate-project <path>` |
| User had to specify each phase (A, B, C...) | 🔴 High | Phases should auto-chain with confirmation prompts |
| Reports scattered across outputs/ and governance/ | 🟡 Medium | Single consolidated report with sections |
| Context Packet setup was manual | 🟡 Medium | Auto-generate from project-state + active-risks |
| Verifier syntax error on REALWORLD-0 check | 🟢 Low | Fix `Test-Path` with `-or` — use proper boolean logic |
| No visual progress indicator | 🟡 Medium | Show task-graph.json progress as a table |
| H2 startup required manual process kill | 🟡 Medium | Add `--bounded-smoke` flag with auto-shutdown |

## 3. Missing Defaults Discovered

| Default | Why Needed | Proposed Location |
|---------|-----------|-------------------|
| `validate-project.ps1` | Single entry point | `scripts/` in pack |
| `auto-chain-phases.json` | Phase dependency + auto-advance config | `.codex-factory/` |
| `smoke-bounded.ps1` | Bounded startup smoke with auto-kill | `scripts/` |
| `grep-checks.json` | Standard grep patterns for diagnostic gate | `.codex-factory/` |
| `consolidated-report.md` template | Single report format | `templates/` in pack |
| `user-prompts.json` | Confirmation prompts between phases | `.codex-factory/` |

## 4. Builder-4-Pack Integration Gaps

| Builder Component | In Staging? | REALWORLD-1 Validated? |
|-------------------|------------|----------------------|
| Build Lite workflow | ✅ | ✅ (10 phases executed) |
| Context Packet | ✅ | ✅ (7 risks carried) |
| Diagnostic Gate | ✅ | ✅ (4 real gaps found) |
| External Memory | ✅ | ✅ (9 files populated) |
| Mode Selector | ✅ | ✅ (Build Lite chosen correctly) |
| Native Build Pro | ✅ | ❌ (correctly NOT triggered) |
| Task Graph | ✅ | ✅ (10 tasks, dependency chain) |
| Negative Controls | ✅ | ✅ (40/40 pattern reusable) |
| Verifier | ✅ | ⚠️ (1 syntax issue) |
| **Single Entry Point** | ❌ | — |
| **Auto-Chain** | ❌ | — |
| **Bounded Smoke** | ❌ | — |
| **Consolidated Report** | ❌ | — |

## 5. Recommended Pack Updates (Pre-Bundle)

| Priority | Change | Effort |
|----------|--------|--------|
| P0 | Fix verifier syntax bug | 1 line |
| P1 | Add `validate-project.ps1` as single entry | ~50 lines |
| P1 | Add `smoke-bounded.ps1` with auto-kill | ~30 lines |
| P2 | Add `consolidated-report.md` template | Template file |
| P2 | Auto-generate Context Packet from active-risks | Logic change |
| P3 | Auto-chain phases with confirmation | Workflow refactor |

## 6. What v0.5 Still Needs

| Requirement | Status |
|-------------|--------|
| 1 real project validated | ✅ REALWORLD-1 |
| 2+ iterations of user feedback | ❌ Not yet |
| Vanilla/non-factory comparison | ❌ Not yet |
| Factory-guided build from scratch | ❌ REALWORLD-2 candidate |
| User satisfaction metrics | ❌ Not yet |
