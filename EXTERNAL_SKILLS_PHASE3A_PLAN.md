# External Skills Phase 3A — 安全筛选与接入计划

> 日期：2026-06-15
> 阶段：Phase 3A
> 状态：调研完成，待人工确认后安装

---

## 1. 为什么要接入外部 Skill

Codex_App_Factory 自建的 skills 和 expertise skills 已经覆盖了项目类型判断、架构匹配、用户路径、API设计、数据库一致性、权限边界、四态和集成失败模式。但它们本质上都是**规则/清单类** skill——告诉 Codex"应该检查什么"。

外部 skill 可以补**技术专项防错能力**：

| 短板 | 自建能力 | 外部 skill 可补充 |
|------|---------|------------------|
| 真实页面点击/表单/跳转验证 | 只有 smoke test 清单 | Playwright 自动化测试（实际执行） |
| 数据库索引/查询优化/并发 | 有事务安全规则 | PostgreSQL 专项最佳实践 |
| 全栈工程结构/认证/错误处理 | 有 API contract 规则 | 全栈开发专项模式 |
| Next.js 特定最佳实践 | 有架构匹配规则 | Next.js 专项（SSR/ISR/路由） |
| 安全默认值/静态分析 | 有权限/密钥规则 | 安全专项检测 |
| UI 设计质量 | 有四态/防AI味规则 | UI 设计模式 |

## 2. 为什么不能大量安装 Skill

1. **上下文冲突**：多个 skill 可能对同一场景给出不同建议，导致 Codex 行为不一致
2. **触发不准**：skill 越多，description 匹配越容易误触发
3. **过度设计**：安装了"万能" skill 后，Codex 可能对简单项目过度工程化
4. **scripts 风险**：部分 skill 包含可执行脚本，未知来源有安全风险
5. **维护成本**：skill 更新可能引入不兼容变更

**原则：少而精，每个 skill 解决一类明确问题，不与已有 skill 重叠。**

## 3. 第一批候选 Skill 对比表

| 候选 | curated 列表状态 | 来源可信度 | 与自建重叠度 | 建议 |
|------|-----------------|-----------|-------------|------|
| webapp-testing | ❌ 不存在 / ✅ 有 `playwright` 替代 | 高（openai/skills） | 低 | ✅ 必选（用 playwright） |
| fullstack-dev | ❌ 不存在于 curated | 未知 | 中 | ⚠️ 条件选择 |
| postgres-best-practices | ❌ 不存在于 curated | 未知 | 低-中 | ✅ 必选（如能找到） |
| frontend-design | ❌ 不存在于 curated | 未知 | 中（与 frontend-ui-system 重叠） | ⏸️ 暂不选择 |
| next-best-practices | ❌ 不存在于 curated | 未知 | 低 | ⚠️ 条件选择 |
| Trail of Bits security | ✅ 有 `security-best-practices` 替代 | 高（openai/skills） | 低-中 | ⚠️ 条件选择 |

**重要发现：** 只有 `playwright`（webapp-testing 替代）和 `security-best-practices`（Trail of Bits 替代）存在于 openai/skills curated 列表中。其他 4 个候选 skill 在 curated 列表中不存在，来源未知。

## 4. 每个候选 Skill 详细评估

---

### 4.1 playwright（= webapp-testing 替代）

**主要作用：** 用 Playwright 对 Web 应用做自动化测试——真实点击按钮、填写表单、验证页面跳转、截图对比。

**主要减少哪类 Codex 项目错误：**
- 主页面能跑但表单/弹窗/跳转坏（最核心）
- 新建成功但列表不刷新
- 删除后 UI 不同步
- 页面四态（loading/empty/error/success）缺失
- 权限变化后菜单不更新

**适合什么项目：** 所有 Web 项目（content-site、fullstack-admin、saas-tool、threejs-interactive）

**不适合什么项目：** miniapp、mobile-app（非 Web 环境）

**是否与已有 skill 重复：** ❌ 不重复。自建的 `webapp-preview-testing` skill 是"检查清单"，playwright 是"实际执行自动化测试"。一个告诉 Codex 该查什么，一个帮 Codex 查。

**是否容易和其他 skill 打架：** 低。Playwright 是测试工具，不干预设计决策。

**是否建议进入第一批：** ✅ **必选**

**建议级别：** 用户级（全局安装，所有 Web 项目受益）

**是否包含 scripts：** 可能包含 Playwright 安装/配置脚本

**如果包含 scripts，是否需要人工确认：** 是。Playwright 需要下载浏览器二进制文件，必须人工确认。

**安全风险：** 低。openai/skills 官方来源。

**推荐接入方式：** 通过 `skill-installer` 从 `openai/skills` curated 列表安装 `playwright`。

---

### 4.2 fullstack-dev

**主要作用：** 全栈开发辅助（项目结构、API、认证、错误处理、前后端集成）。

**主要减少哪类 Codex 项目错误：**
- 前后端字段不一致
- API 错误格式不统一
- 认证流程不完整
- 项目结构不合理

**适合什么项目：** fullstack-admin、saas-tool、api-service

**不适合什么项目：** content-site（纯前端）、miniapp（小程序专用）、threejs-interactive（纯3D前端）

**是否与已有 skill 重复：** ⚠️ **高度重叠。** 自建的 `backend-api-contract`、`auth-permission-boundary`、`frontend-state-and-form-logic`、`integration-failure-patterns` 已经覆盖了大部分内容。

**是否容易和其他 skill 打架：** 高。如果 fullstack-dev 建议的架构模式与 Codex_App_Factory 的 STACK_DECISION_GUIDE 冲突，会导致 Codex 在两种指令间犹豫。

**是否建议进入第一批：** ⏸️ **暂不选择。** 自建 expertise skills 已覆盖大部分内容。未来如果确认来源可信且不与现有规则冲突，可作为可选增强。

**建议级别：** 如安装，建议项目级（按需使用），不建议用户级全局。

**是否包含 scripts：** 未知

**安全风险：** 中等。来源未确认。

**推荐接入方式：** 先确认来源（GitHub 仓库是否可信），再决定。

---

### 4.3 postgres-best-practices

**主要作用：** PostgreSQL 数据库建模、索引、查询优化、并发控制、迁移管理最佳实践。

**主要减少哪类 Codex 项目错误：**
- 数据库事务/并发/竞态条件（Codex 最容易出错的领域）
- 索引缺失导致查询慢
- 唯一约束缺失导致重复数据
- 迁移脚本不规范
- 查询 N+1 问题

**适合什么项目：** 所有使用 PostgreSQL 的项目（fullstack-admin、saas-tool、api-service、miniapp后端、mobile-app后端）

**不适合什么项目：** content-site（通常无数据库）、threejs-interactive（无数据库）

**是否与已有 skill 重复：** ⚠️ **部分重叠。** 自建的 `database-consistency-and-transaction` 已经覆盖了事务、防负数、防重复、状态机、四类表区分。但不会覆盖索引优化、查询性能、迁移管理、PostgreSQL 特性（如 RLS、窗口函数等）。

**是否容易和其他 skill 打架：** 低。PostgreSQL 最佳实践与数据库一致性规则互补而非冲突。

**是否建议进入第一批：** ✅ **必选（条件：能找到可信来源）**

**问题：** 此 skill **不在** curated 列表中。需要确认：
- 是否存在于 openai/skills 的其他路径
- 是否有其他可信仓库提供（如 supabase/postgres-best-practices）

**建议级别：** 用户级（全局安装）

**是否包含 scripts：** 可能包含迁移脚本模板

**安全风险：** 低（如果来源可信）

**推荐接入方式：** 如果 openai/skills 中有 postgres 相关 skill，优先使用；否则搜索可信来源如 supabase 官方。

---

### 4.4 frontend-design

**主要作用：** 前端 UI 设计辅助——配色、布局、组件设计、视觉质量。

**主要减少哪类 Codex 项目错误：**
- AI 味界面（紫色渐变、emoji满天飞、大圆角）
- 配色不协调
- 信息层级混乱
- 移动端布局问题（但不是四态问题）

**适合什么项目：** content-site、saas-tool 落地页

**不适合什么项目：** fullstack-admin（后台优先信息密度）、api-service（无前端）

**是否与已有 skill 重复：** ⚠️ **高度重叠。** 自建的 `frontend-ui-system` 已经覆盖了配色、排版、组件规范、四态、防 AI 味。

**是否容易和其他 skill 打架：** 中。如果 frontend-design 的风格倾向与 `frontend-ui-system` 的"防 AI 味"规则冲突。

**是否建议进入第一批：** ⏸️ **暂不选择。** 第一优先级是防错，UI 质量提升是第二阶段的事。且与自建 skill 重叠。

**建议级别：** 如安装，建议项目级（只在 UI polish 阶段使用）

**是否包含 scripts：** 未知

**安全风险：** 低-中

**推荐接入方式：** 先确认来源，且只在 UI polish 阶段按项目启用。

---

### 4.5 next-best-practices

**主要作用：** Next.js 专项最佳实践——App Router、SSR/ISR、Server Components、路由、缓存、图片优化。

**主要减少哪类 Codex 项目错误：**
- 错误使用 'use client'（不该用客户端组件的用了）
- SSR/ISR 配置错误
- 路由设计不合理
- 图片不优化导致 LCP 差
- Server Actions 安全风险

**适合什么项目：** 所有使用 Next.js 的项目（fullstack-admin、saas-tool、部分 content-site）

**不适合什么项目：** api-service（纯后端）、miniapp、mobile-app、Vite 项目

**是否与已有 skill 重复：** ❌ 不重复。自建 skills 不覆盖 Next.js 框架细节。

**是否容易和其他 skill 打架：** 低。Next.js 最佳实践是框架级指导，不干预架构决策。

**是否建议进入第一批：** ⚠️ **条件选择。** 取决于两个条件：
1. Codex_App_Factory 默认技术栈确实用了 Next.js（大部分类型确实用）
2. 来源可信

**问题：** 此 skill **不在** curated 列表中。

**建议级别：** 用户级（全局安装，因为很多项目类型默认用 Next.js）

**是否包含 scripts：** 可能包含 Next.js 配置脚本

**安全风险：** 低-中

**推荐接入方式：** 如果能在 openai/skills 或其他可信来源找到，可安装。

---

### 4.6 Trail of Bits Security Skills (= security-best-practices 替代)

**主要作用：** 安全检测——不安全默认值、静态分析、安全边界检测。

**主要减少哪类 Codex 项目错误：**
- 密码明文存储
- API 密钥暴露在代码中
- 无鉴权的敏感 API
- SQL 注入风险
- XSS 风险
- 不安全的依赖版本

**适合什么项目：** 所有涉及用户数据、登录、支付、API 的项目（fullstack-admin、saas-tool、api-service、miniapp、mobile-app）

**不适合什么项目：** content-site（纯展示，无用户系统）

**是否与已有 skill 重复：** ⚠️ **部分重叠。** 自建的 `auth-permission-boundary` 已覆盖密钥不入前端、服务端校验、密码哈希、限速。但不覆盖静态分析、依赖扫描、不安全默认值检测。

**是否容易和其他 skill 打架：** 低-中。安全规则通常不会打架，但可能让 Codex 对简单项目过度安全化。

**是否建议进入第一批：** ⚠️ **条件选择。** 用户倾向正确——安全重要但更适合上线前或安全敏感项目。如果第一批已选 playwright + postgres，security 可作为第三选择或推迟到第二批。

**建议级别：** 项目级（按需使用，上线前安全检查时启用）

**是否包含 scripts：** 可能包含安全扫描脚本

**安全风险：** 低（Trail of Bits/openai 官方来源）

**推荐接入方式：** 通过 `skill-installer` 从 `openai/skills` curated 列表安装 `security-best-practices`。

---

## 5. 与现有 Project Expertise Flow 的关系

```
project-expertise-flow（总入口）
 ├── 自建 expertise skills（架构、用户路径、功能完整性...）
 │    └── 负责：项目类型判断 + 设计稿输出 + 错误模式预警
 │
 └── 外部 skills（第一批）
      ├── playwright        → 负责：真实页面/表单/跳转验证
      └── postgres-*        → 负责：数据库专项防错
```

**原则：** 外部 skill 只辅助 Project Expertise Flow，不替代它。Project Expertise Flow 永远是总入口。

## 6. 与现有 Expertise Skills 是否重复

| 外部候选 | 重叠的自建 skill | 重叠度 | 是否可共存 |
|---------|-----------------|--------|-----------|
| playwright | webapp-preview-testing | 低（清单 vs 执行） | ✅ 互补 |
| fullstack-dev | backend-api-contract, auth-permission-boundary, integration-failure-patterns | 高 | ⚠️ 可能冲突 |
| postgres-* | database-consistency-and-transaction | 中（事务规则 vs 索引/查询优化） | ✅ 互补 |
| frontend-design | frontend-ui-system | 高 | ⚠️ 可能冲突 |
| next-best-practices | 无 | 无 | ✅ 互补 |
| security-* | auth-permission-boundary | 中（权限规则 vs 静态扫描） | ✅ 互补 |

## 7. 是否建议第一批接入

| 候选 | 建议 | 理由 |
|------|------|------|
| playwright | ✅ **第一批必选** | 官方 curated，直接解决"页面能跑但坏"的核心问题 |
| postgres-best-practices | ✅ **第一批必选**（如能找到来源） | 数据库是 Codex 最容易出错的领域 |
| security-best-practices | ⚠️ **第一批可选** | 官方 curated，但更适合上线前 |
| next-best-practices | ⚠️ **暂不选择** | 来源未确认，且当前架构未充分验证 Next.js 主导 |
| fullstack-dev | ⏸️ **暂不选择** | 来源未确认 + 与自建 skill 高度重叠 |
| frontend-design | ⏸️ **暂不选择** | 来源未确认 + 与自建 skill 重叠 + 非防错优先 |

## 8. 建议用户级还是项目级

| Skill | 建议级别 | 理由 |
|-------|---------|------|
| playwright | **用户级** | 几乎所有 Web 项目都需要测试 |
| postgres-best-practices | **用户级** | 几乎所有数据库项目都需要 |
| security-best-practices | **项目级** | 只在安全敏感或上线前启用 |
| next-best-practices | **用户级** | 如果确认 Next.js 为主栈 |
| fullstack-dev | **项目级** | 按需使用，避免与自建规则冲突 |
| frontend-design | **项目级** | 只在 UI polish 阶段启用 |

## 9. 是否需要 Scripts

| Skill | 是否包含 scripts | 风险 | 
|-------|-----------------|------|
| playwright | 是（浏览器安装） | 需人工确认下载 |
| postgres-best-practices | 可能（迁移模板） | 低 |
| security-best-practices | 可能（扫描脚本） | 需人工确认 |
| 其他未确认来源 | 未知 | ⚠️ 高风险 |

## 10. 安装前人工确认清单

安装任何外部 skill 前，必须确认：

- [ ] Skill 来源可信（openai/skills 官方 或 知名团队 GitHub）
- [ ] 已读取 SKILL.md 全文，理解其作用
- [ ] 已与自建 skills 对比，确认不冲突
- [ ] 已确认 skill 不包含未知可执行脚本
- [ ] 如果包含 scripts，已审查脚本内容
- [ ] 安装后不超过用户级 4 个外部 skill
- [ ] 不是描述夸张的"全能大师"类 skill

## 11. 安装后验证方式

1. 在新项目触发 Project Expertise Flow
2. 检查 Codex 是否正确引用了外部 skill（不覆盖自建规则）
3. 做一次小型预分析，验证没有规则冲突
4. 如果发现冲突，卸载冲突 skill

## 12. 最终推荐：第一批最多 3 个 Skill

| 优先级 | Skill | 来源 | 建议级别 |
|--------|-------|------|---------|
| 1 | `playwright` | openai/skills curated ✅ | 用户级 |
| 2 | `postgres-best-practices`（或等效） | ⚠️ 需确认来源 | 用户级 |
| 3 | `security-best-practices` | openai/skills curated ✅ | 项目级 |

**如果 postgres-best-practices 来源无法确认：**
- 替代方案 1：搜索 `supabase-postgres-best-practices`（Supabase 官方）
- 替代方案 2：用自建 `database-consistency-and-transaction` 已足够覆盖核心防错
- 暂不安装第三方的未知来源 postgres skill

**关于与用户倾向的差异说明：**
用户倾向第一批选 `webapp-testing` + `postgres` + `fullstack-dev`。经过调研，我建议调整为：
- ✅ `playwright`（webapp-testing 替代）— 同意
- ✅ `postgres-best-practices`（需确认来源）— 同意  
- ⚠️ `fullstack-dev` → 改为 `security-best-practices`

**原因：** 
1. `fullstack-dev` 不在 curated 列表中，来源不明
2. `fullstack-dev` 与自建 backend-api-contract、auth-permission-boundary、integration-failure-patterns 高度重叠，可能冲突
3. `security-best-practices` 在 curated 列表中，来源可信，补安全短板
