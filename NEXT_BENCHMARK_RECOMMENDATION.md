# Next Benchmark Recommendation

> 分析当前状态后，对下一轮应执行的 benchmark 的建议。

---

## 当前状态

### 已 Runtime Validated 的 Starter（3/5）

| Starter | 项目类型 | 验证项目 |
|---|---|---|
| `vite-react-content-site` | content-site | tutor-recruit-landing |
| `next-fullstack-admin` | fullstack-admin | course-signup-demo |
| `next-saas-ai-tool` | saas-tool / ai-tool | ai-copy-demo |

### 仅 Dry-Run 的 Starter（2/5）

| Starter | 项目类型 |
|---|---|
| `node-api-postgres` | api-service / backend-service |
| `vite-threejs-interactive` | threejs-interactive |

---

## Benchmark 执行顺序建议

### 不要从 Benchmark 1 开始

Benchmark 1 (Content Site) 和 Benchmark 2 (Fullstack Admin) 的 starter 已经通过假项目和真实小项目验证。应优先覆盖未验证的 starter。

### 不要从 Benchmark 3 开始

Benchmark 3 (SaaS AI Tool) 的 starter 已经通过 ai-copy-demo runtime validated。

### 推荐第一轮：Benchmark 4 — 小程序签到后端 API

**原因**:
- `node-api-postgres` 至今只有 dry-run，没有 runtime validation
- 可以测试纯 API 项目是否不会被误判为"需要做后台页面"
- 可以测试权限占位、事务注释、幂等 key、统一 API 返回格式
- API service 是常见但容易被过度设计的项目类型

**Benchmark 4 定义**:
> 帮我做一个小程序签到功能的后端 API，用户签到获得积分，连续签到有额外奖励，管理员可以看签到统计。

**测试点**:
- 项目类型判断：是否能识别这是纯 API，不需要前端
- 权限：管理员接口是否有权限占位
- 事务：扣减/发放是否在 mock 中注明需要事务
- 幂等：是否有防重复签到逻辑
- 架构：是否不被误判为 fullstack-admin

### 推荐第二轮：Benchmark 5 — 可点击虚拟展厅

**原因**:
- `vite-threejs-interactive` 至今只有 dry-run
- 可以测试 Three.js 的 UI 与 3D 场景分离、对象注册表、Raycaster
- Three.js 项目最容易出现的错误：用 Three.js 做 UI

### 推荐第三轮：Benchmark 6 — 医院理疗核销系统原型

**原因**:
- L 级项目压力测试
- 测试审计意识、安全风险识别、原型 vs 正式系统边界判断
- 不是做正式系统，而是看 Codex 能否在复杂场景下保持正确判断

---

## 不建议同时跑多个 benchmark

每次只跑 1 个。每个 benchmark 的结果可能引发工厂级改进（修复 starter / 脚本 / skill / prompt），改进后才能继续下一个。

---

## 当前建议

**下一轮执行 Benchmark 4：API Service Benchmark (小程序签到后端 API)**

不要执行 Benchmark 1（content-site 已覆盖）。