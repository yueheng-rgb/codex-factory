# Codex App Factory Control Plane CLI

`factoryctl` 是 Codex App Factory V5 的本地控制平面。它把可选的原生多 Agent 调度、独立上下文空间、专业知识库、证据验证和 GLM 联网搜索放进同一套项目配置中。

当前版本：`5.0.0-preview.1`。它适合在真实项目中试用和审计，但在 `doctor` 与独立验证通过前，不应把一次 Agent 自述当成最终交付。

## 运行边界

- 支持当前 Codex runtime 所使用的模型。默认继承 Codex 的模型配置，不强制绑定 GPT；在兼容 Codex runtime 中使用 DeepSeek 的开发者也可使用。
- `model_runtime.provider` 只是配置标签，不证明某个第三方模型或网关与 Codex 完全兼容；请以 `doctor` 和真实任务验证为准。
- 多 Agent 是显式开关。关闭时不会生成新的多 Agent 任务计划。
- GLM 搜索是显式开关。没有用户选择和 API Key 时不会调用外部搜索。
- Factory 不依赖 Codex 前端压缩后的上下文作为事实来源。前端仍可显示压缩摘要，但任务依据是外部 Context Packet、仓库文件和可复核证据。
- 当前预览版的 `scope_guard` 会对派发前后的真实文件清单、哈希和波次写入范围做检查，但同一波次内不能把落在其他已批准 scope 的变更归因到具体 Agent；它不是 OS ACL，也不是宿主强制的独立 worktree。`doctor` 会据此返回 `READY_WITH_LIMITATIONS`。

## 环境要求

- Node.js 24 或更高版本（使用内置 `node:sqlite`）
- Git
- 支持项目级自定义 Agent 的 Codex 客户端或 CLI

本包没有运行时 npm 依赖。TypeScript、`tsx` 和 Node 类型仅用于构建、测试与源码运行。

## 安装

当前 Preview 的 npm manifest 保持 `private: true`，尚未发布到公共 registry。Windows 从源码仓库安装时，推荐使用仓库内的安装脚本；它会检查 Node 版本，执行 `npm install`、构建 CLI 并创建本机 `factoryctl` 链接：

```powershell
Set-Location C:\Codex_App_Factory
powershell -ExecutionPolicy Bypass -File .\packages\factory-cli\install.ps1
factoryctl --help
```

也可以在安装的同时初始化一个已经存在的目标项目：

```powershell
powershell -ExecutionPolicy Bypass -File .\packages\factory-cli\install.ps1 `
  -ProjectRoot C:\Projects\my-app `
  -MultiAgent `
  -Search none `
  -MaxThreads 4

factoryctl doctor --project C:\Projects\my-app --json
```

第一次在 Codex 中打开该项目时，执行一次 `/hooks`，审阅并信任 `.codex/hooks.json`。这是 Codex 对新增/变更项目 Hook 的宿主安全确认，Factory 不会绕过；确认后，派发、真实 Agent ID 回执、Subagent 停止检查和压缩上下文恢复均自动执行。

独立上下文默认开启；只有明确不需要时才传 `-NoExternalContext`。如传 `-Search glm`，脚本只开启搜索，不接收 API Key。

手动安装是跨平台和排障时的备用路径：

```powershell
Set-Location C:\Codex_App_Factory\packages\factory-cli
npm install
npm run build
```

不创建本机命令链接也能使用：

```powershell
npm run cli -- --help
```

如需手动创建 `factoryctl` 命令链接：

```powershell
npm link
factoryctl --help
```

`npm link` 会创建本机 npm 链接。Windows 推荐脚本已自动执行该步骤，不要重复执行。

本地构建的 `.tgz` 包含运行所需的 `dist`、9 个专业领域 Skill、README 和 manifest，不包含仓库级 `install.ps1`。如以 tarball 形式做消费端 smoke，可运行 `npm install <local-tgz>`，然后使用安装生成的 `factoryctl` bin；正式 npm 发布与跨平台发行安装器属于 Preview 之后的发布工作。

## 两分钟开始

下面的命令启用多 Agent 和独立上下文空间，但不启用外部搜索：

```powershell
npm run cli -- init `
  --project C:\Projects\my-app `
  --multi-agent `
  --external-context `
  --search none `
  --max-threads 4

npm run cli -- doctor --project C:\Projects\my-app --json
```

初始化后，在 Codex 中打开目标项目。项目内的 Factory 规则会让主 Agent 在适合并行的任务上自动生成计划、派发常驻角色，并按需生成临时 Agent；用户不需要手工开窗口或复制粘贴提示词。

如果项目只需要单 Agent：

```powershell
npm run cli -- init `
  --project C:\Projects\my-app `
  --no-multi-agent `
  --external-context `
  --search none
```

## 功能开关

初始化时可用：

```text
--multi-agent | --no-multi-agent
--external-context | --no-external-context
--search glm | none
--max-threads N
```

之后通过 `configure` 修改，不必重新初始化：

```powershell
npm run cli -- configure --project C:\Projects\my-app --no-multi-agent
npm run cli -- configure --project C:\Projects\my-app --multi-agent --max-threads 4
npm run cli -- configure --project C:\Projects\my-app --search none
```

建议默认保留独立上下文空间；关闭它会失去哈希链、角色 Context Packet 和对前端压缩摘要的隔离边界。

## 自动多 Agent 如何工作

Factory 使用单层调度：主 Agent 负责拆分、派发、等待、纠偏和收口，工作 Agent 不能继续生成孙 Agent。默认保留四个常驻角色配置：

| 角色 | 用途 | 写产品代码 |
| --- | --- | --- |
| Factory Router | 任务路由、依赖与并行波次 | 否 |
| Factory Librarian | Skill、知识和证据检索 | 否 |
| Factory Verifier | 独立复跑验收、拒绝假通过 | 否 |
| Factory Drift Auditor | 检查需求、架构、权限和文件漂移 | 否 |

“常驻”只表示角色配置和专业分工长期存在，不表示后台守护进程，也不复用旧对话。每个 assignment 都生成新的 `fork_turns=none` 隔离执行实例，完成 handoff 后释放线程，避免上一个任务的上下文泄漏。实现、测试、研究、集成等临时工作也只在需要时生成。

初始化会安装 8 个角色协议 Skill 和 9 个专业领域 Skill。角色 Skill 通过 Agent TOML 绑定；领域 Skill 由任务的 `required_capabilities` 或受控推断按 assignment 注入，只加载本次需要的前端、后端、数据库、安全、移动端、产品架构或测试知识。移动项目目录后重新运行 `init` 可刷新绝对路径与 Hook 命令。

`max_threads` 是可同时打开的原生工作 Agent 数，不包含主 Agent。调度器优先给已就绪的独立 Verifier 留出释放后的槽位，避免实现任务长期挤占验证。

Codex 原生自定义 Agent 支持 `nickname_candidates`，因此可显示候选昵称；最终昵称和原生 UI 呈现由 Codex 决定。当前原生配置没有供 Factory 设置每个子 Agent 头像图片的接口。Factory 仪表盘可以显示自己的逻辑 icon，但不应把逻辑 icon 宣称为原生头像。

## 外部 Context Space

独立上下文空间默认位于目标项目的 `.codex-factory/context/`，核心状态使用 SQLite WAL、FTS5 和哈希链。主 Agent 派发任务前生成角色限定、带过期时间的 Context Packet。

可以显式写入、查询和验证上下文：

```powershell
$decision = '{"boundary":"server-side authorization"}'
npm run cli -- context append --project C:\Projects\my-app --kind decision --actor main --payload-json $decision
npm run cli -- context query --project C:\Projects\my-app --query "authentication boundary" --role factory_librarian --limit 20
npm run cli -- context verify --project C:\Projects\my-app --json
```

公开的 `context append` 一律写成 `candidate`，不能靠命令参数自称 verified；只有绑定控制平面回执或独立验证回执的内部准入流程才能进入 `trusted_context`。`frontend_summary` 只能作为不可信备注保存。这不会关闭 Codex 前端自身的压缩显示；它改变的是 Factory 的事实依据。

`--role` 与 Packet 的角色过滤用于阻止 Agent 之间误注入上下文，不是操作系统 ACL。任何能读取项目目录或以同一用户调用 CLI 的进程仍可能直接读取本地数据库，或指定另一个角色查询；不互信或强监管场景需要额外使用独立账号、ACL、容器或隔离 worktree。

子 Agent 在工作前会执行角色、运行和 assignment 绑定验证：

```powershell
factoryctl context packet-verify --project C:\Projects\my-app --file <packet.json> --run run-001 --role implementation --assignment <assignment-id>
```

## 专业知识库

知识条目与 Context Space 共用本地 SQLite，但使用独立的严格表、FTS5 索引、来源 SHA-256、角色可见性和全库完整性锚。前端压缩摘要不能入库。

```powershell
factoryctl knowledge import --project C:\Projects\my-app --file docs\architecture.md --roles "librarian,router" --tags "architecture,approved"
factoryctl knowledge query --project C:\Projects\my-app --query "authorization boundary" --role librarian --limit 10
factoryctl knowledge verify --project C:\Projects\my-app --json
factoryctl knowledge bind --project C:\Projects\my-app --id knowledge-restored-policy --json
factoryctl knowledge retire --project C:\Projects\my-app --id knowledge-old-policy --json
factoryctl knowledge revoke --project C:\Projects\my-app --id knowledge-unsafe-policy --json
```

导入文件必须位于项目内；junction/symlink 越界、二进制或无效 UTF-8、重复来源版本和被篡改的索引都会失败关闭。

`retire` 用于正常的版本替代或知识过时；`revoke` 用于已经确认不应再使用的错误或不安全内容。两者都会保留条目用于审计，但从正常检索结果中排除，并且不能通过状态命令重新激活。常规更新应先导入带 `--supersedes <旧 entry-id>` 的新条目，再 retire 旧条目；不要用 revoke 表示普通版本升级。

从 Knowledge 1.0 升级时，Factory 先验证旧锚点；只有旧条目的 `source_uri` 仍指向项目内普通 UTF-8 文件，并且文件 SHA-256 与正文逐字节匹配时，迁移才会自动标记为 `project_file`。无法证明这一点的旧条目会保守迁移为 `uri_claim`，不会自动注入子 Agent assignment。恢复完全一致的项目文件后运行 `knowledge bind --id <entry>` 可重新验证并受控绑定；如果来源已经产生新修订，则用 `knowledge import --supersedes <旧 ID>` 导入新文件，再 retire 旧条目。旧版 Context Packet 1.0 不会继续通过验证，必须由主 Agent 按当前 run/role/assignment 重新生成，禁止手工修改版本号或哈希。

## Memory Quality V5.1 管理

普通用户不需要打开 SQLite。先用统一状态命令检查 Context Space、知识库和占用空间：

```powershell
factoryctl memory status --project C:\Projects\my-app --json
```

输出会明确区分两件事：

- `trust_boundary.integrity`：数据库结构、索引、锚点、准入回执、已存哈希和项目来源绑定是否完整；
- `trust_boundary.content_verification`：记忆内容是否经过独立事实与证据验证。

`integrity.status=VERIFIED` 只表示存储没有被发现篡改，**不表示记忆里的每个判断都是真实或已经验收**。当前管理命令会把内容验证标为 `NOT_ASSERTED`，防止把“完整性通过”误读为“内容通过”。

需要携带给人工审计时，生成脱敏便携导出：

```powershell
factoryctl memory export `
  --project C:\Projects\my-app `
  --out .codex-factory\exports\memory-audit.json `
  --json
```

导出会隐藏敏感字段、项目 secrets 文件中的值、当前环境里的凭据以及常见 Token 格式，并且拒绝覆盖已有文件。相对路径只能位于项目内；确需导出到项目外时必须传绝对 `.json` 路径，且其父目录必须已存在并且不是 symlink/junction。该文件经过脱敏，适合审计和迁移参考，**不是可以还原 SQLite 哈希链的原始备份**。

查看潜在清理项：

```powershell
factoryctl memory cleanup-plan `
  --project C:\Projects\my-app `
  --older-than-days 30 `
  --json
```

`cleanup-plan` 永远是 dry-run：它只统计过期 Context Packet、达到年龄阈值的不可信前端摘要和已被替代的知识条目，并报告候选数量与字节数。它不会删除或改写文件、账本和知识库；哈希链记录与知识条目需要未来的审计式重写流程，不能直接从 SQLite 手工删除。

## GLM 搜索

先显式启用：

```powershell
npm run cli -- configure --project C:\Projects\my-app --search glm
```

API Key 只从进程环境变量 `ZHIPUAI_API_KEY` 或目标项目本地的 `.codex-factory/secrets.env` 读取。不要把 Key 放进命令参数、`config.json`、任务描述或提交记录。

PowerShell 7 可在当前终端临时设置：

```powershell
$env:ZHIPUAI_API_KEY = Read-Host -MaskInput "GLM API Key"
npm run cli -- search --project C:\Projects\my-app --query "Node.js SQLite WAL official guidance" --json
```

或者用文本编辑器创建仅本机使用的 `.codex-factory/secrets.env`：

```dotenv
ZHIPUAI_API_KEY=replace-with-your-key
```

确认该文件被 `.gitignore` 忽略，并限制本机文件权限。缺少 Key、HTTP 错误或响应不合格时，搜索应失败关闭，不会用 mock 结果假装成功。

## 手动审计入口

当需要排查或审计自动调度时，可使用这些底层命令：

```powershell
npm run cli -- plan --project C:\Projects\my-app --tasks tasks.json --run run-001 --json
npm run cli -- plan --project C:\Projects\my-app --run run-001 --json
npm run cli -- agent status --project C:\Projects\my-app --run run-001 --json
npm run cli -- verify --project C:\Projects\my-app --run run-001 --task auth-service --verifier-assignment <assignment-id-from-plan>
```

`agent register-spawn` 和 `handoff record` 用于主 Agent 把 Codex 原生返回的 Agent ID、昵称和实际交接记录写回运行账本。它们是自动调度协议的一部分，普通用户通常不需要手工调用。

主 Agent 登记原生派发时，必须同时保存原始工具回执，且 `--receipt-json` 与 `--receipt-file` 只能二选一。Agent 自己声称的 ID 不能替代原生回执：

```powershell
npm run cli -- agent register-spawn `
  --project C:\Projects\my-app `
  --run run-001 `
  --assignment <assignment-id> `
  --native-id <native-agent-id> `
  --nickname <nickname-returned-by-codex> `
  --receipt-file .codex-factory\runs\run-001\raw-spawn-receipt.json
```

`agent lifecycle`、`handoff record` 和 `verify` 同样是主 Agent 的底层协议。普通用户通过 `agent status` 与最终验证输出观察它们，不需要手工维护生命周期或制造 handoff。

同一运行会自动循环“plan → 原生派发 → handoff → `plan --run` 续波 → 独立 verify”。若某一 wave 尚有未登记的原生派发，重复 plan 会返回原 assignment，不会覆盖或制造超额线程。

同一 run 的任务图在当前预览版中是不可变合同。若独立验证 FAIL，主 Agent 会保留原 run 和失败证据，再用新的 run ID 建立有界修复 DAG；当前没有同 run 追加/修复 API，不应把失败任务原地改写为 PASS。

## 验证与退出

每次初始化或修改开关后运行：

```powershell
npm run cli -- doctor --project C:\Projects\my-app --json
npm run cli -- context verify --project C:\Projects\my-app --json
npm run cli -- knowledge verify --project C:\Projects\my-app --json
```

关闭某项功能使用 `configure`，当前预览版不宣称提供一键卸载命令。完整移除前先关闭功能并备份 `.codex-factory/`；随后仅删除 Factory 标记为 managed 的项目配置。不要直接覆盖或删除用户已有的 `AGENTS.md`、`.codex/config.toml` 或 `.codex/agents/` 内容。

更完整的安装、运行和故障处理见 [`../../docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md`](../../docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md)。

## 开发

```powershell
npm run typecheck
npm test
npm run build
```

脚本说明：

- `npm run cli -- ...`：直接从 TypeScript 源码运行 CLI。
- `npm run typecheck`：严格类型检查，不写入文件。
- `npm test`：使用 Node test runner 和 `tsx` 运行 TypeScript 测试。
- `npm run build`：输出 ESM、类型声明和 source map 到 `dist/`。
