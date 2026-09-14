# 一次真实技能复用试用

日期：2026-09-11。范围：1 个 Worker、1 个独立 Verifier、1 个隔离任务，无对照组，无追加修复。

## 结果

**功能验收通过，工厂整体判定 FAIL。** Worker、独立 Verifier 与控制器分别执行的 `node check.cjs` 均通过。
整体失败原因是 Worker 自行用 `JSON.stringify` 的原键顺序检查任务 capsule 哈希，命令退出码为 1；改用排序后计算才通过。原有“已报告非零命令即失败”规则未修改，失败命令完整保留。

实际使用了 `teach capture → draft → publish → apply → plan → 真实 Worker → 真实 Verifier → 控制器验收`。
教学来源是此前真实 BOM 修复的代码快照：代码由助手修改、用户指定用于试用，不冒充用户亲自编写。
临时 Skill 只发布在隔离项目，没有进入主项目的技能目录。

## 观察到的行为

- Worker 真实读取了学习技能，随后实现了本地配置文件读取和独立的严格消息解析入口。
- 文件入口只移除一个前导 BOM，保留字符串内容，并基于原始字节计算 SHA256。
- 消息入口未复用文件兼容逻辑，仍拒绝前导 BOM，体现了技能的排除条件。
- 独立 Verifier 阅读代码并执行原检查，没有修改文件，也未发现实现缺陷。
- 主项目源文件、技能、验收脚本和六个输入文件的摘要保持不变。宿主中断后恢复的是同一个 Worker，没有新增替代 Agent。

## 限制与下一步

这是从真实修复设计出的单个迁移练习，不是生产任务统计。任务描述也明确规定了目标行为，另有自动选中的后端设计技能，因此不能把正确结果归因于新 Skill，不能宣称成功率、节省 token 或费用。
Verifier 指出尾随 BOM、本地文件里的直接 BOM 字符及 UTF-16BE 没有分别设置执行用例，仅经过代码检查；本轮没有扩大测试。

最值得继续改善的是**统一现有任务 capsule 的读取和校验入口，让 Worker 不必猜测摘要算法**。这是减少执行摩擦，不是新增一层审计；本轮不放宽失败策略，也不为取得 PASS 重跑。

## 文件

- [机器结果](FACTORY_SKILL_TRANSFER_20260911.json)：真实 Agent ID、命令记录、验收结果、摘要和限制。
- 隔离目录：`<temp>\factory-bom-transfer-C3mP44`。
- 实现：该目录下 `solution.cjs`；技能：`.agents/skills/factory-learned-local-json-bom-boundary/SKILL.md`。
- 宿主原始响应和完成消息：`.codex-factory/host-observations/`；最终回执：`.codex-factory/runs/transfer/verification/worker/receipt.json`。

只重看功能检查：`node <temp>\factory-bom-transfer-C3mP44\check.cjs`。这不会改变历史 FAIL，也不会重新派发 Agent。临时目录可能被系统清理，机器结果不是完整项目归档。
