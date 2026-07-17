# FACTORY-REALWORLD-2-LESSONS-0 Section K: 用户摘要

**Timestamp**: 2026-06-28T11:00:00+08:00

---

## REALWORLD-2 完成了什么

TCM 中医项目台账 Django 线上项目的 5 阶段安全验证：
- 项目摄入发现 9 项安全/部署风险（生产密钥、SSH 凭证、服务器 IP）
- 创建工作副本，本地验证通过（manage.py check 干净，smoke HTTP 200）
- 安全加固：9 个文件变更（配置/文档），0 行应用代码修改
- 测试修复分类：13/23 → 21 pass / 2 skip / 0 fail
- 交付用户审查摘要 + 安全轮换清单

**原始项目 untouched，工作副本 safe for local development。**

---

## 对 Codex Factory 证明了什么

- Build Lite 可安全接手真实线上项目工作副本
- 工作副本隔离机制有效（original 完全 untouched）
- Context Space 支持长周期多阶段项目连续性
- 安全/部署门禁对含生产痕迹项目是必须的
- 测试分类优先 + 诚实跳过策略可行

---

## 没有证明什么

- **Factory 比普通 Codex 更聪明**（无对照比较）
- 项目已可生产部署（密钥尚未轮换）
- v0.5 可以发布（仍 BLOCKED）
- 21/2/0 等于 23/23 全通（2 个 skip 不是 pass）

---

## 你必须做的事

1. 离线轮换所有生产密钥（SSH、SECRET_KEY、SMTP）
2. 轮换后验证部署脚本可用
3. 不要将当前工作副本直接部署到生产
4. 不要在 Codex 对话中粘贴任何密钥值

---

## 建议下一步

- `FACTORY-BUILD-PACK-STAGING-P3`：集成 Security/Deploy Gate + realworld 教训
- 或 `FACTORY-CONTEXT-SPACE-P8`：一键挂载加固
- 或用户自行审查本次 LESSONS-0 全部产出
