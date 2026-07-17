# Codex App Factory

> 一个通用项目生成能力包，让 Codex 从"每次从空白写代码"变成"有章法的应用生成器"。

---

## 这是什么

Codex_App_Factory 是一套**不特定于某个业务项目**的通用规则集和模板库。它包含：

- **规则文件**：Codex 新建项目时必须遵守的铁律
- **Starter 模板**：7 种常见应用类型的启动模板说明
- **Blueprint 蓝图**：7 种应用类型的完整设计蓝图
- **Skill 技能包**：9 个通用技能，让 Codex 在各个领域有专业判断力
- **Prompt 提示词**：6 个可复制的提示词模板，覆盖项目全生命周期

## 为什么它能提升 Codex 做项目的能力

Codex 默认会从空白自由发挥，容易：
- 选择不合适的技术栈
- 跳过设计阶段直接写代码
- 过度设计（小项目加微服务）
- 漏掉关键页面状态（loading/error/empty）
- 权限只做前端隐藏按钮
- 数据库缺审计字段、事务处理

Codex_App_Factory 通过**固定规则 + 可复用模板**解决这些问题。

## 目录结构

```
C:\Codex_App_Factory\
├── GLOBAL_CODEX_RULES.md      # 全局铁律
├── APP_TYPE_ROUTER.md         # 应用类型路由
├── STACK_DECISION_GUIDE.md    # 技术栈决策指南
├── README.md                  # 本文件
├── EXTERNAL_SKILLS_RESEARCH.md # 现成 skill 调研清单
├── starters/                  # 7 个 starter 模板
├── blueprints/                # 7 个蓝图文件
├── skills/                    # 9 个通用技能
└── prompts/                   # 6 个提示词模板
```

## 每次新项目怎么用

### 标准流程（推荐）

**第一步：发 prompt**
复制 `prompts/00-intake-project.md` 给 Codex，附上你的需求。

**第二步：等 Codex 输出设计稿**
Codex 会自动：
1. 判断应用类型（走 APP_TYPE_ROUTER）
2. 选择最佳 starter、blueprint、skills
3. 输出完整设计稿（页面结构、数据结构、API 结构、权限边界、最小闭环）

**第三步：确认设计稿**
检查 Codex 的输出，确认方向正确。

**第四步：实现第一阶段**
Codex 根据确认的设计稿，只做最小闭环。

### 快捷方式
如果你忘记发 prompt，Codex 会**主动提醒**你走 Codex_App_Factory 流程。

## 不建议怎么用

- ❌ 不要跳过设计阶段直接让 Codex 写代码
- ❌ 不要在 Codex 输出设计稿前就开始实现
- ❌ 不要在第一版就追求大而全
- ❌ 不要忽略 Codex 主动发出的提醒

## starter、blueprint、skill、prompt 的区别

| 类型 | 作用 | 何时生效 |
|------|------|---------|
| **starter** | 描述某类项目如何启动（技术栈、目录结构、核心模块） | Codex 选型时参考 |
| **blueprint** | 描述某类项目的完整设计蓝图（页面、数据、流程、权限） | Codex 出设计稿时参考 |
| **skill** | 某领域的专业判断能力（如数据库设计、权限安全） | Codex 在各阶段自动应用 |
| **prompt** | 用户发给 Codex 的提示词模板 | 用户手动复制使用 |

## 用户应该怎么配合

1. **说清楚需求**：至少要说明目标用户是谁、核心功能是什么
2. **等设计稿**：不要催 Codex 直接写代码
3. **确认方向**：检查设计稿是否符合预期
4. **最小闭环优先**：第一版只做最核心的功能
5. **逐步扩展**：确认第一版可用后再加功能

## 新项目完整流程（Phase 2 补充）

```
读取 Codex_App_Factory → 使用 project-expertise-flow → 输出专业预分析 → 用户确认 → 实现第一阶段
```

- **Codex_App_Factory 负责**：starter / blueprint / prompt 模板
- **用户级 skills 负责**：长期专业能力（architecture-pattern-matcher, product-user-journey 等）
- **project-expertise-flow 负责**：新项目总入口，串联所有能力

如果用户忘记说流程，Codex 会主动提醒。

---

## Phase 3A：外部 Skill 接入说明

### 第一批外部 Skill 的目的

Codex_App_Factory 自建 skills 负责**项目类型判断、架构匹配、用户路径、功能完整性和易错点地图**。外部 skills 负责**技术专项防错能力**——真实页面测试、数据库专项、安全检测。

### Skill 分工

| 谁负责 | 范围 | 示例 |
|--------|------|------|
| **Codex_App_Factory 自建 skills** | 项目类型、架构匹配、设计稿、错误模式预警 | product-architecture, integration-failure-patterns |
| **用户级 expertise skills** | 通用专业能力：API、数据库、权限、状态、表单 | database-consistency-and-transaction, auth-permission-boundary |
| **外部 skills（精选）** | 技术专项：测试执行、数据库优化、安全扫描 | playwright, postgres-best-practices, security-best-practices |

### Skill 不是越多越好

- 默认新项目最多选择 **2 个** 外部 skill
- 外部 skill 不替代 runnable starter
- 外部 skill 不替代用户确认设计稿
- 不要安装来源不明或描述夸张的 skill

### 第一批推荐

| 优先级 | Skill | 来源 | 级别 |
|--------|-------|------|------|
| 1 | `playwright` | openai/skills curated | 用户级 |
| 2 | `postgres-best-practices` | 需确认来源 | 用户级 |
| 3 | `security-best-practices` | openai/skills curated | 项目级 |

详见 `EXTERNAL_SKILLS_PHASE3A_PLAN.md`。

---

## Phase 3B-1：Runnable Starters

### 已创建

`runnable-starters/vite-react-content-site` — 第一个最小可运行 starter。

用于验证 runnable starter 机制：
- 可复制到新项目直接使用
- 单页内容站骨架（Vite + React + TypeScript）
- 内容与组件分离（修改 `siteContent.ts` 即可替换全部文案）
- 响应式 + 锚点导航 + CTA
- 包含 loading/empty/error 示例组件
- 不含数据库、登录、支付、路由库、UI 框架

### 下一步

- `runnable-starters/next-fullstack-admin` — 管理后台 starter
- `runnable-starters/next-saas-ai-tool` — SaaS/AI 工具 starter
- `runnable-starters/node-api-postgres` — 后端 API starter
- `runnable-starters/vite-threejs-interactive` — Three.js 交互原型 starter

### Phase 3B-2

`runnable-starters/next-fullstack-admin` — 第一个管理后台可运行 starter。

用于 fullstack-admin 类型项目：
- Next.js App Router + TypeScript
- 6 个页面（登录 / 仪表盘 / 记录列表 / 记录详情 / 用户管理占位）
- 4 组 API routes（health / auth / records CRUD）
- 10 个共享组件（AppShell / Sidebar / DataTable / StatusBadge / FormField 等）
- Mock 数据库 + 统一 API 响应格式 + 服务端校验
- 无真实依赖（无 Prisma / shadcn / 认证库）

### 下一步

- `runnable-starters/next-saas-ai-tool`
- 或先创建复制脚本（跨 starter 的 CLI 工具）

---

## Phase 3B-3：复制脚本与注册表

### 已创建

| 文件 | 用途 |
|------|------|
| `runnable-starters/STARTER_REGISTRY.md` | 所有 starter 的注册表，含匹配类型、适合/不适合项目、运行命令 |
| `runnable-starters/STARTER_QUALITY_CHECKLIST.md` | 新 starter 的质量检查清单（33 项） |
| `scripts/create-project-from-starter.ps1` | Windows 复制脚本（PowerShell） |
| `scripts/create-project-from-starter.sh` | macOS/Linux 复制脚本（Bash） |
| `scripts/README.md` | 脚本使用说明 |
| `prompts/09-test-copy-starter-dry-run.md` | Dry-run 复制测试提示词 |

### 当前可复制 Starter

| Starter | 类型 | 状态 |
|---------|------|------|
| `vite-react-content-site` | content-site | ✅ |
| `next-fullstack-admin` | fullstack-admin | ✅ |

### 复制脚本功能

- 根据 starter 名称复制项目
- 自动替换 PROJECT_NAME
- 自动排除 node_modules / 构建产物
- 不自动安装依赖 / 不 build / 不联网
- 不覆盖已有目录（除非 -Force）

### 下一步建议

1. 执行 dry-run 复制测试（`prompts/09`）
2. 验证通过后创建 `next-saas-ai-tool`

---

## Phase 3B-4.5：Architecture Scaling Ladder

### 新增能力

**`architecture-scaling-ladder` skill** — 项目体量判断与架构升级决策。

### 核心原则

- **starter 是默认起点，不是架构天花板**
- **项目必须先判断体量（S/M/L/XL），再选择 starter**
- **高级架构必须由需求触发，不由 Codex 主观炫技触发**
- **防止两种错误：**
  1. 小项目过度设计（S 级加数据库）
  2. 大项目硬套小 starter（L 级用 mock-db）

### 体量速查

| 体量 | 典型项目 | 默认 Starter |
|------|---------|-------------|
| S | 官网、落地页、展示页 | `vite-react-content-site` |
| M | 报名系统、简单后台 | `next-fullstack-admin` |
| L | 核销、AI工具、多角色系统 | starter + 真实DB/审计/事务 |
| XL | 多租户、支付、实时协作 | 拆第一阶段，按模块升级 |

### 更新文件

- `architecture-scaling-ladder/SKILL.md` — 新用户级 skill
- `project-expertise-flow/SKILL.md` — 增加 Architecture Scaling Check 步骤
- `APP_TYPE_ROUTER.md` — 每类增加体量判断
- `STACK_DECISION_GUIDE.md` — 增加升级决策树
- `STARTER_REGISTRY.md` — 每个 starter 增加升级/禁止条件
- `prompts/06` — 选择 starter 前先判体量
- `prompts/10-architecture-scaling-check.md` — 架构体量评估提示词

---

## Phase 3B-5：next-saas-ai-tool

### 已创建

`runnable-starters/next-saas-ai-tool` — 第三个可运行 starter。

用于 saas-tool / ai-tool 类型项目：AI 文案生成、模板工具、文本处理、用户额度、生成历史。

特性：
- Mock AI Provider（1-2 秒延迟返回 placeholder）
- 用户额度管理（生成失败自动恢复）
- 生成历史（按用户隔离）
- 幂等 Key 防重复提交
- 6 个页面（落地页/登录/控制台/工具/历史/账户）
- 5 组 API

### 当前可用 Starter（3 个）

| Starter | 类型 | 体量 |
|---------|------|------|
| `vite-react-content-site` | content-site | S |
| `next-fullstack-admin` | fullstack-admin | M |
| `next-saas-ai-tool` | saas-tool | M-L |

---

## Phase 3B-7：node-api-postgres

### 已创建

`runnable-starters/node-api-postgres` — 第四个可运行 starter。

用于 api-service / backend-service / miniapp-backend / app-backend 类型项目：
- Node.js + TypeScript + Fastify
- 8 个 API 端点（health / login / records CRUD / action / admin audit）
- 3 层架构（route → service → repository）
- 3 个中间件（auth / error-handler / request-logger）
- Mock DB + Prisma Schema Example + Transaction Notes
- 统一 API 响应格式 + 分页 + 服务端校验 + 幂等占位
- 无真实依赖（无 Prisma / pg driver / Redis / ORM）

### 当前可用 Starter（4 个）

| Starter | 类型 | 体量 |
|---------|------|------|
| `vite-react-content-site` | content-site | S |
| `next-fullstack-admin` | fullstack-admin | M |
| `next-saas-ai-tool` | saas-tool | M-L |
| `node-api-postgres` | api-service | M-L |

### 下一步建议

1. dry-run 复制 `node-api-postgres` 验证复制脚本
2. 或创建 `vite-threejs-interactive`（最后一个计划 starter）

---

## Phase 3B-9：vite-threejs-interactive

### 已创建

`runnable-starters/vite-threejs-interactive` — 第五个可运行 starter。

用于 threejs-interactive / 3d-web-prototype / interactive-scene 类型项目：
- Vite + TypeScript + Three.js
- 8 个场景模块（camera / renderer / lights / objects / interaction / animation / resize）
- 4 个 UI 模块（HUD / Panel / MiniMap / Toast）
- 场景对象 Registry + 简单状态管理
- Raycaster hover/click 交互 + 信息面板更新闭环
- 响应式布局（移动端 Panel 变底部抽屉）
- 3 个 low-poly placeholder（圆桌 / 线索盒 / 上锁的门）

### 当前可用 Starter（5 个，全部完成）

| Starter | 类型 | 体量 |
|---------|------|------|
| `vite-react-content-site` | content-site | S |
| `next-fullstack-admin` | fullstack-admin | M |
| `next-saas-ai-tool` | saas-tool | M-L |
| `node-api-postgres` | api-service | M-L |
| `vite-threejs-interactive` | threejs-interactive | M |

### 下一步建议

1. dry-run 复制 `vite-threejs-interactive` 验证复制脚本兼容性
2. 全链路假项目测试（端到端验证 Project Expertise Flow）

---

## Phase 3C-1R：Runtime Validation

### 已完成

对 `course-signup-demo`（fullstack-admin 类型假项目）完成了完整的运行时验证：

| 步骤 | 结果 |
|------|------|
| npm install | ✅ 28 packages |
| npm run typecheck | ✅ 通过 |
| npm run build | ✅ 11 pages |
| npm run dev | ✅ 短启动成功 |

### 修复的工厂级问题

| # | 问题 | 修复范围 |
|---|------|---------|
| 1 | SearchAndFilterBar 缺少可选 props | 组件 + 原 starter |
| 2 | package.json BOM 导致 build 失败 | 5 个 starter |
| 3 | 复制脚本写入 BOM | 脚本增加剥离 |
| 4 | 源模板同步修复 | next-fullstack-admin |

### 沉淀文件

- `RUNTIME_VALIDATION_REPORT.md` — 完整验证报告
- `STARTER_QUALITY_CHECKLIST.md` — 新增 Runtime Validation 9 项
- `scripts/README.md` — 新增 Encoding / BOM Safety 章节
- `prompts/11-runtime-validation.md` — 运行验证提示词
- `prompts/06` — 新增 Runtime Validation 步骤
- `project-expertise-flow/SKILL.md` — 新增验证建议

---

## Phase 3D：收尾总结

### 当前状态

Codex_App_Factory 已验证以下全链路闭环：

```
用户需求 → Project Expertise Flow → Architecture Scaling Ladder
         → 选择 Starter → 复制项目 → 填写 PROJECT_BRIEF
         → 最小业务改造 → npm install → typecheck → build → dev server
```

### 资产清单

| 类型 | 数量 | 状态 |
|------|------|------|
| **Runnable Starters** | 5 | ✅ 全部创建 + dry-run |
| **Runtime Validated** | 1 | ✅ course-signup-demo |
| **Expertise Skills** | 11 | ✅ |
| **External Skills** | 2 | ✅ playwright-interactive + postgres-best-practices-wrapper |
| **Prompts** | 11 | ✅ 00-10 + 11-runtime-validation |
| **Blueprints** | 7 | ✅ |
| **Factory Docs** | 4 | ✅ RULES + ROUTER + STACK + VALIDATION |

### 后续建议

1. **第二个假项目验证** — 用不同 starter 类型（如 SaaS AI Tool）做交叉验证
2. **开始真实小项目** — 用 Codex_App_Factory 做真实业务项目（必须仍走 Project Expertise Flow）
3. **首次真实项目后** — 根据经验回补 starter 和文档

---

> **Codex_App_Factory v1.0：第一版闭环已完成。**

---

## Phase 3E：Cross-Type Runtime Validation

### 第二个假项目：AI 文案生成网站

| 属性 | 值 |
|------|-----|
| **项目类型** | saas-tool / ai-tool |
| **Starter** | next-saas-ai-tool |
| **npm install** | ✅ 28 packages |
| **typecheck** | ✅ first try |
| **build** | ✅ 14 pages |
| **dev server** | ✅ short-start pass |

### 已 Runtime Validate 的 Starter

| Starter | 类型 | 状态 |
|---------|------|:--:|
| `next-fullstack-admin` | fullstack-admin | ✅ validated |
| `next-saas-ai-tool` | saas-tool | ✅ validated |
| `vite-react-content-site` | content-site | dry-run only |
| `node-api-postgres` | api-service | dry-run only |
| `vite-threejs-interactive` | threejs-interactive | dry-run only |

### 当前结论

Codex_App_Factory 第一版已证明能从一句话需求选择不同 starter 并生成可运行测试项目。
两个不同类型的跨类型验证均通过。

### 下一步建议

- 不继续扩展 starter
- 可以开始真实小项目试用
- 真实项目仍必须先走 Project Expertise Flow + Architecture Scaling Ladder + Runtime Validation

---

## Phase 4A：First Real Small Project Trial

### 第一个真实小项目：线上家教老师招募落地页

| 属性 | 值 |
|------|-----|
| **项目类型** | content-site / landing-page |
| **Starter** | vite-react-content-site |
| **体量** | S |
| **npm install** | ✅ 71 packages |
| **typecheck** | ✅ |
| **build** | ✅ 39 modules |
| **dev server** | ✅ |

### 发现并修复的工厂级问题

**BOM 污染全面：** PowerShell Set-Content 在所有文件写入 UTF-8 BOM，导致 Vite/PostCSS 解析失败。复制脚本已升级为全文件 BOM 剥离，原 starter 同步修复。

### 当前 Runtime Validated Starters（3 个）

| Starter | 类型 | 测试项目 |
|---------|------|---------|
| `next-fullstack-admin` | fullstack-admin | course-signup-demo |
| `next-saas-ai-tool` | saas-tool | ai-copy-demo |
| `vite-react-content-site` | content-site | tutor-recruit-landing |

### 当前 Dry-Run Only（2 个）

| Starter | 类型 |
|---------|------|
| `node-api-postgres` | api-service |
| `vite-threejs-interactive` | threejs-interactive |

### 结论

Codex_App_Factory 已通过 2 个假项目 + 1 个真实小项目验证，覆盖 3 种项目类型。后续真实项目仍必须走 Project Expertise Flow + Architecture Scaling Ladder + Runtime Validation。


---

## Phase 4R: 方向校正与能力评估体系建设

> 2026-06-16

家教落地页 (`tutor-recruit-landing`) 已归档为 `vite-react-content-site` 的 runtime validation case。当前主线回到 Codex 能力提升本身。

### 新建文档

| 文档 | 用途 |
|---|---|
| `CODEX_FACTORY_DIRECTION.md` | 方向校正 — 明确目标不是做业务项目，而是提升 Codex 生成能力 |
| `CODEX_CAPABILITY_SCORECARD.md` | 10 维度 × 5 级能力评分表 |
| `CODEX_BENCHMARK_SUITE.md` | 8 个 benchmark 项目，覆盖所有类型和体量 |
| `FINAL_STRESS_TEST_PLAN.md` | 3 个候选大项目 + 推荐：医院理疗核销系统原型 |
| `PHASE4R_REFOCUS_SUMMARY.md` | Phase 4R 总结 |

### 后续路线

1. 使用 benchmark suite 跑分评估当前 Codex 能力
2. 每个 benchmark 对照 CODEX_CAPABILITY_SCORECARD.md 打分
3. 发现工厂级缺陷时回流修复
4. 最后执行 FINAL_STRESS_TEST_PLAN 中的大项目压力测试
5. 不再做小页面 UI polish

---

## Phase 4S: Benchmark 执行规范与评分记录系统

> 2026-06-16

在真正跑 benchmark 之前，建立了统一的执行协议和评分记录模板，确保每次 benchmark 结果可比较、可追溯。

### 新建资产

| 文件/目录 | 用途 |
|---|---|
| `benchmark-results/` | Benchmark 结果存档目录 |
| `benchmark-results/templates/` | 评分模板和日志模板 |
| `benchmark-results/runs/` | 每次 benchmark 独立结果目录 |
| `BENCHMARK_RUN_PROTOCOL.md` | 固定执行流程 (Phase A-F)，含禁止事项 |
| `NEXT_BENCHMARK_RECOMMENDATION.md` | 首轮 benchmark 选择建议 |

### 关键规则

- Benchmark 不是用来做业务项目的，是测试 Codex 能力
- 不允许一上来写代码或复制 starter
- 必须先做 Project Expertise Flow 预分析
- 用户确认后才允许进入复制改造阶段
- 每次 benchmark 必须生成 SCORE_RECORD + RUN_LOG + FINAL_REPORT
- 发现工厂级缺陷必须回流修复

### 当前建议

**下一轮执行 Benchmark 4：API Service Benchmark (小程序签到后端 API)**

不执行 Benchmark 1 (content-site 已通过真实小项目验证)。
优先覆盖未 runtime validated 的 `node-api-postgres` starter。

---

## Phase 5A: Single-Entry Orchestration Layer

> **Date**: 2026-06-18

### Current Status

All 5 runnable starters have completed runtime validation:

| Starter | Type | Validation | Benchmark |
|---|---|---|---|
| `vite-react-content-site` | content-site | Runtime validated | Tutor-recruit-landing (Phase 4A) |
| `next-fullstack-admin` | fullstack-admin | Runtime validated | B04: course-signup-demo |
| `next-saas-ai-tool` | saas-tool | Runtime validated | B04: ai-copy-demo |
| `node-api-postgres` | api-service | Runtime validated | B04 (46/50 Pass) |
| `vite-threejs-interactive` | threejs-interactive | Runtime validated | B05 (44/50 Pass) |

### What Changed

The Factory's focus has shifted from **starter creation + benchmark testing** to **single-entry automatic orchestration**. Users no longer need to send detailed Phase A/B/C/D instructions ? they provide one natural-language requirement and Codex executes the full workflow automatically.

### New Entry Point

**`RUN_CODEX_APP_FACTORY.md`** ? the only document users need. Usage:

```
Read C:\Codex_App_Factory\RUN_CODEX_APP_FACTORY.md,
then create a project from: <natural-language requirement>
```

### New Assets

| File | Purpose |
|---|---|
| `RUN_CODEX_APP_FACTORY.md` | Single-entry orchestration master doc |
| `FACTORY_RUN_STATE.template.json` | Run state schema for resume support |
| `prompts/00-run-factory-from-natural-language.md` | Minimal user prompt template |
| `ORCHESTRATOR_SELF_CHECK.md` | Post-run verification checklist |

### Automation Pipeline

```
Natural Language Requirement
  ? Stage 0: Factory Bootstrap (read routing docs)
  ? Stage 1: Requirement Interpretation (extract goals, constraints)
  ? Stage 2: Project Classification (type, size, risk, starter)
  ? Stage 3: Auto-Stop Check (pause only on safety conflicts)
  ? Stage 4: Project Init (copy starter, fill BRIEF, create run-state)
  ? Stage 5: Minimal Business Closure (implement first loop)
  ? Stage 6: Automatic Validation (install, typecheck, build, dev)
  ? Stage 7: Defect Classification & Factory Backflow
  ? Stage 8: Final Report
```

### What NOT to Do

- Do NOT create more starters (5 is sufficient for v1)
- Do NOT run more benchmarks (B04 and B05 are closed)
- Do NOT create real business projects from this phase
- The next step is a blind-test single-entry run in a fresh Codex session

---

## Phase 5C — Evidence Trail

Every Factory run now produces an auditable evidence trail:

| Artifact | Purpose |
|----------|---------|
| `.codex-factory/run-state.json` | Current state snapshot (updated each stage) |
| `.codex-factory/run-events.jsonl` | Immutable process history (append-only event log) |

### Delivery Gate

```powershell
C:\Codex_App_Factory\scripts\validate-factory-run.ps1 -ProjectPath <path>
```

Must return PASS before the final report can claim orchestration complete.

See `ORCHESTRATOR_SELF_CHECK.md` for the full 20-point checklist.