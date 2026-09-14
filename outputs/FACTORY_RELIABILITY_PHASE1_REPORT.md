# Codex Factory 第一阶段可靠性迭代

日期：2026-09-09。状态：已实现并完成 Windows 本地验证，未提交或推送 Git。

## 本轮交付

- `run inspect`：只读汇总状态、依赖阻塞、失败原因、派发/handoff/独立验收证据及下一步。区分历史证据完整性与宿主实时状态；查看 FAILED 本身不是命令错误。
- `failed` 终态：不能原地恢复 pending/ready；同状态重试不再改写任务图。失败回执、验收合同及 Worker/Verifier 身份必须一致。
- `repair create`：创建有来源关联的新 run，保留原失败记录。支持 request-id 幂等、项目级并发互斥、父任务唯一子修复、沿链最多2次、scope和验收条件约束，自动生成独立 Verifier。
- 创建中断保护：PREPARING/COMMITTED journal及子 run origin共同控制可见性，正常读取与执行入口拒绝半成品；不自动删除残留或擅自恢复派发。
- README和初始化时生成的主 Agent 协议已接入正式接口。未安装新运行时依赖，未新增Web界面、数据库架构或收费模型调用。

## 验证结果

目录：`<repo>\packages\factory-cli`，Node.js `v24.15.0`。

| 检查 | 结果 |
| --- | --- |
| `npm run typecheck` | 通过 |
| `npm test` | 117通过、0失败、0跳过；基线88，新增29 |
| `npm run build` | 通过 |
| `npm run demo:repair` | 原FAIL → 关联修复 → 新PASS；旧run文件摘要不变 |
| 编译后 `node dist/cli.js` | help、原FAIL诊断、幂等repair create烟雾通过 |
| `git diff --check -- packages/factory-cli` | 通过 |

新增测试覆盖上下文开关、已打开数据库的WAL读取、篡改/缺失回执、验收合同漂移、失败终态重试、并发修改诊断、同请求并发幂等、不同请求并发冲突、两次修复上限、范围扩张、弱化验收、helper依赖、来源回执替换，以及6个写入中断点。

只读实现曾被测试发现仍会创建SQLite辅助文件，现改为校验临时稳定副本并清理；测试比较项目文件内容与文件集合，而不宣称文件系统访问时间不变。

## 复跑与证据

```powershell
npm --prefix <repo>\packages\factory-cli run demo:repair
```

本次演示目录：`<temp>\codex-factory-repair-3AC4IR`。该目录保留 `demo-report.json`、原 run、新 run、回执和真实验收命令日志。复跑会创建新的隔离目录，不覆盖旧演示。

- 原 run：`demo-original`，FAILED。
- 子 run：`repair-r1-bebabf1447e63a0f1c8db5f93f3a237f`，PASSED。
- 验收命令真实检查 `artifact.txt` 内容从 broken 修复为 ready；创建请求重复执行返回相同子 run。
- **宿主派发是显式离线 fixture**，不是实际原生Agent调用。117项本地测试也不等于117次真实Agent执行，不代表远程CI。

实施依据：用户已确认设计；Evidence Pack `EVID-20260908-795-IMPL` 通过实施阶段门禁，记录位于 `.codex-work/factory-reliability/implementation-research-gate.json`。

## 边界与下一步

- 未运行真实宿主Agent闭环、Linux/macOS CI、掉电耐久性测试、消费端tarball安装。当前能力是本地控制平面可靠性，不是OS沙箱或对同权限恶意进程的防护。
- 修复上限采用固定2次的保守策略，未新增可调高上限的配置；修复草稿只支持明确相对路径，不支持root/glob scope。
- 部分创建残留需要保留并调查，不提供自动恢复命令。历史手动failed但无独立回执的run会拒绝作为可信修复来源。
- 数据库副本检查的内存和临时磁盘用量随账本体积增长，大账本性能尚未压测。
- 原有 `RUNTIME_VALIDATION_REPORT.md` 和其他无关改动保留。全仓库diff检查在该既有报告发现尾随空格，本轮没有顺手改动。
- 独立待办：研究门禁在PowerShell7的内容哈希兼容问题仍未定位，本轮使用已通过的Windows PowerShell路径，没有放宽证据校验。

下一阶段建议：建立小型真实Agent评测集，记录任务成功率、修复次数、失败分类、验收耗时，以及宿主实际提供的用量；先验证真实执行效果，再考虑Dashboard或更复杂检索。
