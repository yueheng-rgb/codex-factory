# Codex Factory 第二阶段：真实原生 Agent 评测闭环

日期：2026-09-10。状态：本地实现、真实宿主调用及独立验收完成；未提交或推送 Git，未执行远程 CI。

## 结论

本轮把第一阶段的离线修复演示推进到了真实 Worker / 独立 Verifier 执行：两个公开合成任务、四个 run、八个不同原生 Agent，最终两个任务通过。它证明这组小样本中的派发、交接、验收、失败留存和关联修复能够闭环，**不证明生产成功率，也不是模型能力排行榜**。

| 样本 / 尝试 | 功能验收 | 控制器最终结果 | 原因 | 控制器验收命令耗时 |
| --- | --- | --- | --- | --- |
| normalize，首次实现 | PASS | PASSED | 校验输入、Unicode、稳定去重及不修改输入 | 69 ms |
| lower-bound，人为植入缺陷的原始尝试 | FAIL | FAILED | `<=` 跳过相等元素，错误实现成 upper bound | 66 ms |
| lower-bound，第 1 次关联修复 | PASS | FAILED | 代码已修好，但 Worker 的 Git 诊断和 Verifier 的 CLI 探测有非零退出码 | 101 ms |
| lower-bound，第 2 次关联修复 | PASS | PASSED | 显式补齐 Git 环境；新 Worker 与新 Verifier 重新检查 | 80 ms |

lower-bound 的冻结验收脚本包含 2,567 次断言，不是 2,567 个项目或 Agent。正常实现样本只有 1 个，首次通过数量为 1；故意失败的基线不计入正常首次通过统计。第二次修复没有重复修改正确代码，而是验证环境修正后的同一实现。

## 本轮代码

- `packages/factory-cli/scripts/live-eval.ts`：隔离项目准备、原生派发回执登记、交接采集、独立 Verifier 续波、有界修复和机器报告。
- 两份冻结的 CommonJS 任务种子与验收脚本；仓库中的种子保持原状，Agent 实现在临时评测项目中。
- 新准备的评测项目先初始化本地 Git，不创建提交或 remote。历史评测目录的环境修正单独留证，不覆盖旧 FAIL。
- 交接格式不合格时拒绝入库；允许原 Agent 修正格式，禁止删去失败命令。原始错误交接保留在 `host-observations/rejected/`。
- 中断后的实际完成记录可从宿主任务历史恢复，不编造 wait 结果；两次用量限制导致的失败 turn 独立留存。
- 报告核对验收脚本摘要、运行证据、原生派发摘要、完成消息与入库交接的一致性、修复来源及原始 run 快照。缺少已派发 Agent 的完成记录或交接被改写时拒绝报告。
- 新增评测使用说明、`eval:prepare` / `eval:report` / `eval:typecheck` 命令和 CI 类型检查步骤。未新增运行时依赖或付费 API 集成。

## 验证

| 本地检查 | 结果 |
| --- | --- |
| `npm run typecheck` | 通过 |
| `npm run eval:typecheck` | 通过 |
| `npm test` | 120 通过，0 失败，0 跳过；第一阶段为 117 |
| `npm run build` | 通过 |
| `git diff --check -- packages/factory-cli .github/workflows/factory-cli-v5.yml` | 通过 |
| 真实报告生成与初始 run 快照核对 | 通过，两份初始快照未改变 |
| ZIP 归档逐文件 SHA256 对比 | 186 个文件全部一致，包含隐藏目录 |

新增测试使用明确标识的离线 fixture 验证采集器，不混入真实 Agent 数量。覆盖 Git 预检、种子失败、未完成状态、验收篡改、错误 Agent/未完成消息、越界路径、错误交接结构，以及入库后完成消息被改写的拒绝行为。

## 证据入口

- 机器报告：[FACTORY_NATIVE_EVAL_20260910.json](FACTORY_NATIVE_EVAL_20260910.json)
- 完整评测项目归档：[FACTORY_NATIVE_EVAL_20260910_EVIDENCE.zip](FACTORY_NATIVE_EVAL_20260910_EVIDENCE.zip)
- 使用说明：[evals/README.md](../packages/factory-cli/evals/README.md)
- 第一阶段背景：[FACTORY_RELIABILITY_PHASE1_REPORT.md](FACTORY_RELIABILITY_PHASE1_REPORT.md)

归档 SHA256：`0c5216aea2dfb3e6b7a66496a59057d957d463d06e4e26e4aa13de39de49d0b1`。

原目录：`<temp>\factory-live-eval-hiPvQq`。归档保留 manifest、冻结检查、最终实现、上下文数据库、运行回执、原生工具返回、环境修正记录和八个 Agent 的宿主任务记录。宿主记录为 API 返回的结构化记录，单项输出上限为 5,000 字符，可能被截断，不冒充完整底层会话转储。

`source-provenance.json` 记录 38 个相关源码/配置文件的摘要及当时 Git HEAD；工作区含未提交改动，不把 HEAD 当成完整交付版本。归档包含评测项目，不包含 Factory 源码包。记录中绑定原绝对路径，因此归档供审计，不宣称任意目录解压即可原地继续运行。

复跑准备命令（只生成新隔离项目，不自动派发 Agent）：

```powershell
npm --prefix <repo>\packages\factory-cli run eval:prepare
```

读取本次仍保留在原位置的证据并重新生成报告：

```powershell
npm --prefix <repo>\packages\factory-cli run eval:report -- <temp>\factory-live-eval-hiPvQq\manifest.json
```

## 边界与下一轮

- 本次八个原生 Agent 执行中发生两次宿主用量限制中断；恢复后完成。壁钟时间包含暂停、控制器等待和轮询，不等于推理延迟。宿主未提供逐任务 token 和费用，报告为 null，不是零；未使用重置额度。
- 当前由主控制器调用原生工具并登记回执，不是无人值守 runner，也不证明 Hook 自动触发成功。工具 JSON 和摘要提供可核对的一致性，不是密码学宿主签名。
- `write_scope` 是物理文件基线核对，不是 OS 沙箱；基线排除目录不在业务文件差异断言内。同权限恶意进程防护、掉电耐久性及跨平台验证未覆盖。
- 现有策略把所有已报告非零命令都视为失败，本轮未放宽策略。第一修复的 Verifier 明确把历史 Worker 的 Git 失败注明为历史证据，该重复转述没有当作一次额外宿主中断。
- 下一轮优先研究并设计**验收命令、环境诊断和宿主故障的可审计分类**：由冻结合同或控制器确定类别，不能让 Worker 自行把失败测试降级成诊断；保留原始结果，再验证分类规则。
- 随后增加一个来自 Factory 自身的多文件、依赖关系和回归测试任务，并增加对照与重复运行。先扩大真实业务证据，不急于新增 Dashboard 或复杂检索。

研究依据沿用已确认的第一阶段设计；本轮为 P2 测试补充。任务化检查、边界用例和保留日志的设计参考 [OpenAI 官方评测建议](https://developers.openai.com/api/docs/guides/evaluation-best-practices)。
