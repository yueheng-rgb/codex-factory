# Codex Factory 核心实现原理讲解稿

> 用途：项目作者本人复习、准备 AI Agent 校招面试。
> 写法：少贴代码，多把源码里的机制翻译成“业务流程 + 工程流程”。
> 事实来源：当前本地 `<repo>` 项目源码与测试。附件/学习资料只用于确定学习范围，不作为项目事实来源。

---

## 0. 先给结论

### 0.1 一句话定位

【源码确认】Codex Factory 不是训练模型，也不是普通 README 模板库。它更像一个“AI Coding 控制平面”：把大任务拆成有依赖的任务图，把不同 Agent 限定在不同角色和文件范围里，把长期知识放到外部 SQLite 知识库中，再用 Context Packet、hooks、registry、handoff、receipt、verifier 这些机制，把“Agent 说完成了”变成“系统能复查、能追溯、能拒绝假通过”。

### 0.2 RAG 结论

【源码确认】它用了 RAG 思路，但不是典型向量 RAG。

更准确地说，当前 Factory 主链路是：

```text
项目知识 / 规则 / 决策
↓
SQLite 严格表 + FTS5 全文索引
↓
按任务和角色检索
↓
筛选 active、source-bound、role-visible 的知识
↓
截取有限 excerpt
↓
写入 Context Space
↓
生成可验证 Context Packet
↓
交给对应 Agent
```

它没有把标准 RAG 里的 `Embedding → Vector DB → Rerank` 做成当前主链路。当前检索核心是 SQLite FTS5 / BM25 / lexical fallback。外部搜索是可选 GLM live search evidence，不是默认 RAG 知识库。

### 0.3 多 Agent 结论

【源码确认】Factory 把 Agent 拆成 8 个 profile：

- resident：`factory_router`、`factory_librarian`、`factory_verifier`、`factory_drift_auditor`
- temporary：`factory_researcher`、`factory_implementer`、`factory_tester`、`factory_integrator`

resident 的意思不是“同一个对话永远复用”，而是“长期存在的角色模板”。源码和测试明确要求：每次 assignment 仍然要 fresh execution，不能复用旧对话上下文。

### 0.4 编排结论

【源码确认】主编排在 `packages/factory-cli/src/orchestrator.ts`。它接收任务图，校验 DAG、write_scope、acceptance_methods、required_artifacts，自动为非 verifier 任务追加 `verify-xxx` 任务，然后生成 spawn plan、agent registry、assignment prompt、Context Packet、filesystem baseline。

### 0.5 防漂移结论

【源码确认】Factory 防漂移不是靠一句“相信 Agent 自觉”，而是靠多层硬约束：

- Context Packet 防上下文漂移
- Knowledge source hash 防知识漂移
- hook + native agent id + registry 防身份漂移
- write_scope + filesystem baseline + real diff 防文件越权
- handoff + independent verifier + verification receipt 防完成状态漂移
- interface contract + manifest + drift detector 防接口漂移

---

## 1. 术语先讲人话

第一次出现的关键术语先解释清楚。

| 术语 | 人话解释 |
|---|---|
| RAG | Retrieval-Augmented Generation，生成前先从外部资料里找相关内容，再把相关内容交给模型。 |
| FTS5 | SQLite 自带的全文搜索能力，可以像搜文档一样搜数据库里的文本。 |
| BM25 | 一个排序算法，用来判断“哪条文本更像用户想找的内容”。它不是 AI，只是检索排序。 |
| MATCH | SQLite FTS5 的查询写法，意思是“在全文索引里匹配这些词”。 |
| lexical fallback | 当全文索引对短词、中文片段或特殊术语不够稳定时，再用普通字符串包含关系兜底找一次。 |
| Context Space | Factory 的外部上下文账本，存在 SQLite 里，记录需求、决策、任务状态、知识检索、证据等事件。 |
| Context Packet | 给某个 Agent 的“上下文包”。它不是简单复制聊天记录，而是带 hash、来源、角色、过期时间的可验证上下文。 |
| DAG | Directed Acyclic Graph，有向无环图。这里就是任务依赖图：B 依赖 A，A 没完成 B 不能跑，且不能形成循环依赖。 |
| assignment | 给某个 Agent 的施工单，里面写明任务、角色、可见上下文、允许写哪些文件、怎么验收。 |
| handoff | Worker 做完后交给主控的交接单，里面声明改了什么、产出了什么、跑了什么命令。它不是最终通过。 |
| hook | Codex 工具调用前后的拦截器。Factory 用它拦截 spawn、检查 prompt、记录 native agent id、强制 handoff 格式。 |
| registry | Agent 登记册，记录 assignment 和真实 native agent id 的绑定、生命周期、receipt、baseline。 |
| native agent id | Codex 宿主实际创建 Agent 后返回的真实 ID。不能让 Agent 自己编一个。 |
| receipt | 回执。Factory 里通常是带 hash 的 JSON 证据，比如 native spawn receipt、verification receipt。 |
| artifact | 可检查的产物，比如文件、目录、测试报告、构建输出。 |
| baseline | Agent 开工前记录的文件系统快照，用来和完工后的真实变化对比。 |
| manifest | 清单。比如 Worker 声明自己导出了哪些接口、导入了哪些接口。 |
| contract lock | 开工前锁定的接口契约文件，规定接口 ID、名称、文件、owner、requiredBy。 |
| fail closed | 只要证据不完整、hash 不对、来源不可信，就默认失败，而不是默认放行。 |

---

# 第一部分：Codex Factory 到底有没有使用 RAG？

## 1. 它是干什么的

Factory 的 RAG 层解决的是：Agent 不应该只靠当前聊天窗口和自己的记忆做工程决策。它要能从项目已有规则、架构决策、接口规范、历史经验中找出“当前任务真正需要的那几条”，再把这些内容以受控方式交给 Agent。

【源码确认】当前它不是典型向量库 RAG。它没有主链路 embedding、vector DB、semantic rerank。它用的是 SQLite FTS5/BM25/词法检索，再通过 Context Packet 注入。

## 2. 为什么需要它

假设用户说：“给已有项目增加登录功能。”如果只让一个 Agent 直接读聊天上下文，它可能会：

- 忘记项目规定“登录和权限必须服务端校验”
- 用过期的接口文档
- 把 verifier 私有规则暴露给 implementer
- 一次塞太多资料进 prompt，导致上下文污染
- 被用户或前端摘要里的不可信信息误导

RAG 层的价值不是“显得高级”，而是让 Agent 在开工前拿到少量、当前、可追溯、角色可见的知识。

## 3. Factory 实际怎么实现

### 3.1 knowledge entry 是什么

【源码确认】knowledge entry 是知识库里的最小检索单位。它不是把一个 Markdown 自动切成很多 chunk，而是一次导入或添加形成一条条 `knowledge_entries` 记录。

一条 knowledge entry 里主要有：

```json
{
  "entry_id": "knowledge-auth-boundary",
  "title": "Auth boundary",
  "content": "登录、JWT、权限必须在服务端校验。",
  "source_uri": "docs/auth-policy.md",
  "source_sha256": "源文件内容的SHA256",
  "roles": ["implementation", "verifier"],
  "tags": ["auth", "security"],
  "status": "active",
  "supersedes_id": null,
  "source_binding": "project_file",
  "content_digest": "规范化内容摘要",
  "content_hash": "整条记录的哈希"
}
```

这段不是源码原样，是为了帮助理解的简化结构。它表达的核心是：知识不只是文本，还带来源、角色、状态、版本关系和完整性 hash。

### 3.2 一份 Markdown 导入后，在数据库里变成什么

【源码确认】`importKnowledgeFile()` 会做这些事：

1. 输入：项目内的 Markdown 或文本文件路径，比如 `knowledge/auth-policy.md`。
2. 程序处理：确认路径没有逃出项目根目录；确认不是 credential 文件；确认是有效 UTF-8；计算源文件 SHA-256；检查内容里没有明显 secret。
3. 输出：一条 `knowledge_entries` 记录，同时写入 FTS 表和搜索辅助表。
4. 对应文件/函数：`packages/factory-cli/src/knowledge.ts` 的 `importKnowledgeFile()`、`addKnowledgeEntry()`、`queryKnowledge()`。
5. 为什么要这样做：让每条知识都有物理来源和 hash。以后源文件被改了，系统能知道这条知识可能过期。
6. 没有这一步的问题：Agent 会把“别人随口说的一段话”和“项目源码里的正式规则”混为一谈。

### 3.3 有没有真正的 Chunk

【源码确认】当前主链路没有典型 RAG 的自动 chunk pipeline。也就是说，不是把一个长文档按 500 tokens 切成几十段，再分别 embedding。

当前检索单位是 knowledge entry。导入一个文件时，这个文件内容通常成为一条 entry。检索命中后，`memory-packet.ts` 会从 entry 内容里截取和查询词附近相关的一段 excerpt。这个 excerpt 更像“结果摘要片段”，不是预先切好的向量 chunk。

### 3.4 `knowledge_entries` 和 `knowledge_entries_fts` 分别干什么

【源码确认】

- `knowledge_entries` 是主表，保存完整知识、来源、角色、状态、hash、supersedes 等可信元数据。
- `knowledge_entries_fts` 是全文索引表，帮助快速搜索 title/content/tags。

打个比方：`knowledge_entries` 像图书馆藏书登记册，记录这本书是谁、来源在哪、版本是否有效；`knowledge_entries_fts` 像图书馆搜索引擎，负责快速找到可能相关的书。

只用 FTS 表不行，因为它不承载全部可信元数据。只用主表也不行，因为搜索会慢，而且不好排序。

### 3.5 FTS5、MATCH、BM25、lexical fallback 怎么配合

【源码确认】`queryKnowledge()` 会把任务 query 转成 FTS expression，然后查 `knowledge_entries_fts`：

- FTS5：SQLite 的全文搜索模块。
- MATCH：在 FTS5 索引里匹配查询词。
- BM25：给匹配结果排序，越相关越靠前。
- lexical fallback：用普通字符串包含关系兜底，尤其照顾短中文、接口名、规则编号、特殊词。

为什么要 lexical fallback？因为工程知识里经常出现 `JWT`、`login.ts`、`R2.4`、`事务` 这种短词或混合符号。纯全文检索可能分词不理想，兜底能减少“明明有但搜不到”。

### 3.6 roles、tags、status、supersedes 怎么参与检索

【源码确认】

- `roles`：控制谁能看到。比如 verifier 私有规则不会自动注入 implementer。
- `tags`：参与检索和归类，比如 `auth`、`security`、`transaction`。
- `status`：只默认返回 `active`。`retired` 或 `revoked` 不进入当前知识。
- `supersedes`：版本替代关系。V2 替代 V1 后，检索只返回 active leaf revision，也就是最新有效叶子版本。

例子：`auth-api-v1.md` 说登录接口是 `/api/signin`，后来 `auth-api-v2.md` supersedes V1，改成 `/api/login`。Factory 检索时应该只给 Agent V2，不能把 V1/V2 一起塞进去让它混乱。

### 3.7 最多 6 条、单条 excerpt、总长度限制防什么

【源码确认】`memory-packet.ts` 里有硬限制：

- 最多 6 条 knowledge entries
- 单条 excerpt 最多 1200 字符
- 总 excerpt 最多 6000 字符
- query 最多 1000 字符

这些限制防三件事：

1. 防上下文污染：不要把 50 条知识全塞给 Agent。
2. 防 prompt 被撑爆：Agent 只拿当前任务必要内容。
3. 防检索漂移：越长越容易夹带无关规则，Agent 可能抓错重点。

### 3.8 Context Packet 和“把搜索结果粘进 Prompt”的区别

普通粘贴搜索结果的问题是：Agent 看到了，但系统不知道它来自哪里、什么时候生成、有没有被改、是不是给这个角色看的。

【源码确认】Context Packet 多了这些约束：

- `run_id`：绑定这次运行，不让别的 run 的上下文混进来。
- `assignment_id`：绑定具体施工单，不让 A 任务的包给 B 任务用。
- `target_role`：绑定角色，比如 implementation，不给 verifier 私有内容。
- `ledger_head_hash`：绑定生成时 Context Space 的账本位置。
- `source_event_ids`：说明这个包来自哪些上下文事件。
- `expires_at`：过期后不能继续用。
- `packet_hash`：整个包被改过就验证失败。

这使它从“prompt 文本”变成“可审计、可验证、可过期、可拒绝”的上下文输入。

## 4. 举一个完整例子

用户任务：

```text
给已有 Web 项目增加用户登录功能，并增加测试。
```

### 第一步：形成 Task

输入：用户自然语言。

程序实际能力边界：`prepareSpawnPlan()` 不直接从自然语言自动生成全部业务任务，它接收已经形成的 `FactoryTask[]`。任务通常由主控/Router 角色根据用户需求和规则产生。源码确认的是：Factory 会校验和调度这个任务图。

一个可能的实现任务：

```json
{
  "task_id": "auth-login-api",
  "title": "Implement login API",
  "description": "Add server-side login validation and token issuance.",
  "role": "implementation",
  "status": "pending",
  "dependencies": ["auth-analysis"],
  "write_scope": ["src/login.ts", "tests/login.test.ts"],
  "acceptance_methods": ["command:npm test -- login"],
  "required_artifacts": ["tests/login.test.ts"]
}
```

解释：

- `title/description` 后面会变成知识检索 query 的重要来源。
- `write_scope` 限制 Implementer 能动哪些文件。
- `acceptance_methods` 是后面 Verifier 要重跑的验收方法。

### 第二步：生成检索词

输入：Task 的 `title`、`description`、`acceptance_methods`、`required_artifacts`。

程序处理：`memory-packet.ts` 把这些字段拼成 query，并控制最大长度。

输出：类似：

```text
Implement login API Add server-side login validation and token issuance command:npm test -- login tests/login.test.ts
```

为什么要这么做：它不是让 Agent 随便说“我想查认证”，而是让检索和施工单绑定。

没有这一步的问题：Agent 可能查到泛泛的登录教程，而不是项目自己的 auth policy、API 规范、测试要求。

### 第三步：去哪里查

输入：query + 请求角色 `implementation`。

程序处理：查 `.codex-factory/context/state.db` 里的 knowledge tables。

输出：候选 knowledge entries。

对应文件/函数：`knowledge.ts` 的 SQLite schema、`queryKnowledge()`；`memory-packet.ts` 的 `appendAssignmentKnowledgeContext()`。

### 第四步：查到什么，怎么排序

假设知识库里有 50 条：

- `docs/auth-policy.md`：登录必须服务端校验，密码 hash，不把密钥放前端
- `docs/api-contract.md`：统一错误格式 `{ error: { code, message } }`
- `docs/test-policy.md`：认证逻辑必须有成功、失败、权限不足测试
- `docs/verifier-private.md`：Verifier 内部反作弊检查
- `docs/old-auth-v1.md`：旧登录接口 `/signin`
- `docs/auth-v2.md`：新登录接口 `/api/login`，supersedes V1

程序处理：

- FTS5 用 MATCH 找 title/content/tags 命中的条目。
- BM25 把更相关的条目排前面。
- lexical fallback 补上短词、中文、接口名可能漏掉的命中。
- 只保留当前角色可见的内容。
- 只保留 active 且没有 active successor 的版本。
- 如果要求 sourceBoundOnly，只保留绑定项目文件且源文件 hash 当前仍一致的知识。

输出可能是 3 条：

1. `auth-v2.md`
2. `auth-policy.md`
3. `test-policy.md`

`verifier-private.md` 因为 role 不可见被过滤。`old-auth-v1.md` 因为被 superseded 被过滤。

### 第五步：为什么只拿几条，怎么控制长度

输入：排序后的结果。

程序处理：最多拿 6 条，每条截取和 query 相关的一段 excerpt，总量不超过 6000 字符。

输出：bounded excerpts。

为什么要这样：给 Implementer 足够上下文，但不让它被一堆历史知识带偏。

没有这一步的问题：模型容易在太长上下文里抓错规则，比如把旧接口和新接口同时用了。

### 第六步：组成 Context Packet

输入：bounded knowledge excerpts + task state event + role visibility。

程序处理：

- 先把知识检索结果作为 `knowledge_retrieval` 事件写入 Context Space。
- 这个事件带 `store_digest`、entry digests、source digests、content digests。
- 再生成 Context Packet，里面有 trusted_context、untrusted candidates、frontend notes、packet_hash。

输出：一个 `.codex-factory/context/packets/...json` 文件。

为什么不直接粘 prompt：因为 packet 可以被 `verifyContextPacket()` 复查。

### 第七步：Context Packet 进入 Agent

输入：assignment prompt。

程序处理：`assignmentPrompt()` 把 packet 路径和校验命令写进 Agent 提示里，要求 Agent 开工前验证 packet。

输出：Implementer 收到的不是“全量聊天记录”，而是：

- 施工单
- 可验证上下文包路径
- write_scope
- acceptance_methods
- required_artifacts
- 禁止自判 PASS、禁止子 Agent

## 5. 数据到底怎么流

```text
用户需求
↓ 形成任务标题、描述、验收方式、写入范围
FactoryTask
↓ build query from title/description/acceptance/artifacts
queryKnowledge()
↓ SQLite FTS5 MATCH + BM25 + lexical fallback
候选 knowledge entries
↓ role/status/supersedes/source-bound 过滤
少量 active role-visible excerpts
↓ append trusted knowledge_retrieval event
Context Space
↓ createContextPacket()
Context Packet JSON
↓ assignmentPrompt()
Implementer Agent
```

## 6. 我从零实现的话怎么做

1. 先设计 `knowledge_entries` 主表：存 content、source_uri、source_sha256、roles、tags、status、supersedes、hash。
2. 再加 FTS5 表：只负责 title/content/tags 的全文搜索。
3. 写导入函数：只允许项目内文本文件，计算源文件 hash，拒绝 secret。
4. 写验证函数：每次查询前检查 entry_count、store_root_hash、content_hash、source_sha256。
5. 写查询函数：从任务字段生成 query，用 FTS5/BM25 搜索，再做 lexical fallback。
6. 写过滤逻辑：active、role-visible、source-bound、leaf revision。
7. 写 excerpt 逻辑：最多 6 条，单条和总长度限制。
8. 写 Context Packet：绑定 run、assignment、role、source event ids、expires、packet_hash，Agent 启动前必须校验。

## 7. 面试官会怎么问

### Q1：你们这个项目用了 RAG 吗？

小白答案：用了“查资料再交给 Agent”的思想，但不是向量数据库那种 RAG。

正式面试答案：当前主链路是 SQLite FTS5/BM25 的 source-bound knowledge retrieval。它从任务字段构造 query，检索 role-visible、active、未被 supersede 的知识条目，截取 bounded excerpt，并通过 Context Packet 注入 Agent。没有实现 embedding/vector DB/reranker 作为主路径。

追问回答：这样选是因为工程规则里接口名、文件名、规则编号更依赖精确匹配；FTS5 本地零部署、可事务、可审计。以后可以在保持 source hash、roles、status 元数据的前提下加 vector recall，做 hybrid retrieval。

### Q2：为什么不用普通 prompt 粘贴知识？

小白答案：普通粘贴不知道来源，也不能检查有没有被改。

正式面试答案：Factory 把检索结果写成 Context Space 事件，再生成带 `packet_hash`、`source_event_ids`、`run_id`、`assignment_id`、`target_role`、`expires_at` 的 Context Packet。这样上下文能验证、能过期、能按角色隔离。

追问回答：如果有人把 verifier 私有事件挪到 implementer 的 trusted_context，就算重新计算 packet hash，`verifyContextPacket()` 仍会根据源事件 admission 和 role visibility 拒绝。

### Q3：knowledge entry 和 chunk 的区别是什么？

小白答案：entry 是带来源和权限的一条知识，chunk 通常只是文档切片。

正式面试答案：Factory 当前没有标准 chunk pipeline。检索单位是 knowledge entry，命中后再抽取 excerpt。entry 还绑定 source URI、source SHA、角色、生命周期状态、supersedes 和内容 hash。

追问回答：如果后续加 chunk，我会让 chunk 继承 entry 的 source binding 和 lifecycle，不允许 chunk 脱离原始 source 独立被信任。

---

# 第二部分：Agent 到底是怎么拆的？

## 1. 它是干什么的

Agent 拆分不是为了热闹，而是为了把“会互相污染的职责”分开：规划的人不直接改代码，改代码的人不能自己验收，通过的人必须独立复查证据。

Factory 里 Agent profile 是角色模板。源码里每个 profile 都写了能做什么、不能做什么、是否只读、有哪些 capabilities、对应哪些 skills。

## 2. 为什么不能只用一个 Codex Agent

如果一个 Agent 从头到尾负责：

```text
需求分析
↓
查资料
↓
改代码
↓
测试
↓
自己宣布通过
```

会有几个真实工程问题：

- 它会把“想完成任务”的动机带进验收，容易宽松判断。
- 它可能读到太多无关历史上下文，把旧方案带进新任务。
- 它可能边做边改任务范围，最后和原始需求不一致。
- 它可能越权修改别的模块，还在总结里不提。
- 它可能测试失败但写“已修复”。
- 它可能临时查资料，但资料来源没有证据包。

Factory 的拆分逻辑是：让每个 Agent 只对一个有限职责负责，并用外部控制平面记录交接。

## 3. Factory 实际怎么实现

### 3.1 `factory_router`

【源码确认】

它什么时候出现：用户任务需要分类、架构路由、任务拆解、反过度设计判断时。

收到什么：用户需求、项目约束、Router 可见的 Context Packet。

能做什么：判断项目类型、决定是否多 Agent、设计任务 DAG、判断角色和能力需求。

不能做什么：不能直接实现代码，profile 是 read-only。

输出什么：任务图、角色分配、架构/范围决策。

下一棒交给谁：通常交给 Orchestrator 生成 assignments，也可能交给 Librarian 检索知识。

### 3.2 `factory_librarian`

【源码确认】

它什么时候出现：需要为任务选择知识、技能、来源时。

收到什么：任务描述、角色、可见知识库、Context Packet。

能做什么：知识检索、source verification、skill curation。

不能做什么：不能改业务代码，不能把不可信前端摘要升级为专业知识。

输出什么：候选知识、来源说明、给某个角色的上下文建议。

下一棒交给谁：Implementer、Tester、Verifier 或主控。

### 3.3 `factory_verifier`

【源码确认】

它什么时候出现：任何非 verifier 任务 handoff 后，Factory 会自动增加 `verify-xxx` 任务，由 verifier 接棒。

收到什么：Worker handoff、artifacts、acceptance_methods、Context Packet、真实文件系统状态。

能做什么：重跑命令、检查 exit code、重算 artifact hash、验证 required artifacts、出 verification receipt。

不能做什么：不能相信 Worker 自报；不能在证据缺失时 PASS；通常 read-only。

输出什么：`VerificationReceipt`，verdict 为 PASS 或 FAIL。

下一棒交给谁：主控 Orchestrator。PASS 后依赖它的任务才可继续。

### 3.4 `factory_drift_auditor`

【源码确认】

它什么时候出现：需要检查上下文、范围、契约、架构、证据是否偏离时。

收到什么：任务图、Context Space、registry、handoff、evidence、源码状态。

能做什么：drift-audit、scope-audit、contract-audit。

不能做什么：不修复问题，不替代 verifier 给 PASS。

输出什么：漂移报告或风险报告。

下一棒交给谁：主控，主控决定是否开 repair task。

### 3.5 `factory_researcher`

【源码确认】

它什么时候出现：需要外部资料、官方文档、最新 API 信息时。

收到什么：研究问题、搜索约束、可用 search 配置。

能做什么：web/documentation research、生成 evidence pack。

不能做什么：不能把搜索结果无证据地当事实，不能绕过搜索 fail-closed。

输出什么：search evidence bundle 或研究证据。

下一棒交给谁：Librarian 或 Implementer。

### 3.6 `factory_implementer`

【源码确认】

它什么时候出现：有明确实现任务、write_scope 和验收方法时。

收到什么：FACTORY_ASSIGNMENT、Context Packet、允许修改路径、acceptance_methods、required_artifacts。

能做什么：在 write_scope 内实现前端/后端/数据库/auth 等变更。

不能做什么：不能改 write_scope 外文件；不能 spawn 子 Agent；不能自己宣布 PASS。

输出什么：handoff，包含 summary、changed_paths、artifacts、commands、proposed_verdict。

下一棒交给谁：Verifier。

### 3.7 `factory_tester`

【源码确认】

它什么时候出现：需要补测试、跑 smoke/e2e/negative tests 时。

收到什么：测试任务 assignment、要验证的功能范围、允许写的测试文件。

能做什么：写测试、运行测试、收集测试证据。

不能做什么：不能替代 verifier 宣布最终完成；不能超范围改业务代码。

输出什么：测试 artifacts、命令结果、handoff。

下一棒交给谁：Verifier 或 Integrator。

### 3.8 `factory_integrator`

【源码确认】

它什么时候出现：多个 Worker 输出都通过验证，需要集成、解决冲突、准备 release 时。

收到什么：已验证 handoff、artifacts、验证 receipts、可能的冲突信息。

能做什么：整合已验证产物，处理冲突，做 release 级别收尾。

不能做什么：不能集成未验证输出；不能绕过 verifier。

输出什么：集成 handoff、release artifacts。

下一棒交给谁：Verifier 或主控闭环。

## 4. 举一个完整例子

“增加登录功能”里可能发生：

1. Router 先判断这是 auth-security + backend + testing 任务。
2. Librarian 找到 auth policy、API contract、test policy。
3. Implementer 只改 `src/login.ts`。
4. Tester 只改 `tests/login.test.ts`。
5. Integrator 处理登录接口和测试之间的命名/路径一致性。
6. Verifier 重跑 `npm test -- login`，检查 artifact 和 receipt。
7. Drift Auditor 可以检查有没有越权改 `src/database.ts` 或使用旧接口。

## 5. 数据到底怎么流

```text
User
↓ 需求文本
Router
↓ 任务 DAG、角色、能力、write_scope
Orchestrator
↓ assignments + Context Packet
Librarian
↓ role-visible knowledge retrieval
Implementer / Tester / Researcher
↓ handoff + artifacts + commands
Verifier
↓ verification receipt
Integrator
↓ verified integration handoff
Drift Auditor
↓ drift report / risk report
Main controller
↓ VERIFIED 或 repair task
```

## 6. resident 和 temporary 为什么这样分

Router/Librarian/Verifier/Drift Auditor 适合 resident，因为它们代表长期制度角色：

- Router 代表项目方法论和任务拆解纪律。
- Librarian 代表知识治理纪律。
- Verifier 代表独立验收纪律。
- Drift Auditor 代表长期漂移审计纪律。

Implementer/Tester/Researcher/Integrator 适合 temporary，因为它们更像一次性施工队：

- 任务做完就交 handoff。
- 不需要带着旧任务上下文长期存在。
- 避免“上一个任务的实现细节”污染下一个任务。

【源码确认】即使 resident，Factory 也要求每个 assignment fresh execution。测试里专门验证了 resident 完成一次 bounded handoff 后，下次仍然要 fresh spawn，不能复用旧 native agent。

如果所有 Agent 都长期保留，最大问题是上下文残留：某个 Implementer 记住了上个项目的数据库结构，下次登录任务就可能把旧字段写进新项目。这正是 Factory 要避免的。

## 7. 面试官会怎么问

### Q1：为什么不一个 Agent 干到底？

小白答案：一个人又写又验，容易给自己放水。

正式面试答案：Factory 把 planning、knowledge retrieval、implementation、testing、integration、verification、drift audit 拆开，核心是降低上下文污染和自证完成风险。Worker 只能 handoff，Verifier 用独立 native id 复查。

追问回答：这里不是简单多开几个模型，而是每个 Agent 有 profile、capabilities、read_only、write_scope、Context Packet、handoff contract。

### Q2：resident 是不是一直运行的 Agent？

小白答案：不是。它更像固定岗位，不是固定聊天窗口。

正式面试答案：resident 表示 durable specialist profile。源码里的 spawn plan instructions 明确说 resident 不是可复用 conversation，每个 assignment 仍 fresh isolated execution。

追问回答：这样做是为了保留角色纪律，又避免上下文残留。

### Q3：Implementer 为什么不能 PASS？

小白答案：写代码的人不能自己判卷。

正式面试答案：Implementer 的输出是 `FACTORY_HANDOFF_JSON`，状态是 `RECORDED_UNVERIFIED`。只有 verifier 读取 handoff、复查 artifacts、重跑 acceptance methods、生成 receipt 后，任务状态才可能变成 verified。

追问回答：测试覆盖了“unverified handoff 不会提升为 completed/verified”。

---

# 第三部分：多 Agent 编排到底怎么运行？

## 1. 它是干什么的

多 Agent 编排就是把“一个大需求”变成“多个有顺序、有边界、有验收方式的施工单”，再按依赖和资源限制启动 Agent。Factory 不是让 Agent 自由群聊，而是让控制平面决定谁能开始、拿什么上下文、能改哪些文件、怎么验收。

## 2. 为什么需要它

假设需求是“给 Web 项目增加用户登录功能，并增加测试”。如果两个 Agent 同时乱改：

- A 改 `src/login.ts`，B 也改 `src/login.ts`，互相覆盖。
- A 还没定义接口，B 就按自己猜的接口写测试。
- A 把函数叫 `createUser()`，B 调 `registerUser()`。
- A 测试失败但说完成，B 又基于失败代码继续做。

编排层要解决的是：谁先谁后、谁能并行、谁不能并行、什么时候算真的完成。

## 3. Factory 实际怎么实现

### 3.1 一个 Task 在源码里长什么样

【源码确认】`FactoryTask` 的关键字段是：

```json
{
  "task_id": "auth-login-api",
  "title": "Implement login API",
  "description": "Add login endpoint with server-side validation.",
  "role": "implementation",
  "profile_id": "factory_implementer",
  "required_capabilities": ["backend", "auth-security"],
  "status": "pending",
  "dependencies": ["auth-analysis"],
  "write_scope": ["src/login.ts"],
  "acceptance_methods": ["command:npm test -- login"],
  "required_artifacts": ["src/login.ts"]
}
```

字段解释：

- `task_id`：任务身份，后续 registry、handoff、receipt 都靠它绑定。
- `title/description`：给 Agent 理解任务，也用于构造知识检索 query。
- `role/profile_id/required_capabilities`：决定派给哪个 Agent profile。
- `status`：pending、assigned、in_progress、handoff、verified、failed 等。
- `dependencies`：依赖谁。普通任务只有依赖 verified 才能 ready。
- `write_scope`：允许写哪些路径。
- `acceptance_methods`：怎么验收，比如文件存在、JSON 可解析、命令 exit code 为 0。
- `required_artifacts`：必须交付并绑定 hash 的产物。

### 3.2 DAG 是如何形成的

【源码确认 + 合理推断】

源码确认：`prepareSpawnPlan()` 接收 `FactoryTask[]`，不从自然语言直接自动规划业务 DAG。它负责校验和执行这个 DAG。任务通常由主控/Router 根据用户需求产生，这是 profile 设计和 prompt 层承担的职责。

程序会检查：

- 每个 task id 唯一。
- dependencies 都存在。
- 不能有循环依赖。
- status 不能由调用方伪造成 verified。
- write_scope 不能路径逃逸。
- acceptance_methods 必须至少有一个。
- required_capabilities 必须被对应 profile 支持。

如果 A 没完成，B 为什么不能执行？因为 B 的 dependencies 里有 A。`selectReadyTasks()` 对普通任务要求依赖已经 verified；对 verifier 任务则允许在目标任务 handoff 后执行。

### 3.3 `prepareSpawnPlan()` 具体干什么

输入：

- 项目根目录
- run id
- 一组 FactoryTask
- Factory config，比如 multi_agent 是否开启、max_threads、external_context 是否开启

它做几轮检查：

1. 读取配置，确认 multi-agent enabled、execution_mode 是 `codex_native`、max_depth 是 1。
2. 自动追加 verifier 任务：每个非 verifier task 后面都加 `verify-xxx`。
3. 校验 DAG：缺依赖、循环、非法 status、非法 write_scope 都拒绝。
4. 初始化/验证 Context Space 和 Knowledge Store。
5. 检查是否有上次计划但还没 native dispatch 的 assignment，避免孤儿 wave。
6. 读取 registry，看哪些任务已在跑、哪些已 handoff、哪些已 verified。
7. 选择 ready tasks：受依赖、max_threads、resident 唯一性、write_scope 冲突限制。
8. 为每个选中任务生成 Context Packet。
9. 记录 filesystem baseline。
10. 写出 spawn plan、task graph、agent registry、run metadata 和各种 hash。

输出：

- `.codex-factory/runs/<run_id>/spawn-plan.json`
- `.codex-factory/runs/<run_id>/task-graph.json`
- `.codex-factory/runs/<run_id>/agent-registry.json`
- Context Packet 文件
- baseline 文件

为什么自动增加 `verify-xxx`：因为 Factory 的核心原则是 Worker handoff 不能等于 PASS。每个任务都要有独立验证路径。

### 3.4 FACTORY_ASSIGNMENT 是什么

可以把它理解成“给工人的施工单”。一个简化例子：

```json
{
  "run_id": "run-auth-001",
  "assignment_id": "assignment-login-api-001",
  "project_root": "C:/project/web-app",
  "task": {
    "task_id": "auth-login-api",
    "role": "implementation",
    "title": "Implement login API"
  },
  "context_packet_path": ".codex-factory/context/packets/assignment-login-api-001.json",
  "write_scope": ["src/login.ts"],
  "acceptance_methods": ["command:npm test -- login"],
  "required_artifacts": ["src/login.ts"],
  "forbidden": [
    "do not spawn child agents",
    "do not edit outside write_scope",
    "do not mark your own work PASS"
  ]
}
```

这不是源码原始 JSON，而是符合真实字段含义的教学版。真实 prompt 还会要求 Agent 先验证 Context Packet，并在最后输出单行 `FACTORY_HANDOFF_JSON`。

### 3.5 Agent 到底怎么被真正启动

流程是：

```text
prepareSpawnPlan()
↓ 生成 assignment.prompt
主控调用 Codex spawn_agent
↓ PreToolUse hook 拦截
检查 prompt 是否是计划内 FACTORY_ASSIGNMENT、fork_turns 是否 none
↓ Codex 宿主真正创建 Agent
返回 native agent id
↓ PostToolUse hook 读取宿主返回
registerNativeDispatch()
↓ 写 registry + native receipt + Context Space agent_event
```

为什么不能相信 Agent 自己说“我是 Agent 123”？因为 Agent 可以输出任何文本。真实身份必须来自宿主工具返回，也就是 Codex 平台创建子 Agent 后的返回值。Factory 把这个 native id 和 assignment id、run id、tool receipt hash 绑定起来。

为什么 Agent 不能自己 spawn 子 Agent？因为 `max_depth` 固定为 1，assignment prompt 禁止 child agents，PreToolUse 会拒绝 unmanaged spawn。这样所有并发都由主控调度，避免子 Agent 私自扩散。

### 3.6 Handoff 是什么

Implementer 做完后交的是 handoff，里面包括：

- `summary`：做了什么
- `changed_paths`：自己声明改了哪些路径
- `artifacts`：产物路径和 SHA-256
- `commands`：跑过什么命令、exit_code 是多少
- `proposed_verdict`：Worker 自己建议 PASS/FAIL/BLOCKED
- `caveats/unresolved_risks`：风险说明

【源码确认】handoff 写入后状态是 `RECORDED_UNVERIFIED`。这句话特别重要：它表示“系统记录了这个交接，但还没有承认它通过”。

Verifier 接棒后，读取这个 handoff，重新检查 artifacts 和 acceptance_methods，最后写 verification receipt。

## 4. 举一个完整例子

需求：给 Web 项目增加登录功能，并增加测试。

一种符合 Factory 思路的任务图：

```text
auth-analysis
↓
auth-login-api
↓
auth-login-tests
↓
auth-integration
```

Factory 会自动变成：

```text
auth-analysis → verify-auth-analysis
auth-login-api → verify-auth-login-api
auth-login-tests → verify-auth-login-tests
auth-integration → verify-auth-integration
```

如果 `auth-login-tests` 依赖 `auth-login-api`，那么 API 未 verified 前，测试任务不会执行。不是因为 Agent 不想执行，而是调度器不会把它选入 ready assignments。

如果 `auth-login-api` 和 `auth-login-tests` write_scope 不冲突，并且依赖允许，它们可以并行。若两个任务都要改 `src/login.ts`，其中一个会被 blocked，原因是 `scope:<task_id>`。

## 5. 数据到底怎么流

```text
FactoryTask[]
↓ validateTaskGraph(): 查字段、依赖、循环、scope、capabilities
任务 DAG
↓ addAutomaticVerificationTasks()
带 verify-xxx 的任务图
↓ selectReadyTasks()
当前 wave 可派发任务
↓ createAssignmentPacket()
Context Packet
↓ writeAssignmentBaseline()
开工前文件系统快照
↓ assignmentPrompt()
FACTORY_ASSIGNMENT prompt
↓ hooks + spawn_agent
真实 native Agent
↓ recordAgentHandoff()
RECORDED_UNVERIFIED handoff
↓ verifyTaskCompletion()
VerificationReceipt
↓ setRunTaskStatus()
verified 或 failed
```

## 6. 我从零实现的话怎么做

1. 定义 Task schema：id、role、status、dependencies、write_scope、acceptance_methods、artifacts。
2. 写 DAG validator：查唯一 ID、缺依赖、循环依赖、非法状态、路径逃逸。
3. 写 profile router：根据 role/capability 映射到 Agent profile。
4. 写 ready selector：依赖 verified 才能跑，scope 冲突不能并行，max_threads 控制并发。
5. 自动为每个 Worker task 加 verifier task。
6. 每个 assignment 生成 Context Packet 和 filesystem baseline。
7. 用 hook 拦截 spawn，确保只有计划内 assignment 能启动。
8. Worker 只能 handoff，Verifier 独立复查后写 receipt。

## 7. 面试官会怎么问

### Q1：DAG 在你们项目里具体是什么？

小白答案：就是任务之间的先后关系图。

正式面试答案：FactoryTask 的 `dependencies` 构成 DAG。`validateTaskGraph()` 检查依赖存在、无循环、状态合法；`selectReadyTasks()` 根据依赖 verified/handoff 状态决定当前 wave。

追问回答：普通任务依赖 verified；verifier 任务依赖目标任务 handoff，因为 verifier 的职责就是验证 handoff。

### Q2：`prepareSpawnPlan()` 是不是执行 Agent？

小白答案：不是。它准备施工计划。

正式面试答案：它生成 spawn plan、assignment prompt、Context Packet、baseline、registry 初始记录，并把 task graph 持久化。真正启动由主控调用 native spawn_agent，hook 再绑定真实返回。

追问回答：这样能把“计划”与“宿主实际创建 Agent”分离，避免 Agent 自己伪造启动状态。

### Q3：为什么要自动加 `verify-xxx`？

小白答案：为了让另一个人检查。

正式面试答案：Worker handoff 只是未验证证据。自动 verifier task 强制每个非 verifier 输出经过 independent verification，最终以 receipt 决定任务 PASS/FAIL。

追问回答：测试覆盖了 verifier command 失败、handoff 篡改、receipt 不可变、worker/verifier 不是同一 native id 等场景。

---

# 第四部分：Factory 到底怎么防 Agent 漂移？

## 1. 它是干什么的

漂移就是 Agent 做着做着偏离了原本的任务、上下文、权限、接口或完成标准。在 AI Coding 里，漂移通常不是恶意攻击，而是模型“顺手修一下”“参考了旧内容”“把未验证输出当事实”“测试没过但总结得很好”。

Factory 的防漂移策略是：所有关键动作都要外部记录、hash 绑定、角色隔离、范围约束、独立验证。

## 2. 为什么需要它

贯穿例子：原始任务是：

```text
只修改 src/login.ts 和 tests/login.test.ts，增加登录校验。
```

Agent 可能漂移成：

- 顺手改了 `src/database.ts`
- 使用过期 `auth-api-v1.md`
- 把 verifier 私有规则带进 implementer
- 自己又开了一个未经授权 Agent
- 测试失败却说“已完成”
- A Agent 导出 `createUser()`，B Agent 仍调用 `registerUser()`
- handoff 说只改 1 个文件，实际改了 4 个

Factory 要做的不是事后抱怨，而是把这些问题变成可检测的失败。

## 3. Factory 实际怎么实现

### A. 上下文漂移

【源码确认】Context Packet 的字段各防一种具体错误：

- `run_id`：防止拿别的运行的上下文包。比如 `run-old` 的登录决策被拿到 `run-new`，验证时 run 不匹配。
- `assignment_id`：防止 A 任务 packet 被 B 任务复用。比如 `assignment-login-api` 的上下文被测试任务使用，验证时 assignment 不匹配。
- `target_role`：防止角色串线。比如 verifier 私有事件被塞给 implementation，验证时 role visibility 不通过。
- `packet_hash`：防止 packet 文件被手改。改一个字段 hash 就对不上。
- `ledger_head_hash`：防止生成 packet 后账本被篡改成另一条链。
- `source_event_ids`：防止偷偷加入未选择的事件。验证会对照源事件集合。
- `expires_at`：防止拿很久以前的上下文继续施工。

### B. 知识漂移

【源码确认】知识库会记录：

- `source_uri`：知识来自哪个项目文件。
- `source_sha256`：导入时源文件的 hash。
- `content_hash` / `content_digest`：知识内容本身有没有被改。
- `store_root_hash`：整个知识库的锚点 hash。
- `active / retired / revoked`：生命周期。
- `supersedes`：版本替代关系。

例子：`auth-api-v1.md` 说登录接口是 `/signin`，后来 `auth-api-v2.md` 改成 `/api/login` 并 supersedes V1。查询时只返回 active leaf V2。如果有人改了 V2 源文件但没重新导入，`verifyKnowledgeStore()` 会发现 source digest mismatch，assignment planning 直接 fail closed。

### C. Agent 身份漂移

【源码确认】

- native agent id：Codex 宿主实际创建 Agent 后返回的真实 ID。
- registry：Factory 记录 assignment 和 native id 的绑定。
- hook：在工具调用前后拦截，保证这个绑定来自真实工具回执。

为什么 registry 登记了也不代表完成？因为 registry 只说明“这个 assignment 被某个真实 native Agent 接走了”。它不说明代码正确，不说明测试通过，也不说明 artifacts 没被篡改。完成必须看 handoff 和 verification receipt。

### D. write_scope 漂移

【源码确认】假设 assignment 规定只能改：

```text
src/login.ts
tests/login.test.ts
```

Agent 实际改了：

```text
src/login.ts
src/database.ts
package.json
```

Factory 怎么知道？

1. 派发前，`prepareSpawnPlan()` 记录 filesystem baseline，也就是开工前每个文件的 hash/状态。
2. Agent 完工后，handoff 声明 `changed_paths`。
3. `recordAgentHandoff()` 不只看声明，而是读取真实文件系统变化。
4. 系统把真实 diff 和 write_scope 比较。
5. `src/database.ts` 和 `package.json` 不在 write_scope，就拒绝 handoff。
6. 如果 Agent 实际改了 3 个文件，却只在 handoff 写 `src/login.ts`，也会因为 unreported diff 被拒绝。

这不是“靠 Agent 诚实汇报”，而是“用开工前 baseline 对比完工后真实文件”。

### E. 完成状态漂移

【源码确认】Worker 说：

```text
我完成了，测试通过。
```

系统不直接相信。真实顺序是：

1. Worker handoff 被记录为 `RECORDED_UNVERIFIED`。
2. Verifier 必须是 `factory_verifier` profile。
3. Verifier 必须有不同 native agent id。
4. Verifier 读取 Worker handoff。
5. 系统重算 artifacts 当前 hash，和 Worker handoff 里的 hash 比较。
6. 系统重跑 task 的 acceptance_methods，比如 `command:npm test -- login`。
7. 命令 exit code 非 0 就 FAIL。
8. required artifacts 缺失就 FAIL。
9. verifier 自己 handoff 里有失败命令也 FAIL。
10. 只有没有 failure reasons，receipt verdict 才是 PASS。

最终 PASS 条件：worker handoff 绑定正确、verifier handoff 绑定正确、artifact checks PASS、acceptance checks PASS、verifier proposal PASS、命令 exit code 都通过、receipt hash 写入且不可变。

### F. 接口漂移

【源码确认：harness 层】两个 Agent 并行开发：

- Agent A 在 `src/user.ts` 导出 `createUser()`
- Agent B 在 `src/login.ts` 仍然调用 `registerUser()`

Interface Drift Gate 的做法：

- `interface-contract.lock.json`：开工前锁定接口，写清楚 `interfaceId`、接口名、文件、owner、requiredBy。
- Worker manifest：每个 Worker 声明自己实际 export/import 了什么。
- Source-derived manifest：脚本从 TypeScript 源码正则抽取 export/import。
- Honesty report：比较 Worker 声称和源码实际。
- Drift report：比较所有 Worker manifest 和 contract lock。
- Integration gate：drift report PASS 才允许集成。

【未实现/主链路边界】`harness` 的 `validate-state.ps1` 已经检查 interface drift report、manifest honesty report、integration gate；U0-D verifier 里还有 real workers used 的证据检查。但在 `packages/factory-cli/src/orchestrator.ts` 主调度代码里，我没有看到每个 assignment 自动生成 interface contract 并自动执行 drift scripts 的内建流程。所以讲面试时要说：接口漂移门是 harness 验证能力，已经有脚本和验证链路；不是当前 V5 CLI orchestrator 对每个任务默认内建的自动步骤。

## 4. 举一个完整例子

任务：只允许改 `src/login.ts`、`tests/login.test.ts`。

Agent 做完后 handoff：

```json
{
  "summary": "Added login validation.",
  "changed_paths": ["src/login.ts"],
  "artifacts": [{ "path": "src/login.ts", "sha256": "..." }],
  "commands": [{ "command": "npm test -- login", "exit_code": 0 }],
  "proposed_verdict": "PASS"
}
```

但真实文件系统显示：

```text
src/login.ts       changed
tests/login.test.ts changed
src/database.ts    changed
package.json       changed
```

Factory 会拒绝，因为：

- `tests/login.test.ts` 改了但未声明，是 unreported。
- `src/database.ts` 和 `package.json` 不在 write_scope，是 out-of-scope。
- 即使 Worker 写了 PASS，也只是 proposed_verdict，不是系统 verdict。

## 5. 数据到底怎么流

```text
Assignment.write_scope
↓
prepareSpawnPlan() 记录 baseline
↓
Worker 修改文件
↓
Worker handoff 声明 changed_paths/artifacts/commands
↓
recordAgentHandoff() 对比真实 diff 和 write_scope
↓ 如果通过
RECORDED_UNVERIFIED
↓
Verifier 重跑 acceptance_methods、重算 artifact hash
↓
VerificationReceipt
↓
Task status = verified 或 failed
```

## 6. 我从零实现的话怎么做

1. 每个 assignment 必须有 write_scope，空数组表示只读。
2. 派发前记录文件系统 baseline。
3. Agent 完成后必须提交 handoff JSON。
4. 读取真实 diff，不只信 handoff。
5. 真实 diff 必须等于 handoff 声明，且必须落在 write_scope 内。
6. artifacts 必须存在并计算 hash。
7. verifier 必须是另一个 native Agent。
8. verifier 重跑验收命令并生成不可变 receipt。
9. 接口类任务额外加 contract lock + manifest + drift detector。

## 7. 面试官会怎么问

### Q1：什么是 Agent 漂移？

小白答案：Agent 做着做着偏题了。

正式面试答案：在 AI Coding 中，漂移包括上下文漂移、知识版本漂移、身份漂移、文件范围漂移、完成状态漂移和接口契约漂移。Factory 用 Context Packet、source hash、hooks、registry、baseline diff、verification receipt、interface drift gate 分别处理。

追问回答：重点是把漂移从“主观感觉”变成“机器能检查的失败条件”。

### Q2：write_scope 怎么防越权？

小白答案：先规定能改哪些文件，最后查它到底改了哪些。

正式面试答案：`prepareSpawnPlan()` 给 assignment 写入 write_scope 并记录 filesystem baseline；`recordAgentHandoff()` 比较 baseline 与当前文件状态，得到真实 diff，再和 handoff changed_paths、write_scope 交叉验证。超范围、漏报、虚报都拒绝。

追问回答：测试里有 out-of-scope 文件被改但 handoff 没声明的负例，系统会因为 baseline/diff 拒绝。

### Q3：Verifier 为什么还要看 command exit code？

小白答案：因为“我测试过了”不算数，命令结果才算数。

正式面试答案：`executeAcceptanceMethod()` 会执行 `command:` 方法，把 stdout/stderr 写到 verification 目录并记录 hash、duration、exit code。非 0 直接形成 failure reason。

追问回答：这样能避免 Worker 把失败测试包装成成功总结。

### Q4：接口漂移现在是主链路吗？

小白答案：不是完全主链路，是 harness 验证层能力。

正式面试答案：Factory 有 `detect-interface-drift.ps1`、`extract-source-interface-manifest.ps1`、`compare-worker-manifest-to-source.ps1` 和 `validate-state.ps1` 的相关 gate。它能发现 contract、manifest、源码抽取之间的 export/import 不一致。但在 V5 CLI orchestrator 里未看到默认对每个 assignment 自动执行这些脚本。

追问回答：如果继续工程化，我会把 interface contract 作为 task graph 的 artifact，在 selected wave 前锁定，在 handoff 后自动抽取 manifest，并把 drift report 作为 verifier 的 required artifact。

---

# 第五部分：把所有东西串成一次完整运行

## 1. 它是干什么的

这一章把前面所有机制放进一个真实案例里：用户要求“给一个现有项目增加用户登录功能，并增加测试”，Factory 如何从输入走到 VERIFIED。

## 2. 为什么需要串起来看

单独看 RAG、多 Agent、Verifier 都容易变成概念。真正的项目理解，是知道一个数据对象如何流到下一个对象：Task 如何变 Assignment，Knowledge 如何变 Context Packet，Worker handoff 如何变 Receipt。

## 3. Factory 实际怎么实现

### 3.1 用户输入

用户说：

```text
给这个 Web 项目增加用户登录功能，并增加测试。
```

主控/Router 做项目理解：这是 auth-security + backend + testing，可能需要：

- 分析现有 auth 结构
- 实现 login API
- 增加 login tests
- 集成路由/错误格式
- 独立验证

【源码确认边界】源码确认了 Router profile 和任务图调度机制；从自然语言自动生成业务 DAG 的具体 LLM 规划不是 TypeScript 函数硬编码实现。

### 3.2 DAG

形成任务图：

```text
auth-analysis
↓
auth-login-api
↓
auth-login-tests
↓
auth-integration
```

每个任务都有 write_scope 和 acceptance_methods。`prepareSpawnPlan()` 检查它不是循环图，依赖存在，不能伪造 verified。

### 3.3 Librarian + FTS5 knowledge retrieval

对 `auth-login-api`：

输入：task title、description、acceptance_methods、required_artifacts、role implementation。

检索：

```text
SQLite state.db
↓
knowledge_entries_fts MATCH
↓
BM25 排序
↓
lexical fallback 补短词/中文/接口名
↓
active + role-visible + source-bound 过滤
```

输出：比如 auth policy、API contract、test policy 的 bounded excerpts。

### 3.4 Context Packet

检索结果作为 `knowledge_retrieval` 写入 Context Space，然后生成 Context Packet：

```text
run_id = run-auth-001
assignment_id = assignment-login-api
target_role = implementation
trusted_context = [task_state, knowledge_retrieval]
source_event_ids = [...]
packet_hash = ...
expires_at = ...
```

Implementer 不继承全部聊天历史，只收到这个 packet 的路径和施工单。

### 3.5 Assignment

Orchestrator 给 Implementer：

```text
你是 factory_implementer
任务：实现 login API
只能写：src/login.ts
验收：command:npm test -- login
必须交付：src/login.ts
上下文：Context Packet 路径
禁止：子 Agent、自判 PASS、越权改文件
```

### 3.6 Implementer

Implementer 验证 packet，读取 trusted context，修改 `src/login.ts`。做完后输出 handoff：

```text
summary: 增加登录校验
changed_paths: src/login.ts
artifacts: src/login.ts + sha256
commands: npm test -- login exit_code=0
proposed_verdict: PASS
```

系统记录 handoff，但状态是 `RECORDED_UNVERIFIED`。

### 3.7 Tester

如果测试是单独任务，Tester 可能收到：

```text
任务：补 tests/login.test.ts
依赖：auth-login-api verified
write_scope: tests/login.test.ts
acceptance: command:npm test -- login
```

如果 `auth-login-api` 未 verified，Tester 不能 ready。这样避免测试基于未验证接口开工。

### 3.8 Verifier

Factory 自动追加 `verify-auth-login-api`。Verifier 接棒：

1. 确认自己是 `factory_verifier`。
2. 确认 native id 不同于 Worker。
3. 读取 Worker handoff。
4. 重算 `src/login.ts` hash。
5. 检查 required artifact 存在。
6. 重跑 `npm test -- login`。
7. 记录 stdout/stderr hash 和 exit code。
8. 写 verification receipt。

只有 receipt verdict PASS，`auth-login-api` 才变成 verified。

### 3.9 Evidence + receipt + drift check

过程中形成：

- native spawn receipt：证明真实 Agent 被宿主创建。
- handoff：证明 Worker 交付了什么，但未验证。
- artifact hash：证明产物当时长什么样。
- command evidence：证明命令实际怎么跑。
- verification receipt：证明独立 verifier 检查过。
- baseline/diff check：证明没有越权文件变化。
- optional interface drift report：如果启用 harness 接口门，证明 export/import 没漂。

### 3.10 最终 VERIFIED

只有当所有依赖任务都 verified，集成任务也 verified，主控才可以说最终完成。否则即使 Worker 写了“已完成”，Factory 也不会把它当成工程事实。

## 4. 举一个完整例子

最终运行像这样：

```text
User: 增加登录功能和测试
↓
Router: 生成 auth-analysis / auth-login-api / auth-login-tests / auth-integration DAG
↓
Orchestrator: 校验 DAG，自动追加 verify-*，生成 spawn plan
↓
Librarian/RAG: 用 FTS5 找 auth policy/API contract/test policy
↓
Context Space: 写 knowledge_retrieval 事件
↓
Context Packet: 绑定 run/assignment/role/source/hash/expires
↓
Implementer: 只改 src/login.ts，提交 handoff
↓
recordAgentHandoff: baseline 对比真实 diff，确认没越权
↓
Verifier: 重算 hash，重跑 npm test -- login
↓
VerificationReceipt: PASS
↓
Tester: 补 tests/login.test.ts，提交 handoff
↓
Verifier: 重跑测试，receipt PASS
↓
Integrator: 整合已验证输出
↓
Drift Auditor / harness gate: 检查接口、范围、上下文、证据漂移
↓
最终 VERIFIED
```

## 5. 数据到底怎么流

```text
自然语言需求
↓
FactoryTask[]
↓
SpawnPlanEntry / Assignment
↓
Context Packet
↓
Native Agent
↓
Handoff
↓
Evidence
↓
Verification Receipt
↓
Task status verified/failed
↓
下一批 ready tasks
```

## 6. 我从零实现的话怎么做

如果让我现场设计类似系统，我会按这个顺序：

1. 定义任务图 schema，不允许无验收方法的任务。
2. 定义 Agent profiles，把规划、实现、测试、验证隔离。
3. 设计外部知识库：source-bound + role-visible + lifecycle + FTS5。
4. 设计 Context Packet：run/assignment/role/hash/source/expiry。
5. 写 orchestrator：校验 DAG、选 ready tasks、生成 assignment。
6. 写 hook：拦截未授权 spawn，绑定真实 native id。
7. 写 handoff recorder：记录 Worker 声明并校验真实 diff。
8. 写 verifier：重跑 acceptance，生成 receipt。
9. 写 drift gates：知识漂移、上下文漂移、scope 漂移、接口漂移。
10. 写测试：每个 gate 都要有正例和负例。

## 7. 面试官会怎么问

### Q1：你能从头讲一次运行吗？

小白答案：先拆任务，再查知识，再派 Agent，做完交接，最后独立验证。

正式面试答案：用户需求先被 Router/主控转成 FactoryTask DAG；orchestrator 校验 DAG 并自动加 verifier tasks；Librarian/knowledge retrieval 从 SQLite FTS5 找 role-visible/source-bound 知识，写入 Context Space 并生成 Context Packet；Implementer/Tester 按 assignment 和 write_scope 工作，handoff 只是未验证证据；Verifier 重跑 acceptance methods、检查 artifacts 和 hash，写 verification receipt；依赖任务 verified 后下游任务才 ready。

追问回答：整个系统的权威来源顺序是物理文件/命令结果/receipt，高于 Agent 自述和前端摘要。

### Q2：你在项目里最核心的工程取舍是什么？

小白答案：宁可慢一点，也要能查证。

正式面试答案：核心取舍是把模型上下文从“聊天记忆”迁移到外部可验证状态，把 Agent 输出从“自然语言结论”迁移到可复查的 handoff/receipt。这样牺牲了一些速度，但换来了长任务可靠性和可审计性。

追问回答：多 Agent 只在复杂任务启用，max_threads 有限制，小项目仍走简单流程，避免过度工程。

---

# 第六部分：四份复习材料

## A. 总架构图

```text
                             User
                              |
                              | 需求文本
                              v
                    +-------------------+
                    | Router / Main     |
                    | 任务分类、DAG规划 |
                    +-------------------+
                              |
                              | FactoryTask[]
                              v
                    +-------------------+
                    | Orchestrator      |
                    | validate DAG      |
                    | add verify-*      |
                    | select ready wave |
                    +-------------------+
                     /        |        \
                    /         |         \
                   v          v          v
        +-------------+  +-------------+  +----------------+
        | Knowledge   |  | Context     |  | Hooks          |
        | SQLite FTS5 |  | Space       |  | Pre/Post spawn |
        | BM25/fallback| | hash ledger |  | native id bind |
        +-------------+  +-------------+  +----------------+
                   \          |          /
                    \         |         /
                     v        v        v
                    +-------------------+
                    | Context Packet    |
                    | run/assignment/   |
                    | role/source/hash  |
                    +-------------------+
                              |
                              | FACTORY_ASSIGNMENT
                              v
        +----------------+  +----------------+  +----------------+
        | Implementer    |  | Tester         |  | Researcher     |
        | scoped writes  |  | tests/evidence |  | search evidence|
        +----------------+  +----------------+  +----------------+
                  \             |              /
                   \            |             /
                    v           v            v
                    +------------------------+
                    | Handoff                |
                    | changed_paths/artifacts|
                    | commands/proposed      |
                    +------------------------+
                              |
                              | RECORDED_UNVERIFIED
                              v
                    +-------------------+
                    | Evidence          |
                    | artifact hash     |
                    | command exit code |
                    | baseline diff     |
                    +-------------------+
                              |
                              v
                    +-------------------+
                    | Verifier          |
                    | independent check |
                    +-------------------+
                              |
                              | Verification Receipt
                              v
                    +-------------------+
                    | Drift Auditor     |
                    | context/knowledge |
                    | scope/interface   |
                    +-------------------+
                              |
                              v
                           VERIFIED
```

## B. 对象关系表

| 对象 | 谁创建它 | 里面有什么 | 交给谁 | 生命周期 |
|---|---|---|---|---|
| Task | Router/主控输入给 orchestrator | id、title、description、role、dependencies、write_scope、acceptance_methods、required_artifacts、status | Orchestrator | pending → assigned → in_progress → handoff → verified/failed |
| Assignment | Orchestrator | assignment_id、task_id、profile_id、Context Packet path、write_scope、prompt | Native Agent | planned → spawned/running → completed |
| Agent | Codex 宿主按 spawn_agent 创建 | native agent id、nickname、profile、assignment 绑定 | Registry / hooks | planned → spawned → running → completed |
| Context Packet | Context Space / Orchestrator | trusted_context、source_event_ids、run_id、assignment_id、target_role、expires_at、packet_hash | 对应 Agent | 生成 → 验证 → 过期 |
| Knowledge Entry | knowledge import/add | content、source_uri、source_sha256、roles、tags、status、supersedes、hash | Query/RAG | active → retired/revoked，或被 superseded |
| Handoff | Worker Agent | summary、changed_paths、artifacts、commands、proposed_verdict、handoff_hash | Verifier | recorded as RECORDED_UNVERIFIED |
| Artifact | Worker 产出，系统 hash | 文件/目录路径、sha256、kind | Evidence / Verifier | 绑定 handoff，后续重算 hash |
| Evidence | Factory control plane | handoff、artifact checks、command outputs、search bundles、ledger events | Verifier /主控 | candidate 或 admitted |
| Verification Receipt | Verifier / verification flow | worker/verifier assignment id、native ids、artifact checks、acceptance checks、verdict、receipt_hash | Orchestrator / downstream tasks | immutable，一旦写入不允许重写 |

## C. 5 分钟项目讲解

如果面试官让我详细介绍 Codex Factory，我会这样讲：

Codex Factory 是我围绕 AI Coding 长任务可靠性做的一个本地控制平面。它解决的不是“让模型更聪明”，而是让模型在复杂工程任务里不乱跑、不带错上下文、不越权改文件、不自己给自己判通过。

它的主流程是：用户给一个需求后，Factory 会把需求转成有依赖关系的任务图，也就是 DAG。每个任务都有明确角色、依赖、允许写的文件范围、验收方法和必须产物。Orchestrator 校验这个任务图，自动给每个 Worker 任务追加独立 verifier 任务，然后选择当前 ready 的任务派发。

在派发 Agent 前，它会做一层类似 RAG 的外部知识检索。但它当前不是向量 RAG，而是 SQLite FTS5/BM25 的 source-bound knowledge retrieval。知识条目来自项目文件或受控输入，带 source_uri、source_sha256、roles、tags、status、supersedes 和 hash。系统会根据任务标题、描述、验收方法等生成 query，只取当前角色可见、active、来源仍然一致的少量知识 excerpt。然后它不是把这些结果随便粘进 prompt，而是写进 Context Space，再生成 Context Packet。这个 packet 绑定 run、assignment、target role、source event ids、ledger hash 和过期时间，Agent 开工前要验证。

Agent 方面，Factory 拆成 Router、Librarian、Verifier、Drift Auditor 四个 resident profile，以及 Researcher、Implementer、Tester、Integrator 四个 temporary profile。resident 是长期岗位模板，不是长期复用对话。每个 assignment 都 fresh spawn，避免旧上下文污染。Implementer 只在 write_scope 内写代码，Tester 写测试，Researcher 负责外部证据，Integrator 只整合已验证结果。

真正关键的是它不相信 Agent 自己说“完成”。Worker 做完只能交 handoff，里面声明 changed_paths、artifacts、commands 和 proposed_verdict。Factory 会用开工前 baseline 对比真实文件 diff，发现越权或漏报就拒绝 handoff。handoff 被记录后状态是 RECORDED_UNVERIFIED。之后必须由不同 native agent id 的 Verifier 接棒，重跑 acceptance command、检查 exit code、重算 artifact hash、确认 required artifacts，并写 verification receipt。只有 receipt PASS，任务才变 verified，下游任务才可以继续。

为了防漂移，Factory 还做了几类约束：Context Packet 防上下文串线，source hash 防知识过期，hooks 防未授权 spawn，registry 绑定真实 native agent id，baseline/diff 防越权修改，receipt 防假通过。接口漂移方面，harness 里还有 contract lock + manifest + drift detector：开工前锁定接口，Worker 提交 export/import manifest，脚本对比 contract、manifest 和源码抽取结果，发现 createUser/registerUser 这种不一致就让 integration gate fail。

所以这个项目的核心不是某一个算法，而是一套 AI Agent 工程闭环：任务分解、受控检索、隔离执行、强制交接、独立验证和漂移检测。它把 AI Coding 从“模型说做完了”推进到“系统能用证据证明做完了”。

## D. 20 道递进式面试题

### 1. Factory 有没有 RAG？

参考答案：部分符合。它用了 retrieval-augmented context，但当前主链路不是 vector RAG，而是 SQLite FTS5/BM25/lexical fallback，从 source-bound knowledge store 检索知识，再通过 Context Packet 注入 Agent。

### 2. 它和标准 RAG 有什么不同？

参考答案：标准 RAG 通常是 chunk、embedding、vector DB、retrieve、rerank、prompt。Factory 当前没有 embedding/vector DB/rerank 主链路；它的检索单位是 knowledge entry，强调来源 hash、角色权限、生命周期、Context Packet 验证。

### 3. 为什么先用 FTS5，不直接向量库？

参考答案：工程知识里很多是精确术语，比如文件名、接口名、规则编号、错误码。FTS5 本地零部署、可事务、可审计，和 SQLite 控制平面天然一致。向量检索适合语义相似召回，后续可以加成 hybrid。

### 4. knowledge entry 是什么？

参考答案：一条带来源和权限的知识记录，包含 content、source_uri、source_sha256、roles、tags、status、supersedes、content/hash 等。它既是检索单位，也是防知识漂移的单位。

### 5. Factory 有没有 chunk？

参考答案：没有标准预切 chunk pipeline。当前导入知识形成 entry，命中后在 entry 内容中截取相关 excerpt。excerpt 是注入片段，不是向量 chunk。

### 6. Context Packet 解决什么？

参考答案：解决上下文可信和隔离。它把 trusted context、untrusted candidates、frontend notes 分开，并绑定 run、assignment、role、source_event_ids、ledger_head_hash、expires_at、packet_hash。

### 7. 为什么不信 frontend summary？

参考答案：前端摘要可能是压缩、遗漏、甚至被污染的信息。Factory 把 frontend_summary 放在 untrusted_frontend_notes，不允许进入 trusted_context，也不允许成为专业知识来源。

### 8. 为什么要拆 Agent？

参考答案：为了分离职责和动机。规划者不直接写代码，写代码者不自判通过，验证者独立复查，漂移审计者只看边界和证据。这样降低上下文污染和自证完成风险。

### 9. resident 和 temporary 有什么区别？

参考答案：resident 是长期角色模板，如 Router、Librarian、Verifier、Drift Auditor；temporary 是一次性施工角色，如 Implementer、Tester、Researcher、Integrator。但 resident 也不是复用同一对话，每个 assignment fresh spawn。

### 10. DAG 在 Factory 里怎么落地？

参考答案：`FactoryTask.dependencies` 构成任务图。orchestrator 校验依赖存在、无循环、状态合法；调度时普通任务依赖 verified，verifier 任务依赖目标任务 handoff。

### 11. `prepareSpawnPlan()` 做什么？

参考答案：它读取配置，校验 multi-agent 和 task graph，自动加 verifier tasks，选择 ready wave，生成 Context Packet、baseline、spawn plan、agent registry 和 run metadata。

### 12. FACTORY_ASSIGNMENT 是什么？

参考答案：给 Agent 的施工单，包含 run、assignment、task、profile、context packet、write_scope、acceptance_methods、required_artifacts 和禁止行为。Agent 只能按它执行。

### 13. hooks 为什么重要？

参考答案：hooks 拦截 Codex 工具调用。PreToolUse 阻止未计划 spawn，检查 prompt 和 fork_turns；PostToolUse 读取宿主返回的 native agent id 并登记 receipt；SubagentStop 强制 handoff 格式。

### 14. native agent id 为什么不能自报？

参考答案：Agent 自报只是文本，不能作为身份事实。native agent id 必须来自 Codex 宿主创建 Agent 后的工具响应，再由 Factory 写入 registry 和 receipt。

### 15. registry 代表完成了吗？

参考答案：不代表。registry 只代表 assignment 和 native Agent 已绑定。完成还要 handoff、artifact hash、acceptance checks、verification receipt。

### 16. handoff 为什么不等于完成？

参考答案：handoff 是 Worker 自述和产物声明，状态是 RECORDED_UNVERIFIED。只有 Verifier 独立复查通过并写 receipt 后，任务才 verified。

### 17. write_scope 怎么防越权？

参考答案：开工前记录 baseline，完工后对比真实 diff，再和 handoff changed_paths、assignment write_scope 比较。超范围、漏报、虚报都拒绝。

### 18. Verifier 具体怎么验收？

参考答案：确认 verifier profile 和不同 native id，读取 Worker handoff，重算 artifact hash，检查 required artifacts，执行 acceptance_methods，记录 exit code/stdout/stderr hash，生成 verification receipt。

### 19. 接口漂移怎么发现？

参考答案：harness 里用 contract lock 锁定接口 ID、名称、文件、owner、requiredBy；Worker 提交 manifest；脚本抽取源码 export/import；drift detector 和 honesty checker 对比，不一致则 integration gate FAIL。

### 20. 如果把 FTS5 升级成 Hybrid RAG，怎么保证原来的来源校验和防漂移仍然成立？

参考答案：我不会让 vector chunk 直接成为可信事实。做法是保留 knowledge entry 作为权威父对象，每个 chunk 继承 entry_id、source_uri、source_sha256、roles、status、supersedes、content_digest。向量召回只产生候选；rerank 后仍要过 role/status/source-bound/filter；最终注入 Context Packet 时记录 chunk ids、parent entry digests、source digests 和 packet hash。这样升级召回能力，但不破坏原来的 source binding、role visibility 和 fail-closed 机制。

---

## 附录：源码确认范围

本稿重点依据：

- `packages/factory-cli/src/types.ts`
- `packages/factory-cli/src/config.ts`
- `packages/factory-cli/src/agents.ts`
- `packages/factory-cli/src/knowledge.ts`
- `packages/factory-cli/src/memory-packet.ts`
- `packages/factory-cli/src/context-space.ts`
- `packages/factory-cli/src/orchestrator.ts`
- `packages/factory-cli/src/hooks.ts`
- `packages/factory-cli/src/evidence.ts`
- `packages/factory-cli/src/search.ts`
- `harness/scripts/detect-interface-drift.ps1`
- `harness/scripts/extract-source-interface-manifest.ps1`
- `harness/scripts/compare-worker-manifest-to-source.ps1`
- `harness/scripts/validate-state.ps1`
- `harness/docs/PHASE_6C_U0_CONTRACT_LOCK_MODEL.md`

测试确认：

```text
cd <repo>\packages\factory-cli
npm test

结果：88 tests, 88 pass, 0 fail
```

关键测试覆盖：

- Context Space：拒绝伪造 trusted context、角色过滤、secret 拒绝、admission receipt 防篡改。
- Knowledge：角色可见性、FTS/主表篡改、source drift、supersedes、lifecycle、secret 拒绝、CJK 短词检索。
- Memory orchestration：自动把 role-visible knowledge 注入 assignment packet；不注入其他角色私有知识；source drift 时 planning fail closed。
- Control plane：DAG 校验、capability routing、scope 冲突、自动 verifier、hooks 绑定 native id、unverified handoff 不算完成、baseline 越权检测、receipt 不可变、并发 registry/handoff 保全。
- Search：GLM 搜索 disabled/missing key fail closed、canonical endpoint、证据 redaction、provider id、tampered bundle rejection。

---

## 最后记忆版

如果只记一段：

```text
Codex Factory 的核心是把 AI Coding 变成可验证的工程流水线。
它用 FTS5/BM25 做 source-bound knowledge retrieval，而不是当前就有向量 RAG。
它把检索结果封进 Context Packet，按 run、assignment、role、source、hash 绑定。
它把 Agent 拆成 Router、Librarian、Implementer、Tester、Integrator、Verifier、Drift Auditor 等角色。
Orchestrator 用 DAG、write_scope、acceptance_methods 调度任务，并自动添加 verifier 任务。
Worker 只能交 handoff，handoff 是 RECORDED_UNVERIFIED。
Verifier 必须独立重跑命令、检查 exit code、artifact hash 和 required artifacts，最后用 receipt 才能 PASS。
漂移防护靠 Context Packet、source hash、hooks、native id、registry、baseline diff、verification receipt，以及 harness 层 interface drift gate。
```
