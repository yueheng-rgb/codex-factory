# Codex App Factory Control Plane CLI

`factoryctl` 是 Codex App Factory V5 的本地控制平面。它把可选的原生多 Agent 调度、独立上下文空间、专业知识库、证据验证和 GLM 联网搜索放进同一套项目配置中。

当前版本：`5.0.0-preview.1`。它适合在真实项目中试用和审计，但在 `doctor` 与独立验证通过前，不应把一次 Agent 自述当成最终交付。

## 先体验三条主线

源码目录安装开发依赖后，执行 `npm run demo:tour`。它依次运行现有的澄清、教学复用和探针修复演示，在临时目录保留摘要与日志；三个案例独立，全部使用离线数据，不调用模型或启动 Agent，也不修改当前项目的 Skill。源码脚本不随安装用 `.tgz` 分发。

实际任务中什么时候启用、什么时候跳过，以及每个演示的停止位置，见[三条主线实用导览](../../docs/FACTORY_PRACTICAL_WALKTHROUGH.zh-CN.md)。

需要分析潜在提升而不运行 Agent 时，可执行 `npm run eval:forecast`。它按明确的示例假设计算净收益、副作用和成本抵消点，输出不代表实测成功率；详见[条件效果分析](../../docs/FACTORY_EFFECT_FORECAST.zh-CN.md)。

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

本地构建的 `.tgz` 包含运行所需的 `dist`、9 个专业领域 Skill、任务示例 `examples`、README 和 manifest，不包含仓库级 `install.ps1`。如以 tarball 形式做消费端 smoke，可运行 `npm install <local-tgz>`，然后使用安装生成的 `factoryctl` bin；正式 npm 发布与跨平台发行安装器属于 Preview 之后的发布工作。

在已安装开发依赖的源码目录执行 `npm run test:package`，可自动构建、生成真实 `.tgz` 并在独立临时目录离线安装。检查通过安装生成的命令运行，覆盖帮助、版本、重复初始化、9 个领域 Skill、`doctor` 和 SQLite 上下文完整性；产物与 `result.json` 保留在输出路径中。此检查已接入 Windows/Ubuntu CI，关闭多 Agent 和联网搜索，不验证真实 Agent 执行或宿主 Hook 信任。

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

## 分阶段演进方向

1. **确认意图**：用同一输入的不同结果澄清关键需求，已实现。
2. **从人工修正中提炼技能**：指定代码修改、保留来源、草拟适用条件与反例、经人工确认发布项目 Skill，本轮实现了最小闭环。
3. **改善决策**：已支持记录两个失败假设、读取获准的诊断 JSON 字段，并将观察结果接入受限修复计划；不自行运行实验。工作流自适应留作后续可选扩展，不自动改权限、验收规则或自身核心代码。

这些都是现有 CLI 的增量功能，不新增训练服务、后台监控或多层 Agent。阶段完成与实际效果提升分开说明。

## 从代码修正中提炼技能

例如你把 `options.retries || 3` 改成 `options.retries ?? 3`，并解释“显式的 0 表示不重试”。Factory 可以协助整理成一条有边界的规则：只有 `null/undefined` 代表缺失时才用这个方法；“空字符串应显示默认名称”属于反例，不能照搬。默认值 3 也不应变成通用规定。

主 Agent 理解修改并编写候选规则；CLI 负责采集来源、核对修改片段、展示草稿和确认发布。**不是模型训练，也不是把任意 diff 自动变成可靠技能。**

在源码目录一条命令查看离线示例，默认停在待审核状态：

```powershell
npm run demo:teach
```

`npm run demo:teach -- --publish-demo` 会在新建的临时 Git 项目内演示发布。样例代码、候选规则与批准回复均明确标注为离线演示；生成的 Skill 是真实文件，但不证明 Agent 在新任务上产生了学习效果。

实际使用由主 Agent 调用以下命令，不需要用户手写 JSON：

```powershell
factoryctl teach capture --project C:\Projects\my-app --path src/retry.mjs --note "0 表示不重试，不能被默认值替换" --json
factoryctl teach template --json
# 主 Agent 根据真实来源编写 lesson.json，不能直接套用模板内容。
factoryctl teach draft --project C:\Projects\my-app --source <source-id> --file lesson.json --json
factoryctl teach show --project C:\Projects\my-app --id <lesson-id>
# 展示全文、适用边界、反例与改动依据，等待真实用户同意后再发布。
factoryctl teach publish --project C:\Projects\my-app --id <lesson-id> --draft-hash <展示的hash> --reply "用户的批准原话" --json
```

首版范围：项目目录必须是 Git 仓库根目录；用户明确指定一个已跟踪的 UTF-8 文本文件，最多 32 KiB；默认比较 `HEAD` 与当前文件，也可用 `--base <用户指定的提交或引用>`。新建、删除、重命名、二进制文件与整仓库采集不在本阶段内。采集不修改索引、不提交代码、不应用补丁；Git diff 在捕获的前后快照上执行，并关闭外部 diff/textconv。

候选格式见[示例](examples/teaching-lesson.json)：1–4 条规则，每条引用实际被移除和新增的片段，附理由、适用条件、不适用情况、不同场景的例子与反例。CLI 验证片段存在和结构完整，不证明因果关系、语义正确性或反例质量。

草稿、完整源文件快照和用户原话留在默认 Git 忽略的 `.codex-factory/teaching/`。发布输出 `.agents/skills/factory-learned-<name>/SKILL.md`，只携带规则、边界、例子和来源标识，不复制完整 diff 或批准原话。该 Skill 可被正常项目技能发现；宿主是否即时刷新需以实际环境为准。已有项目更新 CLI 后，再运行 `factoryctl init --project <root>` 刷新 Factory 管理的工作流段与忽略规则。

| 状态 | 含义 |
| --- | --- |
| `REVIEW_REQUIRED` | 草稿待审核，不是可发现的技能 |
| `APPROVED_NOT_PUBLISHED` | 已保存批准但文件尚未发布，可用同一回复重试 |
| `PUBLISHED` | 已发布文件与批准草稿一致，效果仍是 `UNMEASURED` |
| `CONFLICT` | 目标 Skill 已存在或被修改，保留原文件，不覆盖 |

相同源快照、相同草稿与相同批准可重复调用；不同回复、旧 hash 和篡改记录会被拒绝。已批准但部分写入的技能若内容冲突，也不会被静默覆盖。想修改已发布技能，应另建候选并重新审核，首版不做自动替换。

下次使用时先检查适用条件。单 Agent 可读取已批准 Skill；隔离 Worker 不继承主 Agent 对话，主 Agent 需把相关指导及技能路径放进有边界的任务描述，再按原流程执行与验收。不会把所有学到的规则注入每个任务，也不会自动更新全局偏好。

隐私与信任：复用现有的敏感文件和疑似密钥检查，但它不是完整 DLP，请只选择已脱敏代码。CLI 不上传代码，也不能认证批准者身份或证明修改由谁编写。源文件和注释是待分析资料，不是额外指令；历史快照不代表当前文件版本。

## 用结果对比澄清需求

适用于“同一句需求可能产生两种不同业务结果”的情况，不是每个任务都问一遍。例如“按 ID 去重”可能保留首次值，也可能采用最后传入的更正值。主 Agent 给出同样输入下的两种输出，用户选中后，具体例子才进入执行任务。

流程：**主 Agent 编写对比 → 保存草稿 → 展示并等待用户回答 → 确认生成任务 → 原有执行与独立验收**。CLI 不自行调用模型、检测自然语言歧义或模拟用户，没有引入训练框架或新的 npm 运行时依赖。

从源码目录运行离线示例（默认停在待选择状态）：

```powershell
npm run demo:clarify
```

`npm run demo:clarify -- --option keep-last` 可预览指定分支。系统临时目录保留演示项目，走真实 CLI 到规划为止；示例回答标记为 OFFLINE DEMO，不代表真实用户同意，不调用模型、不生成产品代码、不伪造原生执行。

安装版或主 Agent 的调用方式：

```powershell
factoryctl clarify template --json
factoryctl clarify create --project C:\Projects\my-app --file contrast.json --json
factoryctl clarify show --project C:\Projects\my-app --id <返回的ID>
# 展示后等待真实用户选择，以下参数来自展示内容和用户原话。
factoryctl clarify choose --project C:\Projects\my-app --id <ID> --option keep-last --draft-hash <展示的hash> --reply "用户原话" --json
factoryctl tasks validate --project C:\Projects\my-app --tasks <返回的tasks_file> --json
factoryctl plan --project C:\Projects\my-app --tasks <返回的tasks_file> --run feature-001 --json
```

`template` 输出[完整示例](examples/behavior-contrast.json)。主 Agent 按当前任务改写 `request/question/why_it_matters/task/options`，不能机械套用去重例子。首版只支持一个无前置依赖的 `pending` Worker；原任务需声明可编写测试的范围及可执行验收方法。两项各有 1–3 个输入/预期输出例子，输入须逐项相同，至少一个输出不同。CLI 只检查结构，语义合理性仍需主 Agent 和用户判断。

没有默认选项。两项都不对时，用自由文本澄清并创建新草稿，不强迫二选一。相同草稿重复创建、同一回答重复确认均复用记录；改选、修改已展示草稿、缺少回答或使用旧 hash 会被拒绝。确认记录 `.codex-factory/clarifications/<id>/decision.json` 可直接作为 `tasks validate/plan` 输入，不要提取数组绕过记录校验。

选中的要求与例子进入 Worker 任务描述；原写入范围、产物列表、验收命令均保留。Worker 把例子落实到范围内的测试，独立 Verifier 读取原任务并检查。**确认不是 PASS，示例文本不是执行结果**；CLI 不把自然语言自动编译为验收命令，也不证明测试已覆盖例子。

这是本地协作协议，不认证真实用户身份，也不能阻止有任意文件写权限的人另写普通任务文件。一次决定不更新全局偏好，不替换运行中任务，不用于放宽失败修复契约。多 Agent 关闭时仍可澄清，由单 Agent 按确认契约实现；`plan` 继续遵守多 Agent 开关。

更新 CLI 后，对目标项目再次运行 `factoryctl init --project <root>` 刷新 Factory 管理的 Skill 段，保留现有配置与用户自有段落。澄清记录含用户原话，安装器默认将 `.codex-factory/clarifications/` 加入 Git 忽略规则。原始任务数组和 `{tasks: [...]}` 输入继续兼容。

## 开发任务从启动到交付

主流程是 **确认需求 → 校验任务 → 首次计划 → 原生执行与交接 → 统一推进 → 交付**。不新增后台服务，也不要求用户手工串联底层命令；下面的命令主要由 Codex 主 Agent 调用。

1. 按批准的需求在目标项目内生成 `tasks.json`，只填 `pending/ready` 初始状态。参考 [两阶段模块交付示例](examples/module-delivery.tasks.json)：第一阶段完成实现与相关测试，独立验收通过后第二阶段补齐使用文档。
2. 先只读校验，再生成首波计划：

```powershell
factoryctl tasks validate --project C:\Projects\my-app --tasks tasks.json --json
factoryctl plan --project C:\Projects\my-app --tasks tasks.json --run feature-001 --json
```

`tasks validate` 检查字段、依赖 DAG、角色、写入范围格式和初始状态，展示自动补充的独立 Verifier 与初始就绪任务。它不创建 run、不生成 Packet、不执行验收，也不替代 `doctor`。`VALID` 只代表任务结构有效；线程容量、角色开关与并行范围冲突仍由调度器判定。首次 `plan` 也会先校验输入。

3. 主 Agent 按计划校验 Packet，调用宿主原生工具，登记真实派发回执并等待、记录 handoff。此后统一调用：

```powershell
factoryctl run continue --project C:\Projects\my-app --run feature-001 --json
```

一次调用处理已有 Worker/独立 Verifier 交接的原验收方法，遇到 FAIL 立即停止；仍可推进时返回下一波计划，包括下一阶段工作或独立 Verifier。它不会自行调用模型或宿主 Agent，也不会生成假交接。

| 返回状态 | 主 Agent 下一步 |
| --- | --- |
| `DISPATCH` | 按 `plan.assignments` 派发；先核对宿主，防止中断后重复启动同一个 assignment |
| `WAITING` | 按 `waiting_for` 中的已登记 ID 等待或找回真实交接，不循环空跑 CLI |
| `BLOCKED` | 查看 `next_actions`、依赖或调度限制，解决后再推进 |
| `FAILED` | 保留失败回执，停止新增派发；确认原执行停止并获准修复后创建关联 repair |
| `COMPLETE` | 汇总 `delivery.tasks` 中的产物路径与独立验收回执 |

`delivery` 只包含已 verified 的非 Verifier 任务，失败时保留部分成果，不把未验收工作写成完成。它展示的是**当时 PASS 回执绑定的产物哈希**，不宣称当前文件仍与历史一致。修复 run 只汇总该次修复，原 run 的其他已完成工作仍在原记录中。

与只读 `run inspect` 不同，`run continue` **会执行任务原有的验收命令并更新运行记录**，应仅用于已批准的任务。已通过的验收不重复执行；未登记派发返回原 assignment；等待与终态不生成新波次。`FAILED` 退出 1，正常返回的其他状态退出 0（退出 0 不等于交付完成），参数或运行证据错误退出 1。

主 Agent 应串行调用同一 run 的推进命令。一次调用不是跨文件事务；中途出错时已经完成的回执仍保留，先 `run inspect` 查看状态再重试，不重置任务。这里没有自动无限重试、自动修复或宿主在线状态探测。

更新 CLI 后，对已有目标项目重新运行 `factoryctl init --project <root>`，刷新 managed Skill 协议；不传新的开关时保留已有配置。若生成的 Hook 有变更，仍需按宿主要求审阅信任。

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

启动阅读按角色区分：主控读取配置及完整 `codex-factory` Skill，执行原有 readiness 检查；受派发子 Agent 必须先通过精确绑定 run/role/assignment 的 `context assignment-verify`，随后读取自身 profile、角色 Skill、任务材料和必需专业 Skill。默认不重复加载主控全套说明或执行 whole-project doctor；有具体安装/完整性问题时仍可按需检查。

这只是启动指引的收敛，不豁免用户规则、失败检查、作用域或验收，也不取消独立 Verifier。新安装或按原配置更新项目时生成新版指引，不批量改写旧项目及历史任务。尚未实测这项调整的 Token、费用或耗时收益。

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
factoryctl context assignment-verify --project C:\Projects\my-app --file <context_packet_path> --run run-001 --role implementation --assignment <assignment-id>
```

使用派发计划中的 `context_packet_path` 和角色；同一命令兼容 Context Packet 与关闭外部上下文时的任务胶囊，无需手写 JSON 哈希。成功返回 `valid: true`、输入类型 `kind` 和退出码 0；失败退出码 1，停止该 assignment。原 `context packet-verify` 保留，仅用于 Context Packet。

胶囊检查既有规范化哈希、项目/运行/角色/assignment 绑定，并对照已保存的任务契约；任务状态正常推进不使原胶囊失效。Packet 继续使用原有来源账本和过期检查。校验通过只表示输入有效，不代表任务 PASS，不改写历史运行结果；本地哈希也不是针对同账号任意改写的数字签名。

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

同一运行使用“首次 plan → 原生派发 → handoff → `run continue` 验收并续波”的主流程。`plan --run` 与 `verify` 保留作底层排障入口；单独调用 plan 不会执行独立验收。若某一 wave 尚有未登记的原生派发，重复 plan 会返回原 assignment，不会覆盖或制造超额线程。

新派发提示会列出依赖任务的交接文件位置，供 Worker 按需查看产物路径和当前文件。上下文自动选择保留项目级公共需求，只纳入本 run 的执行记录，避免同名任务串入其他运行。交接内容仍是待核对的报告，不自动等于验收通过，也不扩大写入范围。

同一 run 的任务图在当前预览版中是不可变合同。`failed` 与 `verified` 都是终态，不能改回 pending/ready。独立验证 FAIL 后，保留原 run 和失败证据，通过下面的正式接口建立关联修复 run；不要另起普通 run 来绕过修复限制。

## 失败诊断与有界修复

忘记 run ID 时，先列出当前项目最近创建的运行：

```powershell
npm run cli -- run list --project C:\Projects\my-app
npm run cli -- run list --project C:\Projects\my-app --limit 20 --json
```

默认显示 10 条，`--limit` 为 1–50，按创建时间倒序排列，时间未知的记录排在最后。列表显示已保存状态、已验证任务数/总数（包含独立 Verifier）及修复父 run；无法读取的条目标为 `UNAVAILABLE`，不阻止其余条目显示。空项目返回空列表，不创建运行记录。列表只读，不派发、不重跑验收，也不查询宿主实时在线状态；找到 run ID 后再使用 `run inspect`。

查看状态不会执行 plan、派发 Agent、重跑验收或刷新运行状态：

```powershell
npm run cli -- run inspect --project C:\Projects\my-app --run run-001 --json
```

输出包含 `status`、每个任务的 `failure_reasons`、依赖阻塞、派发/handoff/验收证据引用和 `next_actions`。`integrity: VERIFIED` 只说明历史证据绑定通过，不代表当前工作目录仍符合当时验收，也不证明宿主 Agent 仍在运行；`host_liveness` 明确为 `UNKNOWN`。读到合法 FAILED run 仍退出 0，文件缺失、篡改、部分创建或参数错误退出 1。

`next_actions` 根据当前交接阶段给出下一步：未登记派发时找回原计划并核对宿主；Worker 已交接时提示让调度器安排独立验证；Verifier 已交接时给出包含实际 task/assignment ID 的 `verify` 命令；等待交接时列出已登记 Agent ID。文本输出同时显示阻塞任务 ID。这些是操作指引，查看状态本身不会执行命令，依赖就绪也不代表已绕过并发或写入范围限制。

启用外部上下文时，inspect 在系统临时目录验证数据库及 WAL 的稳定副本，随后清理副本；不在项目数据库上打开连接，不触发迁移或产生新的 WAL/SHM。复制期间发生源变化会拒绝本次读取。这个策略使用与数据库大小相关的内存和临时磁盘空间，不是面向无限大账本的零拷贝查询。

### 从失败证据准备修复

失败后先准备修复上下文，不要立即让 Agent 重写实现：

```powershell
factoryctl repair prepare --project C:\Projects\my-app --from-run run-001 --task auth-service --json
```

该入口只读汇总现有记录，不启动 Agent、不执行验收或诊断命令、不创建项目文件或预留修复次数。启用 Context Space 时沿用 inspect 的系统临时副本读取方式。`run inspect` / `run continue` 遇到 FAILED 会给出带实际任务 ID 的 prepare 指引；安装后的主 Agent 协议也会先使用它。

- `observations` 分别列出控制器验收失败项、产物检查失败项、Worker/Verifier 交接中报告的非零命令及独立 Verifier 提议。每类失败列表最多 20 项，保留总数和完整证据位置；命令日志不整段注入上下文。验收命令日志按检查序号位于 `verification_directory` 的 `01-stdout.log` / `01-stderr.log` 等文件。
- `root_cause=NOT_INFERRED`：描述的是失败发生在哪个环节，不是自动判断代码、环境或宿主故障。Agent 报告的命令不是控制器独立执行的证据；即使原验收全通过，其他失败原因仍保留，不能直接改成 PASS。
- `task_contract` 保留当前失败任务的原始约束；`suggested_tasks` 在上游已 verified 时提供 pending 的同任务草稿，只去掉不重复执行的依赖边，不改变验收和范围。上游未验证时为 null，需显式 helper 计划。
- `upstream_inputs` 提供当前任务及修复祖先中的直接上游产物与回执引用，避免 `--reuse-task` 去掉依赖边后失去输入位置。这里保留历史哈希，不重新证明当前文件正确；复用前仍应查看实际文件。引用不扩大写入范围。
- `repair` 展示已使用/剩余次数及已有直接子修复。`REVIEW_REQUIRED` 只表示可供审阅，不代表批准；`EXISTING_REPAIR` 指向现有修复，失败时转到实际失败的子任务，成功时查看其交付；`BLOCKED` 给出活动执行、次数用尽或部分创建等原因，不建议重复创建。

prepare 成功读取后退出 0，包括 BLOCKED；任务不是已验收失败、记录损坏或参数错误退出 1。修复可用性是读取时的快照，真正 create 仍在既有锁内重新校验。读到已有子修复通过，不会把原失败 run 或其尚未执行的下游任务改成完成。

新修复 assignment 会附带该只读命令，供 Worker 按需查看具体失败及上游输入；其中 `next_actions` 仅供主控制器使用，Worker 不得自行创建运行或派发 Agent。

### 确认后创建修复

审阅准备结果、确认旧执行停止并获得修复批准后，通常只需复用原任务，无需另写 JSON：

```powershell
npm run cli -- repair create `
  --project C:\Projects\my-app `
  --from-run run-001 --task auth-service `
  --reuse-task --request-id auth-repair-001 --json
```

`--reuse-task` 从已保存任务图保留标题、需求、能力、write_scope、验收方法和必需产物，只为失败任务创建新的 pending 执行，并自动生成独立 Verifier。已 verified 的上游任务不重复执行；其产物若也需要重建，应使用显式修复计划。该参数不启动 Agent，不改变原失败记录，也不绕过现有修复上限；同一 request-id 重试仍返回同一个 run。

关联修复的新派发提示自动附带父 run、失败任务、修复次数、失败回执和原任务图的位置。先读回执中的失败原因与验收结果，再按需查看交接和命令日志，不把整份历史日志重复塞入提示词；历史结果不能替代本次验收。外部上下文开关关闭时也提供这些文件指引。

需要拆分辅助任务时，使用项目内的 `repair-tasks.json`，格式与原 `plan --tasks` 一致。`--tasks` 与 `--reuse-task` 不能同时指定。必须保留失败任务的 task_id、profile、能力要求、全部原验收方法和必需产物；仅提供 pending/ready worker，独立 Verifier 自动生成。可以增加有界 helper，但原任务必须传递依赖所有 helper。每个修复任务的 write_scope 必须等于或位于原批准范围内；第一阶段只接受明确相对路径，不接受 `.`、通配符或父目录跳转。

```powershell
npm run cli -- repair create `
  --project C:\Projects\my-app `
  --from-run run-001 --task auth-service `
  --tasks repair-tasks.json --request-id auth-repair-001 --json

# 使用 create 返回的新 run_id，继续既有原生派发与独立验证流程。
npm run cli -- run continue --project C:\Projects\my-app --run <new-run-id> --json
```

- create 只持久化待执行计划，不启动外部 Agent；父 run 中仍有活动或状态不明的执行记录时拒绝创建。主 Agent 必须先核实宿主状态，不能伪造 completed/closed 来通过门禁。
- 相同 request-id 和完全相同输入返回同一个 run；同 ID 不同输入返回 `REQUEST_CONFLICT`。request-id 在项目内唯一。
- 同一父任务只允许一个修复子 run；沿同一根失败任务链最多 **2 次**，本阶段使用固定策略，不开放 CLI 提高上限。额度和幂等校验在项目级锁下执行，PREPARING 也占用预留位置。
- 新 run 使用保留前缀 `repair-r1-`；关联记录位于 `.codex-factory/repairs/<new-run-id>.json`，子 run 的 `repair-origin.json` 绑定该记录。后续派发继续校验原回执与冻结的修复合同。
- 创建采用 PREPARING → COMMITTED 门禁。中断时保留残留并返回 `REPAIR_INCOMPLETE`，inspect/plan/register/handoff/verify 等入口不得执行半成品。先备份并查看 repair journal，核对文件和原回执，由维护者调查或恢复已知良好备份；不要手动改 COMMITTED、删 journal 重试或自行重派。

上述门禁不等于跨文件 ACID、掉电级耐久性、OS 沙箱或对同权限恶意进程的隔离。旧版本中被手动标记 failed、却没有完整独立验收回执的 run 会 fail-closed，不能自动升级成可修复的可信失败。

### 一条命令复跑离线闭环

在源码包目录执行：

```powershell
npm run demo:repair
```

演示在独立系统临时目录生成故意失败的原 run 和修复成功的子 run，输出项目路径及 `demo-report.json`；真实执行文件写入、验收命令、哈希绑定、幂等创建，并断言原 run 未改变。**宿主派发回执是显式离线 fixture，不是真实 Agent 或远程 CI 结果**，不调用收费模型。演示产物保留供检查，不修改调用目录的业务文件；需要时可使用输出 project/run_id 执行 inspect。

## 验证与退出

真实原生 Agent 的小样本评测入口为 `npm run eval:prepare`；该命令只准备隔离项目，不自动派发或消耗模型用量。实际 Worker/独立 Verifier 的运行、回执采集与报告步骤见 [原生评测说明](evals/README.md)。`npm run eval:report -- <manifest.json>` 读取完成证据，`npm run eval:typecheck` 检查评测脚本。两项公开合成任务仅用于验证工作流，不能当作生产成功率。

2026-09-10 已完成一次八个真实 Agent 的小样本闭环，含失败保留、两次关联修复和独立验收；具体结果、环境失败与局限见 [第二阶段评测报告](../../outputs/FACTORY_NATIVE_EVAL_PHASE2_REPORT.md)。

每次初始化或修改开关后运行：

```powershell
npm run cli -- doctor --project C:\Projects\my-app --json
npm run cli -- context verify --project C:\Projects\my-app --json
npm run cli -- knowledge verify --project C:\Projects\my-app --json
```

关闭某项功能使用 `configure`，当前预览版不宣称提供一键卸载命令。完整移除前先关闭功能并备份 `.codex-factory/`；随后仅删除 Factory 标记为 managed 的项目配置。不要直接覆盖或删除用户已有的 `AGENTS.md`、`.codex/config.toml` 或 `.codex/agents/` 内容。

更完整的安装、运行和故障处理见 [`../../docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md`](../../docs/CONTROL_PLANE_V5_GUIDE.zh-CN.md)。

## 把经验带入下一次任务

已有待执行任务文件时，优先获取少量候选，再由主控选定：

```powershell
npm run cli -- teach suggest --project C:\Projects\my-app --tasks tasks.json --task worker --json
```

默认返回最多 3 条已发布且内容未变的经验，`--limit` 可设为 1–5。按标题和任务描述中的词项重合排序，展示 `matched_terms`、适用条件、排除条件及反例；`boundary_overlap_terms` 表示与排除描述重合的词，不是自动否定判断。计数不是概率，至少两个共同词项才会进入候选。完整规则仍在选定后通过 `show/apply` 加载，不自动附加任何 Skill。

词项方法不能理解否定、同义改写或跨语言翻译。返回 `NO_LEXICAL_MATCH` 不代表不存在相关经验；主控确有疑问时可以使用目录查找，但不默认把全库塞进任务。扫描上限为 200 条记录，超过时明确返回 `PARTIAL`、`scan_truncated` 和 `next_catalog_offset`；查询使用前 6,000 字符、最多 64 个有效词项，截断通过 `query_truncated` 标明。它不扫描执行中的任务，也不重写已经附加经验的描述。

固定案例的候选质量、遗漏和体积实测见[经验候选对比](../../docs/FACTORY_LESSON_SELECTION.md)。这不是 Agent 成功率测试，也不保证总成本下降。

本地任务、教学输入和诊断 JSON 使用 UTF-8，兼容文件开头的单个 BOM；读取不会改写原文件，诊断哈希仍基于原始字节。UTF-16 不受支持，字符串内部的 BOM 不会被删除。Windows PowerShell 5.1 的 `Set-Content -Encoding UTF8` 会带 BOM，而直接 `>` 重定向通常产生 UTF-16LE，应明确选择 UTF-8。参见 [PowerShell 编码说明](https://github.com/MicrosoftDocs/PowerShell-Docs/blob/main/reference/5.1/Microsoft.PowerShell.Core/About/about_Character_Encoding.md)。

先查看项目经验目录，不必记住 lesson ID：

```powershell
npm run cli -- teach list --project C:\Projects\my-app
```

目录展示每条经验的状态、适用条件、禁用条件和反例，不输出完整规则、源代码快照或批准回复。主控使用 `--json` 获取 `available_for_reuse` 等结构化字段；默认每页 20 条，按 ID 排序而非相关性排序，可按 `next_offset` 使用 `--offset` / `--limit` 继续浏览。

只有 `PUBLISHED` 且 `available_for_reuse: true` 的经验可以考虑复用。草稿、发布未完成、已修改的 Skill 和无法读取的记录均不可直接应用；`PARTIAL` 表示当前页存在无法读取的记录，不会隐藏其他有效经验或阻断无关任务。列表正常读取时退出码为 0，错误参数等命令级错误才非零退出。

对照当前需求检查条件和反例，没有合适经验就照常执行。选中一条后先用 `teach show --id <lesson-id>` 阅读完整内容，再显式附加到一个待执行 Worker，不必手工复制：

```powershell
npm run cli -- teach show --project C:\Projects\my-app --id <lesson-id>
npm run cli -- teach apply --project C:\Projects\my-app --id <lesson-id> --tasks tasks.json --task worker --reason "说明适用条件为何满足，禁用条件及反例为何不适用" --json
```

输出是包含 `tasks` 的普通任务 JSON。主 Agent 检查后写入项目任务文件，即可用于 `tasks validate` 和 `plan --tasks`；也可接收已确认的澄清 decision 文件，先校验原决定再附加技能。仅指定任务的 description 增加紧凑经验快照：保留规则、理由、适用与禁用条件、正反例、来源、Skill 路径及完整文件哈希，不重复 YAML 元数据与通用发布说明。已发布 Skill 文件和审批哈希不变，其他任务字段和原需求例子不变。这减少的是派发输入字节，不代表总体 Token 或费用下降。

未发布或已改动的 Skill、执行中的任务、直接修改 Verifier 均被拒绝。同一输入重复应用不会堆叠内容。每个任务默认只附加一个窄范围 Skill；CLI 不自动判断业务适用性，也不承诺学会了该方法。生成的任务文件是待审阅的内容快照，不是永久生效的授权记录。`npm run demo:teach -- --publish-demo` 会在临时项目演示发布、目录发现、选择和生成下一任务输入，使用明确标注的离线数据，不代表真实 Agent 的学习效果。

## 命令结果判定

新验证回执记录 `command_policy: rg-files-v1` 和按原命令顺序对应的 `command_outcomes`。可识别的独立 `rg --files` 搜索退出 1 记为 `NO_MATCH`，原退出码仍保留。明确的验收命令、退出 2、未知选项、包装器、插值或复合命令仍按失败处理。不带策略标记的历史回执继续使用严格规则，不会把旧 FAIL 改成 PASS。

## 假设驱动排错（第三阶段最小闭环）

当失败原因不明确时，可以先写两条候选原因、各自预期的诊断值和下一步检查方向，再审批读取一个 JSON 诊断字段。匹配结果只作为调查线索，不宣称证明根因；无法区分就返回 `INCONCLUSIVE`。原因已明确时直接跳过，不增加固定排错仪式。

```powershell
npm run demo:probe -- --observe-demo
```

演示在系统临时目录使用明确标注的离线宿主回执，真实读取故意保留 `retries || 3` 错误的诊断值；不调用模型、不修改当前项目，也不自动修复。真实入口为 `probe template/draft/show/observe`，详见 [使用说明](../../docs/HYPOTHESIS_PROBES.md)。

首版只读一个明确指定的项目内 JSON 文件（最多 64 KiB），不执行脚本，不自动生成诊断文件。草稿绑定原失败回执，读取需要确认准确草稿哈希；结果保存为历史记录，重复调用不会悄悄读取新值。产出诊断的实验仍需单独授权，文件新鲜度和来源仍需人工核实。原验收条件、独立 Verifier 和两次修复上限不变。

### 从诊断进入修复

```powershell
npm run cli -- probe repair-plan --project C:\Projects\my-app --id <probe-id> --json
# 预览任务内容、确认旧执行已停止，并获得正常修复批准后：
npm run cli -- repair create --project C:\Projects\my-app --from-run <failed-run> --task worker --probe <probe-id> --request-id <stable-id> --json
npm run cli -- run continue --project C:\Projects\my-app --run <returned-repair-run> --json
```

`--probe` 与 `--reuse-task`、`--tasks` 三选一，只附加历史诊断线索及准确证据路径，不改变其他任务字段。未观察或无法区分的 probe 不会生成此修复计划；BLOCKED 不提供 tasks，EXISTING_REPAIR 应继续已有修复。同一 request-id 与同一输入重试仍幂等，只有实际创建修复才消耗原有额度。

需要同时使用已发布 Skill 时，把 `probe repair-plan` 的输出作为 `teach apply --tasks` 输入，审阅最终 tasks 后使用 `repair create --tasks`。辅助任务仍走原来的显式计划路径，不自动扩大 scope。`npm run demo:probe -- --repair-demo` 可演示到含诊断线索的 Worker 派发计划，明确停在实际 Agent 启动之前。

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
