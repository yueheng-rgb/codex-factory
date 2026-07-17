# Orchestrator Self-Check

> After any Factory run using `RUN_CODEX_APP_FACTORY.md`, verify:

| # | Check | Expected |
|---|---|---|
| 1 | Started from natural language? | Yes — one requirement sentence |
| 2 | Type classified correctly? | Matches content-site/fullstack-admin/saas-tool/api-service/threejs-interactive |
| 3 | Size + risk assessed? | S/M/L/XL + low/medium/high documented |
| 4 | Correct starter chosen? | Matches type in STARTER_REGISTRY |
| 5 | No scope creep? | Only user-requested features + technical necessities |
| 6 | Minimal loop defined? | First-version end-to-end path documented |
| 7 | Run-state created before business closure? | `.codex-factory/run-state.json` created at Stage 4 |
| 8 | Run-events started from run_started? | `.codex-factory/run-events.jsonl`第一条为 run_started |
| 9 | Sequence continuous? | sequence 从 1 连续无跳号 |
| 10 | Each stage has started+completed? | 每个 stage 有配对的 started/completed 事件 |
| 11 | First failures preserved? | 首次失败事件不被后续成功覆盖 |
| 12 | Runtime validation passed? | install + typecheck + build + dev short-start all pass |
| 13 | Real functional tests executed? | Type-specific checks completed |
| 14 | functionalTests consistent with finalStatus? | functionalTests=completed 时才能 finalStatus=completed |
| 15 | Defects classified correctly? | Generated/starter/script/environment categories used |
| 16 | Only generic defects backflowed? | No business-specific code in source starter |
| 17 | validate-factory-run.ps1 passed? | 门禁脚本返回 PASS |
| 18 | userInterventionCount accurate? | 反映实际用户干预次数 |
| 19 | First-failure records preserved? | Original errors documented before fixes |
| 20 | Final report output? | Concise summary with all required fields |

### The Ultimate Test

**Q**: Did the user need to send additional Phase A/B/C/D instructions manually?

**Required answer**: `No — the user only provided a natural-language requirement.`

If the user had to intervene with detailed phase instructions, the orchestrator failed.