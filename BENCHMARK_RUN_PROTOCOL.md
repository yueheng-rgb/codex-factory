# Benchmark Run Protocol

> 每个 Benchmark 执行前必须遵守本协议。不允许跳过步骤，不允许直接开始写代码。

---

## 目的

Benchmark 不是用来做可用业务项目。

Benchmark 是用来测试 **Codex_App_Factory 是否提升了 Codex** 在以下方面的稳定性：

1. 项目类型判断
2. 架构与体量判断
3. Starter 选择
4. 最小闭环实现
5. 运行稳定性（install / typecheck / build / dev）
6. 问题回流与工厂级修复

---

## 固定执行流程

每个 Benchmark 必须按照以下步骤依次执行，不可跳跃：

### Phase A — 读取工厂知识

```
A1. 读取 C:\Codex_App_Factory
A2. 读取 CODEX_BENCHMARK_SUITE.md — 确认当前 benchmark 的定义
A3. 读取 CODEX_CAPABILITY_SCORECARD.md — 确认评分标准
```

### Phase B — 需求理解

```
B1. 只拿 benchmark 的一句话需求开始
B2. 不要看 benchmark 文档中的"预期类型/预期 starter/预期体量"
B3. 用自己的判断做完整 Project Expertise Flow 预分析
```

### Phase C — 预分析输出（需用户确认）

```
C1. 项目类型判断
C2. 体量等级判断 S/M/L/XL
C3. 风险等级判断
C4. Starter 选择 + 选择理由
C5. 为什么不选其他 starter（必须列出）
C6. 用户角色
C7. 核心用户路径
C8. 页面结构
C9. API 草图
C10. 数据模型草图
C11. 权限边界
C12. 第一阶段最小闭环
C13. 暂不实现内容
C14. 最容易出错的 10 个地方

→ 用户确认后才允许进入 Phase D
```

### Phase D — 复制与改造

```
D1. 读取 STARTER_REGISTRY.md
D2. 使用复制脚本复制 starter 到测试目录
D3. 检查 PROJECT_NAME 替换
D4. 检查 PROJECT_NAME 残留
D5. 填写 PROJECT_BRIEF.md
D6. 做最小业务改造（不改 starter，只改测试项目）
```

### Phase E — 运行验证

```
E1. npm install
E2. npm run typecheck
E3. npm run build
E4. npm run dev 短启动 — 确认不崩溃后停止
E5. 如果失败：先判断问题来源，再修复，不允许乱加依赖
```

### Phase F — 评分与记录

```
F1. 对照 CODEX_CAPABILITY_SCORECARD.md 逐项打分
F2. 填写 SCORE_RECORD 模板
F3. 填写 RUN_LOG 模板
F4. 分析失败点 — 属于生成项目问题 / starter 源缺陷 / 脚本缺陷 / skill 缺陷 / 环境
F5. 如果是工厂级问题，回流修复并更新相关文档
```

---

## 禁止事项

| 禁止 | 原因 |
|---|---|
| 一上来写代码 | 必须先预分析 |
| 一上来复制 starter | 必须先判断类型和体量 |
| 所有 benchmark 套同一个 starter | 失去跨类型验证意义 |
| 为通过 build 乱加依赖 | 破坏 starter 精简化设计 |
| 把 mock 项目升级成正式项目 | Benchmark 不是正式交付 |
| 接真实密钥/支付/患者数据/用户数据 | 安全红线 |
| 跳过用户确认直接执行 | 所有 benchmark 必须有确认步骤 |
| 修测试项目不修源 starter | 工厂级缺陷必须回流 |

---

## Benchmark 输出必须包含

每轮 benchmark 完成后，`benchmark-results/runs/` 下必须生成：

1. `SCORE_RECORD.md` — 按 SCORE_RECORD_TEMPLATE 填写
2. `RUN_LOG.md` — 按 RUN_LOG_TEMPLATE 填写
3. `FINAL_REPORT.md` — 简短总结（1 页以内）

三个文件缺一不可。

---

## Clode-Out Integrity Gate (Phase 4T+)

?? benchmark ????????????? PowerShell ????????? benchmark ??????

```powershell
C:\Codex_App_Factory\scripts\test-copy-encoding.ps1
C:\Codex_App_Factory\scripts\test-copy-content-integrity.ps1
```

???????? PASS?exit 0???? BOM?unexpected diff ? Unicode replacement character ????????

???????
- ?? `create-project-from-starter.ps1` ?
- ???? starter ????
- ????????????
- ?? starter ?
