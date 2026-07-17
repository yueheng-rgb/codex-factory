# Starter Quality Checklist — 可运行 Starter 质量检查清单

> 每个 runnable starter 创建后，必须逐项检查本清单。
> 在 `STARTER_REGISTRY.md` 中标记 `已创建 = ✅` 前，必须通过全部检查。

---

## 基础文件（5 项）

- [ ] `README.md` — 含用途、适合/不适合项目、目录说明、复制使用方式、运行命令
- [ ] `AGENTS.md` — 含 Codex 使用规则、不要添加的内容、防过度设计指南
- [ ] `PROJECT_BRIEF.md` — 可填写模板，含暂不实现内容
- [ ] `package.json` — 有 dev/build/typecheck 脚本，无真实密钥
- [ ] `.env.example` — 含必要环境变量模板，`.env` 在 `.gitignore`

## 工程完整性（10 项）

- [ ] `package.json` 有 `dev` / `build` / `typecheck` 脚本
- [ ] 不含真实密钥（API key / Secret / 密码）
- [ ] 不含 `node_modules` 目录
- [ ] 不含构建产物（`.next` / `dist` / `build` / `.vite`）
- [ ] 不绑定具体业务（内容使用 PROJECT_NAME 等占位符）
- [ ] 包含中性 placeholder（非特定公司/产品名）
- [ ] 有明确"不适合项目"列表
- [ ] 有第一阶段最小闭环说明（用户能完成什么真实任务）
- [ ] 依赖最小化（不引入 UI 框架、认证库、支付库、AI SDK）
- [ ] `tests/smoke-checklist.md` 存在且可逐项验证

## 前端项目专项（6 项）

- [ ] loading 状态组件存在且可复用
- [ ] empty 状态组件存在且可复用
- [ ] error 状态组件存在且可复用
- [ ] 移动端不横向溢出（375px 宽度下验证）
- [ ] 表单有 submitting 状态 + 防重复提交
- [ ] 详情页不依赖上一页 state（可直接通过 URL 访问）

## API/数据库项目专项（7 项）

- [ ] 统一 API 返回格式 `{ ok, data/error }`
- [ ] 服务端校验（不只在客户端校验）
- [ ] 权限占位（服务端 check，前端隐藏按钮 ≠ 权限）
- [ ] 列表支持分页 + 搜索 + 筛选
- [ ] mock-db 有明确标注"不能当正式数据库"
- [ ] schema.example 有审计字段（createdAt / updatedAt）
- [ ] 错误状态有明确 HTTP 状态码

## 复制脚本验证（5 项）

- [ ] `scripts/create-project-from-starter.ps1` 能复制此 starter
- [ ] 复制后 PROJECT_NAME 被正确替换
- [ ] 复制后不含 node_modules
- [ ] 复制后不含构建产物
- [ ] 复制后 `package.json` 的 name 字段已替换

---


## API / Backend Service 专项检查（12 项）

- [ ] 统一 API 返回格式 `{ ok, data/error }` 在所有端点生效
- [ ] 全局错误处理器返回统一格式
- [ ] 服务端校验输入（不信任客户端数据）
- [ ] 权限中间件占位存在且可调用
- [ ] admin 端点有权限中间件保护
- [ ] request logger 中间件占位存在
- [ ] service / repository 分层清晰
- [ ] mock-db 明确标注"不能当正式数据库"
- [ ] schema.example 包含审计字段（createdAt / updatedAt）
- [ ] transaction-notes.md 存在，说明事务/幂等/审计正确做法
- [ ] 幂等 key 占位存在（写操作端点）
- [ ] 不默认依赖 Redis / 队列 / 微服务 / ORM 真实驱动



全部 33 项（基础 5 + 工程 10 + 前端/API 专项 + 复制验证）通过后，才能在 `STARTER_REGISTRY.md` 中标记 `已创建 = ✅`。


## SaaS / AI Tool 专项检查（7 项）

- [ ] 不包含真实 API key
- [ ] 前端不出现模型密钥
- [ ] AI provider 为 placeholder
- [ ] 生成失败不扣次数
- [ ] 成功生成才扣次数
- [ ] 重复提交有幂等/防重复占位
- [ ] 历史记录按用户隔离
- [ ] 额度扣减说明事务/原子更新（条件 UPDATE）
- [ ] API 调用日志有 schema 示例
- [ ] 不默认添加支付/订阅
- [ ] 如果达到 L/XL，必须说明后续升级路径



## Three.js Interactive 专项检查（12 项）

- [ ] 场景可运行（canvas 可见）
- [ ] 有 camera / renderer / lights
- [ ] 有对象 registry（sceneObjects.ts）
- [ ] 对象有 id / name / type / status / metadata
- [ ] 有 Raycaster hover/click 交互
- [ ] 有 selected / hovered 状态管理
- [ ] UI panel 与场景逻辑分离
- [ ] MiniMap 为占位但可见
- [ ] 不依赖外部模型/贴图
- [ ] 不做纯视觉 demo（必须可交互）
- [ ] 移动端不横向溢出
- [ ] 不默认上多人/语音/物理引擎

## Runtime Validation 专项检查（9 项）

- [ ] package.json 不得包含 BOM（UTF-8 with BOM 会导致 npm/Next.js 解析失败）
- [ ] 所有 JSON 文件必须可被 npm 正常解析（`npm install` 不报 JSON parse error）
- [ ] 复制脚本替换 PROJECT_NAME 后不得写入 BOM
- [ ] 每个 starter 至少要能完成一次：`npm install` + `npm run typecheck` + `npm run build`
- [ ] 可复用组件必须支持业务文案替换，不应把 placeholder 文案写死
- [ ] 表格、搜索、筛选组件应支持 labels / placeholders / status options 轻量配置
- [ ] 业务改造不应要求修改底层组件过多（理想 ≤ 2 个组件）
- [ ] 如果运行验证发现 starter 缺陷，必须同步修复源 starter，而不只修测试项目
- [ ] Runtime validation 结果必须记录到 `RUNTIME_VALIDATION_REPORT.md`



## BOM Safety（Phase 4A 新增）

- [ ] 所有 starter 文件必须确保 UTF-8 no BOM
- [ ] 复制脚本必须对所有文本文件执行 BOM 检测/剥离
- [ ] Vite/PostCSS/CSS 相关项目尤其要检查 BOM，BOM 可能导致样式解析失败
- [ ] PowerShell 写文件优先用 UTF8 no BOM；PS5.x 必须额外去 BOM
- [ ] Runtime Validation 后更新 starter 状态表


## Runtime Validation 状态记录

| Starter | Runtime Validated | 备注 |
|---------|:---:|------|
| `next-fullstack-admin` | ✅ | Case 1: course-signup-demo。曾修复 BOM 与 SearchAndFilterBar props。 |
| `next-saas-ai-tool` | ✅ | Case 2: ai-copy-demo。零修复。 |
| `vite-react-content-site` | ✅ | Case 3: tutor-recruit-landing。曾发现并修复 BOM 污染。 |
| `node-api-postgres` | ❌ | dry-run only |
| `vite-threejs-interactive` | ❌ | dry-run only |

**规则：** 新 starter 或重大修改后必须至少 dry-run；真实使用前建议 runtime validate（install + typecheck + build + dev server）。




---

## B04 Benchmark Lessons (2026-06-17)

Based on node-api-postgres runtime validation findings:

- [ ] **Token parsing**: mock tokens must be opaque strings with server-side mapping; never parse userId/role from token structure; userIds may contain hyphens
- [ ] **Mock role**: client must never specify role; role must always come from server-side MOCK_USERS data
- [ ] **Pagination**: invalid page/limit values must return explicit errors (INVALID_PAGINATION), not silently normalized
- [ ] **Fastify hooks**: `addHook` called directly on app instance leaks globally; use `app.register()` for scoped plugins
- [ ] **Error codes**: all custom error codes must be added to `statusFromCode()` mapping; missing entries cause 500 errors
- [ ] **TypeScript strict**: with `strict:true`, catch block variables are `unknown`; error handlers must use explicit type annotations
- [ ] **BOM safety**: all text file writes must use explicit UTF-8 no-BOM encoding; PowerShell version differences cause inconsistencies
- [ ] **Encoding regression**: every copy script change must pass `test-copy-encoding.ps1`

---

## PowerShell File Editing Safety

> Added after B04 Phase D2 encoding corruption incident.

### Rules

* PowerShell ???????????? UTF-8 no BOM?
* ???? `Get-Content | Set-Content` ? `Get-Content | Out-File` ???????
* ??????????? SHA256 ???
* ??????????????`PROJECT_NAME`?`package.json#name`??
* ???? Unicode replacement character `?` (U+FFFD)?
* ???? JSON ?????? `ConvertFrom-Json` ?????

### Regression Tests

???????????????

```powershell
C:\Codex_App_Factory\scripts\test-copy-encoding.ps1
C:\Codex_App_Factory\scripts\test-copy-content-integrity.ps1
```

### Incident Record

B04 Phase D2: PowerShell `Get-Content -Raw` ? `WriteAllText` pipeline corrupted 11 ??? UTF-8 ???
??? Phase 4T ?????`create-project-from-starter.ps1` ???????? BOM ?????
