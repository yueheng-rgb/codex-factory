# Next.js SaaS / AI Tool — Runnable Starter

> 可直接复制使用的 SaaS / AI 工具骨架。适合 AI 文案生成、模板工具、文本处理等带用户额度和历史记录的项目。

## 适合项目

- AI 文案/内容生成工具
- 模板/素材生成工具
- 文本处理 SaaS 工具
- 按次数/额度计费的简单 SaaS
- 带用户历史和账户中心的工具

## 不适合项目

- 官网/展示页（→ `vite-react-content-site`）
- 管理后台/CRUD 系统（→ `next-fullstack-admin`）
- 微信小程序（→ miniapp starter）
- 支付/订阅系统（需从本 starter 升级）
- 多租户 SaaS（XL 级，需架构升级）

## 默认体量等级

**M-L 级。** 如果涉及真实 AI API、支付、订阅、多租户，应由 `architecture-scaling-ladder` 判断是否升级。

## 目录说明

```
next-saas-ai-tool/
├── README.md / AGENTS.md / PROJECT_BRIEF.md
├── package.json / tsconfig.json / next.config.js / .env.example
├── prisma/schema.prisma.example      ← 用户+额度+历史+API日志
├── app/
│   ├── page.tsx                      ← 落地页
│   ├── login/ dashboard/ tool/ history/ account/
│   └── api/ (health, auth, generate, history, usage)
├── components/ (11 个共享组件)
├── lib/ (8 个工具模块)
└── tests/smoke-checklist.md
```

## 如何复制使用

```bash
cp -r C:/Codex_App_Factory/runnable-starters/next-saas-ai-tool ./my-tool
cd my-tool
```

## 运行命令

```bash
npm install
npm run dev          # http://localhost:3000
npm run typecheck
npm run build
```

## API 设计

| 端点 | 说明 |
|------|------|
| `GET /api/health` | 健康检查 |
| `POST /api/auth/login` | Mock 登录 |
| `POST /api/generate` | 生成内容（扣额度+防重复+失败回滚） |
| `GET /api/history` | 生成历史（分页） |
| `GET /api/usage` | 剩余额度 |

## Mock 说明

- **AI Provider：** `lib/ai-provider-placeholder.ts` — mock 生成 1-2 秒后返回 placeholder
- **Usage Quota：** `lib/usage-quota.ts` — 内存额度，生成失败自动恢复
- **History：** `lib/generation-history.ts` — 内存历史记录
- **Idempotency：** `lib/idempotency.ts` — 防止重复提交

## 如何替换为真实 AI API

1. 修改 `lib/ai-provider-placeholder.ts` 中的 `mockGenerate`
2. 替换为 `fetch("https://api.openai.com/v1/chat/completions", ...)`
3. API Key 只放后端环境变量（`.env`），绝对不进前端代码
4. 不要在前端组件中直接调用 AI API

## 如何替换为真实数据库

1. `npm install prisma @prisma/client`
2. 重命名 `prisma/schema.prisma.example` → `schema.prisma`
3. 配置 `DATABASE_URL`
4. `npx prisma migrate dev`
5. 替换 lib 中的 mock 实现为 Prisma Client

## 如何避免额度扣减错误

- ✅ 先扣额度 → 生成 → 成功则 commit，失败则 rollback
- ✅ 条件 UPDATE：`WHERE total - used >= 1`
- ✅ 幂等 Key 防重复提交
- ❌ 不能先生成再扣额度
- ❌ 不能只在前端检查额度

## 第一阶段验收标准

- [ ] `npm run dev` 正常启动
- [ ] 落地页可见
- [ ] 登录功能正常
- [ ] 生成工具页可用
- [ ] 生成成功显示结果
- [ ] 生成失败不扣次数
- [ ] 历史记录可查看
- [ ] 额度显示正确
- [ ] `npm run typecheck` 通过
- [ ] `npm run build` 通过