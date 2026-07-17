# External Skills Phase 3A — 最终决策

> 日期：2026-06-15
> 阶段：Phase 3A 完成
> 状态：第一批已接入，等待 Phase 3B

---

## 1. 为什么第一批不装太多 Skill

- **上下文冲突**：多个 skill 可能对同一场景给出不同建议
- **触发不准**：skill 越多，description 匹配越容易误触发
- **过度设计**：外部 skill 可能让 Codex 对简单项目过度工程化
- **维护成本**：每个外部 skill 的更新都可能引入不兼容变更

**原则：少而精。每个保留的 skill 必须解决一类明确的、自建 skills 无法覆盖的防错问题。**

## 2. 为什么暂不接入 security-best-practices

- 安全检测更适合**上线前**、**权限敏感**、**支付/密钥**专项，不是通用项目生成器的默认能力
- 如果放进第一批，可能让 Codex 对简单展示网站也做安全扫描，过度复杂化
- 作为**项目级** skill，在安全敏感项目中按需启用

## 3. 为什么暂不接入 fullstack-dev

- 与自建 `backend-api-contract`、`auth-permission-boundary`、`integration-failure-patterns` **高度重叠**
- 不在 openai/skills curated 列表中，来源未确认
- 可能与 STACK_DECISION_GUIDE 中的架构选择冲突

## 4. 为什么暂不接入 frontend-design

- 与自建 `frontend-ui-system` 高度重叠（配色、排版、防 AI 味）
- 属于 **UI polish 阶段**能力，不是第一优先级防错能力
- 如果 UI 不好看，用户会主动要求改进；但数据库错了，可能没发现
- 作为项目级 skill，在 UI polish 阶段按需启用

## 5. 为什么暂不接入 next-best-practices

- 只有在我们确定某个**具体项目**使用 Next.js 并遇到框架级问题时才启用
- Codex_App_Factory 的 STACK_DECISION_GUIDE 已覆盖基本栈选择
- 作为项目级 skill，在 Next.js 项目中按需启用

## 6. 第一批最终保留的 2 个 Skill

| Skill | 来源 | 级别 | 解决什么问题 |
|-------|------|------|------------|
| `playwright-interactive` | openai/skills curated ✅ | 用户级 | Web 页面真实点击、表单提交、跳转验证、四态检查、截图对比 |
| `postgres-best-practices-wrapper` / `supabase-postgres-best-practices` | Supabase 官方 ✅ | 用户级 | PostgreSQL 索引、查询优化、RLS、连接管理、并发、schema 设计 |

### playwright-interactive 解决什么问题
- "主页面能跑，但表单提交后没反应"
- "新建成功但列表不刷新"
- "弹窗关闭后状态残留"
- "移动端页面溢出"
- "加载/空/错误/成功四态缺失"
- 通过**实际浏览器操作**验证这些场景，而不是只靠清单检查

### postgres-best-practices-wrapper 解决什么问题
- "查询越来越慢"（缺少索引）
- "数据重复插入了"（缺少唯一约束）
- "并发操作时数据错乱"（事务隔离不足）
- "连接池耗尽"（连接管理不当）
- 补充自建 `database-consistency-and-transaction` 不覆盖的**查询性能和 schema 设计**领域

## 7. 如何避免 Skill 打架

### 分工明确
```
自建 expertise skills          →  事务安全、防负数、防重复、状态机
supabase-postgres-best-practices →  索引、查询优化、RLS、连接管理
```

### 触发隔离
- `postgres-best-practices-wrapper` 只在 PostgreSQL 项目触发
- `playwright-interactive` 只在 Web 项目验证阶段触发
- 两者不重叠、不互相触发

### 优先级
- Codex_App_Factory 架构判断 > 外部 skill 建议
- 用户确认的设计稿 > 任何 skill 的自动推荐

## 8. 后续何时再考虑其他 Skill

| Skill | 时机 |
|-------|------|
| `security-best-practices` | 项目涉及支付、用户隐私数据、API 密钥、上线前安全检查 |
| `frontend-design` | UI polish 阶段，用户对视觉不满意 |
| `next-best-practices` | 具体项目确定使用 Next.js 且遇到 SSR/ISR/路由等框架级问题 |
| `fullstack-dev` | 如果自建 expertise skills 被证明不足以覆盖全栈问题，且找到可信来源 |

## 9. 安装或接入状态

| Skill | 状态 | 位置 |
|-------|------|------|
| `playwright-interactive` | ✅ 已安装（SKILL.md + assets） | `%USERPROFILE%\.agents\skills\playwright-interactive\` |
| `supabase-postgres-best-practices` | ✅ 已安装（SKILL.md + 35 reference 文件） | `%USERPROFILE%\.agents\skills\supabase-postgres-best-practices\` |
| `postgres-best-practices-wrapper` | ✅ 已创建（本地 wrapper） | `%USERPROFILE%\.agents\skills\postgres-best-practices-wrapper\` |

### playwright-interactive 使用前注意事项
- ⚠️ 首次使用需要 `npm install playwright` + `npx playwright install chromium`（下载浏览器约 400MB）
- ⚠️ 需要 `js_repl`（已启用）
- ⚠️ 不会自动下载浏览器，需要用户确认后执行

### supabase-postgres-best-practices
- ✅ 纯知识/规则 skill，无 scripts，无密钥，无 CLI 依赖
- ✅ Supabase 官方维护，MIT license
- ✅ 35 个 reference 文件覆盖 8 个 categories
