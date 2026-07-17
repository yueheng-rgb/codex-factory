# RC-USER-ACCEPTANCE-0 — Section C: Smoke Evidence Review

**Phase:** RC-USER-ACCEPTANCE-0 | **Section:** C | **Status:** COMPLETE

## Evidence by Area

### Extraction
| Evidence | Source | Coverage |
|---|---|---|
| SHA verified before extraction | RC-SMOKE-0 Section B | ✅ Explicitly tested |
| Expand-Archive successful | RC-SMOKE-0 Section B | ✅ Explicitly tested |
| 2735 files, 227 dirs | RC-SMOKE-0 Section B | ✅ Explicitly tested |
| Top-level structure verified | RC-SMOKE-0 Section B | ✅ Explicitly tested |
| RC metadata flags read | RC-SMOKE-0 Section B | ✅ Explicitly tested |

### CLI Commands
| Command | Exit | Coverage |
|---|---|---|
| Get-Help factoryctl.ps1 | 0 | ✅ Explicitly tested |
| factoryctl.ps1 status | 0 (626 chars JSON) | ✅ Explicitly tested |
| factoryctl.ps1 agents | 0 | ✅ Explicitly tested |
| factoryctl.ps1 watch | 0 | ✅ Explicitly tested |
| factoryctl.ps1 verify | 1 (expected) | ✅ Explicitly tested |

### Gates (Policy-Verified)
| Gate | Coverage | Note |
|---|---|---|
| Security/Deploy Gate | ⚠️ POLICY-VERIFIED | Trigger logic confirmed via policy docs; not invoked with live deployed project |
| Package QA Gate | ⚠️ POLICY-VERIFIED | Required-for-handoff confirmed; not triggered (RC is candidate) |
| Context Space | ⚠️ POLICY-VERIFIED | Required-for-long-horizon confirmed; packet generation not live-tested |

### Memory Quality (Policy-Verified)
| Test | Coverage |
|---|---|
| 3 positive cases | ⚠️ POLICY-VERIFIED (schema/policy doc review) |
| 5 negative cases | ⚠️ POLICY-VERIFIED (schema/policy doc review) |

### Cleanup (Policy-Verified)
| Test | Coverage |
|---|---|
| PLAN default | ⚠️ POLICY-VERIFIED (cleanup workflow doc) |
| DELETE requires confirm | ⚠️ POLICY-VERIFIED (cleanup workflow doc) |
| CORE_EVIDENCE protected | ⚠️ POLICY-VERIFIED (cleanup workflow doc) |

### Phase Close (Policy-Verified)
| Test | Coverage |
|---|---|
| Missing verifier → blocked | ⚠️ POLICY-VERIFIED (verifier pattern in governance) |
| Stale snapshot rejected | ⚠️ POLICY-VERIFIED (context-space policies) |

### Forbidden Content
| Check | Coverage |
|---|---|
| 11/11 patterns clean | ✅ Explicitly tested (ZIP audit + extraction audit) |

### Negative Controls
| Check | Coverage |
|---|---|
| 38/38 ALL_DEFENCE_HELD | ✅ Explicitly defined and verified |

## Coverage Assessment

| Category | Explicitly Tested | Policy-Verified |
|---|---|---|
| Extraction | 5/5 | 0 |
| CLI | 5/5 | 0 |
| Gates | 0/3 | 3/3 |
| Memory Quality | 0/8 | 8/8 |
| Cleanup | 0/3 | 3/3 |
| Phase Close | 0/2 | 2/2 |
| Forbidden Content | 11/11 | 0 |
| Negative Controls | 38/38 | 0 |

**WARNING_COMMAND_COVERAGE_CLARIFICATION:**
Gates, memory quality, cleanup, and phase-close were verified via policy document review,
not through live execution against a running Factory instance.
This is acceptable for RC smoke (policy correctness validation) but should be noted
for v0.5 decision: live execution testing would strengthen evidence.

**Section C verdict: COMPLETE (with coverage note)**
