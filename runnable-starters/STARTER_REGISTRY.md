# Starter Registry — 可运行 Starter 注册表

> 当 Project Expertise Flow 判断完项目类型后，从这里选择匹配的 runnable starter。

---

## 注册规则

1. Project Expertise Flow 先判断项目类型（content-site / fullstack-admin / saas-tool / api-service / miniapp / mobile-app / threejs-interactive）
2. 在此表中查找匹配类型
3. 如果 `已创建 = ✅`，使用对应 starter
4. 如果 `已创建 = ❌`，告诉用户"该类型 starter 尚未创建，是否改用最接近的 starter？"

---

## 当前可用 Starter

### 1. vite-react-content-site

| 属性 | 值 |
|------|-----|
| **匹配类型** | content-site / landing-page |
| **已创建** | ✅ |
| **推荐优先级** | content-site 类型首选 |
| **技术栈** | Vite + React + TypeScript |
| **适合** | 官网、宣传页、落地页、招聘页、活动页、服务介绍页 |
| **不适合** | 管理后台、数据库系统、SaaS 工具、小程序、复杂 App |
| **页面入口** | `src/App.tsx` |
| **内容配置** | `src/data/siteContent.ts` |
| **复制后第一步** | 编辑 `src/data/siteContent.ts`，替换所有 placeholder 内容 |
| **不要马上做** | 不要加数据库、登录、后台、支付、路由库、UI 框架 |
| **运行命令** | `npm install` → `npm run dev` → `npm run typecheck` → `npm run build` |

### 2. next-fullstack-admin

| 属性 | 值 |
|------|-----|
| **匹配类型** | fullstack-admin |
| **已创建** | ✅ |
| **推荐优先级** | fullstack-admin 类型首选 |
| **技术栈** | Next.js + TypeScript + mock-db + API route handlers |
| **适合** | 管理后台、会员系统、报名系统、记录系统、审核系统、统计后台 |
| **不适合** | 纯官网、小程序前端、复杂实时协作、复杂电商 |
| **页面入口** | `app/` |
| **API 入口** | `app/api/` |
| **mock 数据** | `lib/mock-db.ts`（内存 mock，重启后重置） |
| **复制后第一步** | 编辑 `PROJECT_BRIEF.md`，明确管理对象和业务流程 |
| **不要马上做** | 不要接真实数据库、不要连支付、不要加复杂审批、不要拆微服务 |
| **运行命令** | `npm install` → `npm run dev` → `npm run typecheck` → `npm run build` |

---


### 3. next-saas-ai-tool

| 属性 | 值 |
|------|-----|
| **匹配类型** | saas-tool / ai-tool |
| **已创建** | ✅ |
| **默认体量** | M-L |
| **技术栈** | Next.js + TypeScript + mock AI provider + mock quota + mock history |
| **适合** | AI 文案工具、模板生成工具、文本处理工具、用户额度工具、生成历史工具 |
| **不适合** | 纯官网、纯后台、小程序前端、复杂多租户 SaaS、支付/订阅系统 |
| **页面入口** | `app/` |
| **API 入口** | `app/api/` |
| **mock 数据** | `lib/mock-db.ts`（内存，重启重置） |
| **升级条件** | 真实 AI API、额度扣减、支付、订阅、多用户历史、API 调用日志、长期上线 |
| **禁止升级条件** | 只做 mock 演示、只做课堂作业、只验证页面流程 |
| **复制后第一步** | 编辑 `PROJECT_BRIEF.md`，明确工具能力和额度模型 |
| **不要马上做** | 不要接真实 AI API、不要加支付/订阅、不要把 API Key 写前端 |
| **运行命令** | `npm install` → `npm run dev` → `npm run typecheck` → `npm run build` |


### 4. node-api-postgres

| 属性 | 值 |
|------|-----|
| **匹配类型** | api-service / backend-service / miniapp-backend / app-backend |
| **已创建** | ✅ |
| **默认体量** | M-L |
| **技术栈** | Node.js + TypeScript + Fastify + mock-db + PostgreSQL schema example |
| **适合** | 小程序后端、App 后端、纯 API 服务、PostgreSQL 业务服务 |
| **不适合** | 纯官网、纯前端、复杂微服务平台、实时协作系统 |
| **API 入口** | `src/routes/` |
| **服务层** | `src/services/` |
| **数据访问层** | `src/repositories/` |
| **mock 数据** | `src/db/mock-db.ts`（内存，重启后重置） |
| **升级条件** | 真实 PostgreSQL、事务、审计、幂等、外部集成、高风险写操作、长期上线 |
| **禁止升级条件** | 只做 API mock、课堂演示、低风险内部工具 |
| **复制后第一步** | 填写 `PROJECT_BRIEF.md`，明确业务资源和调用方 |
| **不要马上做** | 不要接真实 DB、不要加 Redis/队列/微服务、不要加 Swagger |
| **运行命令** | `npm install` → `npm run dev` → `npm run typecheck` → `npm run build` |

（未创建）

| Starter | 匹配类型 | 已创建 | 优先级 |
|---------|---------|--------|--------|
| `next-saas-ai-tool` | saas-tool | ✅ | — |
| `node-api-postgres` | api-service | ✅ | — |
| `vite-threejs-interactive` | threejs-interactive | ✅ | — |
| `miniapp-basic` | miniapp | ❌ | 低 |
| `expo-mobile-app` | mobile-app | ❌ | 低 |

---

## 决策流程

```
Project Expertise Flow 判断类型
          │
          ▼
  ┌──────────────────────┐
  │ 查 STARTER_REGISTRY  │
  └──────────────────────┘
          │
    ┌─────┴─────┐
    │           │
  匹配        无匹配
    │           │
    ▼           ▼
 使用 starter   告知用户"该类型 starter 未创建"
                建议用最接近的 starter 或等待创建
```

## 如果无匹配 Starter

Codex 应该：
1. 告知用户当前没有该类型的 runnable starter
2. 建议基于 Project Expertise Flow 设计稿手动创建项目
3. 在项目完成后，考虑将该项目提炼为新的 starter

---


### 5. vite-threejs-interactive

| 属性 | 值 |
|------|-----|
| **匹配类型** | threejs-interactive / 3d-web-prototype / interactive-scene |
| **已创建** | ✅ |
| **默认体量** | M |
| **技术栈** | Vite + TypeScript + Three.js |
| **适合** | 3D 交互 Web 原型、虚拟房间、线索场景、展厅、地图、可点击物体 |
| **不适合** | 复杂 3D 游戏、多人联机、语音房、物理模拟、大型开放世界 |
| **场景入口** | `src/main.ts` |
| **场景对象** | `src/state/sceneObjects.ts` |
| **交互逻辑** | `src/scene/interaction.ts` |
| **UI 入口** | `src/ui/` |
| **升级条件** | 多场景切换、任务系统、背包、线索系统、后端状态、多人同步、语音房 |
| **禁止升级条件** | 只验证可点击原型、只做场景演示、没有真实多人需求 |
| **复制后第一步** | 编辑 `src/state/sceneObjects.ts` 替换 placeholder 对象 |
| **不要马上做** | 不要下载外部模型/贴图、不要加物理引擎、不要做多人/语音 |
| **运行命令** | `npm install` → `npm run dev` → `npm run typecheck` → `npm run build` → `npm run preview` |

---

：体量 + 升级规则

### vite-react-content-site

- **默认体量：** S
- **升级条件：** 需要表单提交收集数据、需要后台、需要数据库
- **禁止升级条件：** 只是展示信息、无用户数据
- **替代 starter：** 如需后台管理，切换到 `next-fullstack-admin`
- **如果不适合：** 提示用户 "这是一个内容展示 starter，不适合需要数据库/登录的项目。建议使用 next-fullstack-admin。"

### next-fullstack-admin

- **默认体量：** M
- **升级条件：** 涉及次数/余额/库存/核销/审计/提成/多角色/RBAC
- **禁止升级条件：** 简单报名/记录、无高风险数据
- **替代 starter：** 如需 SaaS/AI 工具模式，切换到 `next-saas-ai-tool`（待创建）
- **如果不适合：** 提示用户 "这是管理后台 starter。如果只是展示网站，建议使用 vite-react-content-site。如果需要 SaaS/AI 工具功能，建议等待 next-saas-ai-tool。"



