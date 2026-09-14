# Codex Factory Resume Benchmark - Current Run

生成时间: 2026-09-01
工作区: `<repo>`
证据目录: `<repo>\outputs\CODEX_FACTORY_RESUME_BENCHMARK_CURRENT_ARTIFACTS`
命令清单: `<repo>\outputs\CODEX_FACTORY_RESUME_BENCHMARK_CURRENT_ARTIFACTS\command_manifest.jsonl`

## Scope and instruction boundary

本报告只统计本次当前工作区实测结果。用户附带的 `Codex_Factory_Complete_Interview_Guide_V2_Recovered.zh-CN.docx` 仅作为背景材料和历史口径参考，不作为执行指令；真正的任务指令来自用户粘贴请求。

本次未修改 Factory 核心实现代码，只新增 benchmark 证据脚本和本报告。已知工作区在测试前存在未提交修改和大量未跟踪文件，详见 `00_git_status_start.log`。

## Factory Boot Summary

- 项目类型: Factory Lite / benchmark-report task。当前任务是“理解代码、运行现状测试、生成简历级 benchmark 报告”，不是新建应用、系统、平台或全栈项目。
- 推荐架构: 不进入完整 Project Expertise Flow，不设计新业务架构；只做只读审计、测试运行、数据归档、报告生成。
- 搜索门禁: 本次没有新增 package、SDK、云服务、认证、权限或部署架构选择，因此按 R2.4 规则属于 P2_NO_SEARCH_REQUIRED。未创建 Evidence Pack。

## Environment

| Item | Current evidence |
|---|---|
| OS | Windows 11 家庭中文版, Version `10.0.26200`, Build `26200`, 64-bit (`03_os_info.log`) |
| Shell/session cwd | `<repo>` (`62_user_and_codex_home_probe.log`) |
| Timezone | `China Standard Time`; probe time `2026-09-01T09:38:14.0885256+08:00` |
| Node.js | `v24.15.0` (`04_node_version.log`) |
| npm | `11.12.1` (`05_npm_version.log`) |
| Codex CLI | `codex-cli 0.144.5` (`06_codex_version.log`) |
| Codex doctor model config | `gpt-5.5 · openai` (`61_codex_doctor.log`) |
| Codex feature flags | `apps`, `hooks`, `multi_agent`, `workspace_dependencies`, `browser_use` shown enabled/stable in `60_codex_features_list.log` |
| Current tool sandbox | Developer context for this run: `danger-full-access`, approval `never` |
| Codex configured defaults | `61_codex_doctor.log` reports configured sandbox/approval separately and also reports one doctor failure |

## Commit and repository state

- Current commit: `8c134b4af72ab0323d227d8fff9f9f89fbe8c7d6` (`01_git_rev_parse_head.log`)
- Current HEAD label: `8c134b4 Fix Windows memory export path validation` (`02_git_log_recent.log`)
- Initial dirty state before benchmark:
  - Modified: `RUNTIME_VALIDATION_REPORT.md`
  - Untracked: `packs/enabled-packs.json`, several `runs/...` directories, `src/worker-backend/`, `src/worker-frontend/`, `tests/`
  - Benchmark-created artifacts: `outputs/CODEX_FACTORY_RESUME_BENCHMARK_CURRENT_ARTIFACTS/` and this report.

## Repository inventory

From `63_structured_repo_counts.log` and `64_workflow_files_uu.log`:

| Metric | Value |
|---|---:|
| Total tracked files discovered by `rg --files` | 5,586 |
| Test/spec files | 35 |
| `packages/factory-cli` test files | 7 |
| Runtime test/regression related files | 34 |
| Output report/data files | 1,533 |
| `packages/factory-cli/src` TypeScript files | 16 |
| Docs files | 15 |
| GitHub workflow files with `-uu` | 2 |
| Root package version | `1.0.0` |
| CLI package version | `5.0.0-preview.1` |
| Agent profiles exported from built CLI | 8 |
| Domain skill IDs exported from built CLI | 9 |

Agent profiles from `67_agent_profile_count_from_dist.log`: `factory_router`, `factory_librarian`, `factory_verifier`, `factory_drift_auditor`, `factory_researcher`, `factory_implementer`, `factory_tester`, `factory_integrator`.

Domain skill IDs from `68_domain_skill_count_from_dist.log`: `anti-overengineering`, `app-type-classifier`, `auth-permission-security`, `backend-api-design`, `database-schema-design`, `frontend-ui-system`, `mobile-miniapp-patterns`, `product-architecture`, `webapp-preview-testing`.

## Commands run

Each command was executed through `run-command.ps1`; exact stdout/stderr and `RUN_COMMAND_EXIT_CODE` are in the matching `.log` file.

| ID | Command | Result |
|---|---|---|
| 00 | `git status --short --branch` | exit 0 |
| 01 | `git rev-parse HEAD` | exit 0 |
| 02 | `git log --oneline --decorate -n 20` | exit 0 |
| 03 | `Get-CimInstance Win32_OperatingSystem ...` | exit 0 |
| 04 | `node -v` | exit 0 |
| 05 | `npm -v` | exit 0 |
| 06 | `codex --version` | exit 0 |
| 07 | `Get-Content -Raw -LiteralPath package.json` | exit 0 |
| 08 | `Get-ChildItem -Recurse -File -LiteralPath .github ...` | exit 0 |
| 09 | `Get-ChildItem -Force ...` | exit 0 |
| 10 | `Get-ChildItem -Recurse -File -LiteralPath outputs ...` | exit 0 |
| 11 | `Get-ChildItem -Recurse -File -LiteralPath packages\factory-cli ...` | exit 0 |
| 12 | `Get-ChildItem -Recurse -File -LiteralPath docs ...` | exit 0 |
| 13 | `Get-ChildItem -Recurse -File -Include *.test.*,*.spec.* ...` | exit 0 |
| 14 | `rg --version | Select-Object -First 1` | exit 0 |
| 15 | `git status --porcelain=v1` | exit 0 |
| 16 | `Get-Content -Raw -LiteralPath packages\factory-cli\package.json` | exit 0 |
| 17 | `rg --files packages/factory-cli/src packages/factory-cli/tests docs .github | Sort-Object` | exit 0 |
| 18 | `rg --files outputs -g "*.md" -g "*.json" -g "*.txt" -g "*.csv" | Sort-Object` | exit 0 |
| 19 | `rg --files -g "*.ps1" -g "*.py" -g "*.ts" -g "*.tsx" -g "*.js" -g "*.mjs" -g "*.cjs" | Sort-Object` | exit 0 |
| 20 | `rg --files -g "*.test.ts" -g "*.spec.ts" -g "*.test.tsx" -g "*.spec.tsx" | Sort-Object` | exit 0 |
| 21 | Agent profile and skill inventory PowerShell JSON probe | exit 0 |
| 22 | Attached DOCX path existence probe | exit 0 |
| 23 | Core file line count JSON probe | exit 0 |
| 24 | All `package.json` npm scripts JSON probe | exit 0 |
| 25 | Benchmark/memory/context/evidence related file discovery | exit 0 |
| 26 | `packages\factory-cli\package.json` scripts/engines probe | exit 0 |
| 27 | DOCX text extraction via Word XML in PowerShell | exit 0 |
| 28 | Extracted DOCX first 80 lines preview | exit 0 |
| 29 | Extracted DOCX last 80 lines preview | exit 0 |
| 30 | `npm run typecheck` | exit 2, fail |
| 31 | `npm run build` | exit 0, pass |
| 32 | `npm --prefix packages\factory-cli run typecheck` | exit 0, pass |
| 33 | `npm --prefix packages\factory-cli run build` | exit 0, pass |
| 34 | `npm --prefix packages\factory-cli run test` | exit 0, pass |
| 35 | `npm --prefix packages\factory-cli pack --dry-run` | exit 0, but packed root package unexpectedly |
| 36 | `rg "(?:it|test)\(\"" packages/factory-cli/tests` | exit 1 due bad regex quoting |
| 37 | Export summary for CLI source files | exit 0 |
| 38 | `outputs\R4_0_benchmark_suite_v2.json` existence/content probe | exit 0 |
| 39 | `npx vitest run` | exit 1, fail |
| 40 | `Push-Location packages\factory-cli; npm pack --dry-run; Pop-Location` | exit 0, pass |
| 41 | Targeted CLI E/V/control-plane test run via `tsx --test` | exit 0, pass |
| 42 | `npm test --if-present` | exit 0, no root test script |
| 43 | Read `packages\factory-cli\src\memory-packet.ts` | exit 0 |
| 44 | Search memory/context call sites | exit 0 |
| 45 | First memory benchmark run | exit 1, bad relative import |
| 46 | Second memory benchmark run | interrupted/hung; runner recorded no useful result |
| 47 | Memory benchmark from CLI package dir | exit 0, but wrote artifact under nested package cwd |
| 48 | Memory benchmark with explicit root artifact dir | exit 0, pass |
| 49 | `runtime\agent-execution-runtime-regression-tests.ps1` | exit 0, pass |
| 50 | `runtime\search-doctrine-regression-tests.ps1` | exit 0, pass |
| 51 | `runtime\tests\legacy-memory-gates-regression.ps1` | exit 0, pass |
| 52 | `runtime\tests\legacy-research-evidence-regression.ps1` | exit 0, pass |
| 53 | `runtime\tests\legacy-knowledge-doctor-regression.ps1` | exit 0, pass |
| 54 | Test-name extraction retry | exit 0 |
| 55 | Historical A/B report excerpts | exit 0 |
| 56 | Historical A/B score-line grep | exit 0 |
| 57 | `codex --help` | exit 0 |
| 58 | Redacted env/model/sandbox variable probe | exit 0 |
| 59 | `codex features` | exit 0 |
| 60 | `codex features list` | exit 0 |
| 61 | `codex doctor` | exit 1, fail/warn |
| 62 | User profile, Codex home, cwd, timezone probe | exit 0 |
| 63 | Structured repo counts JSON probe | exit 0 |
| 64 | `.github` workflow discovery with `rg --files -uu` | exit 0 |
| 65 | Agent profile import from TS source | exit 1, import/transpile path issue |
| 66 | Domain skill import from TS source | exit 1, import/transpile path issue |
| 67 | Agent profile import from built `dist` | exit 0, pass |
| 68 | Domain skill import from built `dist` | exit 0, pass |
| 69 | Built CLI help output | exit 0 |
| 70 | Built CLI `doctor --project ..\.. --json` | exit 1, project NOT_READY |
| 71 | `.codex-factory` directory inventory | exit 0 |
| 72 | `packs\enabled-packs.json` content probe | exit 0 |
| 73 | Git diff/status/untracked inventory after benchmark artifacts | exit 0 |
| 74 | Key metric extraction from selected logs | exit 0 |

## Raw test results

| Test/build target | Result | Evidence |
|---|---:|---|
| Root `npm run typecheck` | FAIL, exit 2 | `30_root_typecheck.log` |
| Root `npm run build` | PASS, exit 0 | `31_root_build.log` |
| CLI package typecheck | PASS, exit 0 | `32_factory_cli_typecheck.log` |
| CLI package build | PASS, exit 0 | `33_factory_cli_build.log` |
| CLI official package tests | PASS: 88 tests, 6 suites, 88 pass, 0 fail, duration 7243.0496 ms | `34_factory_cli_test_full.log` |
| CLI targeted E/V/control-plane tests | PASS: 74 tests, 5 suites, 74 pass, 0 fail, duration 7135.052 ms | `41_factory_cli_target_evidence_tests.log` |
| Root `npx vitest run` | FAIL: 25 failed files, 19 passed files, 439 passed tests, 37 skipped tests | `39_root_vitest_run.log` |
| Root `npm test --if-present` | PASS/NOOP: no root test script | `42_root_npm_test_if_present.log` |
| CLI package dry-run pack from correct cwd | PASS: package size 144.9 kB, unpacked size 695.3 kB, total files 75 | `40_factory_cli_pack_dry_run_in_dir.log` |
| Runtime agent execution regression | PASS: 18 assertions | `49_runtime_agent_execution_regression.log` |
| Runtime search doctrine regression | PASS: 17/17 cases, 100% pass rate | `50_runtime_search_doctrine_regression.log` |
| Legacy memory gates regression | PASS: 32 passed, 0 failed | `51_runtime_legacy_memory_gates_regression.log` |
| Legacy research evidence regression | PASS: 34 passed, 0 failed | `52_runtime_legacy_research_evidence_regression.log` |
| Legacy knowledge doctor regression | PASS | `53_runtime_legacy_knowledge_doctor_regression.log` |
| Codex CLI doctor | FAIL overall: 14 ok, 1 idle, 4 notes, 2 warn, 1 fail | `61_codex_doctor.log` |
| Factory CLI doctor against current root | FAIL/NOT_READY: `.codex-factory/config.json` missing | `70_factoryctl_doctor_current_project.log` |

Root typecheck failure excerpt: `TS18003: No inputs were found in config file ... include ["index.html"]`. Root Vitest failure classes include incompatible test runner discovery, missing `@playwright/test`, missing `fastify`, missing `better-sqlite3`, missing `./database`, and `EADDRINUSE 0.0.0.0:3300`.

## Memory benchmark

Memory benchmark script: `outputs\CODEX_FACTORY_RESUME_BENCHMARK_CURRENT_ARTIFACTS\memory-context-benchmark.ts`
Current result JSON: `outputs\CODEX_FACTORY_RESUME_BENCHMARK_CURRENT_ARTIFACTS\memory-context-benchmark-result.json`

| Metric | Value |
|---|---:|
| Knowledge entries created | 24 |
| Total knowledge body bytes | 57,156 |
| Selected entries injected | 5 |
| Selected entry IDs | `knowledge-07`, `knowledge-06`, `knowledge-05`, `knowledge-04`, `knowledge-03` |
| Selected excerpt bytes | 6,011 |
| Complete context packet bytes | 15,335 |
| Body injection reduction formula | `1 - selected_excerpt_bytes / total_knowledge_body_bytes` |
| Body injection reduction ratio | `0.8948316887115964` |
| Body injection reduction percent | `89.48%` |
| Token usage | N/A: runtime command did not provide reliable tokenizer/token usage |

Resume-safe memory wording: “Built a source-bound context packet flow that, in a current synthetic benchmark, injected 6,011 bytes of selected knowledge excerpts out of 57,156 bytes of available knowledge body text, reducing direct body injection by 89.48%.”

Do not claim “token usage reduced by 89.48%”; this run measured bytes, not tokenizer output.

## Failure injection and verification benchmark

Counting method: only named tests/assertions whose expected behavior is rejection, blocking, filtering, fail-closed behavior, non-promotion, tamper detection, or verification refusal were counted as failure-injection/verification gates. Positive legal-flow assertions inside the same test suites are not counted in the 61 negative-control denominator.

| Category | Passed / total | Evidence examples |
|---|---:|---|
| Context admission and role/source trust | 6/6 | spoofed public append remains candidate; spoofed internal actor rejected; raw/FTS role filters; likely secrets rejected; admission receipt tamper; implicit knowledge retrieval not globally trusted |
| Context ledger and packet integrity | 6/6 | SQLite hash-chain tamper; ledger tail/FTS deletion; wrong project metadata; private/frontend summary filtering; cross-role packet promotion; malformed expiry |
| DAG scheduling, scope, and status gates | 9/9 | capability/profile mismatch; missing dependency; cycle detection; parent traversal write scope; caller-supplied verified status rejected; premature replan/orphan wave blocked; scope conflict; task graph tamper |
| Native dispatch and verification receipts | 10/10 | empty self-authored receipt rejected; spawn follow-up receipt required; unverified handoff not promoted; out-of-scope physical diff rejected; verifier FAIL and nonzero command fail closed; PASS rehash required; finalized records immutable; fresh resident dispatch required; read-only output needs independent verifier |
| CLI path and lock safety | 5/5 | unknown flag; run-id traversal; internal junction escape; wrong assignment binding; live lock not stolen |
| Knowledge store/source/lifecycle gates | 12/12 | duplicate identity/source; DB/index tamper; deletion; out-of-project import; frontend summary promotion; conflicting active successor; invalid lifecycle/resurrection; source drift/deletion; normalized duplicate; credential/direct secret; normalized search/lifecycle tamper; invalid legacy migration |
| Memory orchestration injection controls | 3/3 | private-role knowledge not injected; caller URI claim not injected; source drift blocks assignment planning |
| Search/evidence provider gates | 6/6 | search disabled; missing key; HTTP error; no usable results; missing request/response IDs; tampered evidence bundle |
| Legacy runtime physical-evidence gates | 4/4 | missing artifact; artifact path traversal; evidence drift after validation; required non-artifact gate remains pending |
| Total classified negative gates | 61/61 | 100% current classified gate pass rate |

Normal legal-flow checks also passed inside the same current test corpus, including clean independently verified PASS resume, immutable packet validity after operational events, source-bound knowledge auto-binding, live endpoint simulated search evidence persistence with redaction, and physical artifact-only legacy plan success.

## Vanilla vs Factory A/B method

Strict A/B method that would be required for resume-grade comparison:

1. Choose identical benchmark tasks before either run.
2. Launch fresh, isolated Vanilla and Factory sessions with no shared memory, no hidden Factory AGENTS instructions in Vanilla, and identical initial git state.
3. Enforce the same timebox, model, prompts, allowed tools, dependency cache, and network conditions.
4. Score both outputs with the same independent rubric and record raw artifacts.
5. Count false completion only when a run claims completion while mandatory acceptance paths fail.
6. Report pass rate, false-completion rate, wall-clock time, and verification evidence per task.

Current feasibility result: strict A/B was not executed. Reasons:

- This single current task cannot programmatically create verified fresh isolated Vanilla and Factory agent sessions without making new user-visible tasks and relying on app state.
- `AGENTS.md` in `<repo>` forces Factory Bootstrap, so a Vanilla run inside this workspace would be contaminated by Factory rules.
- `factoryctl doctor --project ..\.. --json` reports current root `NOT_READY` because `.codex-factory/config.json` is missing, so “Factory group enabled current Factory runtime” cannot be asserted for the root.
- The benchmark protocol documents require user confirmation before implementation of normal benchmark app tasks; the current user asked for benchmark reporting without stopping for design confirmation.
- Current runtime did not expose reliable per-run token usage.
- Existing dirty/untracked workspace state prevents claiming identical initial conditions without dedicated reset/worktree setup.

### A/B task result table

| Task | Vanilla final pass rate | Factory final pass rate | Vanilla false completion | Factory false completion | Factory time overhead | Status |
|---|---:|---:|---:|---:|---:|---|
| Strict isolated A/B suite | N/A | N/A | N/A | N/A | N/A | Not executed, conditions above not satisfied |

Historical reports found in `outputs/` mention prior A/B-like numbers such as Vanilla 85.5 vs v0.5 80.0, RUN-D 99 vs RUN-E 95, and AB-0 Factory 87 vs Vanilla 50. Those are historical artifacts only and are not current-run claims.

## Summary metrics

| Metric | Current value |
|---|---:|
| CLI official tests | 88/88 PASS |
| CLI targeted E/V/control-plane tests | 74/74 PASS |
| Runtime regression checks | 18/18, 17/17, 32/32, 34/34, and knowledge doctor PASS |
| Classified failure-injection/verification gates | 61/61 PASS, 100% |
| Memory body injection | 57,156 bytes available body -> 6,011 bytes selected excerpts |
| Memory body injection reduction | 89.48% |
| Root typecheck | FAIL |
| Root Vitest suite files | 19/44 files passed, 25/44 files failed |
| Root Vitest test cases | 439 passed, 37 skipped; failures are suite/import/environment level |
| CLI package dry-run pack | PASS, 144.9 kB package, 75 files |
| Vanilla final pass rate | N/A |
| Factory final pass rate | N/A |
| Vanilla false-completion rate | N/A |
| Factory false-completion rate | N/A |
| Factory vs Vanilla time overhead | N/A |

## Failures and negative results

- Root `npm run typecheck` fails with `TS18003` because the root `tsconfig` includes `index.html` and has no matching inputs.
- Root `npx vitest run` fails at suite level: 25 failed files, 19 passed files. Failure causes include missing test dependencies, Vitest trying to run Node `tsx --test` files, missing local modules, and port conflict on `0.0.0.0:3300`.
- `codex doctor` exits 1 with warnings/failure: websocket timeout, `TERM=dumb`, missing rollout files, and overall `14 ok · 1 idle · 4 notes · 2 warn · 1 fail`.
- Built Factory CLI doctor reports current root `NOT_READY`; `.codex-factory/config.json` is missing.
- The first memory benchmark attempt failed due an incorrect relative import path; the second attempt was interrupted; the final explicit-artifact-dir run passed.
- One successful memory attempt wrote an accidental nested artifact directory under `packages\factory-cli\outputs\...` because the script used the package cwd. A later recursive cleanup command was rejected by local policy, so the accidental artifact was left in place and disclosed here.
- `npm --prefix packages\factory-cli pack --dry-run` unexpectedly packed the root package. Running `npm pack --dry-run` from `packages\factory-cli` produced the correct CLI package result.
- Early exploratory `Get-ChildItem | Format-Table` logs are evidence artifacts but are not ideal machine-readable data; later structured probes were added.

## Limitations

- No strict current Vanilla-vs-Factory A/B result was produced; all A/B rates are N/A.
- Memory benchmark is synthetic and byte-based. It does not prove real model token savings.
- Passing control-plane tests does not prove end-to-end generated app quality.
- Root repository health is mixed; CLI package health is stronger than root full-suite health.
- Historical DOCX/report numbers are useful for study context but are not counted as current-run measurements.
- Workspace was dirty before this benchmark, so this is a “current workspace” measurement, not a clean-room release validation.

## Reproducibility steps

From `<repo>` on Windows PowerShell:

1. Record environment:
   ```powershell
   git status --short --branch
   git rev-parse HEAD
   node -v
   npm -v
   codex --version
   ```
2. Run CLI package checks:
   ```powershell
   npm --prefix packages\factory-cli run typecheck
   npm --prefix packages\factory-cli run build
   npm --prefix packages\factory-cli run test
   Push-Location packages\factory-cli; npm pack --dry-run; Pop-Location
   ```
3. Run root checks:
   ```powershell
   npm run typecheck
   npm run build
   npx vitest run
   npm test --if-present
   ```
4. Run targeted current E/V tests:
   ```powershell
   Push-Location packages\factory-cli
   npx tsx --test tests\control-plane.test.ts tests\context-admission.test.ts tests\memory-orchestration.test.ts tests\knowledge.test.ts tests\search.test.ts
   Pop-Location
   ```
5. Run runtime regressions:
   ```powershell
   powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File runtime\agent-execution-runtime-regression-tests.ps1
   powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File runtime\search-doctrine-regression-tests.ps1 -OutputFile outputs\CODEX_FACTORY_RESUME_BENCHMARK_CURRENT_ARTIFACTS\search-doctrine-regression-result.json
   powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File runtime\tests\legacy-memory-gates-regression.ps1
   powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File runtime\tests\legacy-research-evidence-regression.ps1
   powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File runtime\tests\legacy-knowledge-doctor-regression.ps1
   ```
6. Run current memory benchmark:
   ```powershell
   $env:BENCH_ARTIFACT_DIR="<repo>\outputs\CODEX_FACTORY_RESUME_BENCHMARK_CURRENT_ARTIFACTS"
   Push-Location packages\factory-cli
   npx tsx ..\..\outputs\CODEX_FACTORY_RESUME_BENCHMARK_CURRENT_ARTIFACTS\memory-context-benchmark.ts
   Pop-Location
   Remove-Item Env:\BENCH_ARTIFACT_DIR
   ```
7. Review raw logs under:
   ```text
   <repo>\outputs\CODEX_FACTORY_RESUME_BENCHMARK_CURRENT_ARTIFACTS
   ```

## Resume-safe claims

### Claim 1: CLI package regression suite is green

- Metrics/result: 88 tests, 6 suites, 88 pass, 0 fail.
- Sample: `packages\factory-cli` official test script.
- Baseline: Current commit `8c134b4af72ab0323d227d8fff9f9f89fbe8c7d6`; no Vanilla baseline needed for this claim.
- Method: `npm --prefix packages\factory-cli run test`.
- Evidence: `34_factory_cli_test_full.log`.
- YES/NO: YES.
- Recommended wording: “Validated the Factory CLI package with 88/88 passing regression tests on the current commit.”
- What not to claim: Do not say the entire monorepo test suite is green.

### Claim 2: Current E/V and control-plane gates pass targeted tests

- Metrics/result: 74 targeted tests, 5 suites, 74 pass, 0 fail.
- Sample: `control-plane`, `context-admission`, `memory-orchestration`, `knowledge`, and `search` test files.
- Baseline: Current Factory implementation only; not a Vanilla comparison.
- Method: `npx tsx --test` over the five targeted test files.
- Evidence: `41_factory_cli_target_evidence_tests.log`.
- YES/NO: YES.
- Recommended wording: “Verified core evidence, verification, context-admission, memory, knowledge, and search control-plane behavior with 74/74 targeted tests passing.”
- What not to claim: Do not claim this proves generated apps pass user acceptance tests.

### Claim 3: Failure-injection/verification gates reject current negative controls

- Metrics/result: 61/61 classified negative-control gates passed, 100%.
- Sample: spoofed context admission, ledger tamper, unverified handoff, path traversal, source drift, search evidence tamper, legacy artifact drift.
- Baseline: Expected fail-closed behavior defined by current tests; not a Vanilla product-quality baseline.
- Method: Classified negative assertions from current targeted CLI and runtime regression logs.
- Evidence: `41_factory_cli_target_evidence_tests.log`, `49_runtime_agent_execution_regression.log`, `50_runtime_search_doctrine_regression.log`, `51_runtime_legacy_memory_gates_regression.log`, `52_runtime_legacy_research_evidence_regression.log`, `53_runtime_legacy_knowledge_doctor_regression.log`.
- YES/NO: YES.
- Recommended wording: “Hardened Factory control-plane behavior with 61/61 current failure-injection and verification-gate scenarios passing.”
- What not to claim: Do not claim 100% security coverage.

### Claim 4: Source-bound memory packet selection reduces injected body bytes

- Metrics/result: 57,156 bytes available knowledge body -> 6,011 bytes selected excerpt body; 89.48% reduction by formula `1 - 6011 / 57156`.
- Sample: synthetic 24-entry knowledge corpus with 5 selected entries.
- Baseline: Injecting all knowledge body text directly.
- Method: Create source-bound knowledge entries, plan assignment context, write a context packet, measure body/excerpt byte counts.
- Evidence: `48_memory_context_benchmark_root_artifact.log`, `memory-context-benchmark-result.json`.
- YES/NO: YES, with byte-based wording.
- Recommended wording: “In a synthetic current benchmark, context packet selection reduced direct knowledge-body injection from 57,156 bytes to 6,011 bytes, an 89.48% reduction.”
- What not to claim: Do not call this a token reduction or production cost reduction without tokenizer and production traces.

### Claim 5: Runtime regression scripts pass

- Metrics/result: 18/18 agent execution assertions; 17/17 search doctrine cases; 32/32 legacy memory gates; 34/34 legacy research evidence checks; legacy knowledge doctor PASS.
- Sample: runtime PowerShell regression scripts under `runtime\`.
- Baseline: Current runtime expected behavior.
- Method: Execute the five runtime regression scripts.
- Evidence: `49_runtime_agent_execution_regression.log` through `53_runtime_legacy_knowledge_doctor_regression.log`.
- YES/NO: YES.
- Recommended wording: “Ran current runtime regression checks covering agent execution, search doctrine, legacy memory gates, research evidence, and knowledge doctor paths with all targeted checks passing.”
- What not to claim: Do not merge this with root Vitest health; root Vitest still fails.

### Claim 6: Factory beats Vanilla on final pass rate

- Metrics/result: N/A.
- Sample: Strict isolated A/B suite was not executed.
- Baseline: Missing verified Vanilla baseline for this current run.
- Method: Not run because isolation, Factory contamination, current root `NOT_READY`, user-confirmation protocol, token telemetry, and dirty-workspace constraints were not satisfied.
- Evidence: `55_historical_ab_reports_key_excerpts.log`, `56_historical_ab_score_lines.log`, `70_factoryctl_doctor_current_project.log`; these justify N/A, not a positive claim.
- YES/NO: NO.
- Recommended wording: “Historical A/B artifacts exist, but this current benchmark did not produce a strict Vanilla-vs-Factory pass-rate comparison.”
- What not to claim: Do not write any current Vanilla pass-rate advantage.

### Claim 7: Factory reduces false completion rate versus Vanilla

- Metrics/result: N/A.
- Sample: No strict current paired Vanilla/Factory output set.
- Baseline: Missing.
- Method: Not run.
- Evidence: Same A/B feasibility evidence as Claim 6.
- YES/NO: NO.
- Recommended wording: “Current run did not measure false-completion deltas against Vanilla.”
- What not to claim: Do not cite false-completion percentages from this report.

### Claim 8: Factory time overhead versus Vanilla is below a specific percentage

- Metrics/result: N/A.
- Sample: No paired wall-clock A/B tasks.
- Baseline: Missing.
- Method: Not run.
- Evidence: Command durations exist for local checks only, not paired product-generation A/B tasks.
- YES/NO: NO.
- Recommended wording: “Current run did not measure Factory-vs-Vanilla time overhead.”
- What not to claim: Do not claim “<2x overhead”, “+X% overhead”, or any time delta from this current run.

### Claim 9: Entire repository is currently healthy

- Metrics/result: Root typecheck FAIL; root Vitest FAIL with 25/44 failed files.
- Sample: Root-level checks.
- Baseline: Current root.
- Method: `npm run typecheck`, `npx vitest run`.
- Evidence: `30_root_typecheck.log`, `39_root_vitest_run.log`.
- YES/NO: NO.
- Recommended wording: “CLI package and targeted runtime checks pass, while root-level typecheck/Vitest currently fail for documented configuration/dependency/environment reasons.”
- What not to claim: Do not say “all tests pass.”
