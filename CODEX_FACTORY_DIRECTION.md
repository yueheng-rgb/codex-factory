# Codex App Factory — 方向校正

> 最后更新: 2026-06-16

## 真正目标

**提升 Codex 的项目生成能力。**

让 Codex 从"临时写代码工具"变成"能稳定完成以下闭环的项目生成工厂":

1. 项目类型判断 — 知道这是 content-site 还是 fullstack-admin
2. 架构体量判断 — 知道 S/M/L/XL，知道何时不升级
3. Starter 选择 — 选择正确的 starter，清楚为什么不选其他
4. 最小闭环实现 — 定义第一阶段最小可用路径，避免过度设计
5. 真实运行验证 — install / typecheck / build / dev 短启动
6. 问题回流修复 — 判断问题来源（生成项目 / starter 源模板 / 复制脚本 / 环境），回流修复工厂级缺陷

## 家教落地页的定位

`tutor-recruit-landing` 不是主线目标，它是 `vite-react-content-site` 的 **runtime validation case**。

它在 Codex_App_Factory 中的角色等同于:
- `course-signup-demo` (fullstack-admin 的验证案例)
- `ai-copy-demo` (saas-ai-tool 的验证案例)

后续不应继续围绕家教页打磨 UI、替换内容、准备部署。

## 当前已完成

| 资产 | 数量/状态 |
|---|---|
| Runnable Starter | 5 个 |
| Dry-Run 验证 | 5/5 通过 |
| Runtime Validated Starter | 3/5 (next-fullstack-admin, next-saas-ai-tool, vite-react-content-site) |
| 跨类型假项目验证 | 2 个 (fullstack-admin + saas-ai-tool) |
| 低风险真实页面验证 | 1 个 (content-site) |
| 复制脚本 (PS1/SH) | 已完成 |
| BOM 污染修复 | 已修复并预防 |
| STARTER_REGISTRY | 已创建 |
| STARTER_QUALITY_CHECKLIST | 已创建 |
| RUNTIME_VALIDATION_REPORT | 已创建 (3 cases) |
| PHASE3_FINAL_SUMMARY | 已创建 |

## 当前未完成

- 还没有完整的 Codex 能力评分体系
- 还没有 benchmark 项目集
- 还没有大项目压力测试
- 还没有对 Codex 能力提升做结构化对比
- 还有 2 个 starter 未 runtime validate (node-api-postgres, vite-threejs-interactive)

## 下一阶段主线

1. **能力评分体系** — CODEX_CAPABILITY_SCORECARD.md
2. **Benchmark Suite** — CODEX_BENCHMARK_SUITE.md
3. **大项目压力测试** — FINAL_STRESS_TEST_PLAN.md

重点回到 Codex 能力提升本身，而不是具体业务项目。