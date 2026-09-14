# Runtime Validation Report — Codex_App_Factory

> 记录使用 Codex_App_Factory 从一句话需求生成项目后的真实运行验证结果。

---

## 测试项目

| 属性 | 值 |
|------|-----|
| **项目名** | course-signup-demo |
| **项目类型** | fullstack-admin |
| **体量等级** | M |
| **使用 Starter** | next-fullstack-admin |
| **测试路径** | `C:\Codex_Test_Projects\_factory_e2e\course-signup-demo` |
| **验证日期** | 2026-06-16 |

---

## 验证流程

```
npm install → npm run typecheck → npm run build → npm run dev (短启动)
```

| 步骤 | 结果 | 耗时 |
|------|------|------|
| npm install | ✅ 成功（28 packages） | 35s |
| npm run typecheck | ✅ 通过（修复 1 个 TS 错误后） | 1.3s |
| npm run build | ✅ 通过（11 pages compiled） | 10.3s |
| npm run dev | ✅ 启动成功，6s 无崩溃后停止 | 6s |

---

## 发现的问题（4 项）

### 1. SearchAndFilterBar 缺少可选 props

- **类型：** starter source defect
- **描述：** 组件硬编码 placeholder 文案和 status 标签，业务改造时不得不修改底层组件
- **修复：** 添加 `searchPlaceholder` / `statusLabel` 可选 props，默认值保持中性
- **影响范围：** `next-fullstack-admin/components/SearchAndFilterBar.tsx`

### 2. package.json 包含 BOM 导致 build 失败

- **类型：** starter source defect / script defect
- **描述：** PowerShell `Set-Content -Encoding UTF8` 默认写入 UTF-8 with BOM。Next.js build 无法解析含 BOM 的 package.json
- **错误：** `SyntaxError: Unexpected token ''`
- **修复：**
  - 5 个 starter 的 package.json 全部剥离 BOM
  - 复制脚本末尾增加 BOM 剥离步骤
- **影响范围：** 所有 5 个 starter + 复制脚本

### 3. 复制脚本写入 BOM

- **类型：** script defect
- **描述：** 复制脚本中 `Set-Content -Encoding UTF8` 和 `ConvertTo-Json | Set-Content` 组合导致 package.json 被写入 BOM
- **修复：** 在复制脚本 #7 步骤后增加 BOM 剥离
- **影响范围：** `scripts/create-project-from-starter.ps1`

### 4. starter 源模板需同步修复

- **类型：** starter source defect
- **描述：** 测试项目中修复的组件 props 问题，原 starter 未同步更新
- **修复：** 同步修复 `next-fullstack-admin/components/SearchAndFilterBar.tsx`
- **规则：** 运行时验证发现 starter 缺陷 → 必须同步修复原 starter

---

## 修复文件清单

| 文件 | 修复内容 |
|------|---------|
| `next-fullstack-admin/components/SearchAndFilterBar.tsx` | 添加可选 props |
| `next-fullstack-admin/package.json` | 剥离 BOM |
| `vite-react-content-site/package.json` | 剥离 BOM |
| `next-saas-ai-tool/package.json` | 剥离 BOM |
| `node-api-postgres/package.json` | 剥离 BOM |
| `vite-threejs-interactive/package.json` | 剥离 BOM |
| `scripts/create-project-from-starter.ps1` | 增加 BOM 剥离步骤 |

---

## 问题分类

| 问题来源 | 数量 | 示例 |
|---------|------|------|
| **starter source defect** | 3 | SearchAndFilterBar props、BOM in starter |
| **script defect** | 1 | 复制脚本 BOM |
| **generated project adaptation** | 0 | 本次无独立项目级问题 |

---

## 后续预防规则

1. **新增/修改 starter 后**：dry-run 复制 → npm install → npm run typecheck → npm run build
2. **PowerShell 写 JSON 文件**：必须使用 UTF-8 no BOM
3. **复制脚本输出后**：检查 package.json 是否可被 npm 解析
4. **组件设计**：可复用组件必须支持业务文案替换，不应写死 placeholder
5. **运行时验证失败**：先判断问题来源（starter / script / project），不盲目加依赖

---

## 当前结论

Codex_App_Factory 已完成从一句话需求到可运行测试项目的闭环验证：

```
用户需求 → Project Expertise Flow → 选 starter → 复制 → 填写 BRIEF → 业务改造 → install → typecheck → build → dev server
```

**状态：已验证通过。**

---

## Case 2: ai-copy-demo (AI 文案生成网站)

| 属性 | 值 |
|------|-----|
| **项目名** | ai-copy-demo |
| **项目类型** | saas-tool / ai-tool |
| **体量等级** | M-L |
| **使用 Starter** | next-saas-ai-tool |
| **测试路径** | `C:\Codex_Test_Projects\_factory_e2e\ai-copy-demo` |
| **验证日期** | 2026-06-16 |

### 验证流程

| 步骤 | 结果 | 备注 |
|------|------|------|
| npm install | ✅ 成功（28 packages） | 无 warnings |
| npm run typecheck | ✅ 第一次通过 | 零修复 |
| npm run build | ✅ 通过（14 pages） | 第一次通过 |
| npm run dev | ✅ 启动成功，6s 后停止 | 无崩溃 |

### 工程约束结果

| 约束 | 状态 |
|------|------|
| 未接真实 AI API | ✅ |
| 未写真实 API key | ✅（仅注释提及 OpenAI 作为替换说明） |
| 未接真实数据库 | ✅ |
| 未接真实认证 | ✅ |
| 未添加 OpenAI/Anthropic/LangChain SDK | ✅ |
| 未添加支付 SDK | ✅ |
| 未下载 Chromium | ✅ |
| 未运行 Playwright | ✅ |
| 未出现过度设计 | ✅ |

### 发现的问题

**无。** 本次 Runtime Validation 零修复通过。

### 对比 Case 1

| 维度 | Case 1 (course-signup) | Case 2 (ai-copy) |
|------|----------------------|------------------|
| Starter | next-fullstack-admin | next-saas-ai-tool |
| 项目类型 | fullstack-admin | saas-tool / ai-tool |
| typecheck | 需修复 1 个 TS 错误 | 第一次通过 |
| build | 需修复 BOM | 第一次通过 |
| starter 同步修复 | SearchAndFilterBar + 5×BOM | 无 |

**跨类型结论：** Phase 3C-1R 的 BOM 修复和组件灵活性修复对后续项目类型产生了防错效果。ai-copy-demo 零修复通过。

---

## 当前结论

Codex_App_Factory 已完成两个不同类型测试项目的 runtime validation：

| Starter | 类型 | Runtime Validated |
|---------|------|:---:|
| `next-fullstack-admin` | fullstack-admin | ✅ |
| `next-saas-ai-tool` | saas-tool / ai-tool | ✅ |
| `vite-react-content-site` | content-site | dry-run only |
| `node-api-postgres` | api-service | dry-run only |
| `vite-threejs-interactive` | threejs-interactive | dry-run only |

**状态：跨类型切换验证通过。可进入真实小项目试用阶段。**

---

## Case 3: tutor-recruit-landing (线上家教老师招募落地页) — 第一个真实小项目

| 属性 | 值 |
|------|-----|
| **项目名** | tutor-recruit-landing |
| **项目类型** | content-site / landing-page |
| **体量等级** | S |
| **使用 Starter** | vite-react-content-site |
| **项目路径** | `C:\Codex_Real_Projects\tutor-recruit-landing` |
| **验证日期** | 2026-06-16 |

### 验证流程

| 步骤 | 结果 | 备注 |
|------|------|------|
| npm install | ✅ 成功（71 packages） | — |
| npm run typecheck | ✅ 通过（修复 1 个 TS6133） | 未使用的 buttonText prop |
| npm run build | ✅ 通过（39 modules, 3 output） | 修复 BOM 后 |
| npm run dev | ✅ 启动成功，5s 后停止 | localhost:5173 |

### 发现的问题

| 问题 | 类型 | 严重度 |
|------|------|:--:|
| **BOM 污染全面** | starter source defect + script defect | 高 |

**详情：** PowerShell `Set-Content -Encoding UTF8` 在所有文本文件写入 BOM（UTF-8 with BOM）。Vite/PostCSS 无法解析含 BOM 的 CSS/JSON 文件，导致 build 失败。

**修复：**
- 复制脚本升级为全文件 BOM 剥离（.json/.css/.ts/.tsx/.html/.js/.jsx）
- 原 starter `vite-react-content-site` 17 个文件同步去 BOM
- 项目文件 19 个文件运行时去 BOM

### 工程约束

| 约束 | 状态 |
|------|:--:|
| 未接数据库 | ✅ |
| 未接登录 | ✅ |
| 未接支付 | ✅ |
| 未使用外部图片/字体/素材 | ✅ |
| 未下载 Chromium | ✅ |
| 未运行 Playwright | ✅ |

### 当前意义

`vite-react-content-site` 成为第 3 个 Runtime Validated starter。第一次在真实项目中使用 Codex_App_Factory 并发现工厂级缺陷（BOM），已回流修复。



---

## Case 4: b04-checkin-api (node-api-postgres) — B04 Benchmark

**Date**: 2026-06-17
**Starter**: node-api-postgres
**Type**: api-service / miniapp-backend (M)

**Validation**: install 54pkgs → typecheck (1 fix) → build → dev → 14 API tests → all pass
**First-attempt score**: 42/50 (Pass)
**Final score**: 45/50 (Pass)

**Defects found & fixed**:
| Defect | Category | Fix |
|---|---|---|
| error-handler.ts: unknown error type under strict TS | Starter | Add FastifyError type annotation |
| app.ts: addHook leaks auth to health/ | Starter | Wrap in app.register() scoped plugin |
| mock-db.ts + auth.ts: token parsing breaks on dashed userIds | Starter | Opaque token mapping (server-side) |
| pagination.ts: silent normalization of bad params | Starter | Added parsePaginationStrict with INVALID_PAGINATION |
| api-response.ts: missing DUPLICATE_CHECKIN in statusFromCode | Starter | Added DUPLICATE_CHECKIN + INVALID_PAGINATION |
| Copy script: Set-Content -Encoding UTF8 writes BOM | Script | All writes → [System.IO.File]::WriteAllBytes with UTF8Encoding($false) |


---

## Case 5: story-mystery-engine — Story-to-Murder-Mystery Compiler Vertical Slice

**Date**: 2026-08-02
**Type**: saas-tool / ai-generation-engine (L first slice, XL vision)
**Project path**: `<user-documents>\Codex\2026-08-01\files-mentioned-by-the-user-codex`

### Validation Flow

| Step | Result | Notes |
|---|:--:|---|
| npm install | ✅ | 94 packages installed |
| npm run typecheck | ✅ | Passed after pinning TypeScript to 5.9 series |
| npm test | ✅ | 3 Vitest tests, including leakage and deduction negative cases |
| npm run demo | ✅ | Generated HTML, JSON, and ZIP Game Kit |
| npm run build | ✅ | Next.js production build passed |
| npm run dev | ✅ | Started at `http://localhost:3000` |
| Runtime HTTP check | ✅ | Home returned 200; `/api/runs` returned validationPassed=true, 11 clues, 6 roles |

### Defects Found & Fixed

| Defect | Category | Fix |
|---|---|---|
| TypeScript `latest` installed 7.0.2 preview and broke JSX typings | Dependency/environment | Pin TypeScript to `^5.9.2` |
| Vitest could not resolve Next path alias `@/*` | Generated project issue | Added Vitest alias to `./src` |
| Next inferred wrong workspace root because user-level lockfile exists | Environment/workspace | Added `turbopack.root` to `next.config.mjs` |

### Generated Artifact

- `outputs\RUN-20260801161528\game-kit.html`
- `outputs\RUN-20260801161528\game-kit.json`
- `outputs\RUN-20260801161528\game-kit.zip`
