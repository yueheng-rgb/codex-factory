# D: File Integration Map

## Source → Target Mapping

| Source Directory | R1 Package Path | Contents |
|-----------------|-----------------|----------|
| `factory-workflow/` | `workflow/` | 10 protocol docs |
| `factory-isolation/` | `isolation/` | 10 protocols + 2 schemas + 1 template |
| `factory-dashboard/` | `dashboard/` | 7 docs + 3 schemas + 1 template + 7 fixtures + 1 prototype PS1 |
| `factory-recovery/` | `recovery/` | 8 docs + 1 schema + 1 script + 3 prompts |
| `factory-multi-agent/` | `multi-agent/` | 8 docs + 3 schemas |
| `factory-evidence/` | `evidence/` | 5 docs + 2 schemas + 1 validator PS1 |
| `factory-lifecycle/` | `lifecycle/` | 8 docs + 2 schemas |
| `governance/factory-*/` | `governance/` | All governance JSONs |
| `harness/*/` | `harness/` | Simulation scenarios |
| `scripts/factory-*-verify.ps1` | `scripts/` | 7 verifier scripts |
| `outputs/FACTORY_*_REPORT.md` | `docs/reports/` | Phase reports |

## Excluded from R1
- `node_modules/`, `.git/`, temporary fixtures, stale staging dirs
- `factory-ab/`, `benchmark/`, `blind-test-results/` (AB test artifacts, not R1)
- Real project directories (ecommerce_homework, habit-tracker-*, etc.)
