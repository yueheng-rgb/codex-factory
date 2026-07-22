# AGENTS.md — Codex App Factory 项目级工作纪律

> ⚠️ 本文件优先级高于 GLOBAL_CODEX_RULES.md。
> 只要用户工作区是 C:\Codex_App_Factory，本规则即为最高纪律。

---

## 🔴 第零条：Factory Bootstrap 门禁（最高优先级）

### 触发条件
当前工作目录为 `C:\Codex_App_Factory` 或其子目录时，
**任何新对话或新任务的第一个动作必须是 Factory Bootstrap**。

### Factory Bootstrap 流程
1. 读取 `APP_TYPE_ROUTER.md`，判断项目类型
2. 读取 `STACK_DECISION_GUIDE.md`，匹配推荐架构
3. 输出 **Factory Boot Summary**（项目类型 + 推荐架构 + 理由）
4. 如果是复杂应用类任务，必须跑完 Project Expertise Flow 12 步，
   **在用户确认设计之前，禁止写任何实现代码**
5. 简单任务（文档修改、姓名修改、打包修复）走 Factory Lite，
   但仍需经过 Router 判断

### 门禁规则
- ❌ "用户急着要成品" → 不是跳过 Factory 的理由
- ❌ "我已经有思路了" → 不是跳过 Factory 的理由
- ❌ "直接生成压缩包" → 不是跳过 Factory 的理由
- ❌ "先写代码" → 不是跳过 Factory 的理由
- ✅ 只有用户明确说出"跳过 Factory 分析，直接实现"才能跳过

### 哪些任务必须走完整 Expertise Flow
命中以下关键词组合时，**必须**先输出完整设计稿：
- 应用 / 系统 / 平台 / 管理系统
- 服务端 + 客户端
- 数据库 / API / 架构设计
- 全栈 / 前后端
- CRUD + 权限 + 用户系统

### 哪些任务可以走 Factory Lite
- 修改 README 中的姓名/学号
- 修复单个文件的小 bug
- 重新打包已有项目
- 格式化/注释调整

---

## 🔴 BOOT-001：Factory Bootstrap 未触发缺陷

**缺陷编号：** BOOT-001
**缺陷标题：** Project selection did not trigger Factory Bootstrap
**发现日期：** 2026-06-27

**缺陷描述：**
用户已处于 Codex_App_Factory 工作区，但 Codex 在处理"电商平台管理系统，
包含服务端和客户端"任务时，未先执行 Project Expertise Flow，
直接进入普通交付模式生成了 RUN-A 成品（两个压缩包）。
这说明 Factory 规则没有形成项目级启动门禁。

**根因：**
- 项目根目录缺少显式的 AGENTS.md 门禁文件
- GLOBAL_CODEX_RULES.md 的规则表述偏向"新建项目"场景，
  未覆盖"用户在 Factory 项目中直接提复杂任务"的场景

**修复措施（本次提交）：**
1. 创建本 AGENTS.md，将 Factory Bootstrap 提升为第零条铁律
2. 明确"选中 Factory 项目 = 自动进入 Factory 模式"
3. 记录 BOOT-001 供后续审计

**验证方式：**
- 后续任何在 C:\Codex_App_Factory 中的复杂任务，
  Codex 必须先输出 Factory Boot Summary，再获得用户确认后才能编码

---


---

## 🔴 R2.4：搜索基线门禁（Factory Bootstrap 后第二步）

### 搜索系统基线
Factory 搜索子系统基线已冻结（R2.3-AB），完整文档：
- `outputs/FACTORY_R2_3_AB_SEARCH_SYSTEM_BASELINE.ps1`
- `outputs/FACTORY_R2_4_WORKFLOW_SEARCH_INTEGRATION.md`

### 搜索门禁规则

Factory Bootstrap 完成后，**任何涉及以下内容的任务必须先经过 Pre-Build Research Gate**：

**P0_MUST_SEARCH（必须搜索）：**
- 安全关键：登录、认证、JWT、权限、RBAC、文件上传安全、密钥管理
- 外部依赖：新 package / SDK / API / 云服务 / 插件
- 架构选型：新项目、新模块、数据库设计、缓存、部署、AI 接入
- 高返工风险：不确定正确 API、存在多条路线、询问"主流怎么做"

**P2_NO_SEARCH_REQUIRED（不需要搜索）：**
- 已定位本地 bug
- 样式 / 文案 / 格式修改
- 测试补充
- 纯文档
- 按已有模式复制且不涉及安全、依赖、架构变化

### 证据规则
- **Evidence Pack v2 是唯一事实载体**
- **Implementer 永不直接搜索**
- **/chat/completions URL extraction 不能作为 canonical evidence**
- **不允许 Independent Search Agent 或 Dual Search Channel**

### 快速判定命令
```powershell
# 先分类；P0/P1 在还没有 Evidence Pack 时 gate_passed=false 是正确结果
. .\runtime\pre-build-research-gate.ps1
Invoke-PreBuildResearchGate -TaskDescription "你的任务" -AgentId "RSRC-001"

# 搜索与质量门禁完成后，必须绑定真实 pack 才能通过
Invoke-PreBuildResearchGate `
  -TaskDescription "你的任务" `
  -PhaseId "implementation" `
  -AgentId "RSRC-001" `
  -ExistingEvidencePackId ".\knowledge\evidence\EVID-....json" `
  -Context @{ ProjectId = "你的项目ID" }
```

P0/P1 的“分类成功”不等于“研究门禁通过”。缺 pack、`FAIL_FATAL`、非 live
来源、模型文本抽取来源、过期/篡改内容、任务/阶段不匹配都会 fail-closed。

（保持有效）

1. 禁止从空白自由设计项目
2. 新项目必须先判断应用类型
3. 先输出设计稿，再写代码
4. 小项目不要微服务
5. 第一版先做最小闭环
6. 默认不加支付/分账/多租户/消息队列
7. 所有数据库表必须有审计字段
8. 所有登录/权限必须服务端校验
9. 密钥不放前端
10. 响应式布局
11. 一条命令可运行
12. 完成后输出简短里程碑报告

