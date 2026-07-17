# Codex Factory Architecture R2.0 — General Architecture Upgrade Spec

> **Phase:** FACTORY-ARCHITECTURE-R2-0
> **Version:** 2.0.0-draft
> **Date:** 2026-07-05
> **Status:** DESIGN
> **Replaces:** v0.x / v1.x ad-hoc architecture

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [External Ecosystem Survey](#2-external-ecosystem-survey)
3. [Multi-Agent Collaboration v2](#3-multi-agent-collaboration-v2)
4. [Skill Bank / Knowledge Bank](#4-skill-bank--knowledge-bank)
5. [Research / Search Agent](#5-research--search-agent)
6. [Architecture Drift Control](#6-architecture-drift-control)
7. [Runner / Hardware / Cloud Strategy](#7-runner--hardware--cloud-strategy)
8. [Overall Architecture](#8-overall-architecture)
9. [Phase Roadmap](#9-phase-roadmap)
10. [Agent Matrix](#10-agent-matrix)
11. [Skill Matrix](#11-skill-matrix)
12. [Search / Knowledge Program](#12-search--knowledge-program)
13. [Runner / Hardware / Cloud Program](#13-runner--hardware--cloud-program)
14. [Benchmark Project Matrix](#14-benchmark-project-matrix)
15. [Next Phase Recommendations](#15-next-phase-recommendations)

---

## 1. Executive Summary

### 1.1 Problem Statement

Codex Factory v0.x/v1.x 已建立基础体系（7 项目类型路由、8 角色多 agent、starter/blueprint/prompt/skill 四层结构），但在以下维度存在结构性不足：

- **外部生态利用不足**: 大量高质量外部 skill、MCP server、开源模板未系统化评估和导入
- **Agent 体系碎片化**: 角色定义分散在多个文件，缺乏统一的 agent 生命周期、权限模型、handoff 协议
- **知识沉淀缺失**: 没有 Skill Bank、Knowledge Bank、failure lesson 库，每次从零开始
- **搜索能力空白**: 无外接搜索 agent，依赖模型内置知识，框架版本/API 可能过时
- **架构漂移无检测**: 项目进行中方向偏移、复杂度缩水无系统性检测
- **Runner 策略缺失**: 没有硬件/云/本地的分级运行策略

### 1.2 R2.0 目标

设计 Codex Factory 的下一代整体架构，使其成为：

> **一个自我进化的、多 agent 协作的、外部生态感知的、知识沉淀的、漂移自检的项目生成工厂。**

### 1.3 设计原则

1. **External-First**: 先查外部是否有现成方案，不自造轮子
2. **Trust-Tiered**: 区分"可用""可信""已验证"三级信任
3. **Agent-Native**: 所有能力通过 agent 暴露，每个 agent 有明确边界
4. **Knowledge-Accumulating**: 每次失败和成功都沉淀为知识胶囊
5. **Drift-Aware**: 项目全程对比初始意图，自动发现偏移
6. **Hardware-Agnostic**: 默认本地 Windows 可跑，按需扩展 Mac/Cloud
7. **Backward-Compatible**: 兼容现有 starter/blueprint/prompt 体系

---

## 2. External Ecosystem Survey

### 2.1 Survey Scope

| Category | Items Surveyed | Key Sources |
|----------|---------------|-------------|
| OpenAI Codex Skills | SKILL.md spec, skill-installer, curated skills, plugin system | codex-skill spec, codex marketplace |
| Claude Agent Skills | CLAUDE.md, custom slash commands, MCP integration | Anthropic Claude Code docs |
| Cursor Rules | .cursorrules, .cursor/rules/*.mdc, project rules | Cursor IDE docs |
| AGENTS.md | Agent instruction files, directory-scoped rules | community convention |
| MCP Servers | Filesystem, GitHub, Postgres, Brave Search, Puppeteer, etc. | modelcontextprotocol.io |
| Open-Source Templates | create-t3-app, create-next-app, shadcn/ui blocks, v0 | GitHub, Vercel |
| Big-Tech Engineering Specs | Google, Microsoft, Alibaba engineering standards | public engineering docs |
| Official Framework Examples | Next.js, React, Fastify, Prisma, Expo examples | official docs + GitHub |

### 2.2 Detailed Findings

#### 2.2.1 OpenAI Codex Skills Ecosystem

**Available mechanism:**
- `SKILL.md` spec: 每个 skill 是一个包含 SKILL.md 的目录，支持 references/ 子目录
- `skill-installer`: 内置 skill，用于从 curated list 或 GitHub repo 安装 skill
- Plugin system: `.codex-plugin/plugin.json`，可打包 skills + MCP servers
- Skill scoping: file-based（AGENTS.md 同级目录树生效）

**可直接借鉴:**
- SKILL.md 格式规范 → Factory Skill 的标准格式
- skill-installer 安装流程 → Factory Skill Import 流程
- curated list 审核机制 → Factory Skill Trust Level 审核

**可改造成 Factory Skill:**
- `openai-docs` → 通用文档查询 skill
- `skill-creator` → Factory Skill 脚手架生成器
- `skill-installer` → Factory Skill 市场客户端
- `browser` → 前端验证 + 截图 skill
- `supabase-postgres-best-practices` → 数据库规范 skill（已安装）
- `playwright-interactive` → UI 测试 skill（已安装）

**不能信任:**
- 任何标记为 "community" 且无 review history 的 skill
- 任何声称 "全能大师" 的 skill
- 任何包含可执行脚本但无源码审查的 skill

**进入 Factory 前的安全检查:**
1. Source provenance check — 来源仓库是否可信
2. SKILL.md content review — 指令是否与 Factory 铁律冲突
3. Script audit — 所有脚本必须可审计
4. Network capability audit — 是否要求外网访问
5. File write scope check — 写入范围是否越界
6. Conflict test — 与已有 skill 是否冲突
7. Sandbox test — 在隔离环境中试运行

#### 2.2.2 Claude Agent Skills / Claude Code

**Available mechanism:**
- `CLAUDE.md`: 类似 AGENTS.md 的项目级指令文件
- Custom slash commands: 用户自定义命令
- MCP servers: 通过 `claude_desktop_config.json` 配置
- Hooks: 事件驱动的自动化

**可直接借鉴:**
- CLAUDE.md 的简洁指令格式 → 可补充 AGENTS.md 规范
- MCP 配置的声明式风格 → Factory MCP registry
- Hook 机制 → Factory 的 phase gate / lifecycle hook

**可改造成 Factory Skill:**
- Claude 的 MCP 集成模式 → Factory agent 的 MCP tool 分配
- 自定义斜杠命令 → Factory prompt 模板的 CLI 快捷方式

**不能信任:**
- Claude 特有功能（如 computer use）的 skill → 不可直接移植
- Claude-only MCP servers → 需要适配层

#### 2.2.3 Cursor Rules / Project Rules

**Available mechanism:**
- `.cursorrules` (legacy, deprecated)
- `.cursor/rules/*.mdc` (current): 支持 glob pattern 匹配、description、alwaysApply
- Project-specific rules: 与 AGENTS.md 类似但语法不同

**可直接借鉴:**
- Glob pattern 文件匹配 → Factory 的 per-file-type rule scoping
- `alwaysApply: true/false` → Factory 的 mandatory vs. advisory rule
- `.mdc` 格式的结构化元数据 → Factory rule 的 YAML front matter

**可改造成 Factory Skill:**
- Cursor rules 的 "只在特定文件类型生效" → Factory skill 的 file-scope 激活条件
- 项目级 rules 目录 → Factory 的 `governance/rules/` 目录

**不能信任:**
- Cursor 的 AI 特有语法 → 不可直接复制到 AGENTS.md
- 过于宽松的 glob 匹配 → 可能导致规则意外生效

#### 2.2.4 MCP Servers Ecosystem

**Popular / high-quality MCP servers:**

| MCP Server | Category | Trust Level | Factory Use |
|------------|----------|-------------|-------------|
| `@anthropic/mcp-server-filesystem` | Filesystem | VERIFIED | Agent file ops |
| `@anthropic/mcp-server-github` | GitHub | VERIFIED | Research agent, template fetch |
| `@anthropic/mcp-server-postgres` | Database | VERIFIED | DB schema verification |
| `brave-search` | Search | TRUSTED | Research agent |
| `puppeteer` | Browser | TRUSTED | Web testing, screenshot |
| `sequential-thinking` | Reasoning | TRUSTED | Architect agent |
| `memory` | Knowledge | TRUSTED | Knowledge bank backend |
| `context7` | Docs | TRUSTED | Research agent (up-to-date docs) |
| `playwright` (browserbase) | Browser | TRUSTED | UI verification |

**可直接借鉴:**
- MCP 的 tool/resource/prompt 三层模型 → Factory agent tool 分类
- MCP server 的声明式配置 → Factory MCP registry
- `sequential-thinking` 的结构化推理 → Architect agent 的设计流程

**可改造成 Factory Skill:**
- `brave-search` → Research Agent 的搜索后端
- `memory` → Knowledge Bank 的持久化存储
- `context7` → 最新框架文档查询

**不能信任:**
- 未审计的第三方 MCP server（可能有数据泄露风险）
- 需要 API key 且无 billing 控制的 server
- `@modelcontextprotocol/server-everything` 类万能 server

#### 2.2.5 Open-Source Project Templates

| Template | Source | Quality | Factory Relevance |
|----------|--------|---------|-------------------|
| `create-t3-app` | t3-oss | HIGH | fullstack-admin starter 参考 |
| `create-next-app` | Vercel | HIGH | Next.js 项目骨架 |
| `shadcn/ui blocks` | shadcn | HIGH | UI 组件模板库 |
| `v0` | Vercel | MEDIUM | UI 生成参考（AI 味重） |
| `next-enterprise` | Blazity | HIGH | 企业级 Next.js 模板 |
| `bulletproof-react` | Alan N. | HIGH | React 架构参考 |
| `nestjs-realworld` | lujakob | MEDIUM | API 架构参考 |
| `expo-starter` | Expo team | HIGH | mobile-app starter 参考 |

**可直接借鉴:**
- `create-t3-app` 的技术栈决策 → 验证 Factory 的 STACK_DECISION_GUIDE
- `next-enterprise` 的项目结构 → fullstack-admin starter 升级参考
- `bulletproof-react` 的目录规范 → frontend 代码组织

**可改造成 Factory Starter:**
- 提取每个模板的"骨架"作为 starter 变体
- 记录每个模板的"为什么这样设计"作为 knowledge capsule

**不能信任:**
- AI 生成的模板（v0 等）→ 需要人工审核
- 放弃维护的模板 → 记录但不用
- 过于复杂的模板（monorepo + microservices 等）→ 反模式

#### 2.2.6 Big-Tech Engineering Specs

| Source | Key Assets | Factory Reference |
|--------|------------|-------------------|
| Google Engineering Practices | Code review standard, style guides | Verifier agent 的检查清单 |
| Microsoft REST API Guidelines | API design, naming, versioning | Architect agent 的 API contract |
| Alibaba Java Development Manual | DB specification, exception handling | Backend implementer 规范 |
| Airbnb JavaScript Style Guide | React/JS best practices | Frontend implementer 规范 |
| Google SRE Book | Reliability patterns | Drift auditor 参考 |

**可改造成 Factory Rule/Skill:**
- API 设计规范 → Architect agent 的必读材料
- 数据库规范 → Database agent 的约束条件
- 代码规范 → Implementer agent 的 lint 规则

**不能信任:**
- 过时的规范（如 2018 年前的）
- 公司特有的内部工具依赖
- 与 Factory 铁律冲突的（如强制微服务）

#### 2.2.7 Official Framework Examples

| Framework | Example Quality | Factory Integration |
|-----------|----------------|---------------------|
| Next.js examples | HIGH | starter 验证基准 |
| Prisma examples | HIGH | DB schema 模板 |
| Fastify examples | HIGH | API service 模板 |
| Expo examples | MEDIUM | mobile app 参考 |
| Three.js examples | HIGH | 3D scene 模板 |
| Tailwind UI | HIGH | UI 组件参考 |

**策略**: Research Agent 定期抓取官方 examples 的最新版本，更新 Factory 的 knowledge bank。

### 2.3 Ecosystem Summary Matrix

| Source | Direct Reuse | Adapt to Factory | Cannot Trust |
|--------|-------------|-----------------|--------------|
| OpenAI Codex Skills | SKILL.md format, skill-installer, curated list | ~10 skills can be adapted | Unreviewed community skills |
| Claude Agent Skills | CLAUDE.md format, MCP config | MCP integration pattern | Claude-only features |
| Cursor Rules | Glob pattern scoping, .mdc metadata | File-scope skill activation | AI-specific syntax |
| MCP Servers | filesystem, github, postgres, playwright | brave-search, memory, context7, sequential-thinking | Unaudited 3rd party, "everything" servers |
| Open-Source Templates | t3-app, next-enterprise, bulletproof-react | Extracted skeletons as starters | Abandoned/unmaintained templates |
| Big-Tech Specs | API guidelines, DB specs, code style | Rule library for agents | Outdated specs |
| Official Examples | Next.js, Prisma, Fastify, Three.js | Benchmark validation data | — |

### 2.4 External Skill Import Safety Protocol

```
External Skill → Source Check → Content Audit → Script Audit 
→ Network Audit → Scope Audit → Conflict Test → Sandbox Test 
→ Trust Level Assignment → Registry Entry
```

**Trust Levels:**
- **VERIFIED** (绿色): 官方出品或知名安全团队，已通过全部检查
- **TRUSTED** (黄色): 知名社区出品，已通过全部检查但非官方
- **AVAILABLE** (蓝色): 已通过安全检查，但 Factory 尚未充分验证
- **UNVERIFIED** (灰色): 已入库但未完成全部检查
- **BLOCKED** (红色): 安全检查未通过，禁止加载

---


---

## 3. Multi-Agent Collaboration v2

### 3.1 Architecture Overview

R2.0 的 multi-agent 体系从 v1.x 的 "8 roles, ad-hoc spawn" 升级为:

> **常驻 agent 池 + 临时 agent 工厂 + 统一 handoff 总线**

```
┌──────────────────────────────────────────────────────┐
│                  MAIN AGENT (PM)                       │
│         Orchestration, Task Decomposition              │
└──────────┬──────────────────────────────┬─────────────┘
           │                              │
    ┌──────▼──────┐              ┌───────▼───────┐
    │  CONSTANT    │              │   ON-DEMAND    │
    │  AGENT POOL  │              │  AGENT FACTORY │
    └──────┬──────┘              └───────┬───────┘
           │                              │
    ┌──────┴──────────────────────────────┴──────┐
    │           AGENT HANGOFF BUS                 │
    │   (contract, handoff, ledger, receipt)      │
    └─────────────────────────────────────────────┘
```

### 3.2 Agent Classification

#### Category A: Constant Agents (常驻)

These agents persist across sessions and projects.

| Agent ID | Name | Category | Trigger |
|----------|------|----------|---------|
| PM-001 | Router Agent | Management | EVERY project start |
| LIB-001 | Skill Librarian Agent | Knowledge | Skill install/update/audit |
| RSRC-001 | Research Agent | Knowledge | External search requests |

#### Category B: On-Demand Agents (按需)

These agents are spawned per-project, per-phase.

| Agent ID | Name | Category | Trigger |
|----------|------|----------|---------|
| ARCH-001 | Architect Agent | Design | After Router classification |
| IMPL-FE-001 | Frontend Implementer | Implementation | After architecture approval |
| IMPL-BE-001 | Backend Implementer | Implementation | After architecture approval |
| IMPL-DB-001 | Database Implementer | Implementation | After architecture approval |
| VER-001 | Verifier Agent | Quality | After implementation phase |
| SEC-001 | Security Agent | Quality | Before deploy/package |
| INTG-001 | Integrator Agent | Integration | After all workers done |
| AUD-001 | Drift Auditor Agent | Quality | Checkpoints during project |

### 3.3 Detailed Agent Specifications

---

#### AGENT: Router Agent (PM-001)

- **Role ID**: PM-001
- **Category**: Management / Constant
- **Purpose**: Classify project type, match architecture, assess complexity, decide collaboration mode
- **Authority**: Gate all major decisions. Can override specialist recommendations with evidence.

**Inputs:**
- User requirements (natural language)
- Project folder context
- `APP_TYPE_ROUTER.md`
- `STACK_DECISION_GUIDE.md`
- `GLOBAL_CODEX_RULES.md`
- Current Factory state

**Outputs:**
```json
{
  "projectType": "fullstack-admin | content-site | saas-tool | api-service | miniapp | mobile-app | threejs-interactive",
  "complexity": "S | M | L | XL",
  "recommendedMode": "BUILD_LITE | MULTI_AGENT_PRO",
  "multiAgentRecommended": true | false,
  "requiredRoles": ["ARCH-001", "IMPL-BE-001", "..."],
  "risks": ["risk-1", "risk-2"],
  "estimatedFileCount": 25
}
```

**Permissions:**
- Read: All project files, all governance files
- Write: Phase reports, task graph
- Forbidden: Implementation code, architecture docs (owned by Architect)

**Available Tools:**
- `shell_command` (read-only: ls, rg, Get-Content)
- `apply_patch` (governance files only)
- `update_plan`
- `multi_agent_v1__spawn_agent`
- `multi_agent_v1__send_input`

**Loadable Skills:**
- Required: `project-expertise-flow`, `codex-factory`
- Optional: `openai-docs`
- Forbidden: `imagegen`, `spreadsheets`, `documents`, `browser`

**Prohibited:**
- Writing implementation code
- Modifying specialist output directly
- Bypassing Verifier
- Making architecture decisions (owned by Architect)

**Handoff Format:**
```json
{
  "from": "PM-001",
  "to": "ARCH-001",
  "handoffType": "DESIGN_DELEGATION",
  "payload": { /* Router output */ },
  "contractId": "PROJ-{id}-DESIGN-001",
  "ledgerEntry": true
}
```

**Failure Handling:**
- Wrong classification → Escalate to user for confirmation
- Ambiguous project type → List 2-3 candidates, ask user
- Missing key information → Request user clarification
- Recovery: Re-run classification with updated input

---

#### AGENT: Research Agent (RSRC-001)

- **Role ID**: RSRC-001
- **Category**: Knowledge / Constant
- **Purpose**: Search external sources (docs, templates, skills, architecture cases), return structured research packets with provenance
- **Authority**: Provide findings. Cannot implement or decide.

**Inputs:**
- Research question (structured)
- Search scope (official docs, open-source, skills, architecture)
- Version constraints (framework version, date range)

**Outputs:**
```json
{
  "researchPacketId": "RSRC-{timestamp}",
  "question": "What is the latest recommended way to do auth in Next.js 15?",
  "findings": [
    {
      "source": "https://nextjs.org/docs/app/building-your-application/authentication",
      "sourceType": "official_docs",
      "summary": "Next.js recommends...",
      "relevanceScore": 0.95,
      "versionApplicable": ">=15.0.0",
      "retrievedAt": "2026-07-05T12:00:00Z"
    }
  ],
  "recommendations": ["Use NextAuth.js v5", "Consider middleware-based auth"],
  "confidenceLevel": "HIGH",
  "expiresAt": "2026-10-05T12:00:00Z"
}
```

**Permissions:**
- Read: Search results, Factory knowledge bank
- Write: Research packet (governance/knowledge-bank/research/)
- Forbidden: Implementation code, architecture decisions

**Available Tools:**
- `web_search` (external search)
- `list_mcp_resources` (search MCP ecosystem)
- `shell_command` (read-only)
- `multi_agent_v1__spawn_agent` (sub-searches)

**Loadable Skills:**
- Required: `openai-docs`
- Optional: `supabase-postgres-best-practices`
- Forbidden: `imagegen`, `browser`, `documents`, `spreadsheets`

**Prohibited:**
- Writing code
- Making architectural decisions
- Modifying any project file
- Returning unverified claims as facts

**Handoff Format:**
```json
{
  "from": "RSRC-001",
  "to": "PM-001 | ARCH-001 | LIB-001",
  "handoffType": "RESEARCH_PACKET",
  "payload": { /* Research output */ },
  "contractId": "RSRC-{id}",
  "ledgerEntry": true
}
```

**Failure Handling:**
- Search returns nothing → Report empty with "no results found" + expand search scope suggestion
- Conflicting sources → Report all with conflict flag, let consumer decide
- Outdated results → Flag with "may be outdated" warning
- Timeout → Return partial results with timeout marker

---

#### AGENT: Architect Agent (ARCH-001)

- **Role ID**: ARCH-001
- **Category**: Design / On-Demand
- **Purpose**: Design system architecture, define module boundaries, API contracts, database schema, component tree
- **Authority**: Define architecture and tech stack. Reject architecturally unsound implementations.

**Inputs:**
- Router output (project type, complexity)
- User requirements
- Research packets (from RSRC-001)
- Existing codebase (if applicable)

**Outputs:**
```json
{
  "architecture": {
    "techStack": { "frontend": "...", "backend": "...", "database": "..." },
    "moduleTree": ["module-a", "module-b"],
    "componentDiagram": "mermaid or description"
  },
  "apiEndpoints": [
    { "method": "GET", "path": "/api/users", "auth": "required", "description": "..." }
  ],
  "dbSchema": {
    "tables": [
      { "name": "users", "columns": [...], "relations": [...] }
    ]
  },
  "pageTree": ["/login", "/dashboard", "/users", "/users/[id]"],
  "designDecisions": [
    { "decision": "Use Prisma over Drizzle", "reason": "Better migration tooling for this complexity" }
  ],
  "firstSliceScope": "Login + User CRUD"
}
```

**Permissions:**
- Read: All project files, governance files
- Write: Design docs only (architecture/, api/, db/)
- Forbidden: Implementation code

**Available Tools:**
- `shell_command` (read, design doc writes)
- `apply_patch` (design docs only)
- `multi_agent_v1__spawn_agent` (sub-research)

**Loadable Skills:**
- Required: `codex-factory`, `product-architecture`, `backend-api-design`, `database-schema-design`
- Optional: `openai-docs`
- Forbidden: `imagegen`, `browser`, `spreadsheets`

**Prohibited:**
- Writing production/implementation code
- Modifying running system
- Overriding PM gate
- Designing beyond first-slice scope unless explicitly requested

**Handoff Format:**
```json
{
  "from": "ARCH-001",
  "to": "PM-001",
  "handoffType": "ARCHITECTURE_PROPOSAL",
  "payload": { /* Architecture output */ },
  "contractId": "PROJ-{id}-ARCH-001",
  "requiresApproval": true,
  "ledgerEntry": true
}
```

**Failure Handling:**
- Unclear requirements → Request clarification from PM
- Conflicting constraints → Escalate to PM with options
- Unknown tech → Request research from RSRC-001
- Over-engineering detected → Self-correct per anti-overengineering rules

---

#### AGENT: Skill Librarian Agent (LIB-001)

- **Role ID**: LIB-001
- **Category**: Knowledge / Constant
- **Purpose**: Manage skill registry, import/adapt external skills, version skills, assign trust levels, maintain knowledge bank
- **Authority**: Gate all skill imports. Assign trust levels. Deprecate outdated skills.

**Inputs:**
- Skill import request (source URI, skill name)
- Skill audit request
- Knowledge capsule write request

**Outputs:**
```json
{
  "skillId": "SKILL-{uuid}",
  "name": "nextjs-auth-patterns",
  "version": "2.1.0",
  "trustLevel": "VERIFIED | TRUSTED | AVAILABLE | UNVERIFIED | BLOCKED",
  "source": "https://github.com/...",
  "importedAt": "2026-07-05T12:00:00Z",
  "lastAuditedAt": "2026-07-05T12:00:00Z",
  "checksPassed": ["source_check", "content_audit", "script_audit", "conflict_test"],
  "dependencies": ["skill-x@1.0.0"],
  "applicableProjectTypes": ["fullstack-admin", "saas-tool"],
  "status": "ACTIVE | DEPRECATED | SUPERSEDED"
}
```

**Permissions:**
- Read: All skill files, knowledge bank, governance
- Write: Skill registry, knowledge bank, skill files
- Forbidden: Project implementation files

**Available Tools:**
- `shell_command`
- `apply_patch` (skills/ and governance/ only)
- `multi_agent_v1__spawn_agent` (audit delegation)
- `list_mcp_resources` (discover new skills)

**Loadable Skills:**
- Required: `skill-creator`, `skill-installer`, `codex-factory`
- Optional: `openai-docs`
- Forbidden: `imagegen`, `browser`, `spreadsheets`

**Prohibited:**
- Auto-importing unverified skills
- Modifying verified skills without version bump
- Deleting skill history (only deprecate/supersede)
- Bypassing security audit

**Handoff Format:**
```json
{
  "from": "LIB-001",
  "to": "PM-001 | RSRC-001",
  "handoffType": "SKILL_READY | SKILL_BLOCKED | KNOWLEDGE_CAPSULE",
  "payload": { /* Skill info or capsule */ },
  "contractId": "SKILL-{id}",
  "ledgerEntry": true
}
```

**Failure Handling:**
- Import failed security check → BLOCK, report to PM
- Version conflict → Report conflict, suggest resolution
- Skill deprecated → Mark SUPERSEDED, suggest replacement
- Knowledge capsule corrupted → Request resubmission

---

#### AGENT: Frontend Implementer (IMPL-FE-001)

- **Role ID**: IMPL-FE-001
- **Category**: Implementation / On-Demand
- **Purpose**: Implement frontend modules per Architect spec and contract
- **Authority**: Implement assigned frontend scope. Cannot change API contract.

**Inputs:**
- Architect output (page tree, component specs, API contract)
- Agent contract (scope boundaries)
- Starter template (if applicable)
- UI skill profiles

**Outputs:**
```json
{
  "files": ["src/app/login/page.tsx", "src/components/UserTable.tsx", "..."],
  "pagesImplemented": ["/login", "/dashboard", "/users"],
  "statesHandled": ["loading", "empty", "error", "success"],
  "testResults": { "pass": 12, "fail": 0, "skip": 0 },
  "knownCaveats": ["Dark mode not yet implemented"],
  "contractCompliance": true
}
```

**Permissions:**
- Read: All project files, Architect docs, API contract
- Write: Frontend source files only (contract-defined paths)
- Forbidden: Backend code, database schema, API routes

**Available Tools:**
- `shell_command` (npm, npx, dev server)
- `apply_patch` (assigned frontend paths only)
- `mcp__node_repl__js` (browser testing)

**Loadable Skills:**
- Required: `browser`, `codex-factory`, `frontend-ui-system`
- Optional: `imagegen` (for placeholder images)
- Forbidden: `supabase-postgres-best-practices`, `pdf`, `spreadsheets`

**Prohibited:**
- Writing outside assigned paths
- Modifying API contracts
- Changing architecture decisions
- Accessing other agent working copies

**Handoff Format:**
```json
{
  "from": "IMPL-FE-001",
  "to": "INTG-001",
  "handoffType": "IMPLEMENTATION_COMPLETE",
  "payload": { /* FE output */ },
  "contractId": "PROJ-{id}-FE-001",
  "ledgerEntry": true
}
```

**Failure Handling:**
- Contract cannot be fulfilled → Notify Architect + Integrator
- Dependency issue → Report with specific error
- Scope violation risk → Pause and escalate
- Test failure → Self-fix up to 3 attempts, then escalate

---

#### AGENT: Backend Implementer (IMPL-BE-001)

- **Role ID**: IMPL-BE-001
- **Category**: Implementation / On-Demand
- **Purpose**: Implement backend API, business logic, middleware per Architect spec
- **Authority**: Implement assigned backend scope. Cannot change API contract.

**Inputs:**
- Architect output (API contract, DB schema, auth design)
- Agent contract (scope boundaries)
- Starter template

**Outputs:**
```json
{
  "files": ["src/routes/users.ts", "src/middleware/auth.ts", "..."],
  "endpointsImplemented": ["GET /api/users", "POST /api/users", "..."],
  "middlewareApplied": ["auth", "validation", "error-handling"],
  "testResults": { "pass": 20, "fail": 0, "skip": 0 },
  "knownCaveats": [],
  "contractCompliance": true
}
```

**Permissions:**
- Read: All project files, Architect docs, API contract
- Write: Backend source files only (contract-defined paths)
- Forbidden: Frontend code, database migration decisions (owned by DB agent)

**Available Tools:**
- `shell_command` (npm, npx, test runners)
- `apply_patch` (assigned backend paths only)

**Loadable Skills:**
- Required: `codex-factory`, `backend-api-design`, `auth-permission-security`
- Optional: `supabase-postgres-best-practices`
- Forbidden: `browser`, `imagegen`, `presentations`

**Prohibited:**
- Writing outside assigned paths
- Modifying API contracts
- Skipping auth middleware
- Hardcoding secrets

**Handoff Format:**
```json
{
  "from": "IMPL-BE-001",
  "to": "INTG-001",
  "handoffType": "IMPLEMENTATION_COMPLETE",
  "payload": { /* BE output */ },
  "contractId": "PROJ-{id}-BE-001",
  "ledgerEntry": true
}
```

**Failure Handling:**
- Contract cannot be fulfilled → Notify Architect + Integrator
- Database migration conflict → Escalate to DB agent
- Auth flow broken → Escalate to Security agent + Architect

---

#### AGENT: Verifier Agent (VER-001)

- **Role ID**: VER-001
- **Category**: Quality / On-Demand
- **Purpose**: Verify implementation against contracts, run tests, check negative controls
- **Authority**: Reject non-compliant implementations. Cannot modify source.

**Inputs:**
- Implementer outputs (FE + BE + DB)
- Agent contracts
- Verifier schema (what to check)
- Negative control definitions

**Outputs:**
```json
{
  "verifierVerdict": "PASS | FAIL | PARTIAL",
  "testResults": {
    "unit": { "pass": 45, "fail": 2, "skip": 0 },
    "integration": { "pass": 15, "fail": 0, "skip": 0 },
    "e2e": { "pass": 5, "fail": 0, "skip": 0 }
  },
  "contractValidations": [
    { "contractId": "API-001", "compliant": true },
    { "contractId": "UI-001", "compliant": false, "reason": "Missing error state on login form" }
  ],
  "negativeControls": [
    { "controlId": "NEGC-001", "description": "Invalid login should not crash", "passed": true },
    { "controlId": "NEGC-002", "description": "Empty submission should show validation", "passed": true }
  ],
  "gaps": ["No loading state on dashboard"],
  "failureAttribution": [
    { "agentId": "IMPL-FE-001", "file": "src/app/login/page.tsx", "issue": "Missing error state" }
  ]
}
```

**Permissions:**
- Read: All project files
- Write: Verification reports only
- Forbidden: Implementation code, test fixture tampering

**Available Tools:**
- `shell_command` (test runners: vitest, jest, playwright, curl)
- `apply_patch` (test files only)
- `mcp__node_repl__js` (browser testing)

**Loadable Skills:**
- Required: `codex-factory`, `webapp-preview-testing`
- Optional: `browser`
- Forbidden: `imagegen`, `documents`, `spreadsheets`, `pdf`, `presentations`

**Prohibited:**
- Modifying implementation code
- Faking test results
- Skipping negative controls
- Marking PASS with unresolved failures

**Handoff Format:**
```json
{
  "from": "VER-001",
  "to": "INTG-001",
  "handoffType": "VERIFICATION_REPORT",
  "payload": { /* Verifier output */ },
  "contractId": "PROJ-{id}-VER-001",
  "ledgerEntry": true
}
```

**Failure Handling:**
- Test failure → Attribute to specific agent + file
- False PASS detected → Re-run with tighter checks
- Corrupt test fixture → Report, request fixture rebuild
- Cannot verify (missing tool) → Report gap, suggest manual verification

---

#### AGENT: Security Agent (SEC-001)

- **Role ID**: SEC-001
- **Category**: Quality / On-Demand
- **Purpose**: Audit for secrets, security vulnerabilities, deployment readiness
- **Authority**: Block deployment if security issues found. Cannot modify source.

**Inputs:**
- All project files
- Gate configuration (what to check)
- Security rule library

**Outputs:**
```json
{
  "secretsFound": [],
  "vulnerabilities": [
    { "severity": "HIGH", "file": "src/routes/admin.ts", "issue": "No server-side auth check", "line": 42 }
  ],
  "deployReadiness": false,
  "gateVerdict": "BLOCKED",
  "recommendations": ["Add auth middleware to /api/admin/* routes"],
  "checksRun": ["secret_scan", "auth_audit", "sql_injection_check", "xss_check", "csrf_check"]
}
```

**Permissions:**
- Read: All project files
- Write: Security reports only
- Forbidden: Modifying source, printing secrets

**Available Tools:**
- `shell_command` (grep, rg for patterns)
- `apply_patch` (security reports only)

**Loadable Skills:**
- Required: `codex-factory`, `auth-permission-security`
- Optional: `openai-docs`
- Forbidden: `browser`, `imagegen`, `documents`, `spreadsheets`

**Prohibited:**
- Modifying source code
- Printing secrets in output
- Executing deployment
- Marking PASS with unresolved HIGH severity

**Handoff Format:**
```json
{
  "from": "SEC-001",
  "to": "INTG-001",
  "handoffType": "SECURITY_REPORT",
  "payload": { /* Security output */ },
  "contractId": "PROJ-{id}-SEC-001",
  "ledgerEntry": true
}
```

**Failure Handling:**
- Secret found → BLOCK immediately, report (do not print secret)
- False positive → Document as known false positive, PASS with note
- Cannot scan (binary file) → Report as unscanned

---

#### AGENT: Integrator Agent (INTG-001)

- **Role ID**: INTG-001
- **Category**: Integration / On-Demand
- **Purpose**: Merge agent outputs, validate contracts, produce final deliverable, attribute failures
- **Authority**: Sole final merger. Can reject any agent output. Cannot introduce new features.

**Inputs:**
- All agent outputs (FE, BE, DB, VER, SEC)
- Agent contracts
- Handoff ledger

**Outputs:**
```json
{
  "integratorVerdict": "ACCEPT | REJECT",
  "mergedOutputs": ["src/", "prisma/", "package.json", "..."],
  "contractValidations": [
    { "contractId": "PROJ-{id}-FE-001", "compliant": true },
    { "contractId": "PROJ-{id}-BE-001", "compliant": true },
    { "contractId": "PROJ-{id}-VER-001", "compliant": false }
  ],
  "failureAttribution": [
    { "agentId": "IMPL-FE-001", "failure": "Missing error state", "recommendation": "Add error boundary" }
  ],
  "rejectedOutputs": [],
  "finalHandoff": "C:\\Codex_App_Factory\\projects\\{projectId}\\"
}
```

**Permissions:**
- Read: All agent outputs, contracts, handoff ledger
- Write: Integration layer, final output directory
- Forbidden: Introducing new features, silently accepting rejected output

**Available Tools:**
- `shell_command` (merge, copy, verify)
- `apply_patch` (integration only)

**Loadable Skills:**
- Required: `codex-factory`
- Optional: none
- Forbidden: `imagegen`

**Prohibited:**
- Worker output bypassing Integrator review
- Silent accept of rejected output
- Introducing new features
- Omitting failure attribution

**Handoff Format:**
```json
{
  "from": "INTG-001",
  "to": "PM-001 (final)",
  "handoffType": "FINAL_DELIVERABLE",
  "payload": { /* Integrator output */ },
  "contractId": "PROJ-{id}-INTG-001",
  "ledgerEntry": true,
  "finalVerdict": "ACCEPT | REJECT"
}
```

**Failure Handling:**
- Agent output rejected → Attribute, report, do not merge
- Anonymous output → Auto-REJECT
- Contract validation failed → Return to agent for rework
- Merge conflict → Resolve per INTEGRATOR_PROTOCOL.md

---

#### AGENT: Drift Auditor Agent (AUD-001)

- **Role ID**: AUD-001
- **Category**: Quality / On-Demand
- **Purpose**: Detect architecture drift, skill misuse, evidence gaps, responsibility gaps. Read-only.
- **Authority**: Flag drift and gaps. Cannot fix issues directly.

**Inputs:**
- Project Intent Contract
- Architecture Contract
- Feature Contract
- Non-goal Contract
- Current project state (code, docs, config)
- Agent handoff ledger

**Outputs:**
```json
{
  "driftReport": {
    "driftDetected": true,
    "drifts": [
      {
        "type": "COMPLEXITY_COLLAPSE",
        "description": "Architecture specified RBAC with 3 roles, found only 1 role implemented",
        "severity": "HIGH",
        "affectedContracts": ["AUTH-001"],
        "recommendation": "Implement remaining 2 roles or update contract"
      },
      {
        "type": "SCOPE_CREEP",
        "description": "Added payment module not in original scope",
        "severity": "MEDIUM",
        "affectedContracts": ["SCOPE-001"],
        "recommendation": "Document as intentional expansion or remove"
      }
    ]
  },
  "gapInventory": [
    { "gap": "No error handling on API routes", "severity": "HIGH" }
  ],
  "roleComplianceAudit": {
    "compliant": false,
    "violations": [
      { "agentId": "IMPL-FE-001", "violation": "Wrote to backend paths" }
    ]
  },
  "evidenceChainAudit": {
    "intact": true,
    "missingLinks": []
  }
}
```

**Permissions:**
- Read: All project files, all contracts, agent ledger
- Write: Drift reports only
- Forbidden: Writing code, marking PASS, fixing issues

**Available Tools:**
- `shell_command` (read-only analysis)
- `apply_patch` (drift reports only)

**Loadable Skills:**
- Required: `codex-factory`
- Optional: none
- Forbidden: `imagegen`, `browser`, `documents`, `spreadsheets`, `pdf`

**Prohibited:**
- Writing code
- Marking PASS
- Fixing issues
- Modifying contracts

**Handoff Format:**
```json
{
  "from": "AUD-001",
  "to": "PM-001",
  "handoffType": "DRIFT_REPORT",
  "payload": { /* Auditor output */ },
  "contractId": "PROJ-{id}-AUD-001",
  "ledgerEntry": true,
  "requiresAction": true | false
}
```

**Failure Handling:**
- Drift detected → Flag, report severity, do not fix
- Evidence chain broken → Escalate to PM
- Contract missing → Report gap, request contract creation

---

### 3.4 Agent Lifecycle

```
CREATED → ACTIVATED → WORKING → HANDOFF_READY → REVIEWED → CLOSED
                                         │
                                         ├→ REJECTED → REWORK → WORKING
                                         └→ ACCEPTED → CLOSED
```

### 3.5 Handoff Bus Protocol

All inter-agent communication goes through the **Handoff Bus**:

1. Agent produces output → Signs with agent ID + contract ID
2. Output enters handoff bus → Ledger entry created
3. Target agent (or Integrator) picks up → Validates against contract
4. ACCEPT → Merge / next phase
5. REJECT → Return to source agent with reason

**Ledger Entry Format:**
```json
{
  "ledgerId": "LEDGER-{uuid}",
  "timestamp": "ISO 8601",
  "fromAgent": "PM-001",
  "toAgent": "ARCH-001",
  "handoffType": "DESIGN_DELEGATION",
  "contractId": "PROJ-{id}-DESIGN-001",
  "status": "PENDING | ACCEPTED | REJECTED",
  "rejectionReason": null
}
```

### 3.6 Collaboration Modes

| Mode | Agents | When |
|------|--------|------|
| BUILD_LITE | PM only | S complexity, < 10 files |
| BUILD_STANDARD | PM + ARCH + IMPL(x1) + VER + INTG | M complexity |
| BUILD_PRO | PM + ARCH + IMPL-FE + IMPL-BE + IMPL-DB + VER + SEC + INTG | L complexity |
| BUILD_ENTERPRISE | All agents + AUD at checkpoints | XL complexity |
| FACTORY_MAINTENANCE | PM + LIB + RSRC (constant agents) | Skill/KB maintenance |

---


---

## 4. Skill Bank / Knowledge Bank

### 4.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    SKILL BANK                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │ Registry │  │ Import   │  │ Adapt    │               │
│  │          │  │ Pipeline │  │ Engine   │               │
│  └──────────┘  └──────────┘  └──────────┘               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │ Version  │  │ Trust    │  │ Deprecate│               │
│  │ Manager  │  │ Tiers    │  │ Engine   │               │
│  └──────────┘  └──────────┘  └──────────┘               │
├─────────────────────────────────────────────────────────┤
│                  KNOWLEDGE BANK                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │Knowledge │  │ Domain   │  │ External │               │
│  │Capsules  │  │Playbooks │  │Docs Index│               │
│  └──────────┘  └──────────┘  └──────────┘               │
│  ┌──────────┐  ┌──────────┐                              │
│  │ Failure  │  │ Pattern  │                              │
│  │ Lessons  │  │ Library  │                              │
│  └──────────┘  └──────────┘                              │
└─────────────────────────────────────────────────────────┘
```

### 4.2 Skill Registry

**Location:** `governance/skill-bank/registry.json`

```json
{
  "skills": [
    {
      "skillId": "SKILL-{uuid}",
      "name": "nextjs-auth-patterns",
      "displayName": "Next.js Authentication Patterns",
      "version": "2.1.0",
      "trustLevel": "VERIFIED",
      "source": {
        "type": "external_adapted",
        "originUrl": "https://github.com/vercel/next.js/examples/auth",
        "importedAt": "2026-07-05T12:00:00Z",
        "importedBy": "LIB-001"
      },
      "category": "auth",
      "applicableProjectTypes": ["fullstack-admin", "saas-tool", "api-service"],
      "requiredByRoles": ["ARCH-001", "IMPL-BE-001"],
      "dependencies": [],
      "conflicts": ["skill-legacy-auth"],
      "filePath": "skills/nextjs-auth-patterns/",
      "checksum": "sha256:abc123...",
      "status": "ACTIVE",
      "lastAuditedAt": "2026-07-05T12:00:00Z",
      "deprecationNotice": null,
      "supersededBy": null
    }
  ],
  "totalSkills": 42,
  "byTrustLevel": {
    "VERIFIED": 15,
    "TRUSTED": 18,
    "AVAILABLE": 7,
    "UNVERIFIED": 2,
    "BLOCKED": 0
  }
}
```

### 4.3 Skill Import Pipeline

```
Request → Source Check → Content Audit → Script Audit 
→ Network Audit → Scope Audit → Conflict Test 
→ Sandbox Test → Trust Level Assignment → Registry Entry
```

**Import sources:**
1. **Curated List** (skill-installer built-in)
2. **GitHub Repo** (public or private)
3. **Local Path** (custom skill)
4. **MCP Server** (wrapped as skill)
5. **Prompt Template** (converted to skill)

**Check details:**

| Check | Description | Auto/Manual |
|-------|-------------|-------------|
| Source Check | Verify origin repo/author reputation | Auto (GitHub API) |
| Content Audit | Read SKILL.md, check for rule conflicts | Auto + Manual |
| Script Audit | Audit all executable scripts | Manual |
| Network Audit | Check if skill requires external network | Auto |
| Scope Audit | Check file write scope | Auto |
| Conflict Test | Test against existing skills | Auto |
| Sandbox Test | Trial run in isolated environment | Auto |

### 4.4 Skill Adaptation

External skills often need adaptation before they can be used in Factory:

**Adaptation patterns:**

| Pattern | Description | Example |
|---------|-------------|---------|
| WRAP | Wrap external skill with Factory-compatible layer | MCP server → Factory skill |
| EXTRACT | Extract relevant portions, discard rest | Large skill → focused sub-skills |
| MERGE | Merge multiple skills into one | 3 auth skills → 1 comprehensive auth skill |
| TRANSLATE | Convert from one format to SKILL.md | Cursor rules → SKILL.md |
| SPLIT | Split monolithic skill into focused skills | "fullstack-helper" → FE/BE/DB skills |

### 4.5 Skill Versioning

**Semantic versioning:** MAJOR.MINOR.PATCH

- **MAJOR**: Breaking changes (incompatible with previous version)
- **MINOR**: New feature, backward compatible
- **PATCH**: Bug fix, backward compatible

**Version history:** Each skill keeps a `CHANGELOG.md` in its directory.

**Upgrade policy:**
- VERIFIED/TRUSTED skills: Auto-notify of new versions, manual upgrade
- AVAILABLE skills: Manual check + upgrade
- BLOCKED skills: No upgrade tracking

### 4.6 Trust Levels

| Level | Icon | Criteria | Auto-Load | Use in Production |
|-------|------|----------|-----------|-------------------|
| VERIFIED | 🟢 | Official source OR audited by security team, all checks passed | Yes | Yes |
| TRUSTED | 🟡 | Known community source, all checks passed | Yes (with warning) | With review |
| AVAILABLE | 🔵 | All security checks passed, not yet validated in Factory | No | With caution |
| UNVERIFIED | ⬜ | In registry but not all checks complete | No | No |
| BLOCKED | 🔴 | Failed security check | No | No |

### 4.7 Knowledge Capsules

Knowledge capsules are structured, reusable knowledge units:

```json
{
  "capsuleId": "CAP-{uuid}",
  "title": "Why Prisma over Drizzle for L+ complexity projects",
  "domain": "database-orm",
  "type": "DESIGN_DECISION | FAILURE_LESSON | PATTERN | TIP | GOTCHA",
  "content": "Prisma provides better migration tooling, relation management, and studio UI for complex projects...",
  "source": {
    "projectId": "PROJ-042",
    "agentId": "ARCH-001",
    "date": "2026-06-15"
  },
  "tags": ["prisma", "drizzle", "orm", "decision"],
  "applicableProjectTypes": ["fullstack-admin", "saas-tool"],
  "trustLevel": "VERIFIED",
  "relatedCapsules": ["CAP-015", "CAP-023"],
  "expiresAt": null
}
```

### 4.8 Domain Playbooks

Playbooks are collections of knowledge capsules organized by domain:

| Playbook | Domain | Key Topics |
|----------|--------|------------|
| `miniapp-playbook` | 小程序开发 | 微信登录、OPENID安全、分包策略、审核规范 |
| `ecommerce-playbook` | 电商系统 | 订单状态机、库存扣减、支付幂等、对账 |
| `distributed-playbook` | 分布式架构 | 服务拆分、消息队列、最终一致性、降级 |
| `security-playbook` | 安全审计 | OWASP Top 10、密钥管理、权限模型、审计日志 |
| `refactor-playbook` | 项目重构 | 重构策略、数据迁移、灰度发布、回滚方案 |
| `fullstack-playbook` | 全栈开发 | Next.js模式、API设计、DB优化、部署方案 |
| `mobile-playbook` | 移动开发 | Expo模式、推送通知、离线缓存、应用上架 |

### 4.9 External Docs Index

An index of external documentation sources kept up-to-date by the Research Agent:

```json
{
  "docs": [
    {
      "name": "Next.js App Router",
      "url": "https://nextjs.org/docs/app",
      "category": "framework",
      "lastChecked": "2026-07-05",
      "currentVersion": "16.x",
      "breakingChangesSince": "15.0",
      "relevantProjectTypes": ["fullstack-admin", "saas-tool", "content-site"]
    }
  ]
}
```

### 4.10 Failure Lessons

Every project failure is recorded as a structured lesson:

```json
{
  "lessonId": "FAIL-{uuid}",
  "title": "小程序 wx.request 不支持 async/await 直接返回",
  "domain": "miniapp",
  "severity": "MEDIUM",
  "symptom": "API 调用返回 undefined",
  "rootCause": "wx.request 使用 callback 模式，未正确封装为 Promise",
  "solution": "使用 wx.request 的 success/fail 回调或封装的 promisify 工具",
  "detectedBy": "VER-001",
  "projectId": "PROJ-051",
  "date": "2026-07-03",
  "tags": ["miniapp", "async", "api", "gotcha"],
  "prevention": "在 miniapp-playbook 中加入异步处理模式说明"
}
```

### 4.11 Bank Maintenance

| Task | Frequency | Agent | 
|------|-----------|-------|
| Skill audit | Weekly | LIB-001 |
| Trust level review | Monthly | LIB-001 |
| Deprecation sweep | Monthly | LIB-001 |
| Docs index update | Weekly | RSRC-001 |
| Failure lesson review | Per project | PM-001 |
| Playbook update | On new capsule | LIB-001 |
| Conflict check | On import | LIB-001 (auto) |

---

## 5. Research / Search Agent

### 5.1 Purpose

The Research Agent (RSRC-001) is a **constant agent** that provides up-to-date external information to other agents. It is the sole gateway for external search in the Factory.

### 5.2 Architecture

```
┌──────────────────────────────────────────────┐
│              RESEARCH AGENT (RSRC-001)         │
│                                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Query    │  │ Source   │  │ Result   │    │
│  │ Parser   │  │ Router   │  │ Synthesizer│   │
│  └──────────┘  └──────────┘  └──────────┘    │
│                                                │
│  Sources:                                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Web      │  │ MCP      │  │ Skill    │    │
│  │ Search   │  │ Ecosystem│  │ Registry │    │
│  └──────────┘  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ Docs     │  │ GitHub   │  │ Knowledge│    │
│  │ Index    │  │ Search   │  │ Bank     │    │
│  └──────────┘  └──────────┘  └──────────┘    │
│                                                │
│  Output: Research Packet (with provenance)     │
└──────────────────────────────────────────────┘
```

### 5.3 Search Types

| Type | Description | Sources | Freshness |
|------|-------------|---------|-----------|
| DOCS_SEARCH | Search official documentation | Official docs, docs index | Must be latest |
| SKILL_SEARCH | Search existing skills (internal + external) | Skill registry, MCP ecosystem, Codex marketplace | Weekly |
| TEMPLATE_SEARCH | Search open-source project templates | GitHub, npm, create-* tools | Monthly |
| ARCHITECTURE_SEARCH | Search architecture case studies | Tech blogs, engineering blogs, conference talks | As needed |
| VERSION_CHECK | Check latest framework versions | npm registry, GitHub releases | Real-time |
| BEST_PRACTICE | Search best practices for specific pattern | Official docs, community guides, Stack Overflow | As needed |

### 5.4 Source Priority

```
1. Official documentation (highest trust)
2. Official examples / starters
3. Well-known community resources (e.g., Next.js conf talks)
4. GitHub repos with > 1000 stars
5. Stack Overflow (accepted answer, > 10 votes)
6. Blog posts (author reputation considered)
7. AI-generated content (lowest trust, flagged)
```

### 5.5 Research Packet Format

```json
{
  "packetId": "RSRC-20260705-001",
  "query": {
    "question": "What is the recommended way to handle auth in Next.js 16 App Router?",
    "type": "BEST_PRACTICE",
    "requestedBy": "ARCH-001",
    "context": "Building fullstack-admin, L complexity, PostgreSQL backend"
  },
  "findings": [
    {
      "id": "FIND-001",
      "source": {
        "url": "https://nextjs.org/docs/app/building-your-application/authentication",
        "type": "official_docs",
        "trustLevel": "VERIFIED"
      },
      "summary": "Next.js recommends using middleware for route protection and Server Components for session checks...",
      "keyPoints": [
        "Use middleware.ts for route-level protection",
        "Use Server Components for data-level auth checks",
        "Avoid client-side only auth guards"
      ],
      "versionApplicable": ">=15.0.0",
      "retrievedAt": "2026-07-05T12:00:00Z"
    }
  ],
  "synthesis": {
    "recommendation": "Use NextAuth.js v5 with middleware-based route protection and Server Component session checks",
    "confidence": "HIGH",
    "alternatives": ["Clerk (managed)", "Lucia (lightweight)"],
    "caveats": ["OAuth setup requires provider configuration", "Middleware cannot access database directly"]
  },
  "meta": {
    "totalSourcesChecked": 5,
    "relevantSources": 3,
    "expiresAt": "2026-10-05T12:00:00Z",
    "confidence": "HIGH"
  }
}
```

### 5.6 Research Packet Review Protocol

Before a research packet enters the Knowledge Bank, it must pass review:

1. **Auto-Check**: Source URLs are accessible, no 404s
2. **Freshness Check**: Information is not older than expiration threshold
3. **Conflict Check**: No contradiction with existing VERIFIED knowledge
4. **LIB-001 Review**: For TRUSTED-level findings
5. **PM Review**: For findings that affect architecture decisions

### 5.7 Rate Limits & Cost Control

| Constraint | Value | Reason |
|------------|-------|--------|
| Max searches per project | 20 | Prevent research-loop |
| Max searches per agent per phase | 5 | Prevent analysis paralysis |
| Cache TTL for docs search | 7 days | Official docs don''t change daily |
| Cache TTL for version check | 1 day | npm releases can happen anytime |
| Cache TTL for template search | 30 days | Templates change slowly |

---

## 6. Architecture Drift Control

### 6.1 Purpose

Projects naturally drift from their original intent. Drift Control provides a systematic way to detect, report, and decide on deviations.

### 6.2 Contract System

#### 6.2.1 Project Intent Contract (PIC)

Created at project start. Captures WHY the project exists.

```json
{
  "contractId": "PIC-{projectId}",
  "createdAt": "2026-07-05T12:00:00Z",
  "createdBy": "PM-001",
  "projectName": "医师系统小程序",
  "projectType": "miniapp",
  "complexity": "M",
  "coreProblem": "管理医师排班和患者预约",
  "targetUsers": ["医师", "患者", "管理员"],
  "successCriteria": [
    "医师可以查看和管理自己的排班",
    "患者可以预约可用时段",
    "管理员可以管理医师和查看统计"
  ],
  "nonGoals": [
    "不支持在线支付",
    "不支持多语言",
    "不支持视频问诊",
    "第一版不做消息推送"
  ],
  "constraints": [
    "微信小程序原生框架",
    "服务端 Node.js + Fastify",
    "数据库 PostgreSQL",
    "密钥全部在服务端"
  ]
}
```

#### 6.2.2 Architecture Contract (AC)

Created by Architect. Captures HOW the system is built.

```json
{
  "contractId": "AC-{projectId}",
  "createdAt": "2026-07-05T12:00:00Z",
  "createdBy": "ARCH-001",
  "techStack": {
    "frontend": "微信原生小程序",
    "backend": "Node.js + Fastify",
    "database": "PostgreSQL",
    "orm": "Prisma"
  },
  "moduleBoundaries": [
    { "module": "auth", "responsibility": "登录/注册/权限", "owner": "IMPL-BE-001" },
    { "module": "schedule", "responsibility": "排班管理", "owner": "IMPL-BE-001" },
    { "module": "appointment", "responsibility": "预约管理", "owner": "IMPL-BE-001" },
    { "module": "patient-ui", "responsibility": "患者端页面", "owner": "IMPL-FE-001" },
    { "module": "doctor-ui", "responsibility": "医师端页面", "owner": "IMPL-FE-001" }
  ],
  "apiContracts": [...],
  "dbSchemaVersion": "1.0.0",
  "authModel": "微信登录 + JWT",
  "deploymentTarget": "本地开发"
}
```

#### 6.2.3 Feature Contract (FC)

Per-feature contract. Captures WHAT each feature does.

```json
{
  "contractId": "FC-{projectId}-AUTH-001",
  "feature": "用户认证",
  "userStory": "作为患者，我希望用微信登录，这样我不需要记住额外密码",
  "acceptanceCriteria": [
    "点击微信登录按钮后跳转微信授权",
    "授权后自动创建/绑定账号",
    "登录态在会话期间保持",
    "未登录用户无法访问需要登录的页面"
  ],
  "states": ["loading (授权中)", "error (授权失败)", "success (登录成功)", "empty (未登录)"],
  "apiEndpoints": ["POST /api/auth/wechat-login", "GET /api/auth/me"],
  "uiComponents": ["登录按钮", "授权中loading", "授权失败提示"]
}
```

#### 6.2.4 Non-Goal Contract (NGC)

Negative contract. Captures what the project explicitly WILL NOT do.

```json
{
  "contractId": "NGC-{projectId}",
  "nonGoals": [
    { "item": "在线支付", "reason": "第一版不需要", "riskIfAdded": "增加支付资质、安全审计、财务对账复杂度" },
    { "item": "视频问诊", "reason": "超出MVP范围", "riskIfAdded": "需要WebRTC、媒体服务器、带宽规划" },
    { "item": "消息推送", "reason": "微信模板消息需要认证服务号", "riskIfAdded": "需要额外的微信认证流程" },
    { "item": "多语言", "reason": "目标用户都是中文用户", "riskIfAdded": "增加i18n基础设施和维护成本" }
  ]
}
```

### 6.3 Drift Checkpoints

Checkpoints are triggered at specific project milestones:

| Checkpoint | When | Auditor |
|------------|------|---------|
| CP-ARCH | After architecture design | AUD-001 |
| CP-MID | Mid-implementation (50% features) | AUD-001 |
| CP-PREVER | Before verification phase | AUD-001 |
| CP-PREDEPLOY | Before deploy/package | AUD-001 |
| CP-POSTMORTEM | After project completion | AUD-001 |

### 6.4 Drift Types

| Type | Description | Severity |
|------|-------------|----------|
| COMPLEXITY_COLLAPSE | Architecture simplified beyond contract (e.g., 3 roles → 1 role) | HIGH |
| COMPLEXITY_EXPLOSION | Unnecessary complexity added (e.g., microservices for S project) | HIGH |
| SCOPE_CREEP | Features added beyond original scope | MEDIUM |
| SCOPE_SHRINK | Core features dropped without documentation | HIGH |
| TECH_STACK_DRIFT | Technology changed from contract (e.g., PostgreSQL → SQLite) | HIGH |
| CONTRACT_VIOLATION | Implementation doesn''t match API contract | CRITICAL |
| NONGOAL_VIOLATION | Non-goal feature implemented | MEDIUM |
| ROLE_DRIFT | Agent operating outside its scope | MEDIUM |
| KNOWLEDGE_LOSS | Design decision rationale lost | LOW |

### 6.5 Drift Report Format

See AUD-001 output spec in Section 3.

### 6.6 Drift Resolution Protocol

```
Drift Detected → Drift Report → PM Review → Decision:
  1. ACCEPT_DRIFT → Update contract (intentional change)
  2. REJECT_DRIFT → Revert to contract (implementation error)
  3. DEFER → Document, address in next phase
  4. ESCALATE → User decision required
```

---

## 7. Runner / Hardware / Cloud Strategy

### 7.1 Design Philosophy

- **Default: Local Windows**. Codex Factory runs on the developer''s Windows machine. No hardware purchase required.
- **Optional: Mac mini**. Only for iOS/macOS build requirements (Expo iOS build, Xcode).
- **Optional: Cloud**. Only when local resources are insufficient (LLM inference, heavy CI, 24/7 services).
- **No assumption**: Do not assume the user has or will buy any specific hardware.

### 7.2 Runner Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  LOCAL WINDOWS RUNNER (Default)           │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │ Codex    │  │ Node.js  │  │ Docker   │               │
│  │ CLI/App  │  │ Runtime  │  │ (optional)│              │
│  └──────────┘  └──────────┘  └──────────┘               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │ Python   │  │ Git      │  │ PS1/Bash │               │
│  │ Runtime  │  │          │  │ Scripts  │               │
│  └──────────┘  └──────────┘  └──────────┘               │
│                                                          │
│  Capable of:                                             │
│  - All web projects (Next.js, Vite, Node.js)             │
│  - All backend projects (Fastify, Express, Prisma)       │
│  - Android builds (Expo)                                 │
│  - 小程序开发 (微信开发者工具)                            │
│  - 3D projects (Three.js, WebGL)                         │
│  - Dockerized databases (PostgreSQL, Redis)              │
├─────────────────────────────────────────────────────────┤
│               OPTIONAL MAC MINI RUNNER                    │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │ Xcode    │  │ iOS      │  │ macOS    │               │
│  │          │  │ Simulator│  │ Builds   │               │
│  └──────────┘  └──────────┘  └──────────┘               │
│                                                          │
│  ONLY needed for:                                        │
│  - iOS app builds (Expo EAS Build alternatives)          │
│  - macOS desktop app development                         │
│  - Xcode-dependent testing                               │
├─────────────────────────────────────────────────────────┤
│               OPTIONAL CLOUD RUNNER                       │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐               │
│  │ CI/CD    │  │ Staging  │  │ LLM      │               │
│  │ Pipeline │  │ Env      │  │ Inference│               │
│  └──────────┘  └──────────┘  └──────────┘               │
│                                                          │
│  ONLY needed for:                                        │
│  - 24/7 services (staging environment, API)              │
│  - Heavy CI/CD (parallel test suites)                    │
│  - Team collaboration (shared dev environment)           │
│  - Local LLM inference (if using open-source models)     │
└─────────────────────────────────────────────────────────┘
```

### 7.3 Hardware Need Benchmark

For each project type, assess whether additional hardware is needed:

| Project Type | Local Windows | Mac mini Needed? | Cloud Needed? |
|-------------|---------------|------------------|---------------|
| content-site | ✅ Full | ❌ No | ❌ No |
| fullstack-admin | ✅ Full | ❌ No | ❌ No (S/M), ⚠️ Maybe (L/XL) |
| saas-tool | ✅ Full | ❌ No | ❌ No (S/M), ⚠️ Maybe (L) |
| api-service | ✅ Full | ❌ No | ❌ No (S/M), ⚠️ Maybe (high-concurrency tests) |
| miniapp | ✅ Full | ❌ No | ❌ No |
| mobile-app (Android only) | ✅ Full | ❌ No | ❌ No |
| mobile-app (iOS) | ❌ Cannot build | ✅ Required OR use EAS Build | ❌ No (EAS), ⚠️ Maybe (CI) |
| threejs-interactive | ✅ Full | ❌ No | ❌ No |

### 7.4 Decision Trees

#### When to Buy a Mac mini

```
Need iOS build? → YES → Using EAS Build? → YES → No Mac needed
                      → NO → Mac mini recommended (~$600 Mac mini M4)
Need macOS desktop app? → YES → Mac mini required
Need Xcode Simulator testing? → YES → Mac mini recommended
Everything else → NO → Mac NOT needed
```

#### When to Use Cloud Server

```
Need 24/7 running service? → YES → Cloud server
Need CI/CD with parallel test suites? → YES → Cloud CI
Need staging environment for team? → YES → Cloud staging
Team > 3 developers sharing environment? → YES → Cloud dev environment
Running local LLM (Ollama, etc.)? → YES → Cloud GPU instance OR local GPU
Everything else → NO → Local is sufficient
```

#### When Cloud is Definitely NOT Needed

```
- Solo developer
- All projects are S/M complexity
- No 24/7 services
- No iOS build requirements (or using EAS Build)
- CI/CD handled by GitHub Actions free tier
```

### 7.5 Cloud Provider Recommendations (if needed)

| Use Case | Recommended | Alternative | Monthly Cost (approx) |
|----------|-------------|-------------|----------------------|
| Staging server | Railway / Render | VPS (Hetzner $5) | $5-20 |
| CI/CD | GitHub Actions | — | Free (2000 min/mo) |
| Database (managed) | Supabase / Neon | Self-hosted Postgres | $0-25 |
| LLM Inference | Groq / Together AI | RunPod Serverless | Pay-per-use |
| Full VM | Hetzner CX22 ($4/mo) | DigitalOcean $6/mo | $4-6 |

### 7.6 Runner Configuration

```json
{
  "runners": {
    "local-windows": {
      "status": "ACTIVE",
      "capabilities": ["web", "backend", "android-build", "miniapp", "threejs"],
      "specs": {
        "os": "Windows 11",
        "node": ">=20.0.0",
        "python": ">=3.10",
        "docker": "optional"
      }
    },
    "mac-mini": {
      "status": "NOT_PRESENT",
      "capabilities": ["ios-build", "macos-build", "xcode-test"],
      "purchaseTrigger": "First iOS build requirement without EAS",
      "estimatedCost": "$600 (Mac mini M4)"
    },
    "cloud": {
      "status": "NOT_CONFIGURED",
      "capabilities": ["staging", "ci-cd", "llm-inference"],
      "provisionTrigger": "First 24/7 service requirement OR team > 3",
      "estimatedCost": "$5-25/month"
    }
  }
}
```

---


---

## 8. Overall Architecture

### 8.1 System Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                     CODEX FACTORY R2.0                            │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    GOVERNANCE LAYER                        │   │
│  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────────────┐  │   │
│  │  │Global  │  │App Type│  │Stack   │  │Lifecycle       │  │   │
│  │  │Rules   │  │Router  │  │Decision│  │State Machine   │  │   │
│  │  └────────┘  └────────┘  └────────┘  └────────────────┘  │   │
│  │  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────────────┐  │   │
│  │  │Contracts│  │Drift   │  │Security│  │Quality         │  │   │
│  │  │(PIC/AC/ │  │Control │  │Rules   │  │Checklists      │  │   │
│  │  │ FC/NGC) │  │        │  │        │  │                │  │   │
│  │  └────────┘  └────────┘  └────────┘  └────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                     AGENT LAYER                            │   │
│  │                                                             │   │
│  │  CONSTANT AGENTS:                                           │   │
│  │  ┌──────────┐  ┌──────────────┐  ┌──────────────┐         │   │
│  │  │ PM-001   │  │ LIB-001      │  │ RSRC-001     │         │   │
│  │  │ Router   │  │ Skill Librarian│  │ Research     │         │   │
│  │  └──────────┘  └──────────────┘  └──────────────┘         │   │
│  │                                                             │   │
│  │  ON-DEMAND AGENTS:                                          │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │   │
│  │  │ARCH-001  │  │IMPL-FE   │  │IMPL-BE   │  │IMPL-DB   │   │   │
│  │  │Architect │  │Frontend  │  │Backend   │  │Database  │   │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │   │
│  │  │VER-001   │  │SEC-001   │  │INTG-001  │  │AUD-001   │   │   │
│  │  │Verifier  │  │Security  │  │Integrator│  │Drift Aud.│   │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │   │
│  │                                                             │   │
│  │  ┌──────────────────────────────────────────────────┐     │   │
│  │  │              HANGOFF BUS                          │     │   │
│  │  │  Contract | Handoff | Ledger | Receipt           │     │   │
│  │  └──────────────────────────────────────────────────┘     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   KNOWLEDGE LAYER                          │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────┐  │   │
│  │  │Skill Bank  │  │Knowledge   │  │External Docs       │  │   │
│  │  │Registry    │  │Bank        │  │Index               │  │   │
│  │  │Import/Adapt│  │Capsules    │  │                    │  │   │
│  │  │Versioning  │  │Playbooks   │  │                    │  │   │
│  │  │Trust Tiers │  │Fail Lessons│  │                    │  │   │
│  │  └────────────┘  └────────────┘  └────────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    ASSET LAYER                             │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │   │
│  │  │Starters  │  │Blueprints│  │Skills    │  │Prompts   │  │   │
│  │  │(7 types) │  │(7 types) │  │(9+ types)│  │(11+ tmpl)│  │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    RUNNER LAYER                            │   │
│  │  ┌────────────────┐  ┌────────────┐  ┌────────────────┐  │   │
│  │  │Local Windows   │  │Mac mini    │  │Cloud           │  │   │
│  │  │(Default)       │  │(Optional)  │  │(Optional)      │  │   │
│  │  └────────────────┘  └────────────┘  └────────────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                 EXTERNAL INTERFACE LAYER                   │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │   │
│  │  │Codex     │  │MCP       │  │Open-Source│  │Web Search│  │   │
│  │  │Skills Mkt│  │Servers   │  │Templates │  │APIs      │  │   │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### 8.2 Data Flow

```
User Request
    │
    ▼
PM-001 (Router) ─── reads ──→ Governance Layer
    │
    ├── spawns ──→ RSRC-001 (Research) ──→ External Sources
    │                    │                       │
    │                    ◄── Research Packet ────┘
    │
    ├── spawns ──→ ARCH-001 (Architect) ── reads ──→ Skill Bank
    │                    │
    │                    ◄── Architecture Proposal
    │
    ├── USER APPROVAL GATE
    │
    ├── spawns ──→ IMPL-FE-001 + IMPL-BE-001 + IMPL-DB-001
    │                    │
    │                    ◄── Implementation Outputs
    │
    ├── spawns ──→ VER-001 (Verifier)
    │                    │
    │                    ◄── Verification Report
    │
    ├── spawns ──→ SEC-001 (Security)
    │                    │
    │                    ◄── Security Report
    │
    ├── spawns ──→ AUD-001 (Drift Auditor) [at checkpoints]
    │                    │
    │                    ◄── Drift Report
    │
    └── spawns ──→ INTG-001 (Integrator)
                        │
                        ◄── Final Deliverable
                        │
                        ▼
                   User Receives Project
                        │
                        ▼
              LIB-001 ←── Failure Lessons + Knowledge Capsules
```

### 8.3 Directory Structure (R2.0 Target)

```
C:\Codex_App_Factory\
├── AGENTS.md                          # Factory bootstrap gate
├── GLOBAL_CODEX_RULES.md              # Global iron rules
├── APP_TYPE_ROUTER.md                 # Project type classification
├── STACK_DECISION_GUIDE.md            # Tech stack decision rules
├── README.md                          # Factory overview
│
├── governance/                        # GOVERNANCE LAYER
│   ├── rules/                         # All rule files
│   ├── contracts/                     # Contract templates + active contracts
│   │   ├── templates/                 # PIC, AC, FC, NGC templates
│   │   └── active/                    # Per-project contracts
│   ├── lifecycle/                     # State machine, transitions
│   ├── multi-agent/                   # Agent definitions, handoff protocols
│   │   ├── agent-definitions/         # Per-agent spec files (PM-001.json, etc.)
│   │   ├── handoff-bus/               # Handoff schema, ledger
│   │   └── role-skill-profiles/       # Skill-to-role mapping
│   ├── drift-control/                 # Drift detection policies, reports
│   ├── security/                      # Security rules, audit templates
│   └── quality/                       # Quality checklists, standards
│
├── agents/                            # AGENT LAYER (active agent state)
│   ├── constant/                      # PM-001, LIB-001, RSRC-001 state
│   └── on-demand/                     # Per-project agent instances
│
├── knowledge-bank/                    # KNOWLEDGE LAYER
│   ├── skill-registry.json            # Master skill registry
│   ├── skills/                        # Skill files (organized by domain)
│   │   ├── auth/
│   │   ├── database/
│   │   ├── frontend/
│   │   ├── backend/
│   │   ├── miniapp/
│   │   ├── mobile/
│   │   ├── security/
│   │   ├── testing/
│   │   └── devops/
│   ├── capsules/                      # Knowledge capsules
│   ├── playbooks/                     # Domain playbooks
│   ├── failure-lessons/               # Failure lesson library
│   ├── docs-index.json                # External documentation index
│   └── research/                      # Research packet archive
│
├── assets/                            # ASSET LAYER
│   ├── starters/                      # 7+ starter templates
│   ├── blueprints/                    # 7+ design blueprints
│   ├── prompts/                       # Prompt templates
│   └── mcp-registry.json              # MCP server registry
│
├── runners/                           # RUNNER LAYER
│   ├── runner-config.json             # Active runner configuration
│   ├── windows/                       # Windows-specific scripts
│   ├── mac/                           # Mac-specific scripts (if Mac present)
│   └── cloud/                         # Cloud provisioning scripts
│
├── projects/                          # Generated projects (output)
│   └── {projectId}/                   # Per-project directory
│
├── benchmark/                         # Benchmark project set
├── benchmark-results/                 # Benchmark run results
├── outputs/                           # Reports, specs, documentation
└── harness/                           # Testing harness
```

---

## 9. Phase Roadmap

### 9.1 R2.0 Delivery Phases

```
R2.0 ──────── R2.1 ──────── R2.2 ──────── R2.3 ──────── R3.0
(Design)     (Core Build)  (Knowledge)  (Integration) (Production)
```

### Phase R2.0: Architecture Design (Current)

**Duration:** 1 session
**Deliverable:** `FACTORY_ARCHITECTURE_R2_SPEC.md` (this document)
**Status:** IN PROGRESS

### Phase R2.1: Core Infrastructure Build

**Duration:** 3-5 sessions
**Goals:**
- [ ] Create new directory structure per R2.0 spec
- [ ] Migrate existing governance files to new structure
- [ ] Implement Agent Handoff Bus (schemas + ledger)
- [ ] Define all 10 agent definition files
- [ ] Build agent spawn/control scripts
- [ ] Create contract templates (PIC, AC, FC, NGC)
- [ ] Implement Drift Control checkpoint system
- [ ] Build Runner configuration system
- [ ] Migrate starters/blueprints/prompts to assets/

**Deliverable:** Operational R2.0 skeleton

### Phase R2.2: Knowledge Layer Build

**Duration:** 3-5 sessions
**Goals:**
- [ ] Implement Skill Registry with import pipeline
- [ ] Import and adapt top 10 external skills
- [ ] Create Skill Trust Level audit system
- [ ] Build Knowledge Capsule engine
- [ ] Seed initial knowledge capsules from past projects
- [ ] Create Domain Playbooks (miniapp, ecommerce, security, refactor, fullstack)
- [ ] Build Failure Lesson capture system
- [ ] Implement External Docs Index with auto-update
- [ ] Build Research Agent search pipeline

**Deliverable:** Operational Knowledge Layer

### Phase R2.3: Integration & Verification

**Duration:** 2-3 sessions
**Goals:**
- [ ] End-to-end agent collaboration test (BUILD_PRO on a real project)
- [ ] Drift Control dry run on existing projects
- [ ] Skill import pipeline end-to-end test
- [ ] Research Agent accuracy benchmark
- [ ] Runner configuration validation (Windows)
- [ ] Documentation: Factory R2.0 User Guide
- [ ] Documentation: Agent Development Guide
- [ ] Documentation: Skill Authoring Guide

**Deliverable:** Verified R2.0 system + documentation

### Phase R3.0: Production Hardening

**Duration:** TBD
**Goals:**
- [ ] Multi-project concurrent agent management
- [ ] Agent performance metrics and optimization
- [ ] Skill effectiveness scoring
- [ ] Automated skill update from external sources
- [ ] Cloud runner provisioning automation
- [ ] Mac mini runner integration (if hardware present)
- [ ] Team collaboration features

**Deliverable:** Production-ready R3.0

### 9.2 Quick Wins (Immediate Actions)

These can be done in R2.0 without waiting for full infrastructure:

1. **Write contract templates** (PIC, AC, FC, NGC) — use immediately on next project
2. **Create Failure Lesson template** — start capturing lessons from ongoing projects
3. **Define agent specs** for PM, ARCH, IMPL-FE, IMPL-BE — use existing spawn_agent
4. **Set up knowledge-bank/ directory** — start populating with past project insights
5. **Audit existing skills** — assign initial trust levels

---

## 10. Agent Matrix

### 10.1 Full Agent Inventory

| Agent ID | Name | Category | Type | Status |
|----------|------|----------|------|--------|
| PM-001 | Router Agent | Management | Constant | DEFINED (upgrade from v1) |
| RSRC-001 | Research Agent | Knowledge | Constant | NEW in R2.0 |
| LIB-001 | Skill Librarian Agent | Knowledge | Constant | NEW in R2.0 |
| ARCH-001 | Architect Agent | Design | On-Demand | DEFINED (upgrade from v1) |
| IMPL-FE-001 | Frontend Implementer | Implementation | On-Demand | DEFINED (upgrade from v1) |
| IMPL-BE-001 | Backend Implementer | Implementation | On-Demand | DEFINED (upgrade from v1) |
| IMPL-DB-001 | Database Implementer | Implementation | On-Demand | DEFINED (upgrade from v1) |
| VER-001 | Verifier Agent | Quality | On-Demand | DEFINED (upgrade from v1) |
| SEC-001 | Security Agent | Quality | On-Demand | DEFINED (upgrade from v1) |
| INTG-001 | Integrator Agent | Integration | On-Demand | DEFINED (upgrade from v1) |
| AUD-001 | Drift Auditor Agent | Quality | On-Demand | NEW in R2.0 |

### 10.2 Agent Interaction Matrix

| From \ To | PM | ARCH | FE | BE | DB | VER | SEC | INTG | AUD | RSRC | LIB |
|-----------|---|---|----|----|----|----|-----|-----|------|-----|------|-----|
| PM-001 | — | spawn | spawn | spawn | spawn | spawn | spawn | spawn | spawn | query | query |
| ARCH-001 | handoff | — | — | — | — | — | — | — | — | query | query |
| IMPL-FE-001 | — | — | — | — | — | — | — | handoff | — | query | — |
| IMPL-BE-001 | — | — | — | — | — | — | — | handoff | — | query | — |
| IMPL-DB-001 | — | — | — | — | — | — | — | handoff | — | query | — |
| VER-001 | — | — | — | — | — | — | — | handoff | — | — | — |
| SEC-001 | — | — | — | — | — | — | — | handoff | — | — | — |
| INTG-001 | handoff | — | — | — | — | — | — | — | — | — | — |
| AUD-001 | handoff | — | — | — | — | — | — | — | — | query | — |
| RSRC-001 | handoff | handoff | handoff | handoff | handoff | — | — | — | — | — | query |
| LIB-001 | handoff | handoff | handoff | handoff | handoff | — | — | — | — | handoff | — |

### 10.3 Agent Capability Matrix

| Capability | PM | ARCH | FE | BE | DB | VER | SEC | INTG | AUD | RSRC | LIB |
|-----------|----|------|----|----|----|-----|-----|------|-----|------|-----|
| Read project files | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |
| Write project files | ❌ | ❌* | ✅** | ✅** | ✅** | ❌*** | ❌ | ✅**** | ❌ | ❌ | ❌ |
| Spawn agents | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| Web search | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ |
| Run shell commands | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Approve architecture | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Reject output | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |

*ARCH: Write design docs only
**FE/BE/DB: Write assigned scope only
***VER: Write test files only
****INTG: Write integration layer only

---

## 11. Skill Matrix

### 11.1 Current Skills (v1.x)

| Skill | Domain | File | Status |
|-------|--------|------|--------|
| anti-overengineering | Governance | skills/anti-overengineering/SKILL.md | ACTIVE |
| app-type-classifier | Governance | skills/app-type-classifier/SKILL.md | ACTIVE |
| auth-permission-security | Security | skills/auth-permission-security/SKILL.md | ACTIVE |
| backend-api-design | Backend | skills/backend-api-design/SKILL.md | ACTIVE |
| database-schema-design | Database | skills/database-schema-design/SKILL.md | ACTIVE |
| frontend-ui-system | Frontend | skills/frontend-ui-system/SKILL.md | ACTIVE |
| mobile-miniapp-patterns | Mobile | skills/mobile-miniapp-patterns/SKILL.md | ACTIVE |
| product-architecture | Architecture | skills/product-architecture/SKILL.md | ACTIVE |
| webapp-preview-testing | Testing | skills/webapp-preview-testing/SKILL.md | ACTIVE |

### 11.2 External Skills (Available for Import)

| Skill | Source | Trust Level | Factory Role |
|-------|--------|-------------|--------------|
| openai-docs | OpenAI (built-in) | VERIFIED | RSRC-001, ARCH-001 |
| skill-creator | OpenAI (built-in) | VERIFIED | LIB-001 |
| skill-installer | OpenAI (built-in) | VERIFIED | LIB-001 |
| browser:control-in-app-browser | OpenAI (bundled) | VERIFIED | IMPL-FE-001, VER-001 |
| supabase-postgres-best-practices | Supabase (community) | TRUSTED | IMPL-DB-001, IMPL-BE-001 |
| playwright-interactive | Community | TRUSTED | VER-001 |
| imagegen | OpenAI (built-in) | VERIFIED | IMPL-FE-001 (placeholders only) |
| documents:documents | OpenAI (bundled) | VERIFIED | (documentation projects) |
| pdf:pdf | OpenAI (bundled) | VERIFIED | (documentation projects) |
| presentations:Presentations | OpenAI (bundled) | VERIFIED | (presentation projects) |
| spreadsheets:Spreadsheets | OpenAI (bundled) | VERIFIED | (data projects) |

### 11.3 Planned R2.0 Skills

| Skill | Domain | Priority | Dependencies |
|-------|--------|----------|-------------|
| miniapp-wechat-auth | Miniapp | HIGH | auth-permission-security |
| miniapp-api-patterns | Miniapp | HIGH | backend-api-design |
| nextjs-app-router-patterns | Frontend | HIGH | frontend-ui-system |
| prisma-schema-best-practices | Database | HIGH | database-schema-design |
| fastify-api-patterns | Backend | HIGH | backend-api-design |
| expo-mobile-patterns | Mobile | HIGH | (new) |
| threejs-scene-patterns | 3D | MEDIUM | (new) |
| saas-billing-patterns | SaaS | MEDIUM | auth-permission-security |
| ecommerce-order-patterns | Ecommerce | MEDIUM | database-schema-design |
| distributed-architecture-patterns | Architecture | LOW | product-architecture |
| security-audit-checklist | Security | HIGH | auth-permission-security |
| refactor-migration-patterns | Refactor | LOW | database-schema-design |
| ui-state-management | Frontend | MEDIUM | frontend-ui-system |
| api-error-handling | Backend | MEDIUM | backend-api-design |

### 11.4 Skill-to-Project-Type Mapping

| Skill | CS | FA | ST | API | MA | MB | 3D |
|-------|----|----|----|-----|----|----|----|
| miniapp-wechat-auth | — | — | — | — | ✅ | — | — |
| miniapp-api-patterns | — | — | — | — | ✅ | — | — |
| nextjs-app-router-patterns | ✅ | ✅ | ✅ | — | — | — | — |
| prisma-schema-best-practices | — | ✅ | ✅ | ✅ | ✅ | ✅ | — |
| fastify-api-patterns | — | — | — | ✅ | ✅ | — | — |
| expo-mobile-patterns | — | — | — | — | — | ✅ | — |
| threejs-scene-patterns | — | — | — | — | — | — | ✅ |
| saas-billing-patterns | — | — | ✅ | — | — | — | — |
| ecommerce-order-patterns | — | ✅ | ✅ | — | — | — | — |
| security-audit-checklist | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| ui-state-management | ✅ | ✅ | ✅ | — | ✅ | ✅ | — |

CS=content-site, FA=fullstack-admin, ST=saas-tool, API=api-service, MA=miniapp, MB=mobile-app, 3D=threejs-interactive

---

## 12. Search / Knowledge Program

### 12.1 Research Agent Operation Model

```
Trigger → RSRC-001 Activated → Query Parsing → Source Selection
→ Parallel Search → Result Synthesis → Quality Check
→ Research Packet → LIB-001 Review → Knowledge Bank Entry
```

### 12.2 Search Source Configuration

```json
{
  "searchSources": {
    "web_search": {
      "enabled": true,
      "provider": "codex_builtin",
      "rateLimit": { "perHour": 30, "perProject": 20 },
      "useCases": ["version_check", "best_practice", "architecture_search"]
    },
    "mcp_ecosystem": {
      "enabled": true,
      "provider": "list_mcp_resources",
      "rateLimit": { "perHour": 10, "perProject": 5 },
      "useCases": ["skill_search", "template_search"]
    },
    "skill_registry": {
      "enabled": true,
      "provider": "local_filesystem",
      "rateLimit": { "perHour": 100, "perProject": 50 },
      "useCases": ["skill_search"]
    },
    "docs_index": {
      "enabled": true,
      "provider": "local_filesystem",
      "rateLimit": null,
      "useCases": ["docs_search", "best_practice"],
      "updateFrequency": "weekly"
    },
    "github_search": {
      "enabled": false,
      "reason": "Requires GitHub API token",
      "useCases": ["template_search", "architecture_search"]
    }
  }
}
```

### 12.3 Knowledge Lifecycle

```
Capture → Validate → Classify → Store → Index → Retrieve → Apply → Feedback → Update/Deprecate
```

---

## 13. Runner / Hardware / Cloud Program

### 13.1 Current State Assessment

```json
{
  "assessmentDate": "2026-07-05",
  "localWindows": {
    "status": "OPERATIONAL",
    "capabilities": ["web", "backend", "miniapp", "threejs", "android-build"],
    "limitations": ["no-ios-build", "no-24-7-services"],
    "actionRequired": "NONE"
  },
  "macMini": {
    "status": "NOT_NEEDED_YET",
    "triggerConditions": ["ios-build-without-eas", "macos-app-dev"],
    "estimatedCost": "$600",
    "actionRequired": "MONITOR"
  },
  "cloud": {
    "status": "NOT_NEEDED_YET",
    "triggerConditions": ["24-7-service", "team-over-3", "heavy-ci"],
    "estimatedCost": "$5-25/month",
    "actionRequired": "MONITOR"
  }
}
```

### 13.2 Upgrade Triggers

| Trigger | Action | Timeline |
|---------|--------|----------|
| First iOS app project (no EAS) | Purchase Mac mini | Before implementation phase |
| First 24/7 service project | Provision cloud server | Before deployment phase |
| Team grows beyond 3 | Provision cloud dev environment | When 4th member joins |
| CI minutes exceed GitHub free tier | Provision cloud CI runner | When limit reached |
| Need local LLM for cost savings | Provision GPU cloud OR local GPU | When API costs > $50/month |

---

## 14. Benchmark Project Matrix

### 14.1 Purpose

Benchmark projects test Codex Factory''s ability to generate correct, complete projects across all types and complexity levels.

### 14.2 Benchmark Project Set

| ID | Project | Type | Complexity | Key Challenges |
|----|---------|------|------------|----------------|
| B-01 | Personal Portfolio | content-site | S | Responsive layout, image optimization |
| B-02 | Company Landing Page | content-site | M | Multi-page, form, SEO |
| B-03 | Simple CRUD Admin | fullstack-admin | M | Auth, CRUD, RBAC (2 roles) |
| B-04 | Approval Workflow System | fullstack-admin | L | Multi-role, state machine, audit |
| B-05 | AI Text Generator | saas-tool | M | Auth, quota, generation history |
| B-06 | Subscription Content Platform | saas-tool | L | Subscription, quota, payment mock |
| B-07 | REST API for Todo App | api-service | S | CRUD, validation, OpenAPI |
| B-08 | High-Concurrency Event API | api-service | L | Rate limiting, caching, transactions |
| B-09 | WeChat Mini Program Clinic | miniapp | M | WeChat auth, 2 roles, schedule |
| B-10 | WeChat Mini Program E-commerce | miniapp | L | WeChat pay, order state, inventory |
| B-11 | Expo Todo App | mobile-app | M | Auth, offline, push notification |
| B-12 | Expo Social App | mobile-app | L | Real-time, media upload, chat |
| B-13 | 3D Product Viewer | threejs-interactive | M | 3D model, interaction, UI overlay |
| B-14 | 3D Virtual Gallery | threejs-interactive | L | Multi-scene, avatar, networking |

### 14.3 Benchmark Scoring

| Dimension | Weight | Measurement |
|-----------|--------|-------------|
| Correctness | 40% | All acceptance criteria met |
| Completeness | 20% | All contracted features implemented |
| State Coverage | 15% | Loading, empty, error, success states |
| Security | 15% | No secrets exposed, auth correct, input validated |
| Drift Compliance | 10% | Matches architecture contract |

### 14.4 Benchmark Run Protocol

1. Create clean project context
2. Run Router → Architect → Implementers → Verifier → Security → Integrator
3. Run Drift Auditor at checkpoints
4. Score each dimension
5. Record failures as Failure Lessons
6. Feed back into Skill/Knowledge Bank

---

## 15. Next Phase Recommendations

### 15.1 Immediate Actions (R2.0 Completion)

- [ ] **Review this spec** — user reviews and approves the R2.0 architecture
- [ ] **Prioritize** — confirm which R2.1 items to tackle first
- [ ] **Quick Win 1**: Write contract templates (PIC, AC, FC, NGC) — can use on next project immediately
- [ ] **Quick Win 2**: Start Failure Lesson capture from the 医师系统小程序 experience
- [ ] **Quick Win 3**: Audit existing skills and assign trust levels

### 15.2 R2.1 Priority Order (Recommended)

1. **Agent Handoff Bus** — foundation for all agent collaboration
2. **Agent Definition Files** — formalize all 10 agent specs
3. **Contract Templates** — PIC, AC, FC, NGC templates
4. **Directory Restructure** — migrate to R2.0 layout
5. **Drift Control Checkpoints** — basic PIC/AC creation + CP-ARCH audit
6. **Runner Config** — formalize current Windows runner setup

### 15.3 Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Over-engineering R2.0 itself | MEDIUM | HIGH | Ship incrementally; quick wins first |
| Agent coordination overhead | MEDIUM | MEDIUM | BUILD_LITE default; multi-agent only when triggered |
| External skill quality variance | HIGH | MEDIUM | Strict import pipeline; trust tiers |
| Knowledge bank staleness | MEDIUM | LOW | Weekly auto-audit by LIB-001 |
| Mac mini never needed | HIGH | LOW | No upfront purchase; trigger-based |
| Cloud costs exceed estimate | LOW | MEDIUM | Use free tiers; monitor triggers |

### 15.4 Success Metrics for R2.0

| Metric | Target | Measurement |
|--------|--------|-------------|
| Project type classification accuracy | > 95% | Correct router output / total projects |
| Agent handoff success rate | > 90% | Accepted handoffs / total handoffs |
| Drift detection rate | > 80% | Drifts caught at checkpoint / total drifts |
| Skill import approval rate | > 70% | Approved imports / total import attempts |
| Research packet relevance | > 85% | Relevant findings / total findings |
| BUILD_LITE success rate | > 90% | Successful projects / total BUILD_LITE projects |
| BUILD_PRO success rate | > 70% | Successful projects / total BUILD_PRO projects |

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| PIC | Project Intent Contract — why the project exists |
| AC | Architecture Contract — how the system is built |
| FC | Feature Contract — what each feature does |
| NGC | Non-Goal Contract — what the project will NOT do |
| Handoff Bus | Centralized agent communication protocol |
| Knowledge Capsule | Structured, reusable knowledge unit |
| Domain Playbook | Collection of capsules organized by domain |
| Trust Level | VERIFIED / TRUSTED / AVAILABLE / UNVERIFIED / BLOCKED |
| Drift | Deviation from original contract |
| Runner | Execution environment for Factory projects |
| BUILD_LITE | Single-agent project mode |
| BUILD_PRO | Multi-agent project mode |

## Appendix B: File Inventory (R2.0 Target)

```
New files to create:
├── governance/contracts/templates/PIC-template.json
├── governance/contracts/templates/AC-template.json
├── governance/contracts/templates/FC-template.json
├── governance/contracts/templates/NGC-template.json
├── governance/multi-agent/agent-definitions/PM-001.json
├── governance/multi-agent/agent-definitions/RSRC-001.json
├── governance/multi-agent/agent-definitions/LIB-001.json
├── governance/multi-agent/agent-definitions/ARCH-001.json
├── governance/multi-agent/agent-definitions/IMPL-FE-001.json
├── governance/multi-agent/agent-definitions/IMPL-BE-001.json
├── governance/multi-agent/agent-definitions/IMPL-DB-001.json
├── governance/multi-agent/agent-definitions/VER-001.json
├── governance/multi-agent/agent-definitions/SEC-001.json
├── governance/multi-agent/agent-definitions/INTG-001.json
├── governance/multi-agent/agent-definitions/AUD-001.json
├── governance/multi-agent/handoff-bus/handoff-schema.json
├── governance/multi-agent/handoff-bus/ledger-schema.json
├── governance/drift-control/drift-types.json
├── governance/drift-control/checkpoint-config.json
├── knowledge-bank/skill-registry.json
├── knowledge-bank/docs-index.json
├── knowledge-bank/playbooks/miniapp-playbook.md
├── knowledge-bank/playbooks/ecommerce-playbook.md
├── knowledge-bank/playbooks/distributed-playbook.md
├── knowledge-bank/playbooks/security-playbook.md
├── knowledge-bank/playbooks/refactor-playbook.md
├── knowledge-bank/playbooks/fullstack-playbook.md
├── knowledge-bank/playbooks/mobile-playbook.md
├── knowledge-bank/failure-lessons/FAIL-template.json
├── runners/runner-config.json
├── assets/mcp-registry.json

Files to migrate/refactor:
├── AGENTS.md → (update for R2.0)
├── GLOBAL_CODEX_RULES.md → governance/rules/
├── APP_TYPE_ROUTER.md → governance/rules/
├── STACK_DECISION_GUIDE.md → governance/rules/
├── skills/* → knowledge-bank/skills/ (reorganized)
├── starters/* → assets/starters/
├── blueprints/* → assets/blueprints/
├── prompts/* → assets/prompts/
├── factory-multi-agent/* → governance/multi-agent/
├── factory-lifecycle/* → governance/lifecycle/
```

---

> **End of FACTORY_ARCHITECTURE_R2_SPEC.md**
> 
> Version: 2.0.0-draft
> Status: AWAITING REVIEW
> Next: User review and prioritization → R2.1 kickoff

