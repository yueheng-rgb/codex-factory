# Codex Factory：客户导入预览实测

日期：2026-09-12。结论：本次单任务实测通过，Factory 状态为 COMPLETE，最终回执为 PASS。

## 本轮完成了什么

- 同一名真实 Worker 实现 importer.cjs、cli.cjs、README.md；另一名独立 Verifier 只读复核。
- 原定 10 项验收全部通过，0 失败、0 跳过；确认示例的单独断言也通过。
- Factory 最终验收再次运行原命令，并检查产物哈希及独立验收提案后生成 PASS 回执。
- 验收脚本、用户策略和 8 个输入文件共 10 项冻结输入均保持不变；没有更换测试、修改判定或修复重跑。
- 可运行副本已归档，复制前后文件哈希一致。不修改 Factory 产品逻辑，不做额外大范围测试。

## 新增功能的实际作用

| 功能 | 本次观察 | 不能据此推断 |
| --- | --- | --- |
| 结果对比澄清 | 用户回复“第一”被记录为 keep-first，进入任务契约；实现、原验收及独立示例断言均满足该选择 | 不能证明所有模糊需求都能被发现 |
| 经验候选筛选 | 4 条预置经验中返回 3 条候选；主控查看全文后仅附加文件 BOM 经验 | 不是语义检索，也不是自动选择全部正确经验 |
| 有边界的 Skill 复用 | Worker 实际读取了 Skill；readLocalJson 只移除一个文件前导 BOM，parseStrictMessage 保持严格；对应正反例均通过 | 要求本身也明确了这些行为，没有无 Skill 对照，不能认定通过由 Skill 导致 |
| 独立证据验收 | Worker 自报 PASS 后尚未交付；独立 Verifier 运行验收，Factory 才记录最终 PASS | 不是操作系统级隔离或自动 Hook 已启用的证明 |
| 假设驱动诊断 | 本轮没有需要诊断的歧义失败，未启用 | 不为展示功能而注入故障，未测不算通过 |

## 真实输出

默认预览：total=4，unique=3，duplicates=1；顺序为 u1、u2、__proto__。
u1 保留第一条 Old phone 和标签 old，没有合并后续记录。u2 标签为 Café、VIP。
previewLimit=0：统计仍为 4 / 3 / 1，preview=[]。

## 开销与结论边界

- 同口径 JSON 序列化：附加经验前任务输入 3,378 字节，附加后 5,720 字节，增加 2,342 字节。它是上下文开销，不是 Token 或费用实测。
- 只附加一条经验是有意识的取舍。其余规则从明确需求实现，没有声称使用未读取的经验。
- 4 条经验及业务输入均为预先编写的离线合成夹具；执行和验收是真实的，但本轮没有从真实业务纠错中现场学习出新 Skill。
- 只有一个任务，没有对照组、重复采样或模型 Token 账单。成功率提升、成本改善、普遍泛化能力均未测得。
- 原 Worker 曾因账号额度中断，本轮恢复同一个 Agent 完成。总跨时段时长包含等待，不能当作执行耗时。
- 最终回执的 508ms 仅为主控最后一次验收命令的耗时，不是端到端 Agent 耗时。
- 原生派发和完成响应由主控保存并绑定；工具包装字段与实际 host_response 已区分。Doctor 的 Hook 信任、scope_guard 非系统隔离限制仍保留。

本轮支持的结论是：用户决策、选择性经验注入、边界保留与独立验收能串成一次可复现交付；不支持“比裸 Codex 更便宜或成功率更高”的比较结论。

## 运行与证据

```powershell
node C:/Codex_App_Factory/outputs/FACTORY_CUSTOMER_PREVIEW_DEMO_20260912/cli.cjs C:/Codex_App_Factory/outputs/FACTORY_CUSTOMER_PREVIEW_DEMO_20260912/fixtures/customers.json
```

[Demo 说明](/C:/Codex_App_Factory/outputs/FACTORY_CUSTOMER_PREVIEW_DEMO_20260912/README.md)

[最终回执](/C:/Codex_App_Factory/outputs/FACTORY_CUSTOMER_PREVIEW_DEMO_20260912/evidence/run/verification/worker/receipt.json)；[原始验收输出](/C:/Codex_App_Factory/outputs/FACTORY_CUSTOMER_PREVIEW_DEMO_20260912/evidence/run/verification/worker/01-stdout.log)；[实际运行输出](/C:/Codex_App_Factory/outputs/FACTORY_CUSTOMER_PREVIEW_DEMO_20260912/evidence/demo-commands.json)。

Worker：01a093cd-9632-7cc0-b508-be10e0975a34；Verifier：01a094ba-648d-7d43-b702-eb1904ba96c0。两者均已关闭，无额外 Agent。

evidence 目录保留初始 manifest、确认选择、筛选记录、任务输入、原生工具响应、恢复记录及完整 run 快照。初始 manifest 中的待确认状态是历史记录，最终选择见 confirmed-decision-view.json 和 policy.json；归档中的原绝对路径用于溯源，不是运行 demo 的依赖。

## 下一步建议

先收敛经验注入成本：对已经在任务契约中完整表达的规则，减少重复正文；保持触发条件、禁止适用条件和可追溯来源。延续现有选择性复用方向，不另起复杂框架，也不把本轮当成已证明收益的 benchmark。
