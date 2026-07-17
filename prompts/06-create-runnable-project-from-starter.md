## 选择 Starter 前必须做（Phase 3B-4.5）

在选择 runnable starter 之前，必须先完成体量判断：

1. **判断项目体量** S / M / L / XL（参考 `architecture-scaling-ladder` skill）
2. **判断风险等级** low / medium / high / extreme
3. **选择默认 starter**
4. **判断是否需要升级**
5. 如果项目体量超过 starter 能力，说明 starter 作为第一阶段起点是否仍合适
6. 如果不合适，不要硬套 starter——告知用户当前无匹配 starter
7. 如果建议升级架构，必须说明升级理由和暂不实现内容

### 速查表

| 体量 | 默认 Starter | 何时升级 |
|------|-------------|---------|
| S | `vite-react-content-site` | 几乎不 |
| M | `next-fullstack-admin` | 有条件 |
| L | `next-fullstack-admin` + 真实DB | 正式版必须 |
| XL | 拆第一阶段，不从简单 starter 生成全部 | 按模块 |

---
# 从 Runnable Starter 创建项目提示词

> 在设计稿确认后，从 runnable starter 创建实际项目。

---

## 执行要求

### 步骤 1：选择 Starter

根据项目类型选择对应的 runnable starter：

| 项目类型 | Runnable Starter |
|----------|-----------------|
| content-site / landing-page | `vite-react-content-site` |
| fullstack-admin | `next-fullstack-admin`（开发中） |
| saas-tool | `next-saas-ai-tool`（开发中） |
| api-service | `node-api-postgres`（开发中） |
| threejs-interactive | `vite-threejs-interactive`（开发中） |

当前可用的 starter：`vite-react-content-site`

### 步骤 2：复制 Starter

如果项目类型是 content-site / landing-page：

1. 复制整个 `vite-react-content-site` 目录到目标项目路径
2. 不要改动原始 starter 文件

### 步骤 3：替换占位符

1. 全局搜索 `PROJECT_NAME`，替换为实际项目名
2. 编辑 `src/data/siteContent.ts`，填充实际内容
3. 根据需要修改 `PROJECT_BRIEF.md`
4. 修改 `.env.example` 中的环境变量

### 步骤 4：不添加的内容

- ❌ 不要添加数据库
- ❌ 不要添加用户登录/注册
- ❌ 不要添加管理后台
- ❌ 不要添加支付
- ❌ 不要添加路由库（单页用锚点导航）
- ❌ 不要添加 UI 框架或 Tailwind
- ✅ 如果用户需要表单收集 → 添加 ContactForm 组件
- ✅ 如果用户需要后台管理 → 切换到 `next-fullstack-admin`（准备好后）

### 步骤 5：验证

- 复制后运行 `npm install`
- 运行 `npm run dev` 验证可启动
- 运行 `npm run typecheck` 验证无类型错误
- 运行 `npm run build` 验证可构建
- 按 `tests/smoke-checklist.md` 逐项验收

### 步骤 6：输出

完成实现后输出简短里程碑报告：
- 使用哪个 starter 创建
- 替换了哪些内容
- 如何运行
- smoke test 是否通过

---

### 可用 Starter 列表（持续更新）

| 项目类型 | Runnable Starter | 状态 |
|----------|-----------------|------|
| content-site / landing-page | `vite-react-content-site` | ✅ 可用 |
| fullstack-admin / 管理后台 | `next-fullstack-admin` | ✅ 可用 |
| saas-tool / AI 工具 | `next-saas-ai-tool` | ✅ 可用 |
| api-service / 后端 API | `node-api-postgres` | 🔜 待创建 |
| threejs-interactive / 3D原型 | `vite-threejs-interactive` | ✅ 可用 |

### fullstack-admin 特殊说明

- 复制 `next-fullstack-admin` 后，必须先保留 mock-db
- **不要**直接把 mock-db 当正式数据库
- 确认用户需求后再接入真实认证、数据库、权限系统
- 替换 PROJECT_NAME 占位符为实际项目名
- 先跑通 `npm run typecheck` 和 `npm run build` 再扩展功能
---

## 完整执行流程（Phase 3B-3 更新）

当用户确认 Project Expertise Flow 设计稿后，Codex 必须按以下流程执行：

### 1. 读取注册表
读取 `C:\Codex_App_Factory\runnable-starters\STARTER_REGISTRY.md`，根据项目类型选择匹配的 runnable starter。

### 2. 如果无匹配 Starter
- 不要硬套不匹配的 starter
- 告知用户："该类型（[类型名]）的 runnable starter 尚未创建。"
- 建议：手动创建项目，或先用最接近的 starter
- 当前可用 starter：`vite-react-content-site`（content-site）、`next-fullstack-admin`（fullstack-admin）

### 3. 使用复制脚本
推荐使用 `scripts/create-project-from-starter.ps1`（Windows）或 `.sh`（macOS/Linux）：

```powershell
C:\Codex_App_Factory\scripts\create-project-from-starter.ps1 `
  -StarterName "next-fullstack-admin" `
  -TargetPath "C:\Projects\my-project" `
  -ProjectName "my-project"
```

### 4. 不要手动复制
不要用 `cp -r` 或手动逐文件复制。复制脚本会自动：
- 替换 PROJECT_NAME
- 排除 node_modules 和构建产物
- 更新 package.json name

### 5. 复制后立即做的事
- 填写 `PROJECT_BRIEF.md`
- 编辑内容文件（如 `src/data/siteContent.ts`）

### 6. 复制后不立刻做的事
- ❌ 不立刻接真实数据库（mock-db 先跑通）
- ❌ 不立刻接真实认证（mock auth 先跑通）
- ❌ 不立刻加支付
- ❌ 不立刻加 complex middleware

### 7. 安装依赖前先确认
- 询问用户："是否现在执行 `npm install`？"
- 用户确认后再安装
- 安装后立即运行 `npm run typecheck` 和 `npm run build`

### 8. 输出里程碑报告
```
✅ 项目创建完成
- Starter: [name]
- 目标: [path]
- 下一步: npm install && npm run dev
- 需求模板: PROJECT_BRIEF.md
```


### threejs-interactive 特殊说明

- 使用 `vite-threejs-interactive` starter
- 选择前必须先判断项目体量和风险等级
- 复制后先保留 low-poly placeholder objects
- **不要**下载外部模型或贴图，除非用户明确要求
- **不要**第一阶段做多人、语音、物理、复杂任务系统
- 如果项目涉及后端状态或多人同步，先说明升级路径，不要直接堆复杂架构
- 第一阶段必须验证：可点击对象 + UI Panel + MiniMap + 状态更新闭环
- 复制后编辑 `src/state/sceneObjects.ts` 和 `PROJECT_BRIEF.md`



- 使用 `node-api-postgres` starter
- 选择前必须先判断项目体量和风险等级
- 复制后先保留 mock-db 和 schema.example
- **不要**直接接真实数据库，除非用户明确要求
- 接真实 PostgreSQL 前必须确认：
  - schema 设计（表结构、索引、约束）
  - 事务策略（哪些操作必须原子）
  - 审计策略（哪些操作需要审计日志）
  - 权限策略（行级安全 RLS 或应用层权限）
  - 幂等策略（哪些端点是幂等的）
- **不要**默认添加 Redis / 队列 / 微服务 / 对象存储
- 如果项目达到 L/XL，只在设计中说明升级路径，第一阶段不堆复杂架构
- 复制后编辑 `PROJECT_BRIEF.md` 和 `src/db/mock-db.ts`



- 使用 `next-saas-ai-tool` starter
- 选择前必须先判断项目体量和风险等级
- 复制后先保留 mock AI provider / mock quota / mock history
- **不要**直接接真实 AI API，除非用户明确要求
- 接真实 AI API 前必须确认：
  - API key 存放方式（仅后端环境变量）
  - 额度扣减规则（先生成再扣？先扣再生成？）
  - 失败是否扣次数（默认：不扣）
  - 幂等策略（防止重复提交扣多次）
- **不要**默认添加支付/订阅/多租户
- 如果项目达到 L/XL，只在设计中说明升级路径，第一阶段不堆复杂架构


---

## Runtime Validation（Phase 3D 新增）

当用户确认要运行生成的项目时，Codex 应按顺序执行：

1. `npm install`
2. `npm run typecheck`
3. `npm run build`
4. 只有以上通过后，才短启动 `npm run dev`
5. 如果失败，先判断问题来源：
   - **generated project issue** — 业务改造引入 → 修复测试项目
   - **starter source defect** — 源模板问题 → 同步修复原 starter
   - **copy script defect** — 复制脚本问题 → 修复脚本 + 重新 dry-run
   - **dependency / environment issue** — npm/node 版本问题 → 报告用户
6. 如果是 starter 源模板问题，要同步修复原 starter，不只修测试项目
7. 如果是复制脚本问题，要修复脚本并重新 dry-run
8. 不要通过乱加依赖解决结构性问题
9. 不要接真实数据库或真实认证来掩盖 mock 项目问题
10. Runtime validation 结果必须记录到 `RUNTIME_VALIDATION_REPORT.md`
