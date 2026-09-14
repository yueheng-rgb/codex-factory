# Factory practical walkthrough

本文说明新增三条主线什么时候使用、什么时候跳过，以及离线 demo 会停在哪里。它不是新项目蓝图，也不代表真实 Agent 评测结果。

## 快速体验

在 CLI 源码目录运行：

```powershell
cd <repo>\packages\factory-cli
npm run demo:tour
```

该命令依次运行三个离线案例：

1. 结果对比澄清：用同一输入的不同预期输出确认关键需求。
2. 纠错经验复用：从人工确认的修正中发布一个窄范围 Skill，并附加到另一个待执行任务。
3. 假设驱动排错：对失败任务声明两个候选原因，读取一个预先存在的 JSON 诊断字段，把匹配分支带入修复计划。

demo 使用临时目录、fixture 回执和预写输入；不调用模型、不启动原生 Agent、不证明真实项目已交付。

## 何时使用

使用结果对比澄清：

- 用户需求中有一个行为分歧会改变测试或数据结果。
- 两个候选行为可以用同一输入展示不同输出。
- 需要把确认后的例子带入 worker 描述和 verifier 检查。

使用纠错经验复用：

- 用户明确指出某次单文件 Git 修改代表一条可复用经验。
- 经验有清晰的适用条件、排除条件、反例和来源。
- 后续任务与条件匹配，并且人工愿意把该 Skill 附加到该任务。

使用假设驱动排错：

- 失败原因不唯一，且不同原因能预测某个小型 JSON 诊断字段的不同标量值。
- 诊断文件已经由单独授权的步骤生成。
- 观察结果会改变下一步修复方向。

## 何时跳过

- 需求已经明确，不要为了“流程完整”强行澄清。
- 修正只是一处业务常量或偶然细节，不要发布成通用 Skill。
- 根因已经明确，或者没有可信诊断文件，不要制造假设。
- 任何流程都不能放宽原验收、扩大写范围、跳过独立验证或替代用户确认。

## 命令地图

```powershell
# 澄清
npm run cli -- clarify template --json
npm run cli -- clarify create --file contrast.json --json
npm run cli -- clarify show --id <id>
npm run cli -- clarify choose --id <id> --option <option-id> --draft-hash <hash> --reply <actual-reply> --json

# 教学
npm run cli -- teach template --json
npm run cli -- teach capture --path <tracked-file> --note <user-explanation> --json
npm run cli -- teach draft --source <source-id> --file lesson.json --json
npm run cli -- teach publish --id <lesson-id> --draft-hash <hash> --reply <actual-approval> --json
npm run cli -- teach apply --id <lesson-id> --tasks tasks.json --task <task-id> --reason <why-conditions-match> --json

# 探针
npm run cli -- probe template --json
npm run cli -- probe draft --from-run <run> --task <task> --file probe.json --json
npm run cli -- probe observe --id <probe-id> --draft-hash <hash> --reply <actual-approval> --json
npm run cli -- probe repair-plan --id <probe-id> --json
```

真实任务仍然通过 `tasks validate`、`plan`、`run continue`、`repair prepare/create` 进入现有控制面。

## 交付边界

三条主线只改进决策输入和任务上下文。它们不负责：

- 自动判断语义歧义。
- 自动判断 Skill 一定适用。
- 运行实验或证明根因。
- 启动 Agent、执行产品修复或记录最终 PASS。

最终交付仍以真实文件、命令退出码、artifact hash、handoff、独立 verifier 和 verification receipt 为准。
