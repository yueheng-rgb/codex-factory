# Native Build Pro Readiness Gate v2

## Gate Checks (ALL must PASS)
| # | Check | Evidence Required |
|---|-------|------------------|
| G01 | spawn_agent available | Capability gate result |
| G02 | User explicitly approved | mode-selection.json or equivalent |
| G03 | External memory initialized | .codex-factory/ with 8+ files |
| G04 | Project classified LARGE or HIGH_RISK | Classification result |
| G05 | Requirements sealed | Sealed spec document |
| G06 | Task graph has 8+ parallelizable nodes | Task graph JSON |
| G07 | Write-scope map has 0 overlaps | Write-scope map JSON |
| G08 | Agent capsules defined for all agents | Agent capsules JSON |
| G09 | Agent registry initialized | Registry JSON |
| G10 | Baseline reference exists (Build Lite or Vanilla) | Baseline reference |
| G11 | All P0 issues resolved | Diagnostic gate previous run |
| G12 | Lifecycle policy acknowledged | Policy reference |

## Outcome
- ALL PASS → NATIVE_BUILD_PRO_READY
- ANY FAIL → BLOCKED (use Build Lite or fix gate failures)
